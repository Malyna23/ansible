servers=[
  {
    :hostname => "web",
    :ip => "192.168.56.2",
    :box => "centos/7",
    :ram => 1024,
    :cpu => 1
  },
  {
    :hostname => "web1",
    :ip => "192.168.56.3",
    :box => "centos/7",
    :ram => 1024,
    :cpu => 1
  },
  {
    :hostname => "web2",
    :ip => "192.168.56.4",
    :box => "centos/7",
    :ram => 1024,
    :cpu => 1
  }
]

Vagrant.configure(2) do |config|
  servers.each do |machine|
      config.vm.define machine[:hostname] do |node|
          node.vm.box = machine[:box]
          node.vm.hostname = machine[:hostname]
          node.vm.network "private_network", ip: machine[:ip]
          node.vm.network "public_network", machine
          node.vm.provider "virtualbox" do |vb|
              vb.customize ["modifyvm", :id, "--memory", machine[:ram]]
          end
          if machine == servers[2]
            node.vm.provision "file", source: ".vagrant/machines", destination: "~/"
            node.vm.provision "shell", path: "ansible.sh"
          end
      end
  end
end
