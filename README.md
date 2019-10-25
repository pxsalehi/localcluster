# Kubernetes cluster
A vagrant script for setting up a Kubernetes cluster using Kubeadm

## Pre-requisites

 * **[Vagrant 2.1.4+](https://www.vagrantup.com)**
 * **[Virtualbox 5.2.18+](https://www.virtualbox.org)**
 * **[Vagrant disk resize plugin](https://github.com/sprotheroe/vagrant-disksize)**

## How to Run

In `cluster.sh`, define following variables:
* `docker_registry`: where the docker registry is located, including port
* `vagrant_k8s_folder`: path to this repo 

#### Start cluster

`CLUSTER_TYPE=[multi | single] ./cluster.sh start_k8s`

`single` is a one node cluster and `multi` is a three node cluster with two workers. default is `multi`. Resources for the nodes can be changed in `Vagrantfile`.

Once finished, helm is also installed. The kubeconfig file is copied to ~/.kube/config.

You can ssh into master with vagrant@master_ip with password vagrant. SSH with workers is only via key which is under `.vagrant/machines`. Example:

`ssh -i ~/go/src/github.com/pxsalehi/localcluster/.vagrant/machines/k8s-node1/virtualbox/private_key vagrant@192.168.205.11`

Docker and Kubernetes version can be changed in `configure_box.sh`.

Master also has an NFS server installed and by default there are 10 available PVs created. This can be adjusted in `cluster.sh`.

#### Suspend the cluster

`./cluster.sh suspend_k8s`

#### Resume the suspended cluster

`./cluster.sh resume_k8s`

#### Tear down the cluster

`./cluster.sh tear_down_k8s`

## Licensing

[Apache License, Version 2.0](http://opensource.org/licenses/Apache-2.0).
