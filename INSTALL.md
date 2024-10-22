# Installation Visual Flow for Databricks to Azure Kubernetes Service (AKS)

1. [Prerequisite Installation](#prerequisites)
    - [Setting up prerequisite tools](#prereqtools)
    - [Clone Visual Flow repository](#clonevfrepo)
    - [Create AKS cluster](#createcluster)
    - [Configure GitHub OAuth](#oauthsetup)
2. [Installation of Visual Flow for Databricks](#installvffordbricks)
    - [Install Visual Flow for Databricks chart](#installvfchart)
3. [Use Visual Flow](#usevf)
4. [Delete Visual Flow](#uninstallvf)


## <a id="prerequisites">Prerequisite Installation</a>

To install Visual Flow for Databricks you should have the software below installed. Please use the official documentation to perform prerequisite installation.

>[!IMPORTANT]
>This installation requires an access token to our private Container Registry. Please contact us to get one: info@visual-flow.com
>This token is required for [Install Visual Flow chart](#installvfchart)

## <a id="prereqtools">Setting up prerequisite tools</a>

- Azure CLI ([install](https://learn.microsoft.com/en-us/cli/azure/install-azure-cli))
- kubectl ([install](https://kubernetes.io/docs/tasks/tools/))
- Helm CLI ([install](https://helm.sh/docs/intro/install/))
- Git ([install](https://git-scm.com/downloads))

>[!IMPORTANT]
>all the actions are recommended to be performed from the Microsoft account with the owner privileges.

If you have just installed the Azure CLI, then you need to log in using the following command:

```bash
az login
```

And create a Resource Group (if you do not have any) with the location that suits you best:

```bash
az group create --name MyResourceGroup --location eastus
```

## <a id="clonevfrepo">Clone Visual Flow repository</a>
Clone (or download) the [Azure for Databricks branch from Visual-Flow-deploy repository](https://github.com/ibagroup-eu/Visual-Flow-deploy/tree/azure-databricks) using the following command:
```bash
git clone -b azure-databricks https://github.com/ibagroup-eu/Visual-Flow-deploy.git Visual-Flow-deploy
```
>[!NOTE]
>This `Visual-Flow-deploy` directory will be used later during the application installation steps.

## <a id="createcluster">Create AKS cluster</a>
Visual Flow should be installed on AKS cluster.
>[!IMPORTANT]
> if you are new to AKS, please read about AKS cluster: cluster types, config params and pricing (https://learn.microsoft.com/en-us/azure/aks/)

You can create a cluster using the following commands:
```bash
# Create AKS cluster
export RESOURCE_GROUP=MyResourceGroup
export CLUSTER_NAME=visual-flow
export LOCATION=eastus
export KUBE_VERSION=1.29
export NUM_NODES=1
export NUM_ZONES=1

az aks create --resource-group $RESOURCE_GROUP --name $CLUSTER_NAME --kubernetes-version $KUBE_VERSION --node-count $NUM_NODES --location $LOCATION --zones $NUM_ZONES --generate-ssh-keys

# duration: ~20min
# check access to your AKS cluster
az aks get-credentials --resource-group $RESOURCE_GROUP --name $CLUSTER_NAME
kubectl get pods --all-namespaces
```

>[!TIP]
>For additional info check the following guide:
>
><https://learn.microsoft.com/en-us/cli/azure/aks?view=azure-cli-latest>

## <a id="oauthsetup">Configure GitHub OAuth</a>

  1. Go to GitHub user's OAuth apps (`https://github.com/settings/developers`) or organization's OAuth apps (`https://github.com/organizations/<ORG_NAME>/settings/applications`).
  2. Click the **Register a new application** or the **New Org OAuth App** button.
  3. Fill in the required fields:
     - Choose `<DNS_LABEL>` for your application. Your application hostname `<HOSTNAME>` will be: `<DNS_LABEL>.<CLUSTER_LOCATION>.cloudapp.azure.com`. For example, for `<DNS_LABEL>='myvfapp'` and `eastus` cluster location: `<HOSTNAME>=myvfapp.eastus.cloudapp.azure.com`. Make sure this URL is not taken by anyone else.
     - Set **Homepage URL** to `https://<HOSTNAME>/vf/ui/`
     - Set **Authorization callback URL** to `https://<HOSTNAME>/vf/ui/callback`
  4. Click the **Register application** button.
  5. Click **Generate a new client secret** and save your `Client ID\Client secret` pair, you will need it [later](#installvfchart).

>[!NOTE]
>Make sure to copy client secret before you refresh or close the web page. The value will be hidden.<BR>
>In case you lost your client secret, just create a new `Client ID\Client secret` pair.


## <a id="installvffordbricks">Installation of Visual Flow for Databricks</a>

During the next steps you will create Visual Flow application within your AKS cluster.

>[!NOTE]
>Before you start with Visual Flow for Databricks installation, make sure you have completed all steps from [Prerequisite Installation](#prerequisites).<BR>

## <a id="installvfchart">Install Visual Flow for Databricks chart</a>

>[!NOTE]
>Current installation is configured to work on `default` namespace of your cluster.<BR>
1. Get your [access token](#prerequisites) and replace <PLACE_HERE_YOUR_ACCESS_TOKEN> in this [file](./charts/visual-flow-databricks/charts/vfdbricks-azure-secrets/values.yaml)
    ```yaml
    ...
      - name: vf-image-pull
        app: vfdbricks-azure-app
        type: kubernetes.io/dockerconfigjson
        stringData:
          .dockerconfigjson: |-
          {
            "auths": {
              "visualflowdatabricks.azurecr.io": {
                "auth": "<PLACE_HERE_YOUR_ACCESS_TOKEN>" # <-- Replace <PLACE_HERE_YOUR_ACCESS_TOKEN> here with your access token
              }
            }
          }
    ...
    ```
2. Go to the directory "[visual-flow-databricks](./charts/visual-flow-databricks)" of the downloaded "Visual-Flow-Deploy" repository with the following command:
    ```bash
    cd Visual-Flow-deploy/charts/visual-flow-databricks
    ```

3. Install Visual Flow for Databricks application Helm chart:
    ```bash
    # Admin users for this app. You can have more than 1 github user, see example below
    export GITHUB_USER_LIST="GitHubUser1,GitHubUser2"

    # Use your <DNS_LABEL> you chose before in [Create a GitHub OAuth app](#oauthsetup) section
    export DNS_LABEL=<YOUR_DNS_LABEL>

    # Get your 'Client ID' and 'Client secret' from [Create a GitHub OAuth app](#oauthsetup) section
    export GITHUB_APP_ID=<YOUR_GITHUB_APP_ID>
    export GITHUB_APP_SECRET=<YOUR_GITHUB_APP_SECRET>

    # Set the latest available version
    export VF_HELM_VERSION=0.2.1

    # Helm install
    helm upgrade -i vfdbricks-azure-app . -n default \
    --set vfdbricks-azure-services.databricks.configFile.superusers="{${GITHUB_USER_LIST}}" \
    --set vfdbricks-azure-services.frontend.deployment.secretVariables.GITHUB_APP_ID="${GITHUB_APP_ID}" \
    --set vfdbricks-azure-services.frontend.deployment.secretVariables.GITHUB_APP_SECRET="${GITHUB_APP_SECRET}" \
    --set vfdbricks-azure-services.frontend.service.annotations."service\.beta\.kubernetes\.io\/azure-dns-label-name"="${DNS_LABEL}" \
    --version ${VF_HELM_VERSION}
    ```

4. Make sure all Visual Flow services and databases (Redis + Postgres) are up and running:

    ```bash
    kubectl get pods -n default
    ```

   Expected output:
    ```bash
    NAME                                              READY   STATUS    RESTARTS   AGE
    vfdbricks-azure-app-databricks-57b798b5d5-l86f7   1/1     Running   0          63s
    vfdbricks-azure-app-frontend-695c4f66b6-r466z     1/1     Running   0          63s
    vfdbricks-azure-app-historyserv-bfc8d69dc-t929m   1/1     Running   0          63s
    vfdbricks-azure-app-jobstorage-84658ff954-k5v58   1/1     Running   0          63s
    vfdbricks-azure-app-postgresql-0                  1/1     Running   0          63s
    vfdbricks-azure-app-redis-master-0                1/1     Running   0          63s
    ```


## <a id="usevf">Use Visual Flow</a>

>[!NOTE]
>Visual Flow for Databricks application requires a Databricks environment on your side to run jobs and pipelines.<BR>
>If you don't have one, please [create it](https://www.databricks.com/company/partners/cloud-partners)<BR>
>Visual Flow can work with Databricks created on any cloud (AWS, Azure, GCP).<BR>
>But if you are going to create a new Databricks environment, the best option is to have Databricks and Visual Flow on the same [cloud](https://www.databricks.com/product/azure)

1. All Visual Flow users (including superusers) need active GitHub account in order to be authenticated in the application. Setup GitHub profile as per the following steps:

    1. Navigate to the [account settings](https://github.com/settings/profile)
    2. Go to **Emails** tab: set email as public by unchecking **Keep my email addresses private** checkbox
    3. Go to **Profile** tab: fill in **Name** and **Public email** fields

2. Open the app's web page using the following link:

    ```bash
    https://<HOSTNAME>/vf/ui/
    ```
>[!TIP]
>Your `<HOSTNAME>` was configured here [Configure GitHub OAuth](#oauthsetup)

3. Take a look at this guide: [How to connect Visual Flow to Databricks](https://visual-flow.com/documents/how-connect-visual-flow-to-databricks-user-guide) 

4. See the guide on how to work with Visual Flow at the following link: [Visual_Flow_User_Guide.pdf](https://github.com/ibagroup-eu/Visual-Flow/blob/main/Visual_Flow_User_Guide.pdf)


## <a id="uninstallvf">Delete Visual Flow</a>
1. If the app is no longer required, you can delete it using the following command:

    ```bash
    helm uninstall vfdbricks-azure-app
    ```

2. Check that everything was successfully deleted with the command:

    ```bash
    kubectl get pods --all-namespaces
    ```

#### Delete AKS

1. If the AKS cluster is no longer required, you can delete it using the following command:
    ```bash
    export RESOURCE_GROUP=MyResourceGroup
    export CLUSTER_NAME=visual-flow
    az aks delete --name $CLUSTER_NAME --resource-group $RESOURCE_GROUP
    ```

>[!TIP]
>For additional info check the following guide:
>
><https://learn.microsoft.com/en-us/cli/azure/aks?view=azure-cli-latest#az-aks-delete>
