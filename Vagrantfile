Host = Struct.new(:hostname, :ip_address, :cpus, :memory)
machines = [
  Host.new('worker'      , '192.168.100.11', 2, 2048),
  Host.new('controlplane', '192.168.100.10', 2, 6144)
]

Vagrant.configure("2") do |config|
  config.vm.box = "the-jaxon/mkube"
  config.vm.box_version = "1.32"
  config.vm.synced_folder ".", "/vagrant"
  config.ssh.insert_key = false
  machines.each do |machine|
    config.vm.define machine.hostname do |node|
      node.vm.hostname = machine.hostname
      node.vm.network "private_network", ip: machine.ip_address
      node.vm.provider "vmware_fusion" do |vf|
        vf.cpus = machine.cpus
        vf.memory = machine.memory
      end
      node.vm.provision "shell", path: "scripts/assign_static_ip_address.sh", env: {"IP_ADDRESS" => machine.ip_address }
      node.vm.provision "ansible_local" do |ansible|
        ansible.playbook = "mkube.yml"
        ansible.config_file = "ansible.cfg"
        ansible.raw_arguments = ['--become']
      end
    end
  end
end