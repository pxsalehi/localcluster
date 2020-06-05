# Kubernetes cluster
A vagrant script for setting up a Kubernetes cluster

## Pre-requisites

 * **[Vagrant](https://www.vagrantup.com)**
 * **[Virtualbox](https://www.virtualbox.org)**
 * **[Vagrant disk resize plugin](https://github.com/sprotheroe/vagrant-disksize)**

## Start cluster

`CLUSTER_TYPE=[multi | single] ./cluster.sh create`

`single` is a one node cluster and `multi` is a three node cluster with two workers. default is `single`. Resources for the nodes can be changed in `Vagrantfile`.

Docker and Kubernetes version can be changed in `configure_box.sh`.

Master also has an NFS server installed and by default there are 5 available PVs created. This can be adjusted in `cluster.sh`.
