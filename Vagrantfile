
Vagrant.configure("2") do |config|

  config.vm.box = "ubuntu/bionic64"
 
  config.vm.network "forwarded_port", guest: 8085, host: 8086

 
  config.vm.provider "virtualbox" do |vb|
    vb.memory = "2048"
    vb.cpus   = 2
  end
   
  config.vm.provision "ansible" do |ansible|
   	ansible.playbook = "build-playbook.yml"
  end
end
