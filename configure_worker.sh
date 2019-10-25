#!/usr/bin/env bash
# Requires DOCKER_REGISTRY and K8S_MASTER_IP env variables

echo "This is worker"

echo 'adding insecure registries...'
echo "{ \"insecure-registries\":[\"${DOCKER_REGISTRY}\"] }" | sudo tee /etc/docker/daemon.json
sudo service docker restart

# setup nfs
sudo apt install -y nfs-common
sudo mkdir -p /nfs
sudo mount ${K8S_MASTER_IP}:/var/nfs /nfs

apt-get install -y sshpass
sshpass -p "vagrant" scp -o StrictHostKeyChecking=no vagrant@${K8S_MASTER_IP}:/etc/kubeadm_join_cmd.sh .
sh ./kubeadm_join_cmd.sh