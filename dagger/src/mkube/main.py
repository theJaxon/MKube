"""CI pipeline for MKube and the Fedora Vagrant box it runs on.

Everything that can run in a container lives here, so the same steps run on a
laptop (`dagger call ...`) and in any CI system. Building the box itself needs
VirtualBox on an Apple silicon host, so that step stays outside Dagger.
"""

import asyncio
import json
import re
import time
import urllib.error
import urllib.request
from typing import Annotated

import dagger
from dagger import DefaultPath, Doc, Ignore, dag, function, object_type

PACKER_REPO = "https://github.com/theJaxon/Packer.git"
PACKER_IMAGE = "hashicorp/packer:1.16.1"
ANSIBLE_IMAGE = "python:3.13-slim"
ANSIBLE_VERSION = "13.8.0"
RUBY_IMAGE = "ruby:3.4-slim"
GH_IMAGE = "alpine:3.22"
GITHUB_REPO = "theJaxon/MKube"
CATALOG_FILE = "mkube.json"    # every release carries the full catalog; box_url reads the latest
MAX_ASSET_BYTES = 2 * 1024**3  # GitHub release asset size limit


@object_type
class Mkube:
    source: Annotated[
        dagger.Directory,
        Doc("MKube repository"),
        DefaultPath("/"),
        Ignore([".vagrant", "kubeconf", "dagger", "packer", "*.box", "**/.DS_Store"]),
    ]
    box: Annotated[str, Doc("Box name, as config.vm.box references it")] = "the-jaxon/mkube"

    @function
    def packer_template(
        self,
        ref: Annotated[str, Doc("Branch, tag or commit of theJaxon/Packer")] = "main",
        path: Annotated[str, Doc("Template directory inside the Packer repo")] = "Fedora/44",
    ) -> dagger.Directory:
        """Fetch the Packer template the box is built from."""
        return dag.git(PACKER_REPO).ref(ref).tree().directory(path)

    @function
    async def kubernetes_version(
        self,
        template: Annotated[
            dagger.Directory | None, Doc("Packer template directory (defaults to Fedora/44 on main)")
        ] = None,
    ) -> str:
        """Kubernetes version the box is pinned to, e.g. 1.37.1.

        Read from `kubernetes_version` in the Packer template. This is also the box
        version, and the GitHub release is tagged v<version>.
        """
        template = template or self.packer_template()
        hcl = await template.file("fedora.pkr.hcl").contents()
        match = re.search(r'kubernetes_version\s*=\s*"v?(\d+\.\d+\.\d+)"', hcl)
        if not match:
            raise ValueError('no kubernetes_version = "vX.Y.Z" found in fedora.pkr.hcl')
        return match.group(1)

    @function
    async def lint_packer(
        self,
        template: Annotated[
            dagger.Directory | None, Doc("Packer template directory (defaults to Fedora/44 on main)")
        ] = None,
    ) -> str:
        """Check formatting and validate the Packer template."""
        template = template or self.packer_template()
        return await (
            dag.container()
            .from_(PACKER_IMAGE)
            .with_mounted_cache("/root/.config/packer/plugins", dag.cache_volume("packer-plugins"))
            .with_directory("/src", template)
            .with_workdir("/src")
            .with_exec(["packer", "fmt", "-check", "-diff", "."])
            .with_exec(["packer", "init", "."])
            .with_exec(["packer", "validate", "."])
            .stdout()
        )

    @function
    async def lint_ansible(self) -> str:
        """Syntax-check the MKube playbook and its roles."""
        return await (
            dag.container()
            .from_(ANSIBLE_IMAGE)
            .with_mounted_cache("/root/.cache/pip", dag.cache_volume("pip"))
            # Full Ansible bundles kubernetes.core, so no Galaxy download is needed.
            # 13.x ships ansible-core 2.20, matching Fedora 44's ansible package in the box.
            .with_exec(["pip", "install", f"ansible=={ANSIBLE_VERSION}"])
            .with_directory("/src", self.source)
            .with_workdir("/src")
            .with_exec(
                ["ansible-playbook", "--syntax-check", "-i", "controlplane,worker,", "mkube.yml"]
            )
            .stdout()
        )

    @function
    async def lint_vagrantfile(self) -> str:
        """Check the Vagrantfile is valid Ruby."""
        return await (
            dag.container()
            .from_(RUBY_IMAGE)
            .with_file("/src/Vagrantfile", self.source.file("Vagrantfile"))
            .with_exec(["ruby", "-c", "/src/Vagrantfile"])
            .stdout()
        )

    @function
    async def lint(
        self,
        template: Annotated[
            dagger.Directory | None, Doc("Packer template directory (defaults to Fedora/44 on main)")
        ] = None,
    ) -> str:
        """Run every lint check concurrently."""
        results = await asyncio.gather(
            self.lint_packer(template), self.lint_ansible(), self.lint_vagrantfile()
        )
        return "\n".join(results)

    @function
    async def published_version(self) -> str:
        """Latest box version in the GitHub Releases catalog."""
        try:
            catalog = await asyncio.to_thread(_get_json, _catalog_url(GITHUB_REPO))
        except urllib.error.HTTPError as err:
            if err.code == 404:
                return ""
            raise
        versions = [v["version"] for v in catalog.get("versions", [])]
        return max(versions, key=_version_key, default="")

    @function
    async def publish(
        self,
        box_file: Annotated[dagger.File, Doc("The .box produced by Packer")],
        version: Annotated[str, Doc("Version to publish, e.g. 1.37.1")],
        github_token: Annotated[dagger.Secret, Doc("GitHub token with contents: write on the repo")],
        repo: Annotated[str, Doc("GitHub repository hosting the releases")] = GITHUB_REPO,
    ) -> str:
        """Upload the box to GitHub Releases and add it to the Vagrant catalog.

        Each version gets one release, tagged v<version>, holding the box and the Vagrant
        catalog (`mkube.json`). The catalog lists every version, so config.vm.box_url can
        point at the latest release's copy. Rebuilds of the same version replace both
        assets in place.
        """
        size = await box_file.size()
        if size > MAX_ASSET_BYTES:
            raise ValueError(
                f"box is {size / 1024**3:.2f} GiB; GitHub release assets are limited to 2 GiB"
            )
        checksum = (await box_file.digest(exclude_metadata=True)).removeprefix("sha256:")
        tag = f"v{version}"
        asset = f"mkube-{version}-virtualbox-arm64.box"
        url = f"https://github.com/{repo}/releases/download/{tag}/{asset}"

        gh = (
            _gh(github_token, repo)
            # Publishing changes GitHub, so never reuse a cached result
            .with_env_variable("CACHE_BUSTER", str(time.time_ns()))
        )

        # Read the catalog from the current latest release before creating a new one,
        # so every earlier version stays listed
        latest = (await gh.with_exec(
            ["sh", "-c", "gh release view --json tagName -q .tagName 2>/dev/null || true"]
        ).stdout()).strip()
        current = await gh.with_exec(
            ["sh", "-c", f"gh release download {latest} -p {CATALOG_FILE} -O - 2>/dev/null || echo '{{}}'"]
        ).stdout() if latest else "{}"
        catalog = _update_catalog(json.loads(current or "{}"), self.box, version, url, checksum)

        published = (
            gh.with_mounted_file(f"/work/{asset}", box_file)
            .with_new_file(f"/work/{CATALOG_FILE}", json.dumps(catalog, indent=2) + "\n")
            .with_exec(["sh", "-c", _ensure_release(tag, f"MKube box {version}",
                                                    f"Fedora box with Kubernetes {version} for MKube.")])
            .with_exec(["gh", "release", "upload", tag, f"/work/{asset}", f"/work/{CATALOG_FILE}", "--clobber"])
        )
        # Rebuilding an older version: keep the latest release's catalog in sync too
        if latest and latest != tag and _version_key(latest) > _version_key(tag):
            published = published.with_exec(
                ["gh", "release", "upload", latest, f"/work/{CATALOG_FILE}", "--clobber"]
            )
        await published.sync()
        return f"Published {self.box} {version} ({size / 1024**3:.2f} GiB): {url}"

    @function
    async def bump(
        self,
        version: Annotated[str, Doc("Box version to point MKube at")],
    ) -> dagger.Directory:
        """Point the Vagrantfile and README at a new box version.

        Returns only the changed files, ready to `export` over the repo root.
        """
        vagrantfile = await self.source.file("Vagrantfile").contents()
        vagrantfile, count = re.subn(
            r'(config\.vm\.box_version\s*=\s*)"[^"]*"', rf'\g<1>"{version}"', vagrantfile
        )
        if count != 1:
            raise ValueError("couldn't find config.vm.box_version in Vagrantfile")

        readme = await self.source.file("README.md").contents()
        minor = ".".join(version.split(".")[:2])
        readme = re.sub(r"MKube%20[\d.]+", f"MKube%20{minor}", readme)

        return (
            dag.directory()
            .with_new_file("Vagrantfile", vagrantfile)
            .with_new_file("README.md", readme)
        )


def _gh(token: dagger.Secret, repo: str) -> dagger.Container:
    return (
        dag.container()
        .from_(GH_IMAGE)
        .with_exec(["apk", "add", "--no-cache", "github-cli"])
        .with_secret_variable("GH_TOKEN", token)
        .with_env_variable("GH_REPO", repo)
        .with_workdir("/work")
    )


def _ensure_release(tag: str, title: str, notes: str) -> str:
    """Shell snippet that creates a release only if it doesn't exist yet."""
    return (
        f"gh release view {tag} >/dev/null 2>&1 || "
        f"gh release create {tag} --title '{title}' --notes '{notes}'"
    )


def _update_catalog(catalog: dict, box: str, version: str, url: str, checksum: str) -> dict:
    """Add or replace one version in Vagrant's box metadata format."""
    provider = {
        "name": "virtualbox",
        "architecture": "arm64",
        "default_architecture": True,
        "url": url,
        "checksum_type": "sha256",
        "checksum": checksum,
    }
    versions = [v for v in catalog.get("versions", []) if v.get("version") != version]
    versions.append({"version": version, "providers": [provider]})
    versions.sort(key=lambda v: _version_key(v["version"]))
    return {"name": box, "versions": versions}


def _version_key(version: str) -> tuple[int, ...]:
    return tuple(int(part) for part in re.findall(r"\d+", version))


def _catalog_url(repo: str) -> str:
    return f"https://github.com/{repo}/releases/latest/download/{CATALOG_FILE}"


def _get_json(url: str) -> dict:
    with urllib.request.urlopen(url, timeout=30) as resp:
        return json.load(resp)
