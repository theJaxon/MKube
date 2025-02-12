Vagrant.configure("2") do |config|
  config.vm.box = "bento/fedora-40"
  config.vm.box_version = "202407.22.0"
  config.vm.synced_folder ".", "/vagrant",
  config.vm.box_check_update = false
  config.vm.box_download_insecure = true

    config.vm.define "worker" do |worker|
      worker.vm.hostname = "worker"
      worker.vm.network "private_network", ip: "192.168.100.11"
      worker.vm.provider "vmware_fusion" do |vb|
        vb.memory = 6144
        vb.cpus = 2
        vb.ssh_info_public = true
        vb.gui = false
        vb.linked_clone = false
        vb.vmx["ethernet0.virtualdev"] = "vmxnet3"
      end
    end
  
    config.vm.define "master" do |master|
      master.vm.hostname = "master"
      master.vm.network "private_network", ip: "192.168.100.10"
      master.vm.provider "vmware_fusion" do |vb|
        vb.cpus = 2
        vb.memory = "2048"
        vb.ssh_info_public = true
        vb.gui = false
        vb.linked_clone = false
        vb.vmx["ethernet0.virtualdev"] = "vmxnet3"
      end
    end

    config.vm.provision "shell", inline: <<-SHELL
      nmcli conn modify 'Wired connection 2' ipv4.addresses $(cat /etc/sysconfig/network-scripts/ifcfg-eth1 | grep IPADDR | cut -d "=" -f2)/24
      nmcli conn modify 'Wired connection 2' ipv4.method manual
      service NetworkManager restart
    SHELL

    config.vm.provision "ansible_local" do |ansible|
      ansible.playbook = "mkube.yml"
      ansible.galaxy_role_file = 'requirements.yml'
      ansible.raw_arguments = ['--become']
    end
  end