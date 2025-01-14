# Installation Visual Flow to Google Kubernetes Engine (GKE)

1. [Prerequisite Installation](#prerequisites)
    - [Setting up prerequisite tools](#prereqtools)
    - [Clone Visual Flow repository](#clonevfrepo)
    - [Create GKE cluster](#createcluster)
    - [Configure GitHub OAuth](#oauthsetup)
    - [Install Redis & PostgreSQL](#installdbs)
2. [Installation of Visual Flow](#installvf)
3. [Use Visual Flow](#usevf)
4. [Stop \ Start GKE cluster](#stopvf)
5. [Delete Visual Flow](#uninstallvf)


## <a id="prerequisites">Prerequisite Installation</a>
>[!NOTE]
>If you have any concerns, please contact us: info@visual-flow.com<BR>

## <a id="prereqtools">Setting up prerequisite tools</a>
To install Visual Flow on GKE you should have the following software on your local\master machine already installed:

- Google CLI ([install](https://cloud.google.com/sdk/docs/install))
- kubectl ([install](https://kubernetes.io/docs/tasks/tools/))
- gke-gcloud-auth-plugin ([install](https://cloud.google.com/blog/products/containers-kubernetes/kubectl-auth-changes-in-gke))
- Helm CLI ([install](https://helm.sh/docs/intro/install/))
- Git ([install](https://git-scm.com/downloads))

>[!IMPORTANT]
>All the actions are recommended to be performed from the Google account with "Project: Owner" privileges.

If you have just installed the Google CLI, then you need to log in using the following command:

```bash
gcloud auth login
```

## <a id="clonevfrepo">Clone Visual Flow repository</a>
Clone (or download) the [google branch from Visual-Flow-deploy repository](https://github.com/ibagroup-eu/Visual-Flow-deploy/tree/google) on your local computer using the following command:

```bash
git clone -b google https://github.com/ibagroup-eu/Visual-Flow-deploy.git Visual-Flow-GCP-deploy
cd Visual-Flow-GCP-deploy
```

## <a id="createcluster">Create GKE cluster</a>
>[!IMPORTANT]
>If you are new to GKE, please read about Google cloud cluster: cluster types, config params and pricing (<https://cloud.google.com/kubernetes-engine/docs/concepts/types-of-clusters>)

Visual Flow should be installed on GKE cluster. We recommend to use Standard cluster, because Autopilot cluster has some extra limitations and worse application performance. You can create GKE cluster using the following commands:

```bash
export CLUSTER_NAME=visual-flow
export ZONE_NAME=us-central1-b
export NUM_NODES=2
gcloud container clusters create $CLUSTER_NAME --region $ZONE_NAME --num-nodes=$NUM_NODES

# check access
kubectl get nodes
kubectl get pods --all-namespaces
```
>[!TIP]
>For additional info check the following guide:
>
><https://cloud.google.com/kubernetes-engine/docs/how-to/creating-a-zonal-cluster>

#### Connect to existing GKE cluster from the local machine

If you already have GKE cluster, you can connect to it using the following command:

```bash
gcloud container clusters get-credentials <CLUSTER_NAME> --zone <ZONE_NAME> --project <GOOGLE_PROJECT_NAME>
```

## <a id="oauthsetup">Configure GitHub OAuth</a>

  1. Go to GitHub user's OAuth apps (`https://github.com/settings/developers`) or organization's OAuth apps (`https://github.com/organizations/<ORG_NAME>/settings/applications`)
  2. Click the **Register a new application** or the **New Org OAuth App** button
  3. Fill in the required fields:
     - Set **Homepage URL** to `https://visual-flow-dummy-url.com/vf/ui/`
     - Set **Authorization callback URL** to `https://visual-flow-dummy-url.com/vf/ui/callback`
  4. Click the **Register application** button
  5. Click **Generate a new client secret**
  6. Replace "DUMMY_ID" and "DUMMY_SECRET" with your `Client ID\Client secret` pair value in [values.yaml](./charts/visual-flow/values.yaml).

>[!NOTE]
>Make sure to copy client secret before you refresh or close the web page. The value will be hidden.<BR>
>In case you lost your client secret, just create a new `Client ID\Client secret` pair.
>
>`visual-flow-dummy-url.com` is a dummy URL. After [Install](#installvf) do not forget to update **Homepage URL** and **Authorization callback URL** fields.


## <a id="installdbs">Install Redis & PostgreSQL</a>
Some functionality of VF app requires to have Redis & PosgreSQL dbs. Both of them with custom and default configs included in installation as a separate helm charts (values files with source from bitnami repo). 

<https://github.com/ibagroup-eu/Visual-Flow-deploy/tree/amazon/charts/dbs>

You can get them and install on you cluster using the following commands:

Add 'bitnami' repository to helm repo list
```bash
helm repo add bitnami https://charts.bitnami.com/bitnami
helm repo update
```
1. Redis (for Session and Job's execution history)

`helm install redis -f charts/dbs/bitnami-redis/values.yaml bitnami/redis`

2. PostgreSQL (History service)

`helm install pgserver -f charts/dbs/bitnami-postgresql/values.yaml bitnami/postgresql`

FYI: Just in case, it is better to save output of these commands (it contains helpful info with short guide, how to get access to pod & dbs and show default credentials).


## <a id="installvf">Install Visual Flow</a>
>[!NOTE]
>Current installation is configured to work on `default` namespace of your cluster.<BR>
>But your Visual Flow projects are stored in `vf-<projectname>` namespaces.<BR>

1. Go to the directory "[visual-flow](https://github.com/ibagroup-eu/Visual-Flow-deploy/tree/google/charts/visual-flow)" of the downloaded "Visual-Flow-Deploy" repository with the following command:

    ```bash
    cd charts/visual-flow
    ```

2. *(Optional)* Configure Slack notifications (replace `YOUR_SLACK_TOKEN`) in [values.yaml](./charts/visual-flow/values.yaml) using the following guide:

    <https://github.com/ibagroup-eu/Visual-Flow-deploy/blob/main/SLACK_NOTIFICATION.md>

3. Set superusers in [values.yaml](./charts/visual-flow/values.yaml).

    New Visual Flow users will have no access in the app. The superusers(admins) need to be configured to manage user access. Specify the superusers real GitHub nicknames in [values.yaml](./charts/visual-flow/values.yaml) in the yaml list format:

    ```yaml
    superusers:
      - your-github-nickname
      # - another-superuser-nickname
    ```

4. If you have installed kube-metrics then update values.yaml file according to the example below.

    1. Check that the kube-metrics installed using the following command:

        ```bash
        kubectl top pods
        ```

        Output if the kube-metrics isn't installed:

        `error: Metrics API not available`

        If the kube-metrics isn't installed then go to step 6.

    2. Edit [values.yaml](./charts/visual-flow/values.yaml) file according to the example below:

        ```yaml
        ...
        kube-metrics:
          install: false
        ```

5. If you have installed Argo workflows then update values.yaml file according to the example below.

    1. Check that the Argo workflows installed using the following command:

        ```bash
        kubectl get workflow
        ```

        Output if the Argo workflows isn't installed:

        `error: the server doesn't have a resource type "workflow"`

        If the Argo workflows isn't installed then go to step 7.

    2. Edit [values.yaml](./charts/visual-flow/values.yaml) file according to the example below:

        ```yaml
        ...
        argo:
          install: false
        vf-app:
          backend:
            configFile:
              argoServerUrl: <Argo-Server-URL>
        ```

6. Install the app using the updated [values.yaml](./charts/visual-flow/values.yaml) file with the following command:

    ```bash
    helm upgrade -i vf-app . -f values.yaml -n default
    ```

7. Check that the app is successfully installed and all pods are running with the following command:

    ```bash
    kubectl get pods --all-namespaces
    ```

8. Get the generated app's hostname\IP with the following command:

    ```bash
    kubectl get svc visual-flow-frontend -n default -o yaml | grep -i clusterIP: | cut -c 14-
    ```

    Replace the string `<HOSTNAME_FROM_SERVICE>` with the generated hostname\IP in the next steps.
    Replace `visual-flow-dummy-url.com` from [OAuth step](#oauthsetup) with your hostname or IP in **Homepage URL** and **Authorization callback URL** fields. Save changes.

9. Update 'host' (`host: https://<HOSTNAME_FROM_SERVICE>/vf/ui/`) and 'STRATEGY_CALLBACK_URL' (`STRATEGY_CALLBACK_URL: https://<HOSTNAME_FROM_SERVICE>/vf/ui/callback`) values in [values.yaml](./charts/visual-flow/values.yaml). 

10. Upgrade the app in EKS cluster using updated values.yaml:

    ```bash
    helm upgrade vf-app . -f values.yaml -n default
    ```

11. Wait until the update is installed and all pods are running:

    ```bash
    kubectl get pods --all-namespaces
    ```

## <a id="usevf">Use Visual Flow</a>
1. All Visual Flow users (including superusers) need active Github account in order to be authenticated in application. Setup Github profile as described in the next steps:

    1. Navigate to the [account settings](https://github.com/settings/profile)
    2. Go to **Emails** tab: set email as public by unchecking **Keep my email addresses private** checkbox
    3. Go to **Profile** tab: fill in **Name** and **Public email** fields

2. Open the app's web page using the following link:

    `https://<HOSTNAME_FROM_SERVICE>/vf/ui/`

3. See the guide on how to work with the Visual Flow at the following link: [Visual_Flow_User_Guide.pdf](https://github.com/ibagroup-eu/Visual-Flow/blob/main/Visual_Flow_User_Guide.pdf)

4. For each project Visual Flow (VF) generates a new namespace. 

>[!IMPORTANT]
>For each namespace there is a PVC that will be created and assigned automatically (`vf-pvc`) in RWX mode (`read\write-many`). GKE has default storage classes to provision PV in RWX modes (f.e. `standard-rwx`) that uses Cloud Filestore API service, but it has limitation size (1Tb-10Tb) when VF usually use small disks (f.e. 2G per project\namespace). So, each VF project will cost you at least 200$/month. There is an open ticket for this feature: (https://issuetracker.google.com/issues/193108375?pli=1). Instead, you can use NFS and assign it to each new namespace, but it have to be assigned manually for each VF project. You can read here about how to create yourself NFS server on your Google cloud (https://github.com/ibagroup-eu/Visual-Flow-deploy/blob/google/GCP_NFS_server_how_to.md). If you do not need to know how to create a new NFS server and assign VF to it you can skip this section.

   First, create the project in the app, open it and check the URL of the page. It will have the following format:

   `https://<HOSTNAME_FROM_SERVICE>/vf/ui/<NAMESPACE>/overview`

   Now delete automatically created PVC in that <NAMESPACE>:

   ```bash
   kubectl delete pvc vf-pvc -n <NAMESPACE>
   ```

   Once you have your NFS server ready, create a file with next content and replace items from comments in the header.

    ```yaml
    # <PV_NAME> - name of Persistent Volume for your project. # vf-pvc-testing
    # <STORAGE_SIZE> - storage size that you want to assign to this VF project. # 2G
    # <NFS_HOST> - NFS server ip. # YOUR_NFS_IP
    # <NFS_PATH> - PATH to shared folder in your NFS you want to use in this VF project. # /share
    # <NAMESPACE> - VF project namespace for jobs. # vf-test
    apiVersion: v1
    kind: PersistentVolume
    metadata:
      name: <PV_NAME>
    spec:
      storageClassName: ""
      persistentVolumeReclaimPolicy: Delete
      capacity:
        storage: <STORAGE_SIZE>
      accessModes:
        - ReadWriteMany
      nfs:
        server: <NFS_HOST>
        path: <NFS_PATH>
    ---   
    apiVersion: v1
    kind: PersistentVolumeClaim
    metadata:
      name: vf-pvc
      namespace: <NAMESPACE>
    spec:
      storageClassName: ""
      volumeName: <PV_NAME>
      accessModes:
        - ReadWriteMany
      resources:
        requests:
          storage: <STORAGE_SIZE>
    ```

    Deploy your file using next command:

    ```bash
    kubectl apply -f <your_yaml_file_with_pvc> -n <NAMESPACE>
    ```

## <a id="stopvf">Stop \ Start GKE cluster</a> 
1. If you want to stop temporary your GKE cluster and VF application, the easiest way is to scale down the number of nodes:

    ```bash
    gcloud container clusters resize visual-flow --node-pool default-pool --num-nodes 0 --zone <ZONE_NAME>
    ```

2. Once you need it back, just restore num-nodes back:

    ```bash
    gcloud container clusters resize visual-flow --node-pool default-pool --num-nodes <NUM_NODES> --zone <ZONE_NAME>
    ```


## <a id="uninstallvf">Delete Visual Flow</a>
1. If the app is no longer required, you can delete it using the following command:

    ```bash
    helm uninstall vf-app -n default
    ```

2. Check that everything was successfully deleted with the command:

    ```bash
    kubectl get pods -n default
    ```

#### Delete GKE

1. If the GKE is no longer required, you can delete it using the following guide:

    <https://cloud.google.com/sdk/gcloud/reference/container/clusters/delete>

