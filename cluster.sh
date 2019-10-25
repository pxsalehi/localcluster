#!/usr/bin/env bash


k8s_head_ip=192.168.205.10
docker_registry=10.18.84.169:5000
vagrant_k8s_folder=${GOPATH}/src/github.com/pxsalehi/localcluster
number_of_pvs=10
pv_size=5  # in GB

tear_down_k8s() {
    echo "tearing down k8s cluster..."
    cd ${vagrant_k8s_folder}
    K8S_TYPE=${CLUSTER_TYPE} DOCKER_REGISTRY=${docker_registry} vagrant destroy -f
    cd -
}

suspend_k8s() {
    echo "suspending k8s cluster..."
    cd ${vagrant_k8s_folder}
    K8S_TYPE=${CLUSTER_TYPE} DOCKER_REGISTRY=${docker_registry} vagrant suspend
    cd -
}

resume_k8s() {
    echo "resuming k8s cluster..."
    cd ${vagrant_k8s_folder}
    K8S_TYPE=${CLUSTER_TYPE} DOCKER_REGISTRY=${docker_registry} vagrant resume
    cd -
}

start_k8s() {
    cd ${vagrant_k8s_folder}
    K8S_TYPE=${CLUSTER_TYPE} DOCKER_REGISTRY=${docker_registry} vagrant up
    if [[ ! $? -eq 0 ]]; then
        echo "vagrant up failed"
        exit 1
    fi
    ssh-keygen -f "${HOME}/.ssh/known_hosts" -R ${k8s_head_ip}
    sshpass -p "vagrant" scp -o StrictHostKeyChecking=no vagrant@${k8s_head_ip}:~/.kube/config ${HOME}/.kube/config
    kubectl get nodes
    if [[ ! $? -eq 0 ]]; then
        echo "cannot list k8s nodes"
        exit 1
    fi
    deploy_tiller
    create_pvs
}

deploy_tiller() {
    echo "deploying tiller"
    kubectl create -f tiller_rbac.yaml
    helm init --service-account tiller
}

create_pvs() {
    for i in `seq 1 10`;
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
