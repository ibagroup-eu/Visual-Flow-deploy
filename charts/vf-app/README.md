# Visual Flow application

This helm chart allows to deploy both backend and frontend part of Visual Flow application.

This helm chart creates following kubernetes resources:

- 8 ClusterRoles (roles control access of application users to projects)
- 2 ServiceAccounts and 2 RoleBindings ( for backend and for Spark job)
- 2 Deployments, 2 Services, 2 Routes/Ingresses (backend and frontend parts of application)
- 3 ConfigMaps, 2 Secrets (backend config file, backend and frontend environment variables)

The app requires SSL configuration inside and outside kubernetes cluster and supports setting subpath for both frontend and backend parts of app.

Frontend part contains proxy to backend, so backend can be deployed as inaccesible outside kubernetes cluster.

## Parameters in values.yaml

The following tables list the configurable parameters of the Visual Flow app chart and their default values.
Often there are additions under the tables.

| Parameter               | Default | Description                                                                    |
|:------------------------|:--------|:-------------------------------------------------------------------------------|
| `project`               |         | Value of 'project' label in created resources                                  |
| `imagePullSecret`       |         | Name of secret to pull images                                                  |
| [`backend`](#backend)   |         | *(optional)* Backend part of app, if not exists backend will not be deployed   |
| [`frontend`](#frontend) |         | *(optional)* Frontend part of app, if not exists frontend will not be deployed |

You can deploy backend and frontend separately, even outside target kubernetes cluster. Targets for backend and frontend can be set via configuration.

`imagePullSecret` is a required field. It should contain name of secret with dockerconfigjson located in the namespace where the backend is installed.
This secret is used to pull backend, frontend and jobs docker images. Also this secret will be copied into each new namespace created by app.
([Pull Secret documentation](https://kubernetes.io/docs/tasks/configure-pod-container/pull-image-private-registry/))

### backend

Appears in: [Parameters](#parameters-in-valuesyaml)

| Parameter                                  | Default | Description                                                   |
|:-------------------------------------------|:--------|:--------------------------------------------------------------|
| `createRoles`                              | `false` | *(optional)* Create set of ClusterRoles                       |
| [`serviceAccount`](#backendserviceaccount) |         | Settings of backend ServiceAccount                            |
| [`deployment`](#backenddeployment)         |         | Backend Deployment settings                                   |
| [`configFile`](#backendconfigfile)         |         | Backend app settings                                          |
| [`service`](#befeservice)                  |         | Backend Service settings                                      |
| `subPath`                                  | `"/"`   | *(optional)* Set subpath for backend.                         |
| [`external`](#befeexternal)                |         | Settings of access to backend from outside kubernetes cluster |

Kubernetes cluster can contain only one set of ClusterRoles. These ClusterRoles is used to control access of app users to app projects.

If you set `subPath`, the backend will be available at `https://<hostname>/<subPath>/api/`.

### backend.serviceAccount

Appears in: [backend](#backend)

| Parameter | Default | Description                                                   |
|:----------|:--------|:--------------------------------------------------------------|
| `name`    |         | Name of ServiceAccount with cluster-admin role to run backend |
| `addSA`   | `false` | *(optional)* Create ServiceAccount and ClusterRoleBinding     |

ServiceAccount should have a ClusterRoleBinding with the cluster-admin role because backend should have access to list, get, create and delete namespaces.

### backend.deployment

Appears in: [backend](#backend)

| Parameter                              | Default | Description                                                                |
|:---------------------------------------|:--------|:---------------------------------------------------------------------------|
| `replicas`                             | `1`     | *(optional)* Count of relicas of backend Pod for load balancing            |
| [`image`](#befeimage)                  |         | Settings of backend docker image                                           |
| `cmd`                                  |         | *(optional)* Overwrite backend start command                               |
| [`variables`](#backendvariables)       |         | *(optional)* Add enviroment variables to backend. See details below        |
| [`secretVariables`](#backendvariables) |         | *(optional)* Add secret enviroment variables to backend. See details below |
| `sslSecret`                            |         | Secret with certificate and private key for ssl inside cluster             |
| `resources`                            |         | *(optional)* Set requests and limits for backend Pods                      |

`sslSecret` is a required field. Certificate and key from this secret used to encrypt backend traffic inside kubernetes cluster.
You can use self-signed certificate in this secret.

### backend.variables

Appears in: [backend.deployment](#backenddeployment)

`variables` and `secretVariables` are optional. They can contain map in format `variable_name: variable_value`.

`variables` are stored in ConfigMap, `secretVariables` are stored in Secret.

Both `variables` and `secretVariables` are added in enviroment variables of backend Pod.

Following variables should be set for backend.

| Name              | Description                                                          |
|:------------------|:---------------------------------------------------------------------|
| `KEYSTORE_PASS`   | Password to store ssl certificate and key in p12 storage             |
| `SLACK_API_TOKEN` | *(optional)* Token to send notifications to specific slack workspace |

You can set slack token in `configFile.slackJob.appAPItoken` but it is not recommended, because backend config file are stored in ConfigMap in plaintext.
It is recommended to set `configFile.slackJob.appAPItoken` to value `"${SLACK_API_TOKEN}"`
and define `SLACK_API_TOKEN` variable in `secretVariables`.

The documentation how to get the `SLACK_API_TOKEN` can be found [here](../../SLACK_NOTIFICATION.md).

### backend.configFile

Appears in: [backend](#backend)

| Parameter                        | Default | Description                            |
|:---------------------------------|:--------|:---------------------------------------|
| [`oauth`](#backendoauth)         |         | OAuth settings for backend             |
| `superusers`                     |         | List of users with admin access to app |
| [`namespace`](#backendnamespace) |         | Namespaces-related backend settings    |
| `argoServerUrl`                  |         | URL of Argo Workflows web server       |
| [`sparkJob`](#spark-job)         |         | Spark job settings                     |
| [`slackJob`](#slack-job)         |         | Slack notifications job settings       |

`superusers` list should contain names from `configFile.oauth.fieldsMap.username`.
Superusers have full access to all app projects, can create and delete them.

Argo Workflows web server can be installed inside or outside kubernetes cluster but should be configured to work with kubernetes cluster where backend installed.

### backend.oauth

Appears in: [backend.configFile](#backendconfigfile)

| Parameter   | Default | Description                                                        |
|:------------|:--------|:-------------------------------------------------------------------|
| `userInfo`  |         | URL to user info API on OAuth server                               |
| `fieldsMap` |         | Map between required fields and values in OAuth user info responce |

`fieldsMap` should contain following keys: `id`, `username`, `name`, `email`.
Values are paths to fields in json responce to user info request.
Examples: `username: "login"`, `email: "user.email"`

### backend.namespace

Appears in: [backend.configFile](#backendconfigfile)

| Parameter     | Default                 | Description                                                    |
|:--------------|:------------------------|:---------------------------------------------------------------|
| `label`       | `<helm release name>`   | *(optional)* value of `app` label for all app resources        |
| `prefix`      | `"${namespace.label}-"` | *(optional)* prefix for names of new namespaces (app projects) |
| `annotations` |                         | *(optional)* custom annotations for new namespaces             |

`label` can be used to separate users and projects of 2 or more app instances in one kubernetes cluster.

Example for `prefix`: prefix="vf-", project_name="Test project1" -> namespace="vf-test-project1"

For OpenShift cluster you need to set following custom annotations:

```yaml
"[openshift.io/sa.scc.mcs]": "s0:c25,c20"
"[openshift.io/sa.scc.supplemental-groups]": "1000/10000"
"[openshift.io/sa.scc.uid-range]": "1000/10000"
```

### frontend

Appears in: [Parameters](#parameters-in-valuesyaml)

| Parameter                           | Default | Description                                                    |
|:------------------------------------|:--------|:---------------------------------------------------------------|
| [`deployment`](#frontenddeployment) |         | Frontend Deployment settings                                   |
| [`service`](#befeservice)           |         | Frontend Service settings                                      |
| `subPath`                           | `"/"`   | *(optional)* Set subpath for frontend.                         |
| [`external`](#befeexternal)         |         | Settings of access to frontend from outside kubernetes cluster |

If you set `subPath`, the frontend will be available at `https://<hostname>/<subPath>/`.

### frontend.deployment

Appears in: [frontend](#frontend)

| Parameter                               | Default | Description                                                                 |
|:----------------------------------------|:--------|:----------------------------------------------------------------------------|
| `replicas`                              | `1`     | *(optional)* Count of relicas of frontend Pod for load balancing            |
| [`image`](#befeimage)                   |         | Settings of frontend docker image                                           |
| `cmd`                                   |         | *(optional)* Overwrite frontend start command                               |
| [`variables`](#frontendvariables)       |         | *(optional)* Add enviroment variables to frontend. See details below        |
| [`secretVariables`](#frontendvariables) |         | *(optional)* Add secret enviroment variables to frontend. See details below |
| `sslSecret`                             |         | Secret with certificate and private key for ssl inside cluster              |
| `resources`                             |         | *(optional)* Set requests and limits for frontend Pods                      |

`sslSecret` is a required field. Certificate from this secret used to encrypt frontend traffic inside kubernetes cluster.
You can use self-signed certificate in this secret.

### frontend.variables

Appears in: [frontend.deployment](#frontenddeployment)

`variables` and `secretVariables` are optional. They can contain map in format `variable_name: variable_value`.

`variables` are stored in ConfigMap, `secretVariables` are stored in Secret.

Both `variables` and `secretVariables` are added in enviroment variables of frontend Pod.

Following variables should be set for frontend.

| Name                    | Description                                                                            |
|:------------------------|:---------------------------------------------------------------------------------------|
| `API_SERVER`            | URL to backend part in format `https://<be_hostname>/<be_subPath>/`                    |
| `STRATEGY_CALLBACK_URL` | callback URL for OAuth service in format `https://<fe_hostname>/<fe_subPath>/callback` |
| `STRATEGY_BASE_URL`     | URL of OAuth service in format `https://<hostname>`                                    |
| `GITLAB_APP_ID`         | *(if GitLab OAuth)* ID of app registered in GitLab                                     |
| `GITLAB_APP_SECRET`     | *(if GitLab OAuth)* Token of app registered in GitLab                                  |
| `SESSION_SECRET`        | Random string of characters for session secret                                         |

It is recommended to define `GITLAB_APP_ID`, `GITLAB_APP_SECRET` and `SESSION_SECRET` variables in `secretVariables`.

### be/fe.image

Appears in: [backend.deployment](#backenddeployment), [frontend.deployment](#frontenddeployment)

| Parameter    | Default        | Description                  |
|:-------------|:---------------|:-----------------------------|
| `repository` |                | Repository and image to pull |
| `tag`        |                | Version tag                  |
| `pullPolicy` | `IfNotPresent` | *(optional)* imagePullPolicy |

[imagePullPolicy documentation](https://kubernetes.io/docs/concepts/configuration/overview/#container-images)

### be/fe.service

Appears in: [backend](#backend), [frontend](#frontend)

| Parameter     | Default     | Description                                   |
|:--------------|:------------|:----------------------------------------------|
| `type`        | `ClusterIP` | *(optional)* Service type                     |
| `port`        |             | Service port (doesn't affect the Pod port)    |
| `nodePort`    |             | *(optional)* Custom nodePort if type=NodePort |
| `annotations` |             | *(optional)* Custom annotations for Service   |

[Service types](https://kubernetes.io/docs/concepts/services-networking/service/#publishing-services-service-types)

In OpenShift cluster you can set following Service annotation to automatically generate secret with ssl certificate and key.
```yaml
service.beta.openshift.io/serving-cert-secret-name: <secret_name>
```
Generated secret can be used as `be/fe.deployment.sslSecret`

### be/fe.external

Appears in: [backend](#backend), [frontend](#frontend)

| Parameter                 | Default | Description                                            |
|:--------------------------|:--------|:-------------------------------------------------------|
| `enabled`                 | `false` | *(optional)* Enable/disable external access to app     |
| `type`                    |         | Type of kubernetes object for external access          |
| `host`                    |         | Hostname on which app will be accessible               |
| `annotations`             |         | *(optional)* Custom annotations                        |
| [`ssl`](#befeexternalssl) |         | *(optional)* Customizations of SSL for external access |

`type` supports following values:

- `ingress` - Ingress (networking.k8s.io/v1beta1)
- `route` - Route (route.openshift.io/v1)

If you are using nginx as Ingress, you should set following annotation to send ssl traffic to Service:

```yaml
nginx.ingress.kubernetes.io/backend-protocol: "HTTPS"
```

### be/fe.external.ssl

Appears in: [be/fe.external](#befeexternal)

| Parameter          | Default     | Description                                                     |
|:-------------------|:------------|:----------------------------------------------------------------|
| `cert`             |             | *(optional)* Use custom certificate to encrypt external traffic |
| `key`              |             | *(optional)* Use custom certificate to encrypt external traffic |
| `termination`      | `Reencrypt` | *(If type=route)* Termination value for Route                   |
| `additionalFields` |             | *(If type=route)* Set additional fields for Route               |

`termination` supports following values:

- `Reencrypt` - reencrypt traffic with another certificate (custom provided certificate or cluster default certificate)
- `Passthrough` - don't reencrypt traffic, leave encryption with .deployment.sslSecret certificate. 

`additionalFields` - set additional fields for Route. Possible fields:

- `caCertificate`: set CA certificate for custom certificate
- `destinationCACertificate`: add .deployment.sslSecret certificate if Route cannot automatically detect it
- `insecureEdgeTerminationPolicy`: set reaction to unencypted request (http). See Route documentation for details.

### spark job

Appears in: [backend.configFile](#backendconfigfile)

| Parameter       | Default                                | Description                                        |
|:----------------|:---------------------------------------|:---------------------------------------------------|
| `repository`    |                                        | Repository and image to pull                       |
| `tag`           |                                        | Version tag                                        |
| `jobSA`         |                                        | ServiceAccount to run Spark job                    |
| `jobRB`         |                                        | RoleBinding for .jobSA ServiceAccount              |
| `addSA`         | `false`                                | *(optional)* Create ServiceAccount and RoleBinding |
| `kubernetesAPI` | `k8s://https://kubernetes.default.svc` | *(optional)* Internal kubernetes API URL           |

`jobSA` ServiceAccount should have read access to ConfigMaps and Secrets and full access to Pods.
If you set `addSA`, RoleBinding with `edit` role will be created.

`jobSA` and `jobRB` will be copied into each new namespace for app project.

### slack job

Appears in: [backend.configFile](#backendconfigfile)

| Parameter     | Default | Description                                             |
|:--------------|:--------|:--------------------------------------------------------|
| `repository`  |         | Repository and image to pull                            |
| `tag`         |         | Version tag                                             |
| `appAPItoken` |         | Token to send notifications to specific slack workspace |

It is recommended to set `configFile.slackJob.appAPItoken` to value `"${SLACK_API_TOKEN}"`
and define `SLACK_API_TOKEN` variable in `secretVariables`.

## Example

You can view example of content of values.yaml file in [values_example.yaml file](./values_example.yaml).
