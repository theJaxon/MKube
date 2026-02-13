Host = Struct.new(:hostname, :ip_address, :cpus, :memory)
machines = [
  Host.new('worker'      , '192.168.100.11', 2, 6144),
  Host.new('controlplane', '192.168.100.10', 2, 2048)
]

Vagrant.configure("2") do |config|
  config.vm.box = "the-jaxon/mkube"
  config.vm.box_version = "1.35"
  config.vm.synced_folder ".", "/vagrant"
  config.ssh.insert_key = false
  machines.each do |machine|
    config.vm.define machine.hostname do |node|
      node.vm.hostname = machine.hostname
      node.vm.network "private_network", ip: machine.ip_address
      if machine.hostname == 'worker'
        node.vm.disk :disk, size: "40GB", primary: true
      end
      node.vm.provider "virtualbox" do |vb|
        vb.cpus = machine.cpus
        vb.memory = machine.memory
      end
      node.vm.provision "ansible_local" do |ansible|
        ansible.playbook = "mkube.yml"
        ansible.config_file = "ansible.cfg"
        ansible.raw_arguments = ['--become']
      end
    end
  end
end