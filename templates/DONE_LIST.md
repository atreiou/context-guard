# DONE_LIST.md: {PROJECT_NAME}, THE DONE LIST (everything done, newest at the top)
# The second of the project's two lists: everything finished, NEWEST AT THE TOP. It is also the tested list.
# Everything not yet done lives in TO_DO_LIST.md (the to do list). /start does not read this file; /save and /end check it.
#
# Columns: | ID | Task | Outcome | Tested | Proof |
#   Outcome  starts with one of:
#              DONE dd/mm/yy
#              SUPERSEDED dd/mm/yy by <ID of the item that replaced it>
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
# A finished item moves here from the to do list in the same turn it finishes, and is added at the TOP.
# Something already proved here is never retested unless its files have changed since.
#
# ROTATION: when this file holds more than 500 rows, /end moves the oldest rows beyond 500, verbatim and in order,
# to archive/DONE_LIST_page1.md, page2 and so on. Nothing is ever deleted.
#
# 📁 Archives: (none yet)

---

## DONE

| ID | Task | Outcome | Tested | Proof |
|----|------|---------|--------|-------|
