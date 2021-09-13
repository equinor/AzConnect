[CmdletBinding()]
param(
    [Parameter(Mandatory)]
    [guid] $TenantID,

    [Parameter(Mandatory)]
    [guid] $AppID,

    [Parameter(Mandatory)]
    [securestring] $AppSecret,

    [Parameter()]
    [string] $Subscription,

    [Parameter()]
    [string] $AzEnvironment,

    [Parameter()]
    [switch] $AzCLIEnabled,

    [Parameter()]
    [switch] $UpgradeAzCLI,

    [Parameter()]
    [switch] $AzPowershellEnabled,

    [Parameter()]
    [switch] $AzureADEnabled,

    [Parameter()]
    [switch] $AzureADPreview,

    [Parameter()]
    [switch] $MSGraphEnabled
)
$Task = ($MyInvocation.MyCommand.Name).split('.')[0]

#region Prepare-Runner
New-GitHubLogGroup -Title "$Task-Prepare-Runner"

Write-Output "$Task-Prepare-Runner - AzCLIEnabled - $AzCLIEnabled"
if ($AzCLIEnabled) {
    az --version

    Write-Output "$Task-Prepare-Runner - AzCLIEnabled - UpgradeAzCLI - $UpgradeAzCLI"
    if ($UpgradeAzCLI) {
        az upgrade --all --yes
    }
}

Write-Output "$Task-Prepare-Runner - AzPowershellEnabled - $AzPowershellEnabled"
if ($AzPowershellEnabled) {
    Set-PSRepository PSGallery -InstallationPolicy Trusted
    Install-Module -Name Az -Scope CurrentUser -AllowClobber -Force

    Write-Output "$Task-Prepare-Runner - AzPowershellEnabled - AzureADEnabled - $AzureADEnabled"
    if ($AzureADEnabled) {
        if ($env:ImageOS -notmatch 'win') {
            throw "$Task-Prepare-Runner - AzureADEnabled - $AzureADEnabled - Unsupported OS: $env:ImageOS"
        }
        Write-Output "$Task-Prepare-Runner - AzPowershellEnabled - AzureADEnabled - AzureADPreview - $AzureADPreview"
        if ($AzureADPreview) {
            Install-Module -Name AzureADPreview -Scope CurrentUser -AllowClobber -Force
        } else {
            Install-Module -Name AzureAD -Scope CurrentUser -AllowClobber -Force
        }
    }
}

Write-Output "$Task-Prepare-Runner - MSGraphEnabled - $MSGraphEnabled"
if ($MSGraphEnabled) {
    Install-Module -Name Microsoft.Graph -Scope CurrentUser -AllowClobber -Force
}

#endregion

#region Connecting
New-GitHubLogGroup -Title "$Task-Connecting"

if ($AzEnvironment | IsNullOrEmpty ){
    $AzEnvironment = 'AzureCloud'
}

Write-Output "$Task-Connecting - AzCLIEnabled - $AzCLIEnabled"
if ($AzCLIEnabled) {
    Write-Output "$Task-Connecting - AzCLIEnabled - Login"

    az cloud set --name $AzEnvironment

    az login --service-principal -u $AppID -p="$($AppSecret | ConvertFrom-SecureString -AsPlainText)" --tenant $TenantID --allow-no-subscriptions | Out-Null

    Write-Output '-------------------------------------------'
    Write-Output "$Task-Connecting - AzCLIEnabled - Current context:"
    az account show --output json | ConvertFrom-Json | Select-Object Name, id, state | Format-Table -AutoSize

    Write-Output '-------------------------------------------'
    Write-Output "$Task-Connecting - AzCLIEnabled - Available contexts:"
    az account list --output json | ConvertFrom-Json | Select-Object Name, id, state | Format-Table -AutoSize

    Write-Output '-------------------------------------------'
    Write-Output "$Task-Connecting - AzCLIEnabled - Setting context to selected subscription:"
    az account set --subscription $Subscription --output json | Out-Null
    if ($LASTEXITCODE -ne 0) {
        throw "$Task-Connecting - AzCLIEnabled - Failed to set context to $Subscription"
    }

    $Context = az account show --output json | ConvertFrom-Json
    $Context | Select-Object Name, id, state | Format-Table -AutoSize

    Set-GitHubEnv -Name SubscriptionName -Value "$($Context.Name)" -Verbose
    Set-GitHubEnv -Name SubscriptionID -Value "$($Context.ID)" -Verbose

}

Write-Output "$Task-Connecting - AzPowershellEnabled - $AzPowershellEnabled"
if ($AzPowershellEnabled) {
    Import-Module -Name Az -WarningAction SilentlyContinue

    Write-Output "$Task-Connecting - AzPowershellEnabled - Login"
    $Credential = New-Object -TypeName System.Management.Automation.PSCredential($AppID, $AppSecret)
    try {
        $Params = @{
            Environment      = $AzEnvironment
            Credential       = $Credential
            ServicePrincipal = $true
            Tenant           = $TenantID
        }
        $Params
        Connect-AzAccount @Params
    } catch {
        Write-Warning $_
        throw "$Task-Connecting - AzPowershellEnabled - Login - Failed Connect-AzAccount"
    }

    Write-Output '-------------------------------------------'
    Write-Output "$Task-Connecting - AzPowershellEnabled - Current context:"
    Get-AzContext | Select-Object Name, id, state | Format-Table -AutoSize

    Write-Output '-------------------------------------------'
    Write-Output "$Task-Connecting - AzPowershellEnabled - Available contexts:"
    Get-AzContext -ListAvailable | Select-Object Name, id, state | Format-Table -AutoSize

    Write-Output '-------------------------------------------'
    Write-Output "$Task-Connecting - AzPowershellEnabled - Setting context to selected subscription:"
    if ($Subscription | IsGUID ) {
        Get-AzSubscription -SubscriptionId $Subscription | Set-AzContext -Force | Out-Null
    } else {
        if ((Get-AzSubscription -SubscriptionName $Subscription).count -eq 1) {
            Get-AzSubscription -SubscriptionName $Subscription | Set-AzContext -Force | Out-Null
        } else {
            throw "$Task-Connecting - AzPowershellEnabled - Subscription '$Subscription' is not unique. Specify the GUID for the subscription instead!"
        }
    }
    $AzContext = Get-AzContext
    $CurrentSub = $AzContext.Subscription
    $CurrentSub | Select-Object Name, id, state | Format-Table -AutoSize

    Write-Output "$Task-Connecting - AzPowershellEnabled - AzureADEnabled - $AzureADEnabled"
    if ($AzureADEnabled) {
        if ($env:ImageOS -notmatch 'win') {
            throw "$Task-Connecting - AzureADEnabled - $AzureADEnabled - Unsupported OS: $env:ImageOS"
        }
        Write-Output "$Task-Connecting - AzPowershellEnabled - AzureADEnabled - AzureADPreview - $AzureADPreview"
        if ($AzureADPreview) {
            try {
                Import-Module -Name AzureADPreview -WarningAction SilentlyContinue
            } catch {
                Write-Warning $_
                throw "$Task-Connecting - AzPowershellEnabled - AzureADEnabled - AzureADPreview - $AzureADPreview - Failed Import-Moduel -Name AzureADPreview"
            }
        } else {
            try {
                Import-Module -Name AzureAD -WarningAction SilentlyContinue
            } catch {
                Write-Warning $_
                throw "$Task-Connecting - AzPowershellEnabled - AzureADEnabled - AzureADPreview - $AzureADPreview - Failed Import-Moduel -Name AzureAD"
            }
        }

        $MSGToken = Get-AzAccessToken -ResourceUrl 'https://graph.microsoft.com'
        $AADToken = Get-AzAccessToken -ResourceUrl 'https://graph.windows.net'
        try {
            $Params = @{
                AzureEnvironmentName = $AzEnvironment
                TenantId             = $AzContext.Tenant.Id
                AadAccessToken       = $AADToken.Token
                MsAccessToken        = $MSGToken.Token
                AccountId            = $AzContext.Account.Id
            }
            Connect-AzureAD @Params
        } catch {
            Write-Warning $_
            throw 'Could not connect with Connect-AzureAD'
        }
    }
}

Write-Output "$Task-Connecting - MSGraphEnabled - $MSGraphEnabled"
if ($MSGraphEnabled) {
    Write-Output 'Not yet implemented a login logic.'

    if ($AzPowershellEnabled) {
        try {
            $MSGToken = Get-AzAccessToken -ResourceUrl 'https://graph.microsoft.com'
        } catch {
            Write-Warning $_
            throw "$Task-Connecting - MSGraphEnabled - $MSGraphEnabled - Failed Get-AzAccessToken"
        }
        $Token = $MSGToken.Token
    } else {
        try {
            $Params = @{
                TenantID  = $TenantID
                AppID     = $AppID
                AppSecret = $AppSecret
            }
            $Token = Get-MSGraphToken @Params
        } catch {
            Write-Warning $_
            throw "$Task-Connecting - MSGraphEnabled - $MSGraphEnabled - Failed Get-MSGraphToken"
        }
    }
    try {
        Connect-MgGraph -AccessToken $Token
    } catch {
        Write-Warning $_
        throw "$Task-Connecting - MSGraphEnabled - $MSGraphEnabled - Failed Connect-MgGraph"
    }
}
#endregion
