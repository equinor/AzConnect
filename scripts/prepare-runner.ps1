[CmdletBinding()]
param(
    [Parameter()]
    [bool] $AzCLIEnabled,

    [Parameter()]
    [bool] $UpgradeAzCLI,

    [Parameter()]
    [bool] $AzPowershellEnabled,

    [Parameter()]
    [bool] $AzureADEnabled,

    [Parameter()]
    [bool] $AzureADPreview,

    [Parameter()]
    [bool] $MSGraphEnabled
)

Write-Output "$($MyInvocation.MyCommand) - AzCLIEnabled - $AzCLIEnabled"
if ($AzCLIEnabled) {
    az --version

    Write-Output "$($MyInvocation.MyCommand) - AzCLIEnabled - UpgradeAzCLI - $UpgradeAzCLI"
    if ($UpgradeAzCLI) {
        az upgrade --all --yes
    }
}

Write-Output "$($MyInvocation.MyCommand) - AzPowershellEnabled - $AzPowershellEnabled"
if ($AzPowershellEnabled) {
    Set-PSRepository PSGallery -InstallationPolicy Trusted
    Install-Module -Name Az -Scope CurrentUser -AllowClobber -Force

    Write-Output "$($MyInvocation.MyCommand) - AzPowershellEnabled - AzureADEnabled - $AzureADEnabled"
    if ($AzureADEnabled) {
        if ($env:ImageOS -notmatch 'win') {
            throw "$($MyInvocation.MyCommand) - AzureADEnabled - $AzureADEnabled - Unsupported OS: $env:ImageOS"
        }
        Write-Output "$($MyInvocation.MyCommand) - AzPowershellEnabled - AzureADEnabled - AzureADPreview - $AzureADPreview"
        if ($AzureADPreview) {
            Install-Module -Name AzureADPreview -Scope CurrentUser -AllowClobber -Force
        } else {
            Install-Module -Name AzureAD -Scope CurrentUser -AllowClobber -Force
        }
    }

    Write-Output "$($MyInvocation.MyCommand) - AzPowershellEnabled - MSGraphEnabled - $MSGraphEnabled"
    if ($MSGraphEnabled) {
        Install-Module -Name Microsoft.Graph -Scope CurrentUser -AllowClobber -Force
    }
}
