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

    #Placeholder
    [Parameter()]
    [string] $AzEnvironment,

    [Parameter()]
    [bool] $AzCLIEnabled,

    [Parameter()]
    [bool] $AzPowershellEnabled,

    [Parameter()]
    [bool] $AzureADEnabled,

    [Parameter()]
    [bool] $AzureADPreview,

    #Placeholder
    [Parameter()]
    [bool] $MSGraphEnabled
)

Write-Output "$($MyInvocation.MyCommand) - AzCLIEnabled - $AzCLIEnabled"
if ($AzCLIEnabled) {
    Write-Output "$($MyInvocation.MyCommand) - AzCLIEnabled - Login"
    az login --service-principal -u $AppID -p="$($AppSecret | ConvertFrom-SecureString -AsPlainText)" --tenant $TenantID --allow-no-subscriptions | Out-Null

    Write-Output '-------------------------------------------'
    Write-Output "$($MyInvocation.MyCommand) - AzCLIEnabled - Current context:"
    az account show --output json | ConvertFrom-Json | Select-Object Name, id, state | Format-Table -AutoSize

    Write-Output '-------------------------------------------'
    Write-Output "$($MyInvocation.MyCommand) - AzCLIEnabled - Available contexts:"
    az account list --output json | ConvertFrom-Json | Select-Object Name, id, state | Format-Table -AutoSize

    Write-Output '-------------------------------------------'
    Write-Output "$($MyInvocation.MyCommand) - AzCLIEnabled - Setting context to selected subscription:"
    az account set --subscription $Subscription --output json | Out-Null
    if ($LASTEXITCODE -ne 0) {
        throw "$($MyInvocation.MyCommand) - AzCLIEnabled - Failed to set context to $Subscription"
    }

    $Context = az account show --output json | ConvertFrom-Json
    $Context | Select-Object Name, id, state | Format-Table -AutoSize

    Set-GitHubEnv -Name SubscriptionName -Value "$($Context.Name)" -Verbose
    Set-GitHubEnv -Name SubscriptionID -Value "$($Context.ID)" -Verbose

}

Write-Output "$($MyInvocation.MyCommand) - AzPowershellEnabled - $AzPowershellEnabled"
if ($AzPowershellEnabled) {
    Import-Module -Name Az -WarningAction SilentlyContinue

    Write-Output "$($MyInvocation.MyCommand) - AzPowershellEnabled - Login"
    $Credential = New-Object -TypeName System.Management.Automation.PSCredential($AppID, $AppSecret)
    Connect-AzAccount -Credential $Credential -ServicePrincipal -Tenant $TenantID | Out-Null

    Write-Output '-------------------------------------------'
    Write-Output "$($MyInvocation.MyCommand) - AzPowershellEnabled - Current context:"
    Get-AzContext | Select-Object Name, id, state | Format-Table -AutoSize

    Write-Output '-------------------------------------------'
    Write-Output "$($MyInvocation.MyCommand) - AzPowershellEnabled - Available contexts:"
    Get-AzContext -ListAvailable | Select-Object Name, id, state | Format-Table -AutoSize

    Write-Output '-------------------------------------------'
    Write-Output "$($MyInvocation.MyCommand) - AzPowershellEnabled - Setting context to selected subscription:"
    if ($Subscription | IsGUID ) {
        Get-AzSubscription -SubscriptionId $Subscription | Set-AzContext -Force | Out-Null
    } else {
        if ((Get-AzSubscription -SubscriptionName $Subscription).count -eq 1) {
            Get-AzSubscription -SubscriptionName $Subscription | Set-AzContext -Force | Out-Null
        } else {
            throw "$($MyInvocation.MyCommand) - AzPowershellEnabled - There are multiple subscriptions named $Subscription. Specify the GUID for the subscription instead!"
        }
    }
    $AzContext = Get-AzContext
    $CurrentSub = $AzContext.Subscription
    $CurrentSub | Select-Object Name, id, state | Format-Table -AutoSize

    Write-Output "$($MyInvocation.MyCommand) - AzPowershellEnabled - AzureADEnabled - $AzureADEnabled"
    if ($AzureADEnabled) {
        if ($env:ImageOS -notmatch 'win') {
            throw "$($MyInvocation.MyCommand) - AzureADEnabled - $AzureADEnabled - Unsupported OS: $env:ImageOS"
        }
        Write-Output "$($MyInvocation.MyCommand) - AzPowershellEnabled - AzureADEnabled - AzureADPreview - $AzureADPreview"
        if ($AzureADPreview) {
            try {
                Import-Module -Name AzureADPreview -WarningAction SilentlyContinue
            } catch {
                Write-Warning $_
                throw 'Failed to Import-Moduel -Name AzureADPreview'
            }
        } else {
            try {
                Import-Module -Name AzureAD -WarningAction SilentlyContinue
            } catch {
                Write-Warning $_
                throw 'Failed to Import-Moduel -Name AzureAD'
            }
        }

        $MSGToken = Get-AzAccessToken -ResourceUrl 'https://graph.microsoft.com'
        $AADToken = Get-AzAccessToken -ResourceUrl 'https://graph.windows.net'
        try {
            Connect-AzureAD -TenantId $AzContext.Tenant.Id -AadAccessToken $AADToken.Token -MsAccessToken $MSGToken.Token -AccountId $AzContext.Account.Id
        } catch {
            Write-Warning $_
            throw 'Could not connect with Connect-AzureAD'
        }
    }

    Write-Output "$($MyInvocation.MyCommand) - AzPowershellEnabled - MSGraphEnabled - $MSGraphEnabled"
    if ($MSGraphEnabled) {
        Write-Output 'Not yet implemented a login logic.'
        try {
            $MSGToken = Get-AzAccessToken -ResourceUrl 'https://graph.microsoft.com'
            Connect-MgGraph -AccessToken $MSGToken.Token
        } catch {
            Write-Warning $_
            throw 'Could not connect with Connect-AzureAD'
        }
    }
}
