# MKube

![Mkube](https://img.shields.io/badge/-MKube%201.31.5-326CE5?style=for-the-badge&logo=Kubernetes&logoColor=white)

Just like [Kontainer8](https://github.com/theJaxon/Kontainer8) but for Mac M1

---

### Running Vagrant on Mac M1
- Following the gist [Vagrant and VMWare Fusion 13 Player on Apple M1 Pro](https://gist.github.com/sbailliez/2305d831ebcf56094fd432a8717bed93)

---

### Versions used
- Vagrant V2.4.3
- VMWare Fusion Player V13.6.2 (24409261)
- Kubeadm 1.29.12-1
- Fedora 40

---

### Helper Projects
1. [ContainerD](https://containerd.io/) - Container Runtime
2. [Flannel](https://github.com/flannel-io/flannel) - Container Network Interface
3. [Podman](https://podman.io/) - For building container images
4. [NGINX Ingress Controller](https://docs.nginx.com/nginx-ingress-controller/)
5. [Local Path Provisioner](https://github.com/rancher/local-path-provisioner) Dynamic provisioning (Used as default storage class)
