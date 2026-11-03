#!/bin/bash
# Context Guard: Pre-commit reminder hook
# Before every git commit, reminds the agent that the two task lists must already be current.
# Only the task lists are written as work happens; every other Context Guard file waits for
# /save or /end, so this hook does not ask for them.
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

# 2. SECTION: Commit detection and reminder
# Only trigger on git commit commands
if [[ "$COMMAND" == *"git commit"* ]]; then
  echo "PRE-COMMIT CHECK: is every task that has finished already moved from LIVE (TASK_REGISTRY.md)" >&2
  echo "  to the top of COMPLETED (TASK_REGISTRY_COMPLETED.md), and is every new task on LIVE?" >&2
  echo "  The other Context Guard files wait for /save or /end. (A reminder only; the commit proceeds.)" >&2
fi
# end of 2

# Always allow, because this is a reminder and not a blocker
exit 0
