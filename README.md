# MKube

![Mkube](https://img.shields.io/badge/-MKube%201.35-326CE5?style=for-the-badge&logo=Kubernetes&logoColor=white)

Provision your local Kubeadm Kubernetes cluster with Vagrant and ansible.

MKube is Just like [Kontainer8](https://github.com/theJaxon/Kontainer8) but for Mac with Apple silicon chip (M1/2/3/4).

---

### Prerequisites
- [Virtualbox](https://www.virtualbox.org/wiki/Downloads)
- [Vagrant](https://developer.hashicorp.com/vagrant/install)

---

### How to use
```bash
# Clone the repo
git clone https://github.com/theJaxon/MKube.git

cd MKube

# Start the machines 
vagrant up

# SSH into any of the machines 
vagrant ssh < controlplane | worker >
```

---

### Versions Used
- Vagrant V2.4.9
- Virtualbox 7.2.6
- Kubeadm 1.35.0
- Fedora **43**

---

### Helper Projects
1. [ContainerD](https://cri-o.io/) - Container Runtime
2. [Cilium](https://cilium.io/use-cases/cni/) - Container Network Interface
3. [NGINX Ingress Controller](https://docs.nginx.com/nginx-ingress-controller/)
4. [Local Path Provisioner](https://github.com/rancher/local-path-provisioner) Dynamic provisioning (Used as default storage class)

---

### References
1. [Oracle VirtualBox 7.2 introduces support for macOS on Apple Silicon and Microsoft Windows for Arm](https://blogs.oracle.com/developers/oracle-virtualbox-72)
2. [Kubernetes cluster with Kubeadm on Fedora](https://docs.fedoraproject.org/en-US/quick-docs/using-kubernetes-kubeadm/)
3. [chef/bento Packer Templates](https://github.com/chef/bento)