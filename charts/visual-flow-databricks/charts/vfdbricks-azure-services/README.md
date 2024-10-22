# Visual Flow application

This helm chart allows to deploy both Visual Flow for Databricks backend and frontend part of Visual Flow application.

This helm chart creates following kubernetes resources:

- 8 ClusterRoles (roles control access of application users to projects)
- 2 ServiceAccounts and 2 RoleBindings ( for databricks backend)
- 2 Deployments, 2 Services, 2 Routes/Ingresses (databricks and backend and frontend parts of application)
- 3 ConfigMaps, 2 Secrets (databricks backend config file, databricks backend and frontend environment variables)

The app requires SSL configuration inside and outside kubernetes cluster and supports setting subpath for both frontend and databricks backend parts of app.

Frontend part contains proxy to databrciks backend, so databricks backend can be deployed as inaccesible outside kubernetes cluster.

## Parameters in values.yaml

The following tables list the configurable parameters of the Visual Flow app chart and their default values.
Often there are additions under the tables.

| Parameter                   | Default | Description                                                                     |
|:----------------------------|:--------|:--------------------------------------------------------------------------------|
| `project`                   |         | Value of 'project' label in created resources                                   |
| `imagePullSecret`           |         | Name of secret to pull images                                                   |
| [`databricks`](#databricks) |         | *(optional)* Backend part of app, if not exists databricks will not be deployed |
| [`frontend`](#frontend)     |         | *(optional)* Frontend part of app, if not exists frontend will not be deployed  |

You can deploy databricks backend and frontend separately, even outside target kubernetes cluster. Targets for databricks backend and frontend can be set via configuration.

`imagePullSecret` is a required field. It should contain name of secret with dockerconfigjson located in the namespace where the databricks backend is installed.
This secret is used to pull databricks backend, frontend and jobs docker images. Also this secret will be copied into each new namespace created by app.
([Pull Secret documentation](https://kubernetes.io/docs/tasks/configure-pod-container/pull-image-private-registry/))

### databricks

Appears in: [Parameters](#parameters-in-valuesyaml)

| Parameter                                     | Default | Description                                                      |
|:----------------------------------------------|:--------|:-----------------------------------------------------------------|
| `createRoles`                                 | `false` | *(optional)* Create set of ClusterRoles                          |
| [`serviceAccount`](#databricksserviceaccount) |         | Settings of databricks backend ServiceAccount                    |
| [`deployment`](#databricksdeployment)         |         | Databricks backend Deployment settings                           |
| [`configFile`](#databricksconfigfile)         |         | Databricks backend app settings                                  |
| [`service`](#befeservice)                     |         | Databricks Backend Service settings                              |
| `subPath`                                     | `"/"`   | *(optional)* Set subpath for databricks backend                  |
| [`external`](#befeexternal)                   |         | Settings of access to databricks from outside kubernetes cluster |

Kubernetes cluster can contain only one set of ClusterRoles. These ClusterRoles is used to control access of app users to app projects.

If you set `subPath`, the databricks backend will be available at `https://<hostname>/<subPath>/api/`.

### databricks.serviceAccount

Appears in: [databricks](#databricks)

| Parameter | Default | Description                                                              |
|:----------|:--------|:-------------------------------------------------------------------------|
| `name`    |         | Name of ServiceAccount with cluster-admin role to run databricks backend |
| `addSA`   | `false` | *(optional)* Create ServiceAccount and ClusterRoleBinding                |

ServiceAccount should have a ClusterRoleBinding with the cluster-admin role because databricks should have access to list, get, create and delete namespaces.

### databricks.deployment

Appears in: [databricks](#databricks)

| Parameter                                 | Default | Description                                                                   |
|:------------------------------------------|:--------|:------------------------------------------------------------------------------|
| `replicas`                                | `1`     | *(optional)* Count of relicas of databricks Pod for load balancing            |
| [`image`](#befeimage)                     |         | Settings of databricks docker image                                           |
| `cmd`                                     |         | *(optional)* Overwrite databricks start command                               |
| [`variables`](#databricksvariables)       |         | *(optional)* Add enviroment variables to databricks. See details below        |
| [`secretVariables`](#databricksvariables) |         | *(optional)* Add secret enviroment variables to databricks. See details below |
| `sslSecret`                               |         | Secret with certificate and private key for ssl inside cluster                |
| `resources`                               |         | *(optional)* Set requests and limits for databricks Pods                      |

`sslSecret` is a required field. Certificate and key from this secret used to encrypt databricks backend traffic inside kubernetes cluster.
You can use self-signed certificate in this secret.

### databricks.variables

Appears in: [databricks.deployment](#databricksdeployment)

`variables` and `secretVariables` are optional. They can contain map in format `variable_name: variable_value`.

`variables` are stored in ConfigMap, `secretVariables` are stored in Secret.

Both `variables` and `secretVariables` are added in enviroment variables of databricks Pod.

Following variables should be set for databricks.

| Name              | Description                                                          |
|:------------------|:---------------------------------------------------------------------|
| `KEYSTORE_PASS`   | Password to store ssl certificate and key in p12 storage             |

### databricks.configFile

Appears in: [databricks](#databricks)

| Parameter                           | Default | Description                            |
|:------------------------------------|:--------|:---------------------------------------|
| [`oauth`](#databricksoauth)         |         | OAuth settings for databricks          |
| `superusers`                        |         | List of users with admin access to app |
| [`namespace`](#databricksnamespace) |         | Namespaces-related databricks settings |

`superusers` list should contain names from `configFile.oauth.fieldsMap.username`.
Superusers have full access to all app projects, can create and delete them.

### databricks.oauth

Appears in: [databricks.configFile](#databricksconfigfile)

| Parameter   | Default | Description                                                        |
|:------------|:--------|:-------------------------------------------------------------------|
| `userInfo`  |         | URL to user info API on OAuth server                               |
| `fieldsMap` |         | Map between required fields and values in OAuth user info responce |

`fieldsMap` should contain following keys: `id`, `username`, `name`, `email`.
Values are paths to fields in json responce to user info request.
Examples: `username: "login"`, `email: "user.email"`

### databricks.namespace

Appears in: [databricks.configFile](#databricksconfigfile)

| Parameter     | Default                 | Description                                                    |
|:--------------|:------------------------|:---------------------------------------------------------------|
| `label`       | `<helm release name>`   | *(optional)* value of `app` label for all app resources        |
| `prefix`      | `"${namespace.label}-"` | *(optional)* prefix for names of new secrets (app projects)    |
| `annotations` |                         | *(optional)* custom annotations for new project secrets        |

`label` can be used to separate users and projects of 2 or more app instances in one kubernetes cluster.

Example for `prefix`: prefix="vf-", project_name="Test project1" -> secret="vf-test-project1"

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

| Name                    | Default      | Description                                                                            |
|:------------------------|:-------------|:---------------------------------------------------------------------------------------|
| `API_SERVER`            |              | URL to databricks in format `https://<be_hostname>/<be_subPath>/`                      |
| `STRATEGY_CALLBACK_URL` |              | callback URL for OAuth service in format `https://<fe_hostname>/<fe_subPath>/callback` |
| `STRATEGY_BASE_URL`     |              | URL of OAuth service in format `https://<hostname>`                                    |
| `GITLAB_APP_ID`         |              | *(if GitLab OAuth)* ID of app registered in GitLab                                     |
| `GITLAB_APP_SECRET`     |              | *(if GitLab OAuth)* Token of app registered in GitLab                                  |
| `SESSION_SECRET`        |              | Random string of characters for session secret                                         |
| `PLATFORM`              | `DATABRICKS` | Frontend mode to work with databricks

It is recommended to define `GITLAB_APP_ID`, `GITLAB_APP_SECRET` and `SESSION_SECRET` variables in `secretVariables`.

`PLATFORM` should be set as `DATABRICKS` to work with databricks backend instead of regular backend.

### be/fe.image

Appears in: [databricks.deployment](#databricksdeployment), [frontend.deployment](#frontenddeployment)

| Parameter    | Default        | Description                  |
|:-------------|:---------------|:-----------------------------|
| `repository` |                | Repository and image to pull |
| `tag`        |                | Version tag                  |
| `pullPolicy` | `IfNotPresent` | *(optional)* imagePullPolicy |

[imagePullPolicy documentation](https://kubernetes.io/docs/concepts/configuration/overview/#container-images)

### be/fe.service

Appears in: [databricks](#databricks), [frontend](#frontend)

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

Appears in: [databricks](#databricks), [frontend](#frontend)

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
