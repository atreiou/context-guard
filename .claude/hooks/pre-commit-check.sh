#!/bin/bash
# Context Guard: Pre-commit safety hook
# Reminds Claude to update safeguard files before every git commit
# Runs as a PreToolUse hook on Bash commands

# 1. SECTION: Input parsing
# Do NOT parse the hook payload with jq. jq is not present on a default Windows/Git Bash
# install, and when it is missing this line fails silently, COMMAND ends up empty, and the
# reminder below never fires, so the hook looks installed and does nothing. This reminder only
# has to spot "git commit" somewhere in the payload, which a raw substring check does without
# needing any parser at all.
INPUT=$(cat)
COMMAND="$INPUT"
# end of 1

# 2. SECTION: Commit detection and checklist
# Only trigger on git commit commands
if [[ "$COMMAND" == *"git commit"* ]]; then
  echo "PRE-COMMIT CHECK: Before committing, ensure you have:" >&2
  echo "  1. Logged any new user comments to COMMENTS.md" >&2
  echo "  2. Put new tasks on LIVE (TASK_REGISTRY.md) and moved finished ones to the top of TASK_REGISTRY_COMPLETED.md" >&2
  echo "  3. Updated SESSION_LOG.md if this is a significant milestone" >&2
  echo "  4. Logged any decisions to DECISIONS.md, each with a Category: field" >&2
  echo "  5. Logged any gotcha or >15min debug to LEARNED_BEHAVIOUR.md" >&2
  echo "  6. Updated FEATURE_LIST.json if any feature status changed" >&2
  echo "  7. Recorded any credentials or fixtures created this session, in full" >&2
  echo "  8. Archived any approved plans to plans/ directory" >&2
  echo "  (This is a reminder. The commit will proceed either way.)" >&2
fi
# end of 2

# Always allow, because this is a reminder and not a blocker
exit 0
