<#
.SYNOPSIS
  Enables logcollector.remote_commands on a Wazuh Windows agent.

.DESCRIPTION
  Intended as a GPO computer startup script (runs as SYSTEM). Idempotent: it only
  edits the file and restarts the agent when the setting is missing, so it is safe
  to run at every boot.

  Security note: this lets the Wazuh manager run commands defined in agent.conf on
  this host. Only enable it if your manager is trusted and well protected.
#>

$agentDir = "C:\Program Files (x86)\ossec-agent"
$file     = Join-Path $agentDir "local_internal_options.conf"
$line     = "logcollector.remote_commands=1"

if (-not (Test-Path $file)) { exit 0 }   # Wazuh agent not installed

$content = Get-Content $file -ErrorAction SilentlyContinue
if ($content -notcontains $line) {
    # Write ASCII with CRLF to avoid BOM / encoding problems the agent cannot parse.
    $new = @($content) + $line
    $new | Set-Content -Path $file -Encoding ASCII
    Restart-Service -Name WazuhSvc
}
