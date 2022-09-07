# Connect Visual Flow notifications to a Slack Workspace

In order to allow Visual Flow to send Slack notifications from a pipeline, Visual Flow needs to be added as a bot user to your Slack Workspace.

Below are the steps for adding a bot user to your Slack Workspace.

1. Open [the following link](https://api.slack.com/apps/new).

2. In the `'Create an app'` window select `'From scratch'`.

3. In the `'Name app & choose workspace'` window, populate the `'App name'` field (for example with 'Visual Flow') and in the `'Pick a workspace to develop your app in'` field select your workspace. Then click the `'Create App'` button.

4. Choose the `OAuth & Permissions` tab on the left sidebar.

5. Below the `Bot Token Scopes` click on `'Add an OAuth Scope'` and select the following scopes:

    ```yaml
    users:read (View people in a workspace)
    users:read.email (View email addresses of people in a workspace)
    chat:write (Send messages as Visual flow)
    chat:write.public (Send messages to channels Visual flow isn't a member of)
    channels:read (View basic information about public channels in a workspace)
    groups:read (View basic information about private channels that Visual flow has been added to)
    im:read (View basic information about direct messages that Visual flow has been added to)
    mpim:read (View basic information about group direct messages that Visual flow has been added to)
    ```

6. Above in the `'OAuth Tokens for Your Workspace'` section click on `'Install to Workspace'` then click the `'Allow'` button.

7. Copy the generated `'Bot User OAuth Token'` and paste it to the `SLACK_API_TOKEN` variable in values.yaml in the downloaded repository.

8. Return to the installation guide from which you were redirected to this doc and continue installing.

More information about 'Add a bot user' can be found [here](https://slack.com/intl/en-by/help/articles/115005265703-Create-a-bot-for-your-workspace).
