# Installation Visual Flow to Azure Kubernetes Service (AKS)

## Prerequisites

**IMPORTANT**: *This installation requires access to our private Container Registry. Please contact us to get access:* info@visual-flow.com

To install Visual Flow on AKS you should have the following software on your local\master machine already installed:

- Azure CLI ([install](https://learn.microsoft.com/en-us/cli/azure/install-azure-cli))
- kubectl ([install](https://kubernetes.io/docs/tasks/tools/))
- Helm CLI ([install](https://helm.sh/docs/intro/install/))
- Git ([install](https://git-scm.com/downloads))

**IMPORTANT**: all the actions are recommended to be performed from the Microsoft account with owner privileges.

If you have just installed the Azure CLI, then you need to log in using following command:

`az login`

And create a Resource Group (if you do not have any) with the location that suits you best:

`az group create --name MyResourceGroup --location centralus`

## Create AKS cluster

**IMPORTANT**: if you are new to AKS, please read about AKS cluster: cluster types,config params and pricing (https://learn.microsoft.com/en-us/azure/aks/)

Visual Flow should be installed on AKS cluster. You can create AKS cluster using following commands:

```bash
export RESOURCE_GROUP=MyResourceGroup
export CLUSTER_NAME=visual-flow
export LOCATION=centralus
export NUM_NODES=2
export NUM_ZONES=1
az aks create --resource-group $MyResourceGroup --name $CLUSTER_NAME --node-count $NUM_NODES --location $LOCATION --zones $NUM_ZONES --generate-ssh-keys

# check access
az aks get-credentials --resource-group $RESOURCE_GROUP --name $CLUSTER_NAME
kubectl get pods --all-namespaces
```

For additional info check following guide:

<https://learn.microsoft.com/en-us/azure/aks/learn/quick-kubernetes-deploy-cli>

## Connect to existing AKS cluster from local machine

If you have AKS cluster, you can connect to it using the following command:

`az aks get-credentials --resource-group <YOUR_RESOURCE_GROUP> --name <YOUR_CLUSTER_NAME>`

## Install Visual Flow

1. Clone (or download) the [azure branch from Visual-Flow-deploy repository](https://github.com/ibagroup-eu/Visual-Flow-deploy/tree/azure) on your local computer using following command:

    `git clone -b azure https://github.com/ibagroup-eu/Visual-Flow-deploy.git Visual-Flow-azure-deploy`

2. Go to the directory "[visual-flow](https://github.com/ibagroup-eu/Visual-Flow-deploy/blob/azure/charts/visual-flow)" of the downloaded "Visual-Flow-Deploy" repository with the following command:

    `cd Visual-Flow-azure-deploy/charts/visual-flow`

3. *(Optional)* Configure Slack notifications (replace `YOUR_SLACK_TOKEN`) in [values-az.yaml](./charts/visual-flow/values-az.yaml) using the following guide:

    <https://github.com/ibagroup-eu/Visual-Flow-deploy/blob/main/SLACK_NOTIFICATION.md>

4. Set superusers in [values-az.yaml](./charts/visual-flow/values-az.yaml).

    New Visual Flow users will have no access in the app. The superusers(admins) need to be configured to manage user access. Specify the superusers real GitHub nicknames in [values-az.yaml](./charts/visual-flow/values-az.yaml) in the yaml list format:

    ```yaml
    superusers:
      - your-github-nickname
      # - another-superuser-nickname
    ```

5. *(Optional)* If you want, you can install kube-metrics then update [values-az.yaml](./charts/visual-flow/values-az.yaml) file according to the example below. 

    1. Check if the kube-metrics installed using the following command:

        ```bash
        kubectl top pods
        ```

        Output if the kube-metrics isn't installed:

        `error: Metrics API not available`

        If the kube-metrics is already installed then go to step 6.

    2. Edit [values-az.yaml](./charts/visual-flow/values-az.yaml) file according to the example below:

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

    2. Edit [values-az.yaml](./charts/visual-flow/values-az.yaml) file according to the example below:

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

    4. Update `redis.host` and `redis.password` of backend and frontend section in [values-az.yaml](./charts/visual-flow/values-az.yaml) file according to the example below:

        ```yaml
        ...
        redis:
          host: redis-master.<REDIS_NAMESPACE>.svc.cluster.local 
          port: 6379
        # username: ${REDIS_USER}
          password: # <REDIS_PASSWORD>
          database: 1
        ...
          frontend:
            deployment:
              variables:
                ...
                REDIS_HOST: redis-master.<REDIS_NAMESPACE>.svc.cluster.local
                ...
              secretVariables:
                ...
                REDIS_PASSWORD: # <REDIS_PASSWORD>
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

    4. Update `PG_URL`, `PG_USER` and `PG_PASS` in [values-az.yaml](./charts/visual-flow/values-az.yaml) file according to the example below:

        ```yaml
        ...
        historyserv:
          configFile:
            postgresql:
              PG_URL: jdbc:postgresql://postgresql.<PostgreSQL_NAMESPACE>.svc.cluster.local:5432/postgres # postgres_url
              PG_USER: # postgres_username
              PG_PASS: # postgres_password
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

10. Install the app using the updated [values-az.yaml](./charts/visual-flow/values-az.yaml) file with the following command:

    `helm install visual-flow . -f values-az.yaml -n <VF_NAMESPACE>`

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
    5. Replace "DUMMY_ID" with the Client ID value in [values-az.yaml](./charts/visual-flow/values-az.yaml).
    6. Click **Generate a new client secret** and replace in [values-az.yaml](./charts/visual-flow/values-az.yaml) "DUMMY_SECRET" with the generated Client secret value (Please note that you will not be able to see the full secret value later).

14. Update STRATEGY_CALLBACK_URL value in [values-az.yaml](./charts/visual-flow/values-az.yaml) to `https://<EXTERNAL_IP_FROM_SERVICE>/vf/ui/callback`

15. Upgrade the app in EKS cluster using updated values.yaml:

    `helm upgrade visual-flow . -f values-az.yaml -n <VF_NAMESPACE>`

16. Wait until the update is installed and all pods are running:

    `kubectl get pods -n <VF_NAMESPACE>`

## Use Visual Flow

1. All Visual Flow users (including superusers) need active Github account in order to be authenticated in application. Setup Github profile as per following steps:

    1. Navigate to the [account settings](https://github.com/settings/profile)
    2. Go to **Emails** tab: set email as public by unchecking **Keep my email addresses private** checkbox
    3. Go to **Profile** tab: fill in **Name** and **Public email** fields

2. Open the app's web page using the following link:

    `https://<EXTERNAL_IP_FROM_SERVICE>/vf/ui/`

3. See the guide on how to work with the Visual Flow at the following link: [Visual_Flow_User_Guide.pdf](Visual_Flow_User_Guide.pdf)

4. For each project Visual Flow (VF) generates a new namespace. 

   **IMPORTANT**: For each namespace there is a PVC that will be created and assigned automatically (`vf-pvc`) in RWX mode (`read\write-many`). AKS has default storage clases to provision PVs in RWX mode such as Azure files, but it uses CIFS protocol that does not allow to change file permissions of the files in that PV (https://learn.microsoft.com/en-us/troubleshoot/azure/azure-kubernetes/could-not-change-permissions-azure-files). This option is required for Visual Flow volumes (temporary files), so Azure files could not be used for stable work. We recommend to install third-party storage class in RWX mode, such as rook-ceph to be able to work with files in RWX mode. You can read about how to install rook-ceph on AKS cluster here: [Rook_ceph_on_AKS_guide.md](Rook_ceph_on_AKS_guide.md)

## Stop \ Start AKS cluster

1. If you want to stop temporary your AKS cluster and VF application, you can simply stop the cluster:

    `az aks stop --name <YOUR_CLUSTER_NAME> --resource-group <YOUR_RESOURCE_GROUP_NAME>`

2. Once you need it back:

    `az aks start --name <YOUR_CLUSTER_NAME> --resource-group <YOUR_RESOURCE_GROUP_NAME>`

## Delete Visual Flow

1. If the app is no longer required, you can delete it using the following command:

    `helm uninstall vf-app -n <VF_NAMESPACE>`

2. Check that everything was successfully deleted with the command:

    `kubectl get pods -n <VF_NAMESPACE>`

3. Delete Visual Flow namespace:
     `kubectl delete namespace <VF_NAMESPACE>`

## Delete AKS

1. If the AKS is no longer required, you can delete it using the following guide:

    <https://learn.microsoft.com/en-us/cli/azure/aks?view=azure-cli-latest#az-aks-delete>
