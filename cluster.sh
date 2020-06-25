#!/usr/bin/env bash

k8s_head_ip=192.168.205.10
# If provided, the registries are added to /etc/docker/daemon.json under insecure-registries
insecure_registries=${INSECURE_REGISTRIES}
# single or multi
cluster_type=${CLUSTER_TYPE:-single}
number_of_pvs=10
pv_sizes=("100Mi" "2Gi")

destroy() {
    echo "tearing down k8s cluster..."
    CLUSTER_TYPE=${cluster_type} vagrant destroy -f
}

suspend() {
    echo "suspending k8s cluster..."
    CLUSTER_TYPE=${cluster_type} vagrant suspend
}

resume() {
    echo "resuming k8s cluster..."
    CLUSTER_TYPE=${cluster_type} vagrant resume
}

create() {
    CLUSTER_TYPE=${cluster_type} INSECURE_REGISTRIES=${insecure_registries} vagrant up
    if [[ ! $? -eq 0 ]]; then
        echo "vagrant up failed"
        exit 1
    fi
    ssh-keygen -f "${HOME}/.ssh/known_hosts" -R ${k8s_head_ip}
    sshpass -p "vagrant" scp -o StrictHostKeyChecking=no vagrant@${k8s_head_ip}:~/.kube/config ${HOME}/.kube/config
    kubectl get nodes --insecure-skip-tls-verify
    if [[ ! $? -eq 0 ]]; then
        echo "cannot list k8s nodes"
        exit 1
    fi
    create_pvs
}

# sets up dynamic provisioning
setup_nfs() {
	helm repo add stable https://kubernetes-charts.storage.googleapis.com
	helm install stable/nfs-client-provisioner --set nfs.server=x.x.x.x --set nfs.path=/exported/path  --set storageClass.archiveOnDelete=false
	# create pvc with the following annotation in metadata.annotations:
	# volume.beta.kubernetes.io/storage-class: "nfs-client"
}

"$@"
