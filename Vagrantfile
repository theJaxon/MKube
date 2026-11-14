Host = Struct.new(:hostname, :ip_address, :cpus, :memory)
machines = [
  Host.new('worker'      , '192.168.100.11', 2, 6144),
  Host.new('controlplane', '192.168.100.10', 2, 2048)
]

Vagrant.configure("2") do |config|
  config.vm.box = "the-jaxon/mkube"
  config.vm.box_url = "file://#{__dir__}/mkube.json"
  config.vm.box_version = "1.37.1"
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
        # Optional Argo CD Core: MKUBE_ARGOCD_REPO_URL=<git url> [MKUBE_ARGOCD_REPO_BRANCH=<branch>] vagrant up
        argocd_vars = {
          argocd_repo_url: ENV['MKUBE_ARGOCD_REPO_URL'],
          argocd_repo_branch: ENV['MKUBE_ARGOCD_REPO_BRANCH']
        }.reject { |_, v| v.to_s.strip.empty? }
        ansible.extra_vars = argocd_vars unless argocd_vars.empty?
      end
    end
  end
end
