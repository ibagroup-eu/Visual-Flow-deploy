# Installation Visual Flow to Local Minikube

## Prerequisites

To install Visual Flow you should have the following software installed:

- Git ([install](https://git-scm.com/downloads))
- kubectl ([install](https://kubernetes.io/docs/tasks/tools/))
- Helm CLI ([install](https://helm.sh/docs/intro/install/))
- Docker ([install](https://docs.docker.com/engine/install/))
- Minikube ([install](https://minikube.sigs.k8s.io/docs/start/))

Make sure everything is installed and configured properly by running next commands. You should see isntalled version for every software you need:

```bash
git version
kubectl version --client
helm version
docker version
minikube version
```

## Create Minikube cluster

*In this example we will use the Docker driver. But depending on your system or requirements - you can also use hyperv, VirtualBox, Podman, KVM2 etc.*

*We recommend to use at least 4 cpu and 8G RAM for your Minikube cluster to be able to work properly with Spark jobs. If you lower these settings it may cause some fails. If you want to use more than 2 parallel executors and complex jobs, please consider to increase these values.*

You can create simple cluster in Minikube using following commands:

```bash
minikube start --cpus 4 --memory 8g --driver docker -p visual-flow 

# duration: ~5-10min

# if creation failed - delete cluster using following command and repeat from beginning:

#> minikube delete -p visual-flow
```

When cluster is ready - you can switch default profile to this cluster, check running pods and cluster IP:
```bash
minikube profile visual-flow

kubectl get pods -A
```


For additional info about Minikube check following guide: 
<https://minikube.sigs.k8s.io/docs/start>


## Install Redis & PostgreSQL

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

- After install, go back to main directory
```bash
cd ../../..
```

- Check that both services Ready and Running
```bash
> kubectl get pods
NAME                    READY   STATUS    RESTARTS   AGE
pgserver-postgresql-0   1/1     Running   0          2m59s
redis-master-0          1/1     Running   0          3m23s
```
FYI: Just in case better to save output of these command (it contains helpful info with short guide how to get access to pod & dbs and show default credentials).

## Install Visual Flow

1. Go to the directory "[visual-flow](https://github.com/ibagroup-eu/Visual-Flow-deploy/blob/minikube/charts/visual-flow)" of the downloaded "Visual-Flow-Deploy" repository with the following command:

    `cd Visual-Flow-deploy/charts/visual-flow`

2. If you have installed kube-metrics then update values.yaml file according to the example below.

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

3. If you have installed Argo workflows then update values.yaml file according to the example below.

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
4. Get minikube IP. On this IP will be available VF application and other services

    ```bash
    minikube ip
    ```
    
5. Update [values.yaml](./charts/visual-flow/values.yaml) and replace the string `<HOSTNAME_FROM_SERVICE>` with the generated hostname
   
6. Install the app using the updated [values.yaml](./charts/visual-flow/values.yaml) file with the following command:

    `helm upgrade -i vf-app . -f values.yaml`

7. Wait until the update is installed and all pods are up and running:

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
