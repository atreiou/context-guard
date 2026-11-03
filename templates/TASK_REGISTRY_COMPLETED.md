# TASK_REGISTRY_COMPLETED.md: {PROJECT_NAME} COMPLETED Task List
# The second of the project's TWO task lists: every finished task, NEWEST AT THE TOP. It is also the tested list.
# Unfinished tasks live in TASK_REGISTRY.md (LIVE). /start does not read this file; /save and /end check it.
#
# Columns: | ID | Task | Outcome | Tested | Proof |
#   Outcome  starts with one of:
#              DONE dd/mm/yy
#              SUPERSEDED dd/mm/yy by <ID of the task that replaced it>
#              DROPPED dd/mm/yy, only with the user's own words in quotation marks
#   Tested   on every DONE row, starts with one of the four words below, then where the record of the test is:
#              TESTED BY USER        the user checked it themselves
#              TESTED INDEPENDENTLY  checked by something other than its builder (another agent, a test suite)
#              BUILDER ONLY          only the agent that built it says it works
#              NOT TESTED
#            SUPERSEDED and DROPPED rows may write n/a.
#   Proof    a path or a commit, then the completion record:
#              Files: path1, path2 | Approach: one sentence naming the pattern or library | Governed by: D-xx
#
# A finished task moves here from LIVE in the same turn it finishes, and is added at the TOP.
# Something already proved here is never retested unless its files have changed since.
#
# ROTATION: when this file holds more than 500 rows, /end moves the oldest rows beyond 500, verbatim and in order,
# to TASK_REGISTRY_COMPLETED_page1.md, page2 and so on. Nothing is ever deleted.
#
# 📁 Archives: (none yet)

---

## COMPLETED TASKS

| ID | Task | Outcome | Tested | Proof |
|----|------|---------|--------|-------|
