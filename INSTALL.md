# Installation Visual Flow to Local Minikube

## Prerequisites

To install Visual Flow you should have the following software installed:

- Git ([install](https://git-scm.com/downloads))
- kubectl ([install](https://kubernetes.io/docs/tasks/tools/))
- Helm CLI ([install](https://helm.sh/docs/intro/install/))
- Minikube ([install](https://minikube.sigs.k8s.io/docs/start/))

In case if you going pull\push images from AWS ECR - you need also install few AWS tools:
- AWS CLI ([install](https://docs.aws.amazon.com/cli/latest/userguide/cli-chap-install.html))
- eksctl ([install](https://docs.aws.amazon.com/eks/latest/userguide/eksctl.html))

And if you have just installed the AWS CLI, then you need to log in using following command:

```bash
aws configure
```

In addition, the application has no formal hardware requirements, but Spark itself requires 4 CPUs and 6 GB of RAM to run at least one worker-pod.


## Create Minikube cluster

*In this example we will use the HyperV VM driver, which is recommended for the Windows OS family. But depending on your system or requirements - you can also use Docker, VirtualBox, Podman, KVM2 etc.*

*Also kubernetes version is 1.25.4, since current latest one (1.27.2) caused problem with GitOAuth Authentification (you may get issue like 'Failed to obtain access token'). So at least on this version with HyperV driver app was tested and works without any problem.*

You can create simple cluster in Minikube using following commands:

```bash
minikube start --cpus 4 --memory 6g --disk-size 20g --delete-on-failure=true --driver hyperv --kubernetes-version=v1.25.4 -p visual-flow 

# duration: ~5-10min

# if creation failed - delete cluster using following command and repeat from beginning:

#> minikube delete -p visual-flow
```

When cluster is ready - you can switch default profile to this cluster, check running pods and cluster IP:
```bash
minikube profile visual-flow

kubectl get pods -A

minikube ip
# on this IP will be available VF application and other services
```


For additional info about Minikube check following guide: 
<https://minikube.sigs.k8s.io/docs/start>


## Install Redis & PostgreSQL (optional if need)

Some functionality of VF app requires to have Redis & PosgreSQL dbs. Both of them with custom and default configs included in installation as a separate helm charts (values files with source from bitnami repo). 

<https://github.com/ibagroup-eu/Visual-Flow-deploy/tree/minikube/charts/dbs>

You can get them and install on you cluster using following actions.

- Add 'bitnami' repository to helm repo list
```bash
helm repo add bitnami https://charts.bitnami.com/bitnami
helm repo update
```

- Clone VF repo and change dir on Visual-Flow-deploy/charts/dbs
```bash
git clone -b minikube https://github.com/ibagroup-eu/Visual-Flow-deploy.git Visual-Flow-deploy

cd Visual-Flow-deploy/charts/dbs
```

1. Redis (for Session and Job's execution history)

`helm install redis -f bitnami-redis/values.yaml bitnami/redis`

2. PostgreSQL (History service)

`helm install pgserver -f bitnami-postgresql/values.yaml bitnami/postgresql`

- Check that both services Ready and Running
```bash
> kubectl get pods
NAME                    READY   STATUS    RESTARTS   AGE
pgserver-postgresql-0   1/1     Running   0          2m59s
redis-master-0          1/1     Running   0          3m23s
```
FYI: Just in case better to save output of these command (it contains helpful info with short guide how to get access to pod & dbs and show default credentials).

## Install Visual Flow

1. Clone (or download) the [Minikube branch from Visual-Flow-deploy repository](https://github.com/ibagroup-eu/Visual-Flow-deploy/tree/minikube) on your local computer using following command:

    `git clone -b minikube https://github.com/ibagroup-eu/Visual-Flow-deploy.git Visual-Flow-deploy`

2. Go to the directory "[visual-flow](https://github.com/ibagroup-eu/Visual-Flow-deploy/blob/minikube/charts/visual-flow)" of the downloaded "Visual-Flow-Deploy" repository with the following command:

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

    `kubectl get pods -A`

9. Get the IP of your cluster with following command:

    `minikube ip`

    Replace the string `<HOSTNAME_FROM_SERVICE>` with the generated hostname in the next steps.

10. Create a GitHub OAuth app:

    1. Go to GitHub user's OAuth apps (`https://github.com/settings/developers`) or organization's OAuth apps (`https://github.com/organizations/<ORG_NAME>/settings/applications`).
    2. Click the **Register a new application** or the **New OAuth App** button.
    3. Fill the required fields:
        - Set **Homepage URL** to `https://<HOSTNAME_FROM_SERVICE>:30910/vf/ui/`
        - Set **Authorization callback URL** to `https://<HOSTNAME_FROM_SERVICE>:30910/vf/ui/callback`
    4. Click the **Register application** button.
    5. Replace "DUMMY_ID" with the Client ID value in [values.yaml](./charts/visual-flow/values.yaml).
    6. Click **Generate a new client secret** and replace in [values.yaml](./charts/visual-flow/values.yaml) "DUMMY_SECRET" with the generated Client secret value (Please note that you will not be able to see the full secret value later).

11. Update 'host' (`host: https://<HOSTNAME_FROM_SERVICE>/vf/ui/`) and 'STRATEGY_CALLBACK_URL' (`STRATEGY_CALLBACK_URL: https://<HOSTNAME_FROM_SERVICE>/vf/ui/callback`) values in [values.yaml](./charts/visual-flow/values.yaml). 

12. Upgrade release using updated 'values.yaml':

    `helm upgrade vf-app . -f values.yaml`

13. Wait until the update is installed and all pods are running:

    `kubectl get pods -A`

## Use Visual Flow

1. All Visual Flow users (including superusers) need active Github account in order to be authenticated in application. Setup Github profile as per following steps:

    1. Navigate to the [account settings](https://github.com/settings/profile)
    2. Go to **Emails** tab: set email as public by unchecking **Keep my email addresses private** checkbox
    3. Go to **Profile** tab: fill in **Name** and **Public email** fields

2. Open the app's web page using the following link:

    `https://<HOSTNAME_FROM_SERVICE>:30910/vf/ui/`

3. See the guide on how to work with the Visual Flow at the following link: [Visual_Flow_User_Guide.pdf](https://github.com/ibagroup-eu/VF-deploy/blob/minikube/Visual_Flow_User_Guide.pdf)

## Delete Visual Flow

1. If the app is no longer need, you can delete it using the following command:

    `helm uninstall vf-app`

2. Check that everything was successfully deleted with the command:

    `kubectl get pods --all-namespaces`

#### Delete additional components

If you do no need them anymore - you can also delete and these additional components:

- Redis & PostgreSQL databases

`helm uninstall redis`

`helm uninstall pgserver`

## Delete Minikube cluster and profile

If this cluster is no longer need - you can delete it using the following command:

`minikube delete -p visual-flow`

## Helpful links about Minikube:

- Minikube Start (https://minikube.sigs.k8s.io/docs/start)
- Minikube Basic Control (https://minikube.sigs.k8s.io/docs/handbook/controls)
- Minikube Dashboard (https://minikube.sigs.k8s.io/docs/handbook/dashboard)
- Minikube Tutorials (https://minikube.sigs.k8s.io/docs/tutorials)
- Minikube FAQ (https://minikube.sigs.k8s.io/docs/faq)
