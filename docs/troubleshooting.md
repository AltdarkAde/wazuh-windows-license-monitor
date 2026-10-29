# Troubleshooting

## Nothing shows in the dashboard
Work through the chain in order and stop at the first failure.

1. **Group exists and contains the agent** (names are case-sensitive):
   `/var/ossec/bin/agent_groups -l` then `agent_groups -l -g <Group>`
2. **Agent received the config:** the agent's `shared\merged.mg` should contain `win_license_status`.
3. **Agent accepts remote commands:** `ossec.log` must not show
   `Remote commands are not accepted from the manager` after the last restart.
   The agent reads `local_internal_options.conf` only at service start.
4. **Command works by hand** in an elevated PowerShell on the server.
5. **Event reaches the manager:** temporarily set `<logall_json>yes</logall_json>` and run
   `grep '"location":"win_license_status"' /var/ossec/logs/archives/archives.json | tail -3`.
   Turn it back to `no` afterwards (also check `<logall>`), archives grow fast.
6. **Rule matches:** check `alerts.json` for rule IDs 100800 / 100801.

## Lessons learned
- **Command output contains a newline.** The real event is
  `ossec: output: 'win_license_status':\nLICENSED`, not a single line. A rule matching
  `'win_license_status': LICENSED` will never fire, even though `wazuh-logtest` passes
  when you type it on one line. Match only the prefix (`^ossec: output: 'win_license_status'`)
  and use a child rule for `NOT_LICENSED`.
- **Rule ID collisions** stop the ruleset from loading. Check existing IDs first.
- **`wazuh-logtest` has no `-t`.** Validate rules with `/var/ossec/bin/wazuh-analysisd -t`
  (no output means OK).
- **Notepad can write UTF-16/BOM** or add `.txt` to `local_internal_options.conf`. Check
  extensions and encoding.
- **`logall` and `logall_json`** both write archives; disable both after troubleshooting.
- **Disconnected agents** report nothing until they reconnect.

## Fallback without remote_commands
Put the `<localfile>` block directly in the agent's local `ossec.conf`. Commands defined
locally are always allowed. Remove it from the shared `agent.conf` for that agent to avoid
duplicate runs.
