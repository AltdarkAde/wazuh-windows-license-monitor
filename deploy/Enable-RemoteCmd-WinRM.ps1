<#
.SYNOPSIS
  Enables logcollector.remote_commands on many Wazuh Windows agents via WinRM.

.PARAMETER ServerList
  Text file with one server name per line.

.PARAMETER Credential
  Optional admin credential. Defaults to the current user.

.EXAMPLE
  .\Enable-RemoteCmd-WinRM.ps1 -ServerList .\servers.txt
#>
param(
    [Parameter(Mandatory)] [string] $ServerList,
    [System.Management.Automation.PSCredential] $Credential
)

$servers = Get-Content $ServerList | Where-Object { $_.Trim() -ne "" }

$block = {
    $file = "C:\Program Files (x86)\ossec-agent\local_internal_options.conf"
    $line = "logcollector.remote_commands=1"

    if (-not (Test-Path $file)) {
        "$env:COMPUTERNAME : agent not found"
        return
    }
    $content = Get-Content $file
    if ($content -notcontains $line) {
        (@($content) + $line) | Set-Content -Path $file -Encoding ASCII
        Restart-Service -Name WazuhSvc
        "$env:COMPUTERNAME : updated and restarted"
    } else {
        "$env:COMPUTERNAME : already set"
    }
}

$params = @{ ComputerName = $servers; ScriptBlock = $block; ErrorAction = 'Continue' }
if ($Credential) { $params.Credential = $Credential }

Invoke-Command @params
