# AzConnect - Connect to Azure

[![Action-Test](https://github.com/equinor/AzConnect/actions/workflows/Action-Test.yml/badge.svg)](https://github.com/equinor/AzConnect/actions/workflows/Action-Test.yml)

This action automates logging on to Azure within a workflow, using [Azure service principal](https://docs.microsoft.com/azure/active-directory/develop/app-objects-and-service-principals)
together with Azure CLI and Azure PowerShell. With Azure Powershell you can also login using the Azure AD and MSGraph Powershell modules.

By default, the action only logs in using the Azure CLI (using the `az login` command).
Log in with additional solutions by using the inputs `AzPowershellEnabled`, `AzureADEnabled` and `MSGraphEnabled`.
Login to Azure without any subscriptions is supported by default, neat for deployments on management group or tenant scope, or if you plan on interacting with Azure AD.

## Inputs

| Input               | default | required | Description                                                                     | allowed values                                                                                   |
| ------------------- | ------- | -------- | ------------------------------------------------------------------------------- | ------------------------------------------------------------------------------------------------ |
| TenantID            |         | true     | Specifies the tenant to log in to.                                              | GUID                                                                                             |
| AppID               |         | true     | Specifies the application id to log in with.                                    | GUID                                                                                             |
| AppSecret           |         | true     | Specifies the secret for the application id.                                    | string (use ${{ secrets.APP_SECRET }})                                                           |
| Subscription        |         | false    | Specifies the subnscription name or id to log in to.                            | string (GUID or name of subscription)                                                            |
| AzEnvironment       |         | false    | Specified the azure environment which contains the Azure tenant.                | string, [Azure Environments](https://docs.microsoft.com/en-us/cli/azure/manage-clouds-azure-cli) |
| AzCLIEnabled        | 'true'  | true     | Login with Azure CLI                                                            | 'true'/'false'                                                                                   |
| UpgradeAzCLI        | 'false' | false    | Upgrade AzCLI to most recent version.                                           | 'true'/'false'                                                                                   |
| AzPowershellEnabled | 'false' | false    | Login with Azure Powershell                                                     | 'true'/'false'                                                                                   |
| AzureADEnabled      | 'false' | false    | Login with Azue AD via Azure Powershell. Requires that the runner is windows.   | 'true'/'false'                                                                                   |
| AzureADPreview      | 'false' | false    | Uses Azure AD Preview powershell module. Requires that AzureADEnabled is `true` | 'true'/'false'                                                                                   |
| MSGraphEnabled      | 'false' | false    | Uses Microsoft.Graph powershell module                                          | 'true'/'false'                                                                                   |

### Input overrides

This action uses environment variables with input overrides. For more info please read our article on [Input handling](https://github.com/equinor/OmniaProductTeam/wiki/About-our-actions#input-handling)

## Outputs

This action provides no direct outputs to the workflow, however it leaves the job in a state where it is connected to Azure.
This can be leveraged by other steps in the same job.

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
        # Login using TenantID, AppID, AppSecret and Subscription from environment variables.

      - name: Connect to Azure
        uses: equinor/AzConnect@v1
        with:
          Subscription: d392a84a-30fa-4bb5-b096-ad3ed05306d4
        # Login using TenantID, AppID and AppSecret from environment variables,
        # while overriding subscription with a guid that the App also has access to.

  AzConnect2AzureAD:
    runs-on: windows-latest
    steps:

      - name: Connect to Azure
        uses: equinor/AzConnect@v1
        with:
          AzCLIEnabled: false
          AzPowershellEnabled: true
          AzureADEnabled: true
    # Login to AzureAD using TenantID, AppID, AppSecret and Subscription from environment variables.

```


### Configure deployment credentials:

The usage example above depends on a secret named `APP_SECRET` in the repository.
The value of this secret is expected to be a string containing the secret of the service principal or app identified with the `AppID` variable.

1. [Create a Service Principal and assign a role on the subscription](https://docs.microsoft.com/en-us/azure/active-directory/develop/howto-create-service-principal-portal).
2. [Create a new secret for the Service Principal](https://docs.microsoft.com/en-us/azure/active-directory/develop/howto-create-service-principal-portal#option-2-create-a-new-application-secret).
3. [Store the secret as a repository secret](https://docs.github.com/en/actions/reference/encrypted-secrets#creating-encrypted-secrets-for-a-repository).
4. [Use the secret in your workflow](https://docs.github.com/en/actions/reference/encrypted-secrets#using-encrypted-secrets-in-a-workflow)
## Dependencies

N/A

## License

The scripts and documentation in this project are released under the [MIT License](LICENSE)

## Contributing

This project welcomes contributions and suggestions. Please review [Contributing to projects](https://github.com/equinor/OmniaProductTeam/wiki/How-to-contribute) in the [OmniaProductTeam wiki](https://github.com/equinor/OmniaProductTeam/wiki).
