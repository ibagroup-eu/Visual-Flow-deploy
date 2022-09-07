# Visual Flow Secrets

This helm chart allows to deploy several Secrets required for Visual Flow app chart.

This helm chart can create following kubernetes resources required for Visual Flow app:

- 1 image pull secret (to pull all app components images)
- 2 tls secrets (to encrypt traffic inside kubernetes cluster)

## Parameters in values.yaml

The following tables list the configurable parameters of the Visual Flow Secrets chart and their default values.
Often there are additions under the tables.

| Parameter              | Default | Description                                   |
|:-----------------------|:--------|:----------------------------------------------|
| `project`              |         | Value of 'project' label in created resources |
| [`secrets[]`](#secret) |         | List of secrets to create                     |

### secret

Appears in: [Parameters](#parameters-in-valuesyaml)

The fields of the `secrets` list item are:

| Parameter    | Default | Description                                             |
|:-------------|:--------|:--------------------------------------------------------|
| `name`       |         | Secret name                                             |
| `app`        |         | Value of 'app' label                                    |
| `type`       |         | Secret type                                             |
| `data`       |         | *(optional)* map to add in `date` field of Secret       |
| `stringData` |         | *(optional)* map to add in `stringData` field of Secret |

About possible `type` values see [documentation](https://kubernetes.io/docs/concepts/configuration/secret/#secret-type).

`data` can contain map with names and base64 encoded values.

`stringData` can contain map with names and plaintext values.
During Secret creation values will be base64 encoded and moved along with keys to `data` field of Secret.

## Example

You can view an example of the contents of values.yaml file in [values_example.yaml file](./values_example.yaml).
