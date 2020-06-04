# -*- mode: ruby -*-
# vi: set ft=ruby :

k8sMasterIP = "192.168.205.10"
k8sNode1IP  = "192.168.205.11"
k8sNode2IP  = "192.168.205.12"
dockerRegistry = ENV["DOCKER_REGISTRY"]
k8sType = ENV["K8S_TYPE"]

multiNodes = [
    {
        :name => "k8s-master",
        :type => "master",
        :box => "ubuntu/xenial64",
        :box_version => "20180831.0.0",
        :eth1 => k8sMasterIP,
        :mem => "4096",
        :cpu => "2",
        :disk => "50GB"
    },
    {
        :name => "k8s-node1",
        :type => "node",
        :box => "ubuntu/xenial64",
        :box_version => "20180831.0.0",
        :eth1 => k8sNode1IP,
        :mem => "8192",
        :cpu => "2",
        :disk => "50GB"
    },
    {
        :name => "k8s-node2",
        :type => "node",
        :box => "ubuntu/xenial64",
        :box_version => "20180831.0.0",
        :eth1 => k8sNode2IP,
        :mem => "4096",
        :cpu => "2",
        :disk => "50GB"
    }
]

singleNode = [
    {
        :name => "k8s-master",
        :type => "master",
        :box => "ubuntu/xenial64",
        :box_version => "20180831.0.0",
        :eth1 => k8sMasterIP,
        :mem => "3072",
        :cpu => "2",
        :disk => "10GB"
    }
]

k8sType = "multi" if k8sType.nil? || k8sType.empty?

if k8sType != "single" && k8sType != "multi"
    puts "only k8s type of 'single' and 'multi' is acceptable"
    exit
end

if dockerRegistry.nil? || dockerRegistry.empty?
    puts "you need to define the env variable DOCKER_REGISTRY"
    exit
end

servers = multiNodes
if k8sType == "single"
    servers = singleNode
end

puts "Kubernetes deployment type is #{k8sType}"
puts "Docker registry is #{dockerRegistry}"

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
                if k8sType == "single"
                    config.vm.provision "shell",
                    env: {
                        "K8S_MASTER_IP" => k8sMasterIP,
                        "DOCKER_REGISTRY" => dockerRegistry
                    },
                    path: "configure_master_single.sh"
                else
                    config.vm.provision "shell",
                    env: {
                        "K8S_NODE1IP_IP" => k8sNode1IP,
                        "K8S_NODE2IP_IP" => k8sNode2IP,
                        "DOCKER_REGISTRY" => dockerRegistry
                    },
                    path: "configure_master_multi.sh"
                end
            else
                config.vm.provision "shell",
                env: {
                    "K8S_MASTER_IP" => k8sMasterIP,
                    "DOCKER_REGISTRY" => dockerRegistry
                },
                path: "configure_worker.sh"
            end
        end
    end
end 
