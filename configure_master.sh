#!/usr/bin/env bash
# Requires DOCKER_REGISTRY, K8S_NODE1_IP and K8S_NODE2_IP env variables

echo "This is master of a $CLUSTER_TYPE node k8s cluster"
# ip of this box
IP_ADDR=`ifconfig enp0s8 | grep Mask | awk '{print $2}'| cut -f2 -d:`

if [[ ! -z "$INSECURE_REGISTRIES" ]]; then
    echo 'adding insecure registries...'
    echo "{ \"insecure-registries\":[\"${INSECURE_REGISTRIES}\"] }" | sudo tee /etc/docker/daemon.json
    sudo service docker restart
fi

# setup nfs server
sudo apt-get install -y nfs-kernel-server
sudo mkdir /var/nfs -p
sudo chown nobody:nogroup /var/nfs

# write mounts to /etc/export
if [[ "$CLUSTER_TYPE" = "multi" ]];
then
    echo -e "/var/nfs ${K8S_MASTER_IP}(rw,sync,no_subtree_check,no_root_squash)\n" | sudo tee -a /etc/exports
    echo -e "/var/nfs ${K8S_NODE1_IP}(rw,sync,no_subtree_check,no_root_squash)\n" | sudo tee -a /etc/exports
    echo -e "/var/nfs ${K8S_NODE2_IP}(rw,sync,no_subtree_check,no_root_squash)" | sudo tee -a /etc/exports
else
    echo -e "/var/nfs ${K8S_MASTER_IP}(rw,sync,no_subtree_check,no_root_squash)" | sudo tee -a /etc/exports
fi

sudo systemctl restart nfs-kernel-server
sudo chmod a+rwx /var/nfs
sudo ls -l /var

# install k8s master
HOST_NAME=$(hostname -s)
kubeadm init --apiserver-advertise-address=$IP_ADDR --apiserver-cert-extra-sans=$IP_ADDR  \
             --node-name $HOST_NAME --pod-network-cidr=172.16.0.0/16

#copying credentials to regular user - vagrant
sudo --user=vagrant mkdir -p /home/vagrant/.kube
sudo cp -i /etc/kubernetes/admin.conf /home/vagrant/.kube/config
sudo chown $(id -u vagrant):$(id -g vagrant) /home/vagrant/.kube/config

# install Calico pod network addon
export KUBECONFIG=/etc/kubernetes/admin.conf
kubectl apply -f https://docs.projectcalico.org/manifests/calico.yaml

if [[ "$CLUSTER_TYPE" = "multi" ]];
then
    kubeadm token create --print-join-command >> /etc/kubeadm_join_cmd.sh
    chmod +x /etc/kubeadm_join_cmd.sh
fi

# required for setting up password less ssh between guest VMs
sudo sed -i "/^[^#]*PasswordAuthentication[[:space:]]no/c\PasswordAuthentication yes" /etc/ssh/sshd_config
sudo service sshd restart