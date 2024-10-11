# Installation Visual Flow for Databricks to Amazon Elastic Kubernetes Service (EKS)


1. [Prerequisite Installation](#prerequisites)
    - [Setting up prerequisite tools](#prereqtools)
    - [Clone Visual Flow repository](#clonevfrepo)
    - [Create EKS cluster](#createcluster)
    - [Install AWS Load Balancer (ALB) to EKS](#installalb)
    - [Install AWS EBS CSI driver to EKS](#installebsdriver)
    - [Install Redis and PostgreSQL](#settingupdbs) 
2. [Installation of Visual Flow for Databricks](#installvffordbricks)
    - [Install Visual Flow chart](#installvfchart)
    - [Configure GitHub OAuth](#oauthsetup)
    - [Complete the installation process](#completeinstall)
3. [Use Visual Flow](#usevf)
4. [Delete Visual Flow](#uninstallvf)

## <a id="prerequisites">Prerequisite Installation</a>

To install Visual Flow for Databricks you should have software installed below. Please use official documentation to perform prerequisite installation.

## <a id="prereqtools">Setting up prerequisite tools</a>

- AWS CLI ([install](https://docs.aws.amazon.com/cli/latest/userguide/cli-chap-install.html))
- kubectl ([install](https://kubernetes.io/docs/tasks/tools/))
- eksctl ([install](https://docs.aws.amazon.com/eks/latest/userguide/eksctl.html))
- Helm CLI ([install](https://helm.sh/docs/intro/install/))
- Git ([install](https://git-scm.com/downloads))

>[!IMPORTANT]
>All the actions are recommended to be performed from the admin/root AWS account.

If you have just installed the AWS CLI, then you need to log in using following command:

```bash
aws configure
```

## <a id="clonevfrepo">Clone Visual Flow repository</a>
Clone (or download) the [Amazon for Databricks branch from Visual-Flow-deploy repository](https://github.com/ibagroup-eu/Visual-Flow-deploy/tree/amazon-databricks) using following command:
```bash
git clone -b amazon-databricks https://github.com/ibagroup-eu/Visual-Flow-deploy.git Visual-Flow-deploy
```
>[!NOTE]
>This `Visual-Flow-deploy` directory will be used later during application installation steps.

## <a id="createcluster">Create EKS cluster</a>
Visual Flow should be installed on EKS cluster.
>[!IMPORTANT]
> It's recomended to create EKS cluster with at least 1 m5.large node (8GB memory and 2 vCPU) to run VF application on your cluster.
> 
> Additionally, make sure you use one of the latest [K8s version](https://docs.aws.amazon.com/eks/latest/userguide/kubernetes-versions.html#kubernetes-release-calendar) supported by EKS.

You can create cluster using following commands:
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
# if creation failed delete cluster using following command and repeat from beginning
# eksctl delete cluster --region us-east-1 --name $CLUSTER_NAME

# check access
kubectl get nodes
kubectl get pods --all-namespaces
```

>[!TIP]
>For additional info check following guide:
>
><https://docs.aws.amazon.com/eks/latest/userguide/getting-started-eksctl.html>

## <a id="installalb">Install AWS Load Balancer (ALB) to EKS</a>
AWS Load Balancer allows you to access applications on EKS from the Internet by hostname.

>[!NOTE]
>It's recommended to check [kuberneres-sigs/aws-load-balancer-controller](https://github.com/kubernetes-sigs/aws-load-balancer-controller/tree/v2.8.1) GitHub page to make sure v2.8.1 is not outdated.
>Otherwise, use the latest version of [iam_policy.json](https://raw.githubusercontent.com/kubernetes-sigs/aws-load-balancer-controller/v2.8.1/docs/install/iam_policy.json) file for stable ALB work.
>
You can install ALB using following commands:
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

# wait until all pods will be ready
kubectl get pods --all-namespaces
```

>[!TIP]
>For additional info check the following guides:
>
><https://docs.aws.amazon.com/eks/latest/userguide/aws-load-balancer-controller.html>
>
><https://docs.aws.amazon.com/eks/latest/userguide/network-load-balancing.html>

## <a id="installebsdriver">Install AWS EBS CSI driver to EKS</a>
You need to be able to create Persitent Volumes (PV) using Storage Class (SC) in your EKS cluster.<BR>
One way to achieve this - Install AWS EBS CSI driver.

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

# wait until all pods will be ready
kubectl get pods --all-namespaces
```

>[!TIP]
>For additional info, check the following guide:
>
><https://docs.aws.amazon.com/eks/latest/userguide/ebs-csi.html>

## <a id="settingupdbs">Install Redis & PostgreSQL</a>
Some functionality of Visual Flow application requires to have Redis & PosgreSQL dbs. Both of them with custom and default configs included in installation as a separate helm charts (values files with source from bitnami repo). 

<https://github.com/ibagroup-eu/Visual-Flow-deploy/tree/amazon-databricks/charts/dbs>

You can get them and install on you cluster using following steps.

#### 1. Add 'bitnami' repository to helm repo list
```bash
helm repo add bitnami https://charts.bitnami.com/bitnami
helm repo update
```
#### 2. Navigate to Visual-Flow-deploy/charts/dbs directory
Go to the "[dbs](./charts/dbs)" directory of the downloaded 
"[Visual-Flow-Deploy](#clonevfrepo)" repository with the following command:
    
```bash
cd Visual-Flow-deploy/charts/dbs
```
#### 3. Redis (for Session and Job's execution history)
Use helm tool to install `Redis` database service into the `visual-flow` cluster:
```bash
helm install redis -f bitnami-redis/values.yaml bitnami/redis
```
#### 4. PostgreSQL (History service)
Use helm tool to install `PostgreSQL` database server into the `visual-flow` cluster:
```bash
helm install pgserver -f bitnami-postgresql/values.yaml bitnami/postgresql
```
To check that both services Ready and Running use following kubectl command:
```bash
kubectl get pods
```
The command output shows you running pods with installed software.
```bash
NAME                    READY   STATUS    RESTARTS   AGE
pgserver-postgresql-0   1/1     Running   0          2m59s
redis-master-0          1/1     Running   0          3m23s
```

Now it's fine to navigate back to your home directory and proceed with Visual Flow application installation:
```bash
cd ../../..
```


>[!TIP]
> It is recommended to save output of the installation commands which contains helpful info with short guide how to get access to pod & dbs and show default credentials.

## <a id="installvffordbricks">Installation of Visual Flow for Databricks</a>

During next steps you will create Visual Flow application within your EKS cluster.

>[!NOTE]
>Before you start with Visual Flow for Databricks installation, make sure you have completed all steps from [Prerequisite Installation](#prerequisites).<BR>
>If you had a break during this installation process, make sure you are still working with your EKS cluster (visual-flow) and databases are up and running
>```bash
>kubectl get pods
>```
>
>The command output should be like this:
>
>```bash
>NAME                    READY   STATUS    RESTARTS   AGE
>pgserver-postgresql-0   1/1     Running   0          2m59s
>redis-master-0          1/1     Running   0          3m23s
>```

## <a id="installvfchart">Install Visual Flow chart</a>
1. Go to the directory "[visual-flow](./charts/visual-flow)" of the downloaded "Visual-Flow-Deploy" repository with the following command:
    ```bash
    cd Visual-Flow-deploy/charts/visual-flow
    ```

2. Set superusers in [values.yaml](./charts/visual-flow/values.yaml).<BR>
    Specify the superusers real GitHub nicknames in [values.yaml](./charts/visual-flow/values.yaml) in the yaml list format:
    ```yaml
    ...
    superusers:
      - your-github-nickname
      # - another-superuser-nickname
    ...
    ```
  >[!IMPORTANT]
  >New Visual Flow users will have no access in the app.<BR>
  >There should be at least 1 Github user as superuser(admin), but you can specify multiple superusers.

3. Install the app using the updated [values.yaml](./charts/visual-flow/values.yaml) file with the following command:

>[!NOTE]
>Current installation is configured to work on `default` namespace of your cluster.<BR>

    ```bash
    helm upgrade -i vfdbricks-aws-app . -f values.yaml
    ```

4. Check that the app is successfully installed and all pods are running with the following command:

    ```bash
    kubectl get pods --all-namespaces
    ```

5. Get the generated app's hostname with the following command:

    ```bash
    kubectl get svc vfdbricks-aws-app-frontend -o yaml | grep hostname | cut -c 17-
    ```

    Replace the string `<HOSTNAME_FROM_SERVICE>` with the generated hostname in the next steps.
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


## <a id="oauthsetup">Create a GitHub OAuth app</a>

  1. Go to GitHub user's OAuth apps (`https://github.com/settings/developers`) or organization's OAuth apps (`https://github.com/organizations/<ORG_NAME>/settings/applications`).
  2. Click the **Register a new application** or the **New Org OAuth App** button.
  3. Fill the required fields:
     - Set **Homepage URL** to `https://<HOSTNAME_FROM_SERVICE>/vf/ui/`
     - Set **Authorization callback URL** to `https://<HOSTNAME_FROM_SERVICE>/vf/ui/callback`
  4. Click the **Register application** button.
  5. Replace "DUMMY_ID" with the Client ID value in [values.yaml](./charts/visual-flow/values.yaml).
  6. Click **Generate a new client secret** and replace in [values.yaml](./charts/visual-flow/values.yaml) "DUMMY_SECRET" with the generated Client secret value
>[!NOTE]
>Make sure to copy client secret before you refresh or close the web page. The value will be hidden.<BR>
>In case you lost your client secret, just remove it and create a new `Client ID\Client secret` pair.

## <a id="completeinstall">Complete the installation process</a>
1. Upgrade the app in EKS cluster using updated values.yaml:

    ```bash
    helm upgrade vfdbricks-aws-app . -f values.yaml
    ```

2. Wait until the update is installed and all pods are running:

    ```bash
    kubectl get pods --all-namespaces
    ```

## <a id="usevf">Use Visual Flow</a>

>[!NOTE]
>Visual Flow for Databricks application requires a Databricks environment on your side to run jobs and pipelines.<BR>
>If you don't have one, please [create it](https://www.databricks.com/company/partners/cloud-partners)<BR>
>Visual Flow can work with Databricks created on any cloud (AWS, Azure, GCP).<BR>
>But if you are going to create a new Databricks environment, the best option is to have Databricks and Visual Flow on the same [cloud](https://www.databricks.com/product/aws)

1. All Visual Flow users (including superusers) need active Github account in order to be authenticated in application. Setup Github profile as per following steps:

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

#### Delete additional components

If you do no need them anymore - you can also delete and these additional components:

1. Redis database

```bash
helm uninstall redis
```

2. PostgreSQL database
```bash
helm uninstall pgserver
```

#### Delete EKS

1. If the EKS is no longer required, you can delete it using the following guide:

```bash
# for visual-flow cluster created in us-east-1 region.
export AWS_REGION=us-east-1
eksctl delete cluster --name visual-flow --region $AWS_REGION
```

>[!TIP]
> More info about how to delete EKS cluster: <https://docs.aws.amazon.com/eks/latest/userguide/delete-cluster.html>
