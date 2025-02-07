# MKube

![Mkube](https://img.shields.io/badge/-MKube%201.29-326CE5?style=for-the-badge&logo=Kubernetes&logoColor=white)

Provision your local Kubeadm Kubernetes cluster with Vagrant and ansible.

MKube is Just like [Kontainer8](https://github.com/theJaxon/Kontainer8) but for Mac M1.

---

### How to use
```bash
# Clone the repo
git clone https://github.com/theJaxon/MKube.git

cd MKube

# Start the machines 
vagrant up

# Optional: Download kubeconfig file to use it with headlamp
scp vagrant@192.168.100.10:~/.kube/conf kubeconf

# SSH into any of the machines 
vagrant ssh < master | worker >
```

---

### Versions Used
- Vagrant V2.4.3
- VMWare Fusion Player V13.6.2 (24409261)
- Kubeadm 1.29.12-1
- Fedora 40

---

### Helper Projects
1. [ContainerD](https://cri-o.io/) - Container Runtime
2. [Cilium](https://cilium.io/use-cases/cni/) - Container Network Interface
3. [NGINX Ingress Controller](https://docs.nginx.com/nginx-ingress-controller/)
4. [Local Path Provisioner](https://github.com/rancher/local-path-provisioner) Dynamic provisioning (Used as default storage class)

---

### References
1. [Vagrant and VMWare Fusion 13 Player on Apple M1 Pro](https://gist.github.com/sbailliez/2305d831ebcf56094fd432a8717bed93)
2. [Kubernetes cluster with Kubeadm on Fedora](https://docs.fedoraproject.org/en-US/quick-docs/using-kubernetes-kubeadm/)
