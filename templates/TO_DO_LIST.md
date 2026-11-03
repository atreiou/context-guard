# TO_DO_LIST.md: {PROJECT_NAME}, THE TO DO LIST (everything not yet done)
# One of the project's two lists. This one holds everything NOT yet done: tasks, and decisions waiting on the user.
# Everything finished lives in DONE_LIST.md (the done list), newest at the top, with its tested status and proof.
# DROPPING AN ITEM IS A PROJECT FAILURE. CHECK THIS LIST BEFORE ADDING ONE. DO NOT DUPLICATE.
#
# Columns: | ID | Task | Status | Updated | Notes |
#   ID       S{session}-{seq}, for example S1-001, S2-003
#   Status   starts with exactly one of PENDING, IN PROGRESS or WAITING ON USER, then one plain sentence of what is left
#   Updated  the session and date the row was last checked against the evidence, for example S12 03/11/26
#   Notes    may hold `Governed by: D-xx, D-yy` (decisions that constrain the item) and `Blocked on: <id>`
#
# The rules:
#   1. The moment an item is finished, its row comes off this list and goes to the TOP of DONE_LIST.md,
#      in that same turn. Never saved up for /end, never recorded somewhere else instead. "Handed over" is not a status.
#   2. Nothing to do lives anywhere else: no per-session task blocks, no carried or backlog sections, no separate tested list.
#   3. This list and the done list are the only Context Guard files written as work happens; everything else waits for
#      /save or /end. /start reads ALL of this list. /save and /end run the checker and fix or report every flag.
#   4. A handover's open tasks, and its questions for the user, are merged into this list at once. The handover
#      itself still stands for everything else it explains.
#   5. This list never rotates, and no row is carried forward or archived without being checked.
#
# Lives in context-guard/, with every other Context Guard file.
# Checker: node .claude/tools/registry_check.js --root context-guard

---

## TO DO

| ID | Task | Status | Updated | Notes |
|----|------|--------|---------|-------|
