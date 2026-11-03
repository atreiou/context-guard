# TASK_REGISTRY.md: {PROJECT_NAME} LIVE Task List
# One of the project's TWO task lists. This one holds every task that is NOT yet finished, and nothing else.
# Every finished task lives in TASK_REGISTRY_COMPLETED.md, newest at the top, with its tested status and proof.
# DROPPING A TASK IS A PROJECT FAILURE. CHECK THIS LIST BEFORE CREATING A TASK. DO NOT DUPLICATE.
#
# Columns: | ID | Task | Status | Updated | Notes |
#   ID       S{session}-{seq}, for example S1-001, S2-003
#   Status   starts with exactly one of PENDING, IN PROGRESS or WAITING ON USER, then one plain sentence of what is left
#   Updated  the session and date the row was last checked against the evidence, for example S12 03/11/26
#   Notes    may hold `Governed by: D-xx, D-yy` (decisions that constrain the task) and `Blocked on: <id>`
#
# The rules:
#   1. The moment a task finishes, its row comes off this list and goes to the TOP of TASK_REGISTRY_COMPLETED.md,
#      in that same turn. Never saved up for /end, never recorded somewhere else instead. "Handed over" is not a status.
#   2. No task lives anywhere else: no per-session task blocks, no carried or backlog sections, no separate tested list.
#   3. This list and COMPLETED are the only Context Guard files written as work happens; everything else waits for
#      /save or /end. /start reads ALL of this list. /save and /end run the checker and fix or report every flag.
#   4. A handover's open tasks, and its questions for the user, are merged into this list at once. The handover
#      itself still stands for everything else it explains.
#   5. This list never rotates, and no row is carried forward or archived without being checked.
#
# Lives in context-guard/, with every other Context Guard file.
# Checker: node .claude/tools/registry_check.js --root context-guard

---

## LIVE TASKS

| ID | Task | Status | Updated | Notes |
|----|------|--------|---------|-------|
