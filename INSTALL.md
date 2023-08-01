# Installation Visual Flow to Google Kubernetes Engine (GKE)

## Prerequisites

**IMPORTANT**: *This installation requires access to our private Artifact Registry. Please contact us to get access:* info@visual-flow.com

To install Visual Flow on GKE you should have the following software on your local\master machine already installed:

- Google CLI ([install](https://cloud.google.com/sdk/docs/install))
- kubectl ([install](https://kubernetes.io/docs/tasks/tools/))
- gke-gcloud-auth-plugin plugin ([install](https://cloud.google.com/blog/products/containers-kubernetes/kubectl-auth-changes-in-gke))
- Helm CLI ([install](https://helm.sh/docs/intro/install/))
- Git ([install](https://git-scm.com/downloads))

**IMPORTANT**: all the actions are recommended to be performed from the Google account with "Project: Owner" privileges.

If you have just installed the Google CLI, then you need to log in using following command:

`gcloud auth login`

## Create GKE cluster

**IMPORTANT**: if you are new to GKE, please read about Google cloud cluster: cluster types, config params and pricing (<https://cloud.google.com/kubernetes-engine/docs/concepts/types-of-clusters>)

Visual Flow should be installed on GKE cluster. We recommend to use Standard cluster, because Autopilot cluster has some extra limitations and worse application performance. You can create GKE cluster using following commands:

```bash
export CLUSTER_NAME=visual-flow
export ZONE_NAME=us-central1-b
export NUM_NODES=2
gcloud container clusters create $CLUSTER_NAME --region $ZONE_NAME --num-nodes=$NUM_NODES

# check access
kubectl get nodes
kubectl get pods --all-namespaces
```

For additional info check following guide:

<https://cloud.google.com/kubernetes-engine/docs/how-to/creating-a-zonal-cluster>

## Connect to existing GKE cluster from local machine

If you have GKE cluster, you can connect to it using the following command:

`gcloud container clusters get-credentials visual-flow --zone <ZONE_NAME> --project <GOOGLE_PROJECT_NAME>`

## Install Visual Flow

1. Clone (or download) the [google branch from Visual-Flow-deploy repository](https://github.com/ibagroup-eu/Visual-Flow-deploy/tree/google) on your local computer using following command:

    `git clone -b google https://github.com/ibagroup-eu/Visual-Flow-deploy.git Visual-Flow-GCP-deploy`

2. Go to the directory "[visual-flow](https://github.com/ibagroup-eu/Visual-Flow-deploy/tree/google/charts/visual-flow)" of the downloaded "Visual-Flow-Deploy" repository with the following command:

    `cd Visual-Flow-GCP-deploy/charts/visual-flow`

3. *(Optional)* Configure Slack notifications (replace `YOUR_SLACK_TOKEN`) in [values-gcp.yaml](./charts/visual-flow/values-gcp.yaml) using the following guide:

    <https://github.com/ibagroup-eu/Visual-Flow-deploy/blob/main/SLACK_NOTIFICATION.md>

4. Set superusers in [values-gcp.yaml](./charts/visual-flow/values-gcp.yaml).

    New Visual Flow users will have no access in the app. The superusers(admins) need to be configured to manage user access. Specify the superusers real GitHub nicknames in [values.yaml](./charts/visual-flow/values-gcp.yaml) in the yaml list format:

    ```yaml
    superusers:
      - your-github-nickname
      # - another-superuser-nickname
    ```

5. *(Optional)* If you want, you can install kube-metrics then update values-gcp.yaml file according to the example below. 

    1. Check if the kube-metrics installed using the following command:

        ```bash
        kubectl top pods
        ```

        Output if the kube-metrics isn't installed:

        `error: Metrics API not available`

        If the kube-metrics is already installed then go to step 6.

    2. Edit [values.yaml](./charts/visual-flow/values.yaml) file according to the example below:

        ```yaml
        ...
        kube-metrics:
          install: true
        ```

6. If you have installed Argo workflows then update values.yaml file according to the example below.

    1. Check that the Argo workflows installed using the following command:

        ```bash
        kubectl get workflow
        ```

        Output if the Argo workflows isn't installed:

        `error: the server doesn't have a resource type "workflow"`

        If the Argo workflows isn't installed then go to step 7.

    2. Edit [values-gcp.yaml](./charts/visual-flow/values-gcp.yaml) file according to the example below:

        ```yaml
        ...
        argo:
          install: false
        vf-app:
          backend:
            configFile:
              argoServerUrl: <Argo-Server-URL>
        ```

7. Install Redis database. If you have installed Redis database then just update values.yaml file according to the example below.

    1. Create a namespace for Redis. In current configuration <REDIS_NAMESPACE>=redis:

        ```bash
        kubectl create namespace <REDIS_NAMESPACE>
        ```

    2. Update Helm repo:

        ```bash
        helm repo update
        ```

    3. Install Redis with predefined values.yaml (./charts/dbs/bitnami-redis/values.yaml):

        ```bash
        helm install -n <REDIS_NAMESPACE> redis bitnami/redis -f ../dbs/bitnami-redis/values.yaml
        ```

    4. Update `redis.host` and `redis.password` in [values-gcp.yaml](./charts/visual-flow/values-gcp.yaml) file according to the example below:

        ```yaml
        ...
        redis:
          host: redis-master.<REDIS_NAMESPACE>.svc.cluster.local # host: 10.100.26.99
          port: 6379
        # username: ${REDIS_USER}
          password: SuperStrongPassword
          database: 1
        ...
          frontend:
            deployment:
              variables:
                STRATEGY_CALLBACK_URL: 'https://35.188.116.67/vf/ui/callback'
                SESSION_STORE: 'dynamic' # dynamic (requires Redis) / in-memory
                REDIS_HOST: redis-master.<REDIS_NAMESPACE>.svc.cluster.local
                REDIS_PORT: 6379
        ```

8. Install PostgreSQL database. If you have installed PostgreSQL database then just update values.yaml file according to the example below.

    1. Create a namespace for PostgreSQL. In current configuration <PostgreSQL_NAMESPACE>=postgres:

        ```bash
        kubectl create namespace <PostgreSQL_NAMESPACE>
        ```

    2. Update Helm repo:

        ```bash
        helm repo update
        ```

    3. Install PostgreSQL with predefined values.yaml (./charts/dbs/bitnami-postgresql/values.yaml):

        ```bash
        helm install -n <PostgreSQL_NAMESPACE> postgresql bitnami/postgresql -f ../dbs/bitnami-postgresql/values.yaml
        ```

    4. Update `PG_URL`, `PG_USER` and `PG_PASS` in [values-gcp.yaml](./charts/visual-flow/values-gcp.yaml) file according to the example below:

        ```yaml
        ...
        historyserv:
          configFile:
            postgresql:
              PG_URL: jdbc:postgresql://postgresql.<PostgreSQL_NAMESPACE>.svc.cluster.local:5432/postgres
              PG_USER: postgres # postgres_username
              PG_PASS: SuperStrongPassword # postgres_password
        ```
9. Prepare namespace for Visual Flow.

    1. Create a namespace for Visual Flow. In current configuration <VF_NAMESPACE>=visual-flow:

        ```bash
        kubectl create namespace <VF_NAMESPACE>
        ```

    2. *(Optional)* Set visual-flow namespace to be default in your profile:

        ```bash
        kubectl config set-context --current --namespace=<VF_NAMESPACE>
        ```

10. Install the app using the updated [values-gcp.yaml](./charts/visual-flow/values-gcp.yaml) file with the following command:

    `helm install visual-flow . -f values-gcp.yaml -n <VF_NAMESPACE>`

11. Check that the app is successfully installed and all pods are running with the following command:

    `kubectl get pods -n <VF_NAMESPACE>`

12. Get the generated app's hostname with the following command:

    `kubectl get svc visual-flow-frontend -n <VF_NAMESPACE> -o yaml | grep -i clusterIP: | cut -c 14-`

    Replace the string `<EXTERNAL_IP_FROM_SERVICE>` with the generated hostname in the next steps.

13. Create a GitHub OAuth app:

    1. Go to GitHub user's OAuth apps (`https://github.com/settings/developers`) or organization's OAuth apps (`https://github.com/organizations/<ORG_NAME>/settings/applications`).
    2. Click the **Register a new application** or the **New OAuth App** button.
    3. Fill the required fields:
        - Set **Homepage URL** to `https://<EXTERNAL_IP_FROM_SERVICE>/vf/ui/`
        - Set **Authorization callback URL** to `https://<EXTERNAL_IP_FROM_SERVICE>/vf/ui/callback`
    4. Click the **Register application** button.
    5. Replace "DUMMY_ID" with the Client ID value in [values-gcp.yaml](./charts/visual-flow/values-gcp.yaml).
    6. Click **Generate a new client secret** and replace in [values-gcp.yaml](./charts/visual-flow/values-gcp.yaml) "DUMMY_SECRET" with the generated Client secret value (Please note that you will not be able to see the full secret value later).

14. Update STRATEGY_CALLBACK_URL value in [values-gcp.yaml](./charts/visual-flow/values-gcp.yaml) to `https://<EXTERNAL_IP_FROM_SERVICE>/vf/ui/callback`

15. Upgrade the app in EKS cluster using updated values.yaml:

    `helm upgrade visual-flow . -f values-gcp.yaml -n <VF_NAMESPACE>`

16. Wait until the update is installed and all pods are running:

    `kubectl get pods -n <VF_NAMESPACE>`

## Use Visual Flow

1. All Visual Flow users (including superusers) need active Github account in order to be authenticated in application. Setup Github profile as per following steps:

    1. Navigate to the [account settings](https://github.com/settings/profile)
    2. Go to **Emails** tab: set email as public by unchecking **Keep my email addresses private** checkbox
    3. Go to **Profile** tab: fill in **Name** and **Public email** fields

2. Open the app's web page using the following link:

    `https://<EXTERNAL_IP_FROM_SERVICE>/vf/ui/`

3. See the guide on how to work with the Visual Flow at the following link: [Visual_Flow_User_Guide.pdf](https://github.com/ibagroup-eu/Visual-Flow-deploy/blob/google/Visual_Flow_User_Guide.pdf)

4. For each project Visual Flow (VF) generates a new namespace. 

   **IMPORTANT**: For each namespace there is a PVC that will be created and assigned automatically (`vf-pvc`) in RWX mode (`read\write-many`). GKE has default storage classes to provision PV in RWX modes (f.e. `standard-rwx`) that uses Cloud Filestore API service, but it has limitation size (1Tb-10Tb) when VF usually use small disks (f.e. 2G per project\namespace). So, each VF project will cost you at least 200$/month. There is an open ticket for this feature: (https://issuetracker.google.com/issues/193108375?pli=1). Instead, you can use NFS and assign it to each new namespace, but it have to be assigned manually for each VF project. You can read here about how to create yourself NFS server on your Google cloud (https://github.com/ibagroup-eu/Visual-Flow-deploy/blob/google/GCP_NFS_server_how_to.md). If you do not need to know how to create a new NFS server and assign VF to it you can skip this section.

   First, create the project in the app, open it and check the URL of the page. It will have the following format:

   `https://<EXTERNAL_IP_FROM_SERVICE>/vf/ui/<NAMESPACE>/overview`

   Now delete automatically created PVC in that <NAMESPACE>:

   `kubectl delete pvc vf-pvc -n <NAMESPACE>`

   Once you have your NFS server ready, create a file with next content and replace items from comments in the header.

    ```yaml
    # <PV_NAME> - name of Persistent Volume for your project. # vf-pvc-testing
    # <STORAGE_SIZE> - storage size that you want to assign to this VF project. # 2G
    # <NFS_HOST> - NFS server ip. # 10.128.0.15
    # <NFS_PATH> - PATH to shared folder in your NFS you want to use in this VF project. # /share
    # <NAMESPACE> - VF project namespace for jobs. # vf-testing
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

    `kubectl apply -f <your_yaml_file_with_pvc> -n <NAMESPACE>`

## Stop \ Start GKE cluster

1. If you want to stop temporary your GKE cluster and VF application, the easiest way is to scale down number of nodes:

    `gcloud container clusters resize visual-flow --node-pool default-pool --num-nodes 0 --zone <ZONE_NAME>`

2. Once you need it back, just restore num-nodes back:

    `gcloud container clusters resize visual-flow --node-pool default-pool --num-nodes <NUM_NODES> --zone <ZONE_NAME>`

## Delete Visual Flow

1. If the app is no longer required, you can delete it using the following command:

    `helm uninstall vf-app -n <VF_NAMESPACE>`

2. Check that everything was successfully deleted with the command:

    `kubectl get pods -n <VF_NAMESPACE>`

3. Delete Visual Flow namespace:
     `kubectl delete namespace <VF_NAMESPACE>`

## Delete GKE

1. If the GKE is no longer required, you can delete it using the following guide:

    <https://cloud.google.com/sdk/gcloud/reference/container/clusters/delete>
