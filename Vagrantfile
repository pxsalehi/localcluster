# -*- mode: ruby -*-
# vi: set ft=ruby :

multiNodes = [
    {
        :name => "k8s-head",
        :type => "master",
        :box => "ubuntu/xenial64",
        :box_version => "20180831.0.0",
        :eth1 => "192.168.205.10",
        :mem => "4096",
        :cpu => "2",
        :disk => "50GB"
    },
    {
        :name => "k8s-node-1",
        :type => "node",
        :box => "ubuntu/xenial64",
        :box_version => "20180831.0.0",
        :eth1 => "192.168.205.11",
        :mem => "8192",
        :cpu => "2",
        :disk => "50GB"
    },
    {
        :name => "k8s-node-2",
        :type => "node",
        :box => "ubuntu/xenial64",
        :box_version => "20180831.0.0",
        :eth1 => "192.168.205.12",
        :mem => "4096",
        :cpu => "2",
        :disk => "50GB"
    }
]

singleNode = [
    {
        :name => "k8s-head",
        :type => "master",
        :box => "ubuntu/xenial64",
        :box_version => "20180831.0.0",
        :eth1 => "192.168.205.10",
        :mem => "16384",
        :cpu => "6",
        :disk => "100GB"
    }
]



k8sType = ENV["K8S_TYPE"]
k8sType = "multi" if k8sType.nil? || k8sType.empty?

if k8sType != "single" && k8sType != "multi"
    puts "only k8s type of 'single' and 'multi' is acceptable"
    exit
end

servers = multiNodes
if k8sType == "single"
    servers = singleNode
end

puts "Kubernetes deployment type is #{k8sType}"


# This script to install k8s using kubeadm will get executed after a box is provisioned
$configureBox = <<-SCRIPT

    # install docker v17.03
    # reason for not using docker provision is that it always installs latest version of the docker, but kubeadm requires 17.03 or older
    apt-get update
    apt-get install -y apt-transport-https ca-certificates curl software-properties-common
    curl -fsSL https://download.docker.com/linux/ubuntu/gpg | apt-key add -
    add-apt-repository "deb https://download.docker.com/linux/$(. /etc/os-release; echo "$ID") $(lsb_release -cs) stable"
    apt-get update && apt-get install -y docker-ce=$(apt-cache madison docker-ce | grep 17.03 | head -1 | awk '{print $3}')

    # run docker commands as vagrant user (sudo not required)
    usermod -aG docker vagrant

    # install kubeadm
    apt-get install -y apt-transport-https curl
    curl -s https://packages.cloud.google.com/apt/doc/apt-key.gpg | apt-key add -
    cat <<EOF >/etc/apt/sources.list.d/kubernetes.list
    deb http://apt.kubernetes.io/ kubernetes-xenial main
EOF
    apt-get update
    apt-get install -y kubelet=1.14.0-00 kubeadm=1.14.0-00 kubectl=1.14.0-00
    apt-mark hold kubelet kubeadm kubectl

    # kubelet requires swap off
    swapoff -a

    # keep swap off after reboot
    sudo sed -i '/ swap / s/^\(.*\)$/#\1/g' /etc/fstab

    # ip of this box
    IP_ADDR=`ifconfig enp0s8 | grep Mask | awk '{print $2}'| cut -f2 -d:`
    # set node-ip
    # sudo sed -i "/^[^#]*KUBELET_EXTRA_ARGS=/c\KUBELET_EXTRA_ARGS=--node-ip=$IP_ADDR" /etc/default/kubelet
    echo -e "KUBELET_EXTRA_ARGS=--node-ip=$IP_ADDR" | sudo tee /etc/default/kubelet
    sudo systemctl restart kubelet

SCRIPT

$configureMasterMulti = <<-SCRIPT
    echo "This is master of multi-node k8s cluster"
    # ip of this box
    IP_ADDR=`ifconfig enp0s8 | grep Mask | awk '{print $2}'| cut -f2 -d:`

    echo 'adding insecure registries...'
    echo '{ "insecure-registries":["10.18.84.169:5000" ,"docker.wdf.sap.corp:50000"] }' | sudo tee /etc/docker/daemon.json
    sudo service docker restart

    # setup nfs server
    sudo apt-get install -y nfs-kernel-server
    sudo mkdir /var/nfs -p
    sudo chown nobody:nogroup /var/nfs

    # write mounts to /etc/export
    echo -e "/var/nfs 192.168.205.11(rw,sync,no_subtree_check,no_root_squash)\n/var/nfs 192.168.205.12(rw,sync,no_subtree_check,no_root_squash)" | sudo tee -a /etc/exports

    sudo systemctl restart nfs-kernel-server
    sudo chmod a+rwx /var/nfs
    sudo ls -l /var

    # setup docker registry. TRY again!
    # docker run -d -p 5000:5000 --restart=always --name registry registry:2

    # install k8s master
    HOST_NAME=$(hostname -s)
    kubeadm init --apiserver-advertise-address=$IP_ADDR --apiserver-cert-extra-sans=$IP_ADDR  --node-name $HOST_NAME --pod-network-cidr=172.16.0.0/16

    #copying credentials to regular user - vagrant
    sudo --user=vagrant mkdir -p /home/vagrant/.kube
    sudo cp -i /etc/kubernetes/admin.conf /home/vagrant/.kube/config
    sudo chown $(id -u vagrant):$(id -g vagrant) /home/vagrant/.kube/config

    # install Calico pod network addon
    export KUBECONFIG=/etc/kubernetes/admin.conf
    kubectl apply -f https://raw.githubusercontent.com/ecomm-integration-ballerina/kubernetes-cluster/master/calico/rbac-kdd.yaml
    kubectl apply -f https://raw.githubusercontent.com/ecomm-integration-ballerina/kubernetes-cluster/master/calico/calico.yaml

    kubeadm token create --print-join-command >> /etc/kubeadm_join_cmd.sh
    chmod +x /etc/kubeadm_join_cmd.sh

    # required for setting up password less ssh between guest VMs
    sudo sed -i "/^[^#]*PasswordAuthentication[[:space:]]no/c\PasswordAuthentication yes" /etc/ssh/sshd_config
    sudo service sshd restart

SCRIPT

$configureMasterSingle = <<-SCRIPT
    echo "This is master of a single node k8s cluster"
    # ip of this box
    IP_ADDR=`ifconfig enp0s8 | grep Mask | awk '{print $2}'| cut -f2 -d:`

    echo 'adding insecure registries...'
    echo '{ "insecure-registries":["10.18.84.169:5000"] }' | sudo tee /etc/docker/daemon.json
    sudo service docker restart

    # setup nfs server
    sudo apt-get install -y nfs-kernel-server
    sudo mkdir /var/nfs -p
    sudo chown nobody:nogroup /var/nfs

    echo -e "/var/nfs 192.168.205.10(rw,sync,no_subtree_check,no_root_squash)" | sudo tee -a /etc/exports

    sudo systemctl restart nfs-kernel-server
    sudo chmod a+rwx /var/nfs
    sudo ls -l /var

    # mount locally
    sudo apt install -y nfs-common
    sudo mkdir -p /nfs
    sudo mount 192.168.205.10:/var/nfs /nfs

    # setup docker registry. TRY again!
    # docker run -d -p 5000:5000 --restart=always --name registry registry:2

    # install k8s master
    HOST_NAME=$(hostname -s)
    kubeadm init --apiserver-advertise-address=$IP_ADDR --apiserver-cert-extra-sans=$IP_ADDR  --node-name $HOST_NAME --pod-network-cidr=172.16.0.0/16

    #copying credentials to regular user - vagrant
    sudo --user=vagrant mkdir -p /home/vagrant/.kube
    sudo cp -i /etc/kubernetes/admin.conf /home/vagrant/.kube/config
    sudo chown $(id -u vagrant):$(id -g vagrant) /home/vagrant/.kube/config

    # install Calico pod network addon
    export KUBECONFIG=/etc/kubernetes/admin.conf
    kubectl apply -f https://raw.githubusercontent.com/ecomm-integration-ballerina/kubernetes-cluster/master/calico/rbac-kdd.yaml
    kubectl apply -f https://raw.githubusercontent.com/ecomm-integration-ballerina/kubernetes-cluster/master/calico/calico.yaml

    kubeadm token create --print-join-command >> /etc/kubeadm_join_cmd.sh
    chmod +x /etc/kubeadm_join_cmd.sh

    # required for setting up password less ssh between guest VMs
    sudo sed -i "/^[^#]*PasswordAuthentication[[:space:]]no/c\PasswordAuthentication yes" /etc/ssh/sshd_config
    sudo service sshd restart

    # make scheduling on master possible
    kubectl taint nodes --all node-role.kubernetes.io/master-

SCRIPT

$configureNode = <<-SCRIPT
    echo "This is worker"

    echo 'adding insecure registries...'
    echo '{ "insecure-registries":["10.18.84.169:5000" ,"docker.wdf.sap.corp:50000"] }' | sudo tee /etc/docker/daemon.json
    sudo service docker restart

    # setup nfs
    sudo apt install -y nfs-common
    sudo mkdir -p /nfs
    sudo mount 192.168.205.10:/var/nfs /nfs

    apt-get install -y sshpass
    sshpass -p "vagrant" scp -o StrictHostKeyChecking=no vagrant@192.168.205.10:/etc/kubeadm_join_cmd.sh .
    sh ./kubeadm_join_cmd.sh
SCRIPT

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
            	v.customize ["modifyvm", :id, "--groups", "/Ballerina Development"]
                v.customize ["modifyvm", :id, "--memory", opts[:mem]]
                v.customize ["modifyvm", :id, "--cpus", opts[:cpu]]

            end

            # we cannot use this because we can't install the docker version we want - https://github.com/hashicorp/vagrant/issues/4871
            #config.vm.provision "docker"

            config.vm.provision "shell", inline: $configureBox

            if opts[:type] == "master"
                if k8sType == "single"
                    config.vm.provision "shell", inline: $configureMasterSingle
                else
                    config.vm.provision "shell", inline: $configureMasterMulti
                end
            else
                config.vm.provision "shell", inline: $configureNode
            end

        end

    end

end 
