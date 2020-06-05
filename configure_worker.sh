#!/usr/bin/env bash

echo "This is worker"

if [[ ! -z "$INSECURE_REGISTRIES" ]]; then
    echo 'adding insecure registries...'
    echo "{ \"insecure-registries\":[${INSECURE_REGISTRIES}] }" | sudo tee /etc/docker/daemon.json
    sudo service docker restart
fi

# setup nfs
sudo apt install -y nfs-common
sudo mkdir -p /nfs
sudo mount ${K8S_MASTER_IP}:/var/nfs /nfs

apt-get install -y sshpass
sshpass -p "vagrant" scp -o StrictHostKeyChecking=no vagrant@${K8S_MASTER_IP}:/etc/kubeadm_join_cmd.sh .
sh ./kubeadm_join_cmd.sh
