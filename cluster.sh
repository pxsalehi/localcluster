#!/usr/bin/env bash

#TODO: fix k8s/docker version in the vagrant file

k8s_head_ip=192.168.205.10
docker_registry=10.18.84.169:5000

vagrant_k8s_folder=${HOME}/workspace/kubernetes-cluster
helm_depl_name=vsys
vsys_namespace=vsystem
vsys_node=${k8s_head_ip}
vsys_port=30123
vsys_sys_tenant=system
vsys_admin_user=admin

# send env var VSYS_NODE_IP to point to vsystem server IP
if [[ ! -z "${VSYS_NODE_IP}" ]]; then
    vsys_node=${VSYS_NODE_IP}
fi

tear_down_k8s() {
    echo "tearing down k8s cluster..."
    cd ${vagrant_k8s_folder}
    vagrant destroy -f
    cd -
}

start_k8s() {
    cd ${vagrant_k8s_folder}
    K8S_TYPE=multi vagrant up
    if [[ ! $? -eq 0 ]]; then
        echo "vagrant up failed"
        exit 1
    fi
    ssh-keygen -f "${HOME}/.ssh/known_hosts" -R $k8s_head_ip
    if [[ ! ${NO_PROXY} == *${k8s_head_ip}* ]]; then
        echo "k8s head is not in no proxy. set it with:"
        echo "\t\t export NO_PROXY=\$no_proxy,${k8s_head_ip}"
        export NO_PROXY=$no_proxy,${k8s_head_ip}
    fi
    sshpass -p "vagrant" scp -o StrictHostKeyChecking=no vagrant@${k8s_head_ip}:~/.kube/config ${HOME}/.kube/config
    kubectl get nodes
    if [[ ! $? -eq 0 ]]; then
        echo "cannot list k8s nodes"
        exit 1
    fi
    deploy_tiller
#    cd -

    create_pvs
}

deploy_tiller() {
    echo "deploying tiller"
    kubectl create -f tiller_rbac.yaml
    helm init --service-account tiller
}

check_error() {
    result=$1
    msg=$2
    if [[ ! ${result} -eq 0 ]]; then
        echo "ERROR: ${msg}"
        exit 1
    fi
}

create_pvs() {
    for i in `seq 1 10`;
    do
    echo \
"apiVersion: v1
kind: PersistentVolume
metadata:
 name: pv-nfs-00$i
spec:
 capacity:
   storage: 10Gi
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
   server: 192.168.205.10" \
  > pv_temp.yaml

    kubectl create -f pv_temp.yaml
    rm pv_temp.yaml
    done
}

"$@"
