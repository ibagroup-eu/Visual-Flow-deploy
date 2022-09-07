# OAuth configuration

Visual Flow uses an external provider to authenticate users in the app. When new user login to the app for the first time, a new user is automatically created in the app.

The app doesn't restrict access based on any user parameters: if a user has passed OAuth authentication, then he can open the app. But when the user is created in the app, he has no access to any project. The project admin should manually grant the user access to the project.

Visual Flow supports following OAuth providers:

- GitLab
- GitHub

## How to setup

Authentication configuration for Visual Flow consists of the following stages:

1. Get frontend callback URL
2. Register app in OAuth provider
3. Set required parameters for Visual Flow frontend
4. Set required parameters for Visual Flow backend

### Get frontend callback URL

You need to determine the callback URL where the OAuth provider will send user data to the app.

The frontend callback URL has the following format: `https://<frontend-hostname>/<frontend-sub-path>/callback`

### Register app in OAuth provider

You need to register the app in the OAuth provider and get APP_ID and APP_SECRET values for the frontend so that it can use this provider for users authentication.

**Note**: for local frontend development you can register the app with `https://localhost:8888/<frontend-sub-path>/callback` frontend callback URL.

#### GitHub

- Go to the GitHub user's OAuth apps (`https://github.com/settings/developers`) or organization's OAuth apps (`https://github.com/organizations/<ORG_NAME>/settings/applications`).
- Click on `Register an application` or `New OAuth App` button.
- Fill required fields (Set `Authorization callback URL` to frontend callback URL value), click on `Register application` button.
- Save `Client ID` value.
- Click on `Generate a new client secret` and save generated `Client secret` value (Please note that you will not be able to see the full secret value later).
- Use saved `Client ID` and `Client secret` in the next stage.

#### GitLab

- Go to the GitLab user's applications (`https://gitlab.com/-/profile/applications`) or group applications (`https://gitlab.com/groups/<GROUP_NAME>/-/settings/applications`).
- Fill required fields (Set `Redirect URI` to frontend callback URL value), uncheck `Confidential` checkbox, check `read_user` checkbox, click on `Save application` button.
- Save `Application ID` and `Secret` values.
- Use saved `Application ID` and `Secret` values in the next stage.

### Set required parameters for Visual Flow frontend

You need to set the following environment variables for frontend:

#### GitHub

```env
STRATEGY=GITHUB
STRATEGY_BASE_URL=https://github.com
STRATEGY_CALLBACK_URL=https://<frontend-hostname>/<frontend-sub-path>/callback
GITHUB_APP_ID=<put Client ID>
GITHUB_APP_SECRET=<put Client secret>
```

#### GitLab

```env
STRATEGY=GITLAB
STRATEGY_BASE_URL=https://gitlab.com
STRATEGY_CALLBACK_URL=https://<frontend-hostname>/<frontend-sub-path>/callback
GITLAB_APP_ID=<put Application ID>
GITLAB_APP_SECRET=<put Secret>
```

### Set required parameters for Visual Flow backend

You need to set the following values in the backend config file:

- URL to get user info
- mapping between parameters required by app (id, username, name, email) and fields in user info response.

**Important**: all users who want to use Visual Flow must have all 4 required parameters filled in.
If any of the parameters does not exist or is empty for the user, then the app backend will generate a 500 error and the app frontend will show a blank white page when the user opens the app.

**Note**: also you can set a list of superusers - users with access to create and delete projects and full access to all projects. You need to add the value of user's username field to the backend config file in `superusers.set` array.

#### GitHub

```yaml
...
oauth:
  url:
    userInfo: "https://api.github.com/user"
auth:
  id: id
  username: login
  name: name
  email: email
...
```

#### GitLab

```yaml
...
oauth:
  url:
    userInfo: "https://gitlab.com/api/v4/user"
auth:
  id: id
  username: username
  name: name
  email: email
...
```

### Authentication configured

Authentication configuration is done, you can check that by opening the Visual Flow frontend home page:

`https://<frontend-hostname>/<frontend-sub-path>/`

When you open the page, you will be redirected to the provider's page, where it will ask if you want to grant the Visual Flow access to your user data. After approval, you will be redirected back to the app home page, where **you will not see any project** (if you are not added to superusers). During redirection to the home page, Visual Flow will create a user for you. After that **project admins can give you a role** in their projects. **You will only see projects in which you have any role** (if you are not added to superusers).
