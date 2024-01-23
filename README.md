# MKube
Just like Kontainer8 but for Mac M1

---

### Running Vagrant on Mac M1
- Following the gist [Vagrant and VMWare Fusion 13 Player on Apple M1 Pro](https://gist.github.com/sbailliez/2305d831ebcf56094fd432a8717bed93)
- Initially the main limitation was the lack of Boxes that i was able to use, then I found [some other Vagrant boxes by gyptazy](https://app.vagrantup.com/gyptazy), currently for this project the box [gyptazy/ubuntu22.04-arm64](https://app.vagrantup.com/gyptazy/boxes/ubuntu22.04-arm64/versions/1.0.1) is being used

---

### Helper Projects
1. [ContainerD](https://containerd.io/) - Container Runtime
2. [Flannel](https://github.com/flannel-io/flannel) - Container Network Interface
3. [Podman](https://podman.io/) - For building container images
4. [NGINX Ingress Controller](https://docs.nginx.com/nginx-ingress-controller/)
5. [Local Path Provisioner](https://github.com/rancher/local-path-provisioner) Dynamic provisioning (Used as default storage class)
