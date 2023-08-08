If you want to understand how to install rook-ceph on AKS and configure it yourself, you can read about it here: <https://devpress.csdn.net/k8s/62ebdd3d89d9027116a0fa0d.html>

If you want to install it just for Visual Flow projects you can follow the guide below:

For this install we use:
- Rook-ceph v1.12.0 <https://github.com/rook/rook/tree/v1.12.0>
- We expect that you already have AKS installed and configured including Visual Flow install [INSTALL.md](INSTALL.md)
- One extra nodepool for AKS to be created manually for rook-ceph (in this guide we call it `rookcephfs`).
- 1 node (Standard_B2ms machine).
- We recommend to use at least 2vCPU and 8Gb RAM for this rook-ceph node to be able to start and run it succesfully. If you try with worse configuration this install may fail with unexpected errors\warnings.

1. Add Storage Node to your AKS cluster:

```bash
az aks nodepool add --cluster-name <YOUR_CLUSTER_NAME> \
--name rookecephfs --resource-group <YOUR_RESOURCE_GROUP> \ 
--node-count 1 \
--node-taints storage-node=true:NoSchedule
```

2. Make sure you can see your new node:

```bash
kubectl get nodes
```

3. Install [commons.yaml](rook-ceph_1.12.0/common.yaml):

```bash
kubectl create -f rook-ceph_1.12.0/common.yaml
```

4. Create AKS operator [operator-aks.yaml](rook-ceph_1.12.0/operator-aks.yaml):

```bash
kubectl create -f rook-ceph_1.12.0/operator-aks.yaml
```

5. Create AKS CephCluster [cluster-aks.yaml](rook-ceph_1.12.0/cluster-aks.yaml). Defaults are: 1 node, 10G storage and rookcephfs nodepool name. If you need to change storage, please take a look at this [file](rook-ceph_1.12.0/cluster-aks.yaml) and update `spec.mon.volumeClaimTemplate.spec.resources.requests.storage` and `spec.storageClassDeviceSets.volumeClaimTemplates.spec.resources.requests.storage`. If you have another nodepool name, please update `spec.storageClassDeviceSets.placement.nodeAffinity.requiredDuringSchedulingIgnoredDuringExecution.nodeSelectorTerms.matchExpressions.values`.

```bash
kubectl create -f rook-ceph_1.12.0/cluster-aks.yaml
```

6. Wait a couple of minutes and check status using next commands. If CephCluster status is not HEALTH_OK or you do not see rook-ceph-osd-0-`CephID` pods then you need to verify previous steps to make sure you did not missed and check logs. Status check and expected output:

```bash
$ kubectl get -n rook-ceph CephCluster.ceph.rook.io/rook-ceph
NAME        DATADIRHOSTPATH   MONCOUNT   AGE     PHASE   MESSAGE                        HEALTH      EXTERNAL   FSID
rook-ceph   /var/lib/rook     1          2m42s   Ready   Cluster created successfully   HEALTH_OK              d6e47925-b86e-4b12-b10d-aea1d39c327e

$ kubectl get pods -n rook-ceph | grep -i rook-ceph-osd
rook-ceph-osd-0-8844ff8c-slfc5                                    1/1     Running     0          60s
rook-ceph-osd-prepare-set1-data-0mvx2c-6s6wb                      0/1     Completed   0          82s
```

7. Once you have HEALTH_OK status and OSD pod running you can create a cephFilesystem and a rook-ceph storageclass:

```bash
kubectl create -f rook-ceph_1.12.0/storageclass-fs-aks.yaml
```

8. Now you need to change your default storage class to be `rook-cephfs` that we just created. How to change your default storage class: <https://kubernetes.io/docs/tasks/administer-cluster/change-default-storage-class/>

9. Done! Once you changed your default storageclass all your new Visual Flow project PVCs will be provisioned by rook-ceph. Create a new project using Visual Flow and verify that you have BOUND status of your PVC `vf-pvc` in Visual Flow project namespace:

```bash
$ get pvc -n <YOUR_VF_PROJECT_NAMESPACE>
NAME     STATUS   VOLUME                                     CAPACITY   ACCESS MODES   STORAGECLASS          AGE
vf-pvc   Bound    pvc-65ff9574-513e-4ee2-8053-2476423811f2   2Gi        RWX            rook-cephfs-storage   1d
```