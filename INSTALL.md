# Installation Visual Flow to Amazon Elastic Kubernetes Service (EKS)

## Prerequisites

To install Visual Flow you should have the following software already installed:

- AWS CLI ([install](https://docs.aws.amazon.com/cli/latest/userguide/cli-chap-install.html))
- kubectl ([install](https://kubernetes.io/docs/tasks/tools/))
- eksctl ([install](https://docs.aws.amazon.com/eks/latest/userguide/eksctl.html))
- Helm CLI ([install](https://helm.sh/docs/intro/install/))
- Git ([install](https://git-scm.com/downloads))

**IMPORTANT**: all the actions are recommended to be performed from the admin/root AWS account.

If you have just installed the AWS CLI, then you need to log in using following command:

`aws configure`

## Create an EKS cluster

Visual Flow should be installed on an EKS cluster. For the full functionality - recomended use regular AWS EKS claster (if you need Backend & UI). In case if you need just backend and limited functions of frontend UI (without db & history services) - you can use and Fargate claster.


You can create cluster using following commands:

#### EKS Fargate:
```bash
export CLUSTER_NAME=visual-flow

eksctl create cluster \
--fargate \
--name $CLUSTER_NAME \
--region us-east-1 \
--with-oidc \
--full-ecr-access \
--external-dns-access \
--alb-ingress-access

# duration: ~20min
# if creation failed delete cluster using following command and repeat from beginning
# eksctl delete cluster --region us-east-1 --name $CLUSTER_NAME

# check access
kubectl get nodes
kubectl get pods --all-namespaces
```

#### EKS Regular cluster (EC2 instance type 'm5.large' with one Node)
```bash
export CLUSTER_NAME=visual-flow

eksctl create cluster \
--name $CLUSTER_NAME \
--region us-east-1 \
--with-oidc \
--ssh-access \
--full-ecr-access \
--external-dns-access \
--alb-ingress-access \
--instance-types=m5.large \
--managed \
--nodes 1

# duration: ~30min
# if creation failed delete cluster using following command and repeat from beginning
# eksctl delete cluster --region us-east-1 --name $CLUSTER_NAME

# check access
kubectl get nodes
kubectl get pods --all-namespaces
```

For additional info check following guide:

<https://docs.aws.amazon.com/eks/latest/userguide/getting-started-eksctl.html>

## Connect to existing EKS cluster from local machine

If you have an EKS cluster, you can connect to it using the following command:

`aws eks --region <REGION> update-kubeconfig --name <CLUSTER_NAME>`

## Check access to EKS cluster

Run the following command to check access to the EKS cluster from the local machine:

`kubectl get nodes`

If you get the message "`error: You must be logged in to the server (Unauthorized)`", you can try to fix it using the following guide:

<https://aws.amazon.com/premiumsupport/knowledge-center/eks-api-server-unauthorized-error/>

If you have access to the EKS cluster on a different computer, you can on another computer try to provide access to the cluster for the local machine using the following guide:

<https://docs.aws.amazon.com/eks/latest/userguide/add-user-role.html>

For more information on how to use EKS on fargate check the following guide:

<https://docs.aws.amazon.com/eks/latest/userguide/fargate-getting-started.html>

## Install an AWS Load Balancer (ALB) to EKS

AWS Load Balancer allows you to access applications on EKS from the Internet by hostname. If you don't have it installed, then install it. You can install ALB using following commands:

```bash
# add ALB policy
curl -o iam_policy.json https://raw.githubusercontent.com/kubernetes-sigs/aws-load-balancer-controller/v2.2.1/docs/install/iam_policy.json
# the following command will fail if the policy already exists
aws iam create-policy --policy-name AWSLoadBalancerControllerIAMPolicy --policy-document file://iam_policy.json

# create SA for ALB
export ACCOUNT_ID=<ACCOUNT_ID>
eksctl create iamserviceaccount --cluster=$CLUSTER_NAME --namespace=kube-system --name=aws-load-balancer-controller --attach-policy-arn=arn:aws:iam::${ACCOUNT_ID}:policy/AWSLoadBalancerControllerIAMPolicy --override-existing-serviceaccounts --approve

# install ALB via helm chart
helm repo add eks https://aws.github.io/eks-charts || helm repo update

# set correct VPC ID for ALB
VPC_ID_TMP=$(aws eks describe-cluster --name $CLUSTER_NAME | grep vpc- | cut -d ':' -f 2)
VPC_ID=$(echo $VPC_ID_TMP)

helm upgrade -i aws-load-balancer-controller eks/aws-load-balancer-controller --set clusterName=$CLUSTER_NAME --set region=us-east-1 --set vpcId=$VPC_ID --set serviceAccount.create=false --set serviceAccount.name=aws-load-balancer-controller -n kube-system

# wait until all pods will be ready
kubectl get pods --all-namespaces
```

For additional info check following guide:

<https://docs.aws.amazon.com/eks/latest/userguide/aws-load-balancer-controller.html>

<https://docs.aws.amazon.com/eks/latest/userguide/network-load-balancing.html>


## Install an EFS Controller to EKS (for automatic PVC provisioning)

How to install Amazon EFS CSI driver:

<https://docs.aws.amazon.com/eks/latest/userguide/efs-csi.html>

GitHub source of EFS CSI controller:

<https://github.com/kubernetes-sigs/aws-efs-csi-driver>

Depend from your choice - you can use or Dynamic provisioning (PV & PVC will be created and mounted to StorageClass automatically):

<https://github.com/kubernetes-sigs/aws-efs-csi-driver/blob/master/examples/kubernetes/dynamic_provisioning/README.md>

...or Static provisioning (you will need to create PV by yourself with required config):

<https://github.com/kubernetes-sigs/aws-efs-csi-driver/blob/master/examples/kubernetes/static_provisioning/README.md>


## Install Redis & PostgreSQL (optional if need)

Some functionality of VF app requires to have Redis & PosgreSQL dbs. Both of them with custom and default configs included in installation as a separate helm charts (values files with source from bitnami repo). 

<https://github.com/ibagroup-eu/Visual-Flow-deploy/tree/amazon/charts/dbs>

You can get them and install on you cluster using following commands:

Add 'bitnami' repository to helm repo list
```bash
helm repo add bitnami https://charts.bitnami.com/bitnami
helm repo update
```
1. Redis (for Session and Job's execution history)

`helm install redis -f bitnami-redis/values.yaml bitnami/redis`

2. PostgreSQL (History service)

`helm install pgserver -f bitnami-postgresql/values.yaml bitnami/postgresql`

FYI: Just in case better to save output of these command (it contains helpful info with short guide, how to get access to pod & dbs and show default credentials).

## Install Visual Flow

1. Clone (or download) the [Amazon branch from Visual-Flow-deploy repository](https://github.com/ibagroup-eu/Visual-Flow-deploy/tree/amazon) on your local computer using following command:

    `git clone -b amazon https://github.com/ibagroup-eu/Visual-Flow-deploy.git Visual-Flow-deploy`

2. Go to the directory "[visual-flow](https://github.com/ibagroup-eu/Visual-Flow-deploy/blob/amazon/charts/visual-flow)" of the downloaded "Visual-Flow-Deploy" repository with the following command:

    `cd Visual-Flow-deploy/charts/visual-flow`

3. *(Optional)* Configure Slack notifications in [values.yaml](./charts/visual-flow/values.yaml) using following guide:

    <https://github.com/ibagroup-eu/Visual-Flow-deploy/blob/main/SLACK_NOTIFICATION.md>

4. Set superusers in [values.yaml](./charts/visual-flow/values.yaml).

    New Visual Flow users will have no access in the app. The superusers(admins) need to be configured to manage user access. Specify the superusers real GitHub nicknames in [values.yaml](./charts/visual-flow/values.yaml) in the yaml list format:

    ```yaml
    superusers:
      - your-github-nickname
      # - another-superuser-nickname
    ```

5. If you have installed kube-metrics then update values.yaml file according to the example below.

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

6. If you have installed Argo workflows then update values.yaml file according to the example below.

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

7. Install the app using the updated [values.yaml](./charts/visual-flow/values.yaml) file with the following command:

    `helm upgrade -i vf-app . -f values.yaml`

8. Check that the app is successfully installed and all pods are running with the following command:

    `kubectl get pods --all-namespaces`

9. Get the generated app's hostname with the following command:

    `kubectl get svc vf-app-frontend -o yaml | grep hostname | cut -c 17-`

    Replace the string `<HOSTNAME_FROM_SERVICE>` with the generated hostname in the next steps.

10. Create a GitHub OAuth app:

    1. Go to GitHub user's OAuth apps (`https://github.com/settings/developers`) or organization's OAuth apps (`https://github.com/organizations/<ORG_NAME>/settings/applications`).
    2. Click the **Register a new application** or the **New OAuth App** button.
    3. Fill the required fields:
        - Set **Homepage URL** to `https://<HOSTNAME_FROM_SERVICE>/vf/ui/`
        - Set **Authorization callback URL** to `https://<HOSTNAME_FROM_SERVICE>/vf/ui/callback`
    4. Click the **Register application** button.
    5. Replace "DUMMY_ID" with the Client ID value in [values.yaml](./charts/visual-flow/values.yaml).
    6. Click **Generate a new client secret** and replace in [values.yaml](./charts/visual-flow/values.yaml) "DUMMY_SECRET" with the generated Client secret value (Please note that you will not be able to see the full secret value later).

11. Update 'host' (`host: https://<HOSTNAME_FROM_SERVICE>/vf/ui/`) and 'STRATEGY_CALLBACK_URL' (`STRATEGY_CALLBACK_URL: https://<HOSTNAME_FROM_SERVICE>/vf/ui/callback`) values in [values.yaml](./charts/visual-flow/values.yaml). 

12. Upgrade the app in EKS cluster using updated values.yaml:

    `helm upgrade vf-app . -f values.yaml`

13. Wait until the update is installed and all pods are running:

    `kubectl get pods --all-namespaces`

## Use Visual Flow

1. All Visual Flow users (including superusers) need active Github account in order to be authenticated in application. Setup Github profile as per following steps:

    1. Navigate to the [account settings](https://github.com/settings/profile)
    2. Go to **Emails** tab: set email as public by unchecking **Keep my email addresses private** checkbox
    3. Go to **Profile** tab: fill in **Name** and **Public email** fields

2. Open the app's web page using the following link:

    `https://<HOSTNAME_FROM_SERVICE>/vf/ui/`

3. See the guide on how to work with the Visual Flow at the following link: [Visual_Flow_User_Guide.pdf](https://github.com/ibagroup-eu/Visual-Flow/blob/main/Visual_Flow_User_Guide.pdf)

4. For each project Visual Flow generates a new namespace. For each namespace, you should create a Fargate profile to allow running jobs and pipelines in the corresponding project.

   First, create the project in the app, open it and check the URL of the page. It will have the following format:

   `https://<HOSTNAME_FROM_SERVICE>/vf/ui/<NAMESPACE>/overview`

   Get namespace from this URL and use in the following command to create fargate profile:

    `eksctl create fargateprofile --cluster <CLUSTER_NAME> --region <REGION> --name vf-app --namespace <NAMESPACE>`

## Delete Visual Flow

1. If the app is no longer required, you can delete it using the following command:

    `helm uninstall vf-app`

2. Check that everything was successfully deleted with the command:

    `kubectl get pods --all-namespaces`

#### Delete additional components

If you do no need them anymore - you can also delete and these additional components:

1. Redis & PostgreSQL databases

`helm uninstall redis`

`helm uninstall pgserver`

2. EFS & LoadBalancer Controllers

`helm uninstall aws-efs-csi-driver`

`helm uninstall aws-load-balancer-controller`

## Delete EKS

1. If the EKS is no longer required, you can delete it using the following guide:

`eksctl delete cluster --name visual-flow`

<https://docs.aws.amazon.com/eks/latest/userguide/delete-cluster.html>

