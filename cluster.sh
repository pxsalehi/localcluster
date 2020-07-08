#!/usr/bin/env bash

k8s_head_ip=192.168.205.10
# If provided, the registries are added to /etc/docker/daemon.json under insecure-registries
# Should be of the form: "registry1","registry2"
insecure_registries=${INSECURE_REGISTRIES}
# single or multi
cluster_type=${CLUSTER_TYPE:-single}
number_of_pvs=6
pv_size=2Gi

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
}

# sets up dynamic provisioning
setup_nfs() {
	helm repo add stable https://kubernetes-charts.storage.googleapis.com
	helm install nfs-prov stable/nfs-client-provisioner --set nfs.server=${k8s_head_ip} --set nfs.path=/var/nfs  --set storageClass.archiveOnDelete=false
	# create pvc with the following annotation in metadata.annotations:
	# volume.beta.kubernetes.io/storage-class: "nfs-client"
}

create_pvs() {
	for i in `seq 1  ${number_of_pvs}`;
	do
		cat <<EOF | kubectl apply -f -
kind: PersistentVolume
apiVersion: v1
metadata:
  name: hostpath-pv-${i}
spec:
  capacity:
    storage: 2Gi
  accessModes:
    - ReadWriteOnce
  persistentVolumeReclaimPolicy: Recycle
  hostPath:
    path: "/var/hostpath/pv${i}"
EOF
	done
}

"$@"
