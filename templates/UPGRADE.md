# Upgrading a project to the current Context Guard

Two things changed in Context Guard on 03/11/26, and an existing project gets both in one upgrade:

1. **One folder.** Every Context Guard file lives in a single `context-guard/` folder in the project root, with `archive/`, `plans/`, `audits/`, `backups/` and `templates/` inside it. Only `CLAUDE.md` stays in the project root, because that is where the agent reads it automatically. Nothing is left loose in the root, and archive pages never sit beside the live files.
2. **Two lists.** The to do list (`TO_DO_LIST.md`: everything not yet done, tasks and decisions waiting on the user) and the done list (`DONE_LIST.md`: everything finished, newest at the top, with whether and how it was tested and its proof). They replace the old single task list, `TASK_REGISTRY.md`, with its table per session and emoji statuses. The rules are in `templates/CLAUDE.md`, sections `## FILE LAYOUT`, `## WHEN CONTEXT GUARD FILES ARE WRITTEN` and `## THE TO DO LIST AND THE DONE LIST`.

Use this once per project, and only after the user has said to upgrade. Until then the commands keep working on the project as it is, and `/start` asks the question again at each session.

**Why the old task list cannot just be reformatted.** Tasks were often finished and recorded somewhere else (a later row, the session log, a results file) without their own row being updated, and rotation carried backlog sections forward that no session read. Any row may be wrong, whether it says done or pending. Every row is checked against the evidence; none is assumed.

## Part 1: Move into one folder

Do this first, so everything after it happens in the new place. Use `git mv` for tracked files so their history follows them, and plain `mv` for untracked ones. Record every move as you go.

1. **Count first:** list every Context Guard file and folder the project has now (the safeguard files, every `*_page*.md` archive page, `plans/`, `audits/`, `compaction-backups/`, `templates/`), wherever they are: loose in the project root, or in an older folder such as `Context Guard/` or `context-guard/`. Write the count down.
2. **Create** `context-guard/` with `archive/`, `plans/`, `audits/` and `backups/` inside it, if they do not exist.
3. **Move the live files** into `context-guard/`: `RESUME_STATE.md`, `SESSION_LOG.md`, `TASK_REGISTRY.md`, `DECISIONS.md`, `LEARNED_BEHAVIOUR.md`, `COMMENTS.md`, `FEATURE_LIST.json`, and any `RESUME_STATE_*.md` siblings and `CONTEXT_GUARD_UPDATE.md`.
4. **Move every archive page** (`SESSION_LOG_page*.md`, `TASK_REGISTRY_page*.md`, `DECISIONS_page*.md`, `LEARNED_BEHAVIOUR_page*.md`, `COMMENTS_page*.md`, and anything already in an `archive/` folder) into `context-guard/archive/`.
5. **Move the folders:** `plans/` to `context-guard/plans/`, `audits/` to `context-guard/audits/`, `compaction-backups/` to `context-guard/backups/`. If the project root holds a `templates/` folder with nothing but Context Guard templates, move it to `context-guard/templates/`; if the project has a `templates/` folder of its own, move only the Context Guard template files, by name.
6. **Fix the pointers:** every `→ DECISIONS_page3.md` style line in the archive indexes of `DECISIONS.md` and `LEARNED_BEHAVIOUR.md` becomes `→ archive/DECISIONS_page3.md`, and every `📁 Archives:` line names `archive/...`. Update any path in `CLAUDE.md`, `CCG_LOCATION.md`, hooks or docs that pointed at the old places. Delete `CCG_LOCATION.md` only if it does nothing except point at the folder, since `context-guard/` is now found without it.
7. **CLAUDE.md** stays in the project root. If it lived inside an older Context Guard folder, ask the user before moving it to the root, and never overwrite a root `CLAUDE.md` the project already has: merge into it.
8. **Count again:** every file from step 1 must be in its new place. Nothing deleted, nothing left behind.

## Part 2: Build the to do list and the done list

1. **Keep the old file whole, and out of the way.** Move the old `TASK_REGISTRY.md` (`git mv`) to the next free `archive/TASK_REGISTRY_page<N>.md` and add one line at its top saying it is the list as it stood before the move to the to do list and the done list, and the date. Nothing named `TASK_REGISTRY.md` stays among the live files, so no agent can keep writing to it.

2. **Gather the rows to check:** every row in the old main file, and every row in the archive pages that is not a plain done (pending, in progress, blocked, re-queued, deferred, kept in a backlog). Done rows already in old archive pages stay there as history; COMPLETED's header names those pages so a search for an earlier proof still finds them.

3. **Check each row against the evidence:** the files and commits it names, later rows that mention its ID or its files, the session log, results and test records. Search by file name and commit as well as by ID, because a fix is often recorded in a batch row that never names the task. Where a row asks for one thing to happen after another, check the order actually held. Give each row one verdict:
   - **DONE:** real evidence that what the row asked for was finished. Its proof is that evidence; its tested status is TESTED BY USER, TESTED INDEPENDENTLY, BUILDER ONLY or NOT TESTED, with where the record is. A row with no test record is NOT TESTED, with "no test record found".
   - **SUPERSEDED:** a later task replaced it. Name that task's ID.
   - **DROPPED:** only where the user's own words drop it. Quote them.
   - **OPEN:** no finishing record. It goes on the to do list with one sentence of what is left.

   For a long list, check in batches and write each batch's verdicts to a file as you go, so a rate limit or a crash loses nothing.

4. **Build the two lists from the templates** (`templates/TO_DO_LIST.md`, `templates/DONE_LIST.md`). OPEN rows go into the to do list's `## TO DO` table, each with a status of PENDING, IN PROGRESS or WAITING ON USER, and Updated set to this session and date. Every DONE, SUPERSEDED and DROPPED row goes into the done list's `## DONE` table, newest first.

5. **Fold in any separate tested or proven list** the project kept. Each of its entries becomes the Tested value and Proof of the matching done list row (or a done list row of its own if it matched no task). The old file stays where it is, with a line at its top pointing at the done list.

6. **Merge the handovers.** Open tasks and questions for the user found in RESUME_STATE.md or any current handover go onto the to do list, so there is one list of everything still to do. The handover text itself stays.

## Part 3: Bring the instructions into line

1. **CLAUDE.md:** replace its description of the old task registry (the column and emoji line) and of the old file locations with the new ones, and copy in the `## FILE LAYOUT`, `## WHEN CONTEXT GUARD FILES ARE WRITTEN` and `## THE TO DO LIST AND THE DONE LIST` sections from `templates/CLAUDE.md`. Remove any rule that tells agents to update Context Guard files automatically between saves (an auto-checkpoint or save-frequency section): those files are written only by `/save` and `/end` now, and only the to do list and the done list are kept current as work happens. If the project's CLAUDE.md has its own deliberate rules on this, ask the user which wins.
2. **Hooks:** if the project's `.claude/hooks/` files carry local edits only to find a Context Guard folder, the current Context Guard hooks now do that themselves; replace them with the current ones. Keep any other deliberate local change, and ask if unsure.
3. **Templates:** the project's `context-guard/templates/` holds the current Context Guard templates.

## Part 4: Check and report

1. **Run the checker** until it reports both lists clean:
   `node .claude/tools/registry_check.js --root context-guard --session S<N>`
2. **Check the layout:** nothing of Context Guard's is left in the project root except `CLAUDE.md`, and no archive page sits beside the live files.
3. **Show the user** the file count before and after, the task counts (open, done, superseded, dropped), the checker's line, and every row you could not decide, by AskUserQuestion, before committing. Their answers are final.
4. **Log the upgrade in SESSION_LOG.md**, delete `CONTEXT_GUARD_UPDATE.md` once everything it asked for is done, and commit everything by explicit path, never `git add -A`.
