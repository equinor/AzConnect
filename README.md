# AzConnect - Connect to Azure

[![Action-Test](https://github.com/equinor/AzConnect/actions/workflows/Action-Test.yml/badge.svg)](https://github.com/equinor/AzConnect/actions/workflows/Action-Test.yml)

[![Linter](https://github.com/equinor/AzConnect/workflows/Linter/badge.svg)](https://github.com/equinor/AzConnect/actions/workflows/Linter.yml)

[![GitHub](https://img.shields.io/github/license/equinor/AzConnect)](LICENSE)

This action automates logging on to Azure within a workflow, using [Azure service principal](https://docs.microsoft.com/azure/active-directory/develop/app-objects-and-service-principals)
together with Azure CLI and Azure PowerShell. With Azure PowerShell you can also log in using the Azure AD and MSGraph PowerShell modules.

By default, the action only logs in using the Azure CLI (using the `az login` command).
Log in with additional solutions by using the inputs `AzPowershellEnabled`, `AzureADEnabled` and `MSGraphEnabled`.
Log in to Azure without any subscriptions is supported by default, neat for deployments on management group or tenant scope, or if you plan on interacting with Azure AD.

## Why use this module?

There are other public actions which have similar functionality as this one, such as [azure/login](https://github.com/azure/login).
However, there are some reasons why we chose to create our own:

- Uses the environment variables with same name as inputs to reduce the need of specifying same values multiple times, but still have override capability in the inputs given to the action.
  See [AzActions - Input handling](https://github.com/equinor/AzActions#input-handling) for details.
- Support more than Azure Resource Manager deployments in a unified deployment approach. This action allows enabling login to Azure AD and MSGraph as well.
- Follow GitHub security recommendations, where [GitHub Secrets are not stored as JSON data structures](https://docs.github.com/en/actions/reference/encrypted-secrets#naming-your-secrets).

These contributions could be made to [azure/login](https://github.com/azure/login) but at the time of writing, our knowledge on js/ts was lacking.

## Inputs

| Input name            | Default | Required | Description                                                                     | Allowed values                                                                                   |
| :-------------------- | :------ | :------- | :------------------------------------------------------------------------------ | :----------------------------------------------------------------------------------------------- |
| `TenantID`            |         | Yes      | Specifies the tenant to log in to.                                              | GUID                                                                                             |
| `AppID`               |         | Yes      | Specifies the application id to log in with.                                    | GUID                                                                                             |
| `AppSecret`           |         | Yes      | Specifies the secret for the application id.                                    | string (use ${{ secrets.APP_SECRET }})                                                           |
| `Subscription`        |         | No       | Specifies the subnscription name or id to log in to.                            | string (GUID or name of subscription)                                                            |
| `AzEnvironment`       |         | No       | Specified the azure environment which contains the Azure tenant.                | string, [Azure Environments](https://docs.microsoft.com/en-us/cli/azure/manage-clouds-azure-cli) |
| `AzCLIEnabled`        | `true`  | Yes      | Log in with Azure CLI                                                           | `true`/`false`                                                                                   |
| `UpgradeAzCLI`        | `false` | No       | Upgrade AzCLI to most recent version.                                           | `true`/`false`                                                                                   |
| `AzPowershellEnabled` | `false` | No       | Log in with Azure PowerShell                                                    | `true`/`false`                                                                                   |
| `AzureADEnabled`      | `false` | No       | Log in with Azure AD via Azure PowerShell. Requires that the runner is windows. | `true`/`false`                                                                                   |
| `AzureADPreview`      | `false` | No       | Uses Azure AD Preview PowerShell module. Requires that AzureADEnabled is `true` | `true`/`false`                                                                                   |
| `MSGraphEnabled`      | `false` | No       | Uses Microsoft.Graph PowerShell module                                          | `true`/`false`                                                                                   |

### Input overrides

This action uses environment variables with input overrides. For more info please read our article on [Input handling](https://github.com/equinor/AzActions#input-handling)

## Outputs

N/A

## Environment variables

This action creates the following environment variables on the runner.

| Variable name      | Description                                        |
| :----------------- | :------------------------------------------------- |
| `SubscriptionName` | The Azure subscription name in the current context |
| `SubscriptionID`   | The Azure subscription id in the current context   |

## Usage

```yaml
name: Test-Workflow

on: [push]

env:
  TenantID: 0229e31e-273f-49bc-befe-eb255ae83dfc
  AppID: a3825ed9-ca00-4355-9b3e-a37f12f9cf44
  Subscription: Dev-Subscription-123
  AppSecret: ${{ secrets.APP_SECRET }}

jobs:
  AzConnect:
    runs-on: ubuntu-latest
    steps:

      - name: Checkout source code
        uses: actions/checkout@v2

      - name: Connect to Azure
        uses: equinor/AzConnect@v1
        # Log in using TenantID, AppID, AppSecret and Subscription from environment variables.

      - name: Connect to Azure
        uses: equinor/AzConnect@v1
        with:
          Subscription: d392a84a-30fa-4bb5-b096-ad3ed05306d4
        # Log in using TenantID, AppID and AppSecret from environment variables,
        # while overriding subscription with a GUID that the App also has access to.

  AzConnect2AzureAD:
    runs-on: windows-latest
    steps:

      - name: Connect to Azure
        uses: equinor/AzConnect@v1
        with:
          AzCLIEnabled: false
          AzPowershellEnabled: true
          AzureADEnabled: true
    # Log in to AzureAD using TenantID, AppID, AppSecret and Subscription from environment variables.

```

### Configure deployment credentials

The usage example above depends on a secret named `APP_SECRET` in the repository.
The value of this secret is expected to be a string containing the secret of the service principal or app identified with the `AppID` variable.

1. [Create a Service Principal and assign a role on the subscription](https://docs.microsoft.com/en-us/azure/active-directory/develop/howto-create-service-principal-portal).
2. [Create a new secret for the Service Principal](https://docs.microsoft.com/en-us/azure/active-directory/develop/howto-create-service-principal-portal#option-2-create-a-new-application-secret).
3. [Store the secret as a repository secret](https://docs.github.com/en/actions/reference/encrypted-secrets#creating-encrypted-secrets-for-a-repository).
4. [Use the secret in your workflow](https://docs.github.com/en/actions/reference/encrypted-secrets#using-encrypted-secrets-in-a-workflow)

## Dependencies

- [equinor/AzUtilities](https://www.github.com/equinor/AzUtilities)

## Contributing

This project welcomes contributions and suggestions. Please review [How to contribute](https://github.com/equinor/AzActions#how-to-contibute) on our [AzActions](https://github.com/equinor/AzActions) page.
