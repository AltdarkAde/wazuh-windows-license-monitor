# Wazuh Windows License Monitor

See which of your Windows servers are licensed, directly in Wazuh. Agents run a small
PowerShell check on a schedule; the result becomes a searchable event, and unlicensed
machines raise an alert.

## How it works
1. A `full_command` localfile in the Windows group's shared `agent.conf` runs a PowerShell
   CIM query against `SoftwareLicensingProduct`.
2. The agent sends the output to the manager as a command event (built-in rule 530).
3. Custom rules build on 530:
   - **100800** (level 3): every license result reported.
   - **100801** (level 10): result contains `NOT_LICENSED`.
   - **100802** (level 8): the check itself failed (`CHECK_ERROR`).

## Requirements
- Wazuh 4.x manager and Windows agents (tested on 4.14)
- Windows agents in a dedicated agent group
- Admin access to the manager and the servers

## Setup

### 1. Manager: add the rules
Copy `manager/license_rules.xml` into `/var/ossec/etc/rules/local_rules.xml` (or a new file
in that directory). Make sure IDs 100800-100802 are unused, then validate and restart:

```bash
/var/ossec/bin/wazuh-analysisd -t
systemctl restart wazuh-manager
```

### 2. Manager: push the check to the Windows group
Add the block from `manager/agent.conf.example` to
`/var/ossec/etc/shared/<GroupName>/agent.conf` (group names are case-sensitive).
Use `<frequency>60</frequency>` while testing, then `21600`.

### 3. Agents: allow remote commands
Each agent needs this line in `C:\Program Files (x86)\ossec-agent\local_internal_options.conf`,
followed by a restart of the `WazuhSvc` service:

```
logcollector.remote_commands=1
```

Roll it out with either:
- **GPO startup script:** `agent/Enable-WazuhRemoteCmd.ps1`
  (Computer Configuration > Policies > Windows Settings > Scripts > Startup > PowerShell Scripts)
- **WinRM:** `deploy/Enable-RemoteCmd-WinRM.ps1 -ServerList servers.txt`

> **Security:** `remote_commands=1` lets the manager run commands defined in `agent.conf` on
> the agent. Only enable it if you trust and protect your manager. Alternatively, put the
> `<localfile>` block in each agent's local `ossec.conf`, which does not need this setting.

### 4. View results
In Wazuh Dashboard (Threat Hunting / Discover):

| Query | Shows |
|---|---|
| `rule.id: 100800` | Licensed |
| `rule.id: 100801` | Not licensed |
| `rule.id: 100802` | Check failed to run |
| `rule.id: (100800 OR 100801 OR 100802)` | Everything that reported |

Group by `agent.name` for a per-server list. Compare against your agent list; servers that
are missing are disconnected or lack the agent setting.

### Spotting stale or missing results

A server whose agent is down or whose check silently stopped will not appear at all, and an old
"licensed" result can look reassuring. To catch this, build a Data table visualization on
`rule.id: (100800 OR 100801)` with **Max of @timestamp** split by **Terms on agent.name**,
sorted oldest first. Anything older than about twice your `<frequency>` is stale.

## LicenseStatus values

| Value | Meaning |
|---|---|
| 0 | Unlicensed |
| 1 | Licensed |
| 2 | Initial grace period |
| 3 | Additional grace (activation timer) |
| 4 | Non-genuine grace |
| 5 | Notification |
| 6 | Extended grace |

Anything other than 1 is reported as `NOT_LICENSED status=N`. A machine with no matching
product key reports `NOT_LICENSED status=no_key`. KMS-activated servers can show a grace or
notification state if they have not contacted the KMS host for 180 days, so a non-1 status is
not always a missing license.

## Troubleshooting
See [docs/troubleshooting.md](docs/troubleshooting.md).

## License
MIT
