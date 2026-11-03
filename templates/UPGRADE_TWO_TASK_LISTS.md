# Upgrading a project to the two task lists (LIVE and COMPLETED)

Context Guard used to keep one `TASK_REGISTRY.md` with a table per session and emoji statuses. It now keeps two lists: **LIVE** (`TASK_REGISTRY.md`, every task not yet finished) and **COMPLETED** (`TASK_REGISTRY_COMPLETED.md`, every finished task, newest at the top, with its tested status and proof). The rules are in `templates/CLAUDE.md`, section `## TWO TASK LISTS`.

Use this once per existing project, and only after the user has said to build the lists. A project whose `TASK_REGISTRY_COMPLETED.md` does not exist yet is still on the old list; `/start` asks the user whether to build now or wait.

**Why the old list cannot just be reformatted.** Tasks were often finished and recorded somewhere else (a later row, the session log, a results file) without their own row being updated, and rotation carried backlog sections forward that no session read. Any row may be wrong, whether it says done or pending. Every row is checked against the evidence; none is assumed.

## Steps

1. **Keep the old file whole.** Before changing anything, copy `TASK_REGISTRY.md` verbatim to the next free `TASK_REGISTRY_page<N>.md`, with one line at its top saying it is the list as it stood before the move to two lists, and the date. Existing archive pages stay as they are.

2. **Gather the rows to check:** every row in the old main file, and every row in the archive pages that is not a plain done (pending, in progress, blocked, re-queued, deferred, kept in a backlog). Done rows already in old archive pages stay there as history; COMPLETED's header names those pages so a search for an earlier proof still finds them.

3. **Check each row against the evidence:** the files and commits it names, later rows that mention its ID or its files, the session log, results and test records. Search by file name and commit as well as by ID, because a fix is often recorded in a batch row that never names the task. Where a row asks for one thing to happen after another, check the order actually held. Give each row one verdict:
   - **DONE:** real evidence that what the row asked for was finished. Its proof is that evidence; its tested status is TESTED BY USER, TESTED INDEPENDENTLY, BUILDER ONLY or NOT TESTED, with where the record is. A row with no test record is NOT TESTED, with "no test record found".
   - **SUPERSEDED:** a later task replaced it. Name that task's ID.
   - **DROPPED:** only where the user's own words drop it. Quote them.
   - **OPEN:** no finishing record. It goes on LIVE with one sentence of what is left.

   For a long list, check in batches and write each batch's verdicts to a file as you go, so a rate limit or a crash loses nothing.

4. **Build the two lists from the templates.** OPEN rows go into LIVE's `## LIVE TASKS` table, each with a status of PENDING, IN PROGRESS or WAITING ON USER, and Updated set to this session and date. Every DONE, SUPERSEDED and DROPPED row goes into COMPLETED's `## COMPLETED TASKS` table, newest first.

5. **Fold in any separate tested or proven list** the project kept. Each of its entries becomes the Tested value and Proof of the matching COMPLETED row (or a COMPLETED row of its own if it matched no task). The old file stays where it is, with a line at its top pointing at COMPLETED.

6. **Merge the handovers.** Open tasks and questions for the user found in RESUME_STATE.md or any current handover go onto LIVE, so there is one list of pending tasks. The handover text itself stays.

7. **Bring the project's CLAUDE.md into line:** replace its description of the old task registry (the column and emoji line) with the two lists, and copy in the `## TWO TASK LISTS` section from `templates/CLAUDE.md`. Copy `templates/TASK_REGISTRY.md` and `templates/TASK_REGISTRY_COMPLETED.md` into the project's own `templates/` folder if it has one.

8. **Run the checker** until it reports both lists clean:
   `node .claude/tools/registry_check.js --root "<CCG_ROOT>" --session S<N>`

9. **Show the user** the counts (open, done, superseded, dropped), the checker's line, and every row you could not decide, by AskUserQuestion, before committing. Their answers are final.

10. **Remove the update note** from the top of RESUME_STATE.md or TASK_REGISTRY.md, log the move in SESSION_LOG.md, and commit the two lists, the archive page and CLAUDE.md by explicit path.
