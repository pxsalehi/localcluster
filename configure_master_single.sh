#!/usr/bin/env bash
# Requires DOCKER_REGISTRY and K8S_MASTER_IP env variables

echo "This is master of a single node k8s cluster"
# ip of this box
IP_ADDR=`ifconfig enp0s8 | grep Mask | awk '{print $2}'| cut -f2 -d:`

echo 'adding insecure registries...'
echo "{ \"insecure-registries\":[\"${DOCKER_REGISTRY}\"] }" | sudo tee /etc/docker/daemon.json
sudo service docker restart

# setup nfs server
sudo apt-get install -y nfs-kernel-server
sudo mkdir /var/nfs -p
sudo chown nobody:nogroup /var/nfs

echo -e "/var/nfs ${K8S_MASTER_IP}(rw,sync,no_subtree_check,no_root_squash)" | sudo tee -a /etc/exports

sudo systemctl restart nfs-kernel-server
sudo chmod a+rwx /var/nfs
sudo ls -l /var

# mount locally
sudo apt install -y nfs-common
sudo mkdir -p /nfs
sudo mount ${K8S_MASTER_IP}:/var/nfs /nfs

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