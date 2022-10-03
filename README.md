# About Visual Flow

Visual Flow is an ETL tool designed for effective data manipulation via convenient and user-friendly interface. The tool has the following capabilities:

- Can integrate data from heterogeneous sources:
  - DB2
  - IBM COS
  - AWS S3
  - Elastic Search
  - PostgreSQL
  - MySQL/Maria
  - MSSQL
  - Oracle
  - Cassandra
  - Mongo
  - Redis
  - Redshift
- Leverage direct connectivity to enterprise applications as sources and targets
- Perform data processing and transformation
- Run custom code
- Leverage metadata for analysis and maintenance

Visual Flow application is divided into the following repositories:

- [Visual-Flow-frontend](https://github.com/ibagomel/Visual-Flow-frontend)
- [Visual-Flow-backend](https://github.com/ibagomel/Visual-Flow-backend)
- [Visual-Flow-jobs](https://github.com/ibagomel/Visual-Flow-jobs)
- _**Visual-Flow-deploy**_ (current)

# Visual Flow deploy

This repository contains 2 helm charts to deploy Visual Flow app to kubernetes cluster and script to update helm releases in CI/CD.

Helm charts in this repository:

- [vf-app](./charts/vf-app/) - to deploy both backend and frontend part of Visual Flow application.
- [vf-secrets](./charts/vf-secrets/) - to deploy several Secrets required for `vf-app` chart.

## Prerequisites

The application requires the following services installed in kubernetes cluster:

- [kubernetes metrics server](https://kubernetes.io/docs/tasks/debug-application-cluster/resource-metrics-pipeline/)
- [Argo Workflows](https://github.com/argoproj/argo-workflows)

### Kubernetes metrics server

Check if you have metrics server installed by running the following command:

```bash
kubectl top pods
# for OpenShift you can use oc cli
oc adm top pods
```

If your Kubernetes cluster does not have a metrics server, you will receive a message similar to one of the following:

```text
error: Metrics API not available
# or
Error from server (NotFound): the server could not find the requested resource (get services http:heapster:)
```

You can install metrics server from the [official repository](https://github.com/kubernetes-sigs/metrics-server).

### Argo Workflows

You should install Argo Workflows in kubernetes cluster to be able to work with app pipelines.

You can install it using [this helm chart](https://github.com/argoproj/argo-helm/tree/master/charts/argo).

NOTES:

- You should run Argo Workflows web server inside or outside kubernetes cluster.
- You should set requests and limits for executor. Example of Argo Workflows chart values.yaml file:

```yaml
...
executor:
  ...
  resources:
    requests:
      cpu: 0.1
      memory: 64Mi
    limits:
      cpu: 0.5
      memory: 512Mi
...
```

## Installation

First, deploy to kubernetes cluster the Secrets required for deploying main app:

- Open terminal and go to [charts/vf-secrets](./charts/vf-secrets) folder.
- Create values.yaml file with content of [values_example.yaml](./charts/vf-secrets/values_example.yaml) file:

  ```bash
  cp values_example.yaml values.yaml
  ```

- Edit values.yaml file (set correct values).
- Deploy Secrets via helm chart:

  ```bash
  helm install -n <namespace> <release_name> . -f values.yaml
  ```

Then, you can deploy the Visual Flow app:

- Open terminal and go to [charts/vf-app](./charts/vf-app) folder.
- Create values.yaml file with content of [values_example.yaml](./charts/vf-app/values_example.yaml) file:

  ```bash
  cp values_example.yaml values.yaml
  ```

- Edit values.yaml file (set correct values).
- Deploy application via helm chart:

  ```bash
  helm install -n <namespace> <release_name> . -f values.yaml
  ```

Check that everything is deployed correctly:

```http
https://<frontnend.external.host>/<frontend.subPath>/
```

## Contribution

[Check the official guide](https://github.com/ibagomel/Visual-Flow/blob/main/CONTRIBUTING.md).

## License

Visual Flow is an open-source software licensed under the [Apache-2.0 license](./LICENSE).
