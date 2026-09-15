Vagrant.configure("2") do |config|
    config.vm.define "rocky6" do |config|
    config.vm.box = "generic/rocky9"
    config.vm.hostname = "rocky6"

    config.vm.network "private_network", ip: "192.168.56.112"

    config.vm.disk :disk, size: "10GB", name: "secondo_disco"

    config.vm.provider "virtualbox" do |vb|
        vb.memory = "1024"
        vb.cpus = 1
    end

  end
end
