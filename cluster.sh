#!/usr/bin/env bash

k8s_head_ip=192.168.205.10
# If provided, the registries are added to /etc/docker/daemon.json under insecure-registries
insecure_registries=${INSECURE_REGISTRIES}
# single or multi
cluster_type=${CLUSTER_TYPE:-single}
number_of_pvs=5
pv_size=5  # in GB

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

start_k8s() {
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
#    deploy_tiller
    create_pvs
}

deploy_tiller() {
    echo "deploying tiller"
    kubectl create -f tiller_rbac.yaml
    helm init --service-account tiller
}

create_pvs() {
    for i in `seq 1 5`;
    do
    echo \
"apiVersion: v1
kind: PersistentVolume
metadata:
 name: pv-nfs-00${i}
spec:
 capacity:
   storage: ${pv_size}Gi
 volumeMode: Filesystem
 accessModes:
   - ReadWriteOnce
 persistentVolumeReclaimPolicy: Recycle
 storageClassName:
 mountOptions:
   - hard
   - nfsvers=4.2
 nfs:
   path: /var/nfs
   server: ${k8s_head_ip}" \
  > pv_temp.yaml

    kubectl create -f pv_temp.yaml
    rm pv_temp.yaml
    done
}

"$@"
