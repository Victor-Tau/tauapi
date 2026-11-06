# Backup and recovery

Applicability: authorized operations on an identified target environment. Cwd: tauapi-ops.
Never restore over production or delete volumes. Confirm backup freshness, target and permissions.
Run scripts/backup.sh, then scripts/restore-check.sh only in the script's isolated database.
Expected result includes nonempty tables, root presence and application-readable data.
If a stage fails, retain logs without credentials, keep original backup, inspect isolated state,
and retry only after fixing the prerequisite. A local backup is not an off-site copy.
Evidence must identify environment, backup revision/time, engine versions, command, outcome and gaps.
No backup/restore command was executed by this documentation rollout.
