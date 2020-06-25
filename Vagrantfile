# -*- mode: ruby -*-
# vi: set ft=ruby :

k8sMasterIP = "192.168.205.10"
k8sNode1IP  = "192.168.205.11"
k8sNode2IP  = "192.168.205.12"
insecureRegistries = ENV["INSECURE_REGISTRIES"]
k8sType = ENV["CLUSTER_TYPE"]

multiNodes = [
    {
        :name => "k8s-master",
        :type => "master",
        :box => "ubuntu/xenial64",
        :box_version => "20200514.0.0",
        :eth1 => k8sMasterIP,
        :mem => "4096",
        :cpu => "2",
        :disk => "20GB"
    },
    {
        :name => "k8s-node1",
        :type => "node",
        :box => "ubuntu/xenial64",
        :box_version => "20200514.0.0",
        :eth1 => k8sNode1IP,
        :mem => "8192",
        :cpu => "2",
        :disk => "30GB"
    },
    {
        :name => "k8s-node2",
        :type => "node",
        :box => "ubuntu/xenial64",
        :box_version => "20200514.0.0",
        :eth1 => k8sNode2IP,
        :mem => "4096",
        :cpu => "2",
        :disk => "30GB"
    }
]

singleNode = [
    {
        :name => "k8s-master",
        :type => "master",
        :box => "ubuntu/xenial64",
        :box_version => "20200514.0.0",
        :eth1 => k8sMasterIP,
        :mem => "5000",
        :cpu => "2",
        :disk => "20GB"
    }
]

k8sType = "single" if k8sType.nil? || k8sType.empty?

if k8sType != "single" && k8sType != "multi"
    puts "only k8s type of 'single' and 'multi' is acceptable"
    exit
end

servers = multiNodes
if k8sType == "single"
    servers = singleNode
end

puts "Kubernetes deployment type is #{k8sType}"
puts "Insecure Docker registries are: #{insecureRegistries}"

Vagrant.configure("2") do |config|
    servers.each do |opts|
        config.vm.define opts[:name] do |config|

            config.vm.box = opts[:box]
            # requires vagrant plugin vagrant-disksize
            config.disksize.size = opts[:disk]
            config.vm.box_version = opts[:box_version]
            config.vm.hostname = opts[:name]
            config.vm.network :private_network, ip: opts[:eth1]

            config.vm.provider "virtualbox" do |v|
                v.name = opts[:name]
            	v.customize ["modifyvm", :id, "--groups", "/LocalCluster"]
                v.customize ["modifyvm", :id, "--memory", opts[:mem]]
                v.customize ["modifyvm", :id, "--cpus", opts[:cpu]]

            end

            # we cannot use this because we can't install the docker version we want - https://github.com/hashicorp/vagrant/issues/4871
            #config.vm.provision "docker"

            config.vm.provision "shell", path: "configure_box.sh"

            if opts[:type] == "master"
                config.vm.provision "shell",
                env: {
                    "K8S_MASTER_IP" => k8sMasterIP,
                    "K8S_NODE1IP_IP" => k8sNode1IP,
                    "K8S_NODE2IP_IP" => k8sNode2IP,
                    "INSECURE_REGISTRIES" => insecureRegistries,
                    "CLUSTER_TYPE" => k8sType
                },
                path: "configure_master.sh"
            else
                config.vm.provision "shell",
                env: {
                    "K8S_MASTER_IP" => k8sMasterIP,
                    "INSECURE_REGISTRIES" => insecureRegistries,
                    "CLUSTER_TYPE" => k8sType
                },
                path: "configure_worker.sh"
            end
        end
    end
end 
