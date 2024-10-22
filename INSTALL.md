# Installation Visual Flow for Databricks to Amazon Elastic Kubernetes Service (EKS)

1. [Prerequisite Installation](#prerequisites)
    - [Setting up prerequisite tools](#prereqtools)
    - [Clone Visual Flow repository](#clonevfrepo)
    - [Create EKS cluster](#createcluster)
    - [Install AWS Load Balancer (ALB) to EKS](#installalb)
    - [Install AWS EBS CSI driver to EKS](#installebsdriver)
    - [Configure GitHub OAuth](#oauthsetup)
2. [Installation of Visual Flow for Databricks](#installvffordbricks)
    - [Install Visual Flow for Databricks chart](#installvfchart)
3. [Use Visual Flow](#usevf)
4. [Delete Visual Flow](#uninstallvf)


## <a id="prerequisites">Prerequisite Installation</a>

To install Visual Flow for Databricks you should have the software below installed. Please use the official documentation to perform prerequisite installation.

## <a id="prereqtools">Setting up prerequisite tools</a>

- AWS CLI ([install](https://docs.aws.amazon.com/cli/latest/userguide/cli-chap-install.html))
- kubectl ([install](https://kubernetes.io/docs/tasks/tools/))
- eksctl ([install](https://docs.aws.amazon.com/eks/latest/userguide/eksctl.html))
- Helm CLI ([install](https://helm.sh/docs/intro/install/))
- Git ([install](https://git-scm.com/downloads))

>[!IMPORTANT]
>All the actions are recommended to be performed from the admin/root AWS account.

If you have just installed the AWS CLI, then you need to log in using the following command:

```bash
aws configure
```

## <a id="clonevfrepo">Clone Visual Flow repository</a>
Clone (or download) the [Amazon for Databricks branch from Visual-Flow-deploy repository](https://github.com/ibagroup-eu/Visual-Flow-deploy/tree/amazon-databricks) using the following command:
```bash
git clone -b amazon-databricks https://github.com/ibagroup-eu/Visual-Flow-deploy.git Visual-Flow-deploy
```
>[!NOTE]
>This `Visual-Flow-deploy` directory will be used later during the application installation steps.

## <a id="createcluster">Create EKS cluster</a>
Visual Flow should be installed on EKS cluster.
>[!IMPORTANT]
> It's recomended to create EKS cluster with at least 1 m5.large node (8GB memory and 2 vCPU) to run VF application on your cluster.
> 
> Additionally, make sure you use one of the latest [K8s version](https://docs.aws.amazon.com/eks/latest/userguide/kubernetes-versions.html#kubernetes-release-calendar) supported by EKS.

You can create a cluster using the following commands:
```bash
# Create EKS Regular cluster (EC2 instance type 'm5.large' with one Node) in us-east-1 region and 1.29 K8s version
export CLUSTER_NAME=visual-flow
export AWS_REGION=us-east-1
export KUBE_VERSION=1.29
export NODES_COUNT=1

eksctl create cluster \
    --name $CLUSTER_NAME \
    --region $AWS_REGION \
    --version $KUBE_VERSION \
    --nodes $NODES_COUNT \
    --nodes-min $NODES_COUNT \
    --nodes-max $NODES_COUNT \
    --with-oidc \
    --ssh-access \
    --full-ecr-access \
    --external-dns-access \
    --alb-ingress-access \
    --instance-types=m5.large \
    --managed 

# duration: ~30min
# if creation failed delete the cluster using the following command and repeat from the beginning
# eksctl delete cluster --region us-east-1 --name $CLUSTER_NAME

# check access
kubectl get nodes
kubectl get pods --all-namespaces
```

>[!TIP]
>For additional info check the following guide:
>
><https://docs.aws.amazon.com/eks/latest/userguide/getting-started-eksctl.html>

## <a id="installalb">Install AWS Load Balancer (ALB) to EKS</a>
AWS Load Balancer allows you to access applications on EKS from the Internet by hostname.

>[!NOTE]
>It's recommended to check [kuberneres-sigs/aws-load-balancer-controller](https://github.com/kubernetes-sigs/aws-load-balancer-controller/tree/v2.8.1) GitHub page to make sure v2.8.1 is not outdated.
>Otherwise, use the latest version of [iam_policy.json](https://raw.githubusercontent.com/kubernetes-sigs/aws-load-balancer-controller/v2.8.1/docs/install/iam_policy.json) file for stable ALB work.
>
You can install ALB using the following commands:
```bash
# add ALB policy
curl -o iam_policy.json https://raw.githubusercontent.com/kubernetes-sigs/aws-load-balancer-controller/v2.8.1/docs/install/iam_policy.json
# the following command will fail if the policy already exists
aws iam create-policy --policy-name AWSLoadBalancerControllerIAMPolicy --policy-document file://iam_policy.json

# create SA for ALB, replace <YOUR_ACCOUNT_ID> with your AWS account id
export ACCOUNT_ID=<YOUR_ACCOUNT_ID>
eksctl create iamserviceaccount --cluster=$CLUSTER_NAME --namespace=kube-system --name=aws-load-balancer-controller --attach-policy-arn=arn:aws:iam::${ACCOUNT_ID}:policy/AWSLoadBalancerControllerIAMPolicy --override-existing-serviceaccounts --approve

# install ALB via helm chart
helm repo add eks https://aws.github.io/eks-charts || helm repo update

# set correct VPC ID for ALB
export VPC_ID=$(aws eks describe-cluster --name $CLUSTER_NAME | grep vpc- | cut -d ':' -f 2 | cut -d '"' -f 2)

helm upgrade -i aws-load-balancer-controller eks/aws-load-balancer-controller --set clusterName=$CLUSTER_NAME --set region=$AWS_REGION --set vpcId=$VPC_ID --set serviceAccount.create=false --set serviceAccount.name=aws-load-balancer-controller -n kube-system

# wait until all pods are ready
kubectl get pods --all-namespaces
```

>[!TIP]
>For additional info check the following guides:
>
><https://docs.aws.amazon.com/eks/latest/userguide/aws-load-balancer-controller.html>
>
><https://docs.aws.amazon.com/eks/latest/userguide/network-load-balancing.html>

## <a id="installebsdriver">Install AWS EBS CSI driver to EKS</a>
You need to be able to create Persitent Volumes (PVs) using Storage Class (SC) in your EKS cluster.<BR>
You can achieve this using AWS EBS CSI driver.

```bash
# create IAM service account
eksctl create iamserviceaccount \
    --name ebs-csi-controller-sa \
    --namespace kube-system \
    --cluster $CLUSTER_NAME \
    --role-name AmazonEKS_EBS_CSI_DriverRole \
    --role-only \
    --attach-policy-arn arn:aws:iam::aws:policy/service-role/AmazonEBSCSIDriverPolicy \
    --approve

# create EBS addon
eksctl create addon --name aws-ebs-csi-driver --cluster $CLUSTER_NAME \
    --service-account-role-arn arn:aws:iam::${ACCOUNT_ID}:role/AmazonEKS_EBS_CSI_DriverRole \
    --force

# wait until all pods are ready
kubectl get pods --all-namespaces
```

>[!TIP]
>For additional info, check the following guide:
>
><https://docs.aws.amazon.com/eks/latest/userguide/ebs-csi.html>

## <a id="oauthsetup">Configure GitHub OAuth</a>

  1. Go to GitHub user's OAuth apps (`https://github.com/settings/developers`) or organization's OAuth apps (`https://github.com/organizations/<ORG_NAME>/settings/applications`).
  2. Click the **Register a new application** or the **New Org OAuth App** button.
  3. Fill in the required fields:
     - Set **Homepage URL** to `https://visual-flow-dummy-url.com/vf/ui/`
     - Set **Authorization callback URL** to `https://visual-flow-dummy-url.com/vf/ui/callback`
  4. Click the **Register application** button.
  5. Click **Generate a new client secret** and save your `Client ID\Client secret` pair, you will need it [later](#installvfchart).

>[!NOTE]
>Make sure to copy client secret before you refresh or close the web page. The value will be hidden.<BR>
>In case you lost your client secret, just create a new `Client ID\Client secret` pair.
>
>`visual-flow-dummy-url.com` is a dummy URL. After [Install](#installvffordbricks) do not forget to update **Homepage URL** and **Authorization callback URL** fields.


## <a id="installvffordbricks">Installation of Visual Flow for Databricks</a>

During the next steps you will create Visual Flow application within your EKS cluster.

>[!NOTE]
>Before you start with Visual Flow for Databricks installation, make sure you have completed all steps from [Prerequisite Installation](#prerequisites).<BR>

## <a id="installvfchart">Install Visual Flow for Databricks chart</a>
1. Go to the directory "[visual-flow-databricks](./charts/visual-flow-databricks)" of the downloaded "Visual-Flow-Deploy" repository with the following command:
    ```bash
    cd Visual-Flow-deploy/charts/visual-flow-databricks
    ```

2. Install Visual Flow for Databricks application Helm chart:
    ```bash
    # Admin users for this app. You can have more than 1 github user, see an example below
    export GITHUB_USER_LIST="GitHubUser1,GitHubUser2"

    # Get your 'Client ID' and 'Client secret' from [Create a GitHub OAuth app](#oauthsetup) section
    export GITHUB_APP_ID=<YOUR_GITHUB_APP_ID>
    export GITHUB_APP_SECRET=<YOUR_GITHUB_APP_SECRET>

    # Set the latest available version
    export VF_HELM_VERSION=0.2.1

    # Helm install
    helm upgrade -i vfdbricks-aws-app . -n default \
    --set vfdbricks-aws-services.databricks.configFile.superusers="{${GITHUB_USER_LIST}}" \
    --set vfdbricks-aws-services.frontend.deployment.secretVariables.GITHUB_APP_ID="${GITHUB_APP_ID}" \
    --set vfdbricks-aws-services.frontend.deployment.secretVariables.GITHUB_APP_SECRET="${GITHUB_APP_SECRET}" \
    --version ${VF_HELM_VERSION}
    ```

3. Make sure all Visual Flow services and databases (Redis + Postgres) are up and running:

    ```bash
    kubectl get pods -n default
    ```

   Expected output:
    ```bash
    NAME                                              READY   STATUS    RESTARTS   AGE
    vfdbricks-aws-app-databricks-57b798b5d5-l86f7   1/1     Running   0          63s
    vfdbricks-aws-app-frontend-695c4f66b6-r466z     1/1     Running   0          63s
    vfdbricks-aws-app-historyserv-bfc8d69dc-t929m   1/1     Running   0          63s
    vfdbricks-aws-app-jobstorage-84658ff954-k5v58   1/1     Running   0          63s
    vfdbricks-aws-app-postgresql-0                  1/1     Running   0          63s
    vfdbricks-aws-app-redis-master-0                1/1     Running   0          63s
    ```

4. Get the generated app's hostname with the following command:

    ```bash
    kubectl get svc vfdbricks-aws-app-frontend -o yaml | grep hostname | cut -c 17-
    ```

    Replace `visual-flow-dummy-url.com` from [OAuth step](#oauthsetup) with your app's hostname in **Homepage URL** and **Authorization callback URL** fields. Save changes.

>[!NOTE]
>If you have your own hostname or you are able to create it using [Route53](https://aws.amazon.com/route53/) for Visual Flow application you can use it instead of autogenereted <HOSTNAME_FROM_SERVICE>.<BR>
>In this case you need:
> 1) Request a certificate [ASM](https://aws.amazon.com/certificate-manager/) for this hostname
> 2) Add next annotations to vfdbricks-aws-app-frontend service (replace <YOUR_AWS_ACCOUNT> and <YOUR_CERT_ID> with your valid values):
>```yaml
>...
>"service.beta.kubernetes.io/aws-load-balancer-backend-protocol": "ssl",
>"service.beta.kubernetes.io/aws-load-balancer-ssl-cert": "arn:aws:acm:us-east-1:<YOUR_AWS_ACCOUNT>:certificate/<YOUR_CERT_ID>"
>...
>```
> 3) Use your own hostname as a <HOSTNAME_FROM_SERVICE> in the next steps


## <a id="usevf">Use Visual Flow</a>

>[!NOTE]
>Visual Flow for Databricks application requires a Databricks environment on your side to run jobs and pipelines.<BR>
>If you don't have one, please [create it](https://www.databricks.com/company/partners/cloud-partners)<BR>
>Visual Flow can work with Databricks created on any cloud (AWS, Azure, GCP).<BR>
>But if you are going to create a new Databricks environment, the best option is to have Databricks and Visual Flow on the same [cloud](https://www.databricks.com/product/aws)

1. All Visual Flow users (including superusers) need active Github account in order to be authenticated in the application. Setup Github profile as per the following steps:

    1. Navigate to the [account settings](https://github.com/settings/profile)
    2. Go to **Emails** tab: set email as public by unchecking **Keep my email addresses private** checkbox
    3. Go to **Profile** tab: fill in **Name** and **Public email** fields

2. Open the app's web page using the following link:

    ```bash
    https://<HOSTNAME_FROM_SERVICE>/vf/ui/
    ```

3. Take a look at this guide: [How to connect Visual Flow to Databricks](https://visual-flow.com/documents/how-connect-visual-flow-to-databricks-user-guide) 

4. See the guide on how to work with the Visual Flow at the following link: [Visual_Flow_User_Guide.pdf](https://github.com/ibagroup-eu/Visual-Flow/blob/main/Visual_Flow_User_Guide.pdf)


## <a id="uninstallvf">Delete Visual Flow</a>
1. If the app is no longer required, you can delete it using the following command:

    ```bash
    helm uninstall vfdbricks-aws-app
    ```

2. Check that everything was successfully deleted with the command:

    ```bash
    kubectl get pods --all-namespaces
    ```

#### Delete EKS

1. If the EKS is no longer required, you can delete it using the following guide:

```bash
# for visual-flow cluster created in us-east-1 region.
export AWS_REGION=us-east-1
export CLUSTER_NAME=visual-flow
eksctl delete cluster --name $CLUSTER_NAME --region $AWS_REGION
```

>[!TIP]
> More info about how to delete EKS cluster: <https://docs.aws.amazon.com/eks/latest/userguide/delete-cluster.html>
