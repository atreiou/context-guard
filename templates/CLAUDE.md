# CLAUDE.md: {PROJECT_NAME} Project Instructions
# The coding agent reads this file automatically at every session start. Claude Code reads CLAUDE.md
# from the project root; for another agent, name this file in its own instruction file (AGENTS.md for Codex).
# Last updated: {DATE}

## FILE LAYOUT: ONE CONTEXT GUARD FOLDER

Every Context Guard file lives in one folder in the project root, never loose in the root:

```
CLAUDE.md                        this file (the one Context Guard file in the root, so the agent reads it automatically)
context-guard/
  RESUME_STATE.md                in-flight state written by /save
  SESSION_LOG.md                 session history
  TO_DO_LIST.md                  the to do list: everything not yet done, decisions waiting on the user included
  DONE_LIST.md                   the done list: everything finished, with its tested status and proof
  DECISIONS.md                   decisions register
  LEARNED_BEHAVIOUR.md           tactical knowledge
  COMMENTS.md                    the user's words, verbatim
  FEATURE_LIST.json              QA tracker
  archive/                       every archive page (SESSION_LOG_page1.md, DECISIONS_page2.md and so on)
  plans/                         archived plans
  audits/                        saved /audit reports
  backups/                       copies made automatically before context compaction
  templates/                     the templates this project was set up from
```

Live files sit in `context-guard/`, archived ones in `context-guard/archive/`, and anything Context Guard keeps as separate files gets a folder of its own inside `context-guard/`. Never create a Context Guard file in the project root, and never put an archive page beside the live files. All paths below are inside `context-guard/` unless they say otherwise.

## CRITICAL: READ THESE FILES FIRST BEFORE ANY WORK

0. **`RESUME_STATE.md`**: In-flight state from the last /save. Read FIRST. If `Clean save: false`, resume from the In-flight section before anything else.
1. **`SESSION_LOG.md`**: What happened in every previous session. Historical narrative.
2. **`TO_DO_LIST.md`** (the to do list) and **`DONE_LIST.md`** (the done list): the project's two lists. The to do list holds every task not yet finished and is read in full at every `/start`; the done list holds every finished task, newest at the top, with its tested status and proof. CHECK the to do list before creating a task. The rules are in `## THE TO DO LIST AND THE DONE LIST` below.
3. **`DECISIONS.md`**: Every architectural decision made. NEVER contradict these without explicit approval. Each entry has a `Category:` field (forever-active, active-constraint, feature-specific, superseded).
4. **`LEARNED_BEHAVIOUR.md`** holds tactical knowledge: platform quirks, version gotchas, non-obvious workarounds. Prevents re-discovering the same bugs every session.
5. **`FEATURE_LIST.json`**: QA tracker. `passes: true` means manually verified end-to-end, NOT just "task complete".
6. **`COMMENTS.md`**: User's verbatim comments from every session. SACRED. Never lose these.
7. **`plans/`**: Archived plans from every session. `/start` does not read them; RESUME_STATE names the plan and section the next task needs, and `/audit` checks every plan against the two lists.
8. **`audits/`**: Saved audit reports with timestamps. Read the latest to check project health.

## Custom Context Files

Additional files `/start` should read at session start, declared per project. Add one line per file:

- (none)

Format: `- path/to/file.md: one-line purpose`
Example: `- API_CONTRACTS.md: external API schemas the integration depends on`

**Security note:** Credentials and secrets should use your platform's secret manager. Plain-text credential files in git are an anti-pattern, so do not declare them here.

## WHEN CONTEXT GUARD FILES ARE WRITTEN

**Only when the user asks, with `/save` or `/end`.** The session log, comments, decisions, learned behaviour, feature list and resume state are written by `/save` (a save point mid-session) and `/end` (everything in full). Never write them on your own initiative between saves: saving constantly spends usage for nothing, which is exactly why `/save` exists. `/save` and `/end` go back through the conversation, so nothing said or decided between saves is lost.

**The one exception is the two lists.** They are updated the moment anything on them changes: a new task goes on the to do list when it is created, and a finished task moves from the to do list to the top of the done list in the same turn it finishes. That touches nothing else.

## LEDGER ROTATION: THE 5-SESSION RULE

Every ledger's main file holds ONLY the last 5 sessions' content. Everything older is moved, verbatim, into numbered pages in `archive/` (`archive/SESSION_LOG_page1.md`, `archive/DECISIONS_page2.md`, and so on). Archive pages are append-only and are never deleted. The two lists are the exception, set out below.

`/end` runs the rotation every session. `/save` does not; it only rotates a file that has clearly overgrown the window, because re-running the whole pass on every save costs context and ages nothing.

**DECISIONS and LEARNED_BEHAVIOUR keep a one-line index of everything they have archived.** When an entry is moved out, a line goes into the main file's `## Index of archived decisions` / `## Index of archived LBs` section giving its ID, title, category, and which page holds it. This is what makes the rotation safe: **archiving a decision does not revoke it.** A `forever-active` or `active-constraint` decision governs from the archive exactly as it did from the main file, and the index is how a future session finds it. Without the index, the only way to keep a binding rule discoverable was to never archive it, and the file grew until it swallowed the context window at every `/start`.

**The to do list never rotates.** A task stays on the to do list until it finishes, however old it is, and no row is ever carried forward or archived without being checked. The done list rotates only when it passes 500 rows, oldest rows first, into `archive/DONE_LIST_page<N>.md`.

**`/start` does not read archive pages.** It reads the main files and the indexes. If an index line touches the work about to be done, the agent opens that one archive entry at that point, not at session start.

## DROPPING TASKS IS ABSOLUTELY UNACCEPTABLE

Dropping tasks will result in the **complete failure of this project**. Every task you create MUST go on the to do list (`TO_DO_LIST.md`) the moment it is created. If a task cannot be completed in this session, it MUST stay on the to do list as `PENDING`. If a background agent fails (rate limit, timeout, etc.), the tasks it was supposed to do MUST be put back on the to do list as `PENDING`.

## THE TO DO LIST AND THE DONE LIST

The project keeps exactly two lists, and no task is kept anywhere else: no per-session task blocks, no carried or backlog sections, no separate tested list.

- **The to do list, `TO_DO_LIST.md`:** everything not yet done, in one table under `## TO DO`: tasks, and the decisions waiting on the user (a decision is not really a task, which is why the list is called the to do list). Columns `| ID | Task | Status | Updated | Notes |`. Status starts with exactly one of `PENDING`, `IN PROGRESS` or `WAITING ON USER`, followed by one plain sentence saying what is left. Updated is the session and date the row was last checked against the evidence, for example `S12 03/11/26`. IDs use `S{session}-{seq}`.
- **The done list, `DONE_LIST.md`:** every finished task, newest at the top, in one table under `## DONE`. Columns `| ID | Task | Outcome | Tested | Proof |`. Outcome starts `DONE dd/mm/yy`, `SUPERSEDED dd/mm/yy by <id>` or `DROPPED dd/mm/yy`, and DROPPED only with the user's own words in quotation marks. Tested starts `TESTED BY USER`, `TESTED INDEPENDENTLY`, `BUILDER ONLY` or `NOT TESTED`, followed by where the record is. Proof names a path or a commit. The done list is also the tested list: something already proved there is never retested unless its files have changed since.

The rules:

1. **Same turn, own row.** The moment a task finishes, its row is taken off the to do list and added to the TOP of the done list, in that same turn. Never saved up for `/end`, never recorded somewhere else instead. "Handed over" is not a status.
2. **`/start` reads only the to do list, all of it**, and tells the user the checker's line: `To do: N (W waiting on user)`.
3. **`/save` and `/end` confirm both lists are correct** with the checker, and fix or report every flagged row before finishing:
   `node .claude/tools/registry_check.js --root context-guard --session S<N>`
4. **A handover's tasks are merged into the to do list at once**, its questions for the user included, so there is only ever one list of pending tasks. Everything else a handover explains (state, context, how things work) is not a task: the handover itself still stands and is read as a handover.
5. **Nothing is ever deleted.** the to do list never rotates and never carries a row unchecked. The done list rotates its oldest rows into `archive/` once it passes 500 rows.

The checker flags: a to do list status not starting with one of the three words; a to do list row not re-checked for two sessions; "handed"; a task row outside the two tables; a done list Outcome or Tested value not in the fixed words; DONE without proof; DROPPED without the user's quoted words; the done list not newest first; the same ID on both lists.

## HANDOVERS MUST BE COMPLETE

A handover is anything one session writes so the next can carry on: RESUME_STATE.md at `/save`, the session's entry in SESSION_LOG.md at `/end`, a handover file written for another session or agent, and a `CONTEXT_GUARD_UPDATE.md` note. Each new session carrying on seamlessly from the last is the main thing Context Guard exists for, and a thin handover is where most mistakes start: the next agent guesses, repeats work, or undoes a decision nobody told it about.

Every handover states all eight of these, in full:

1. **Tasks:** every task ID touched, what each one is, exactly what is done, what is not, and where it stopped.
2. **Files:** every file changed, and whether each one is committed, pushed, or still uncommitted, with the branch.
3. **Next action:** the exact next step: the task ID, the file and section, the command, and the plan file and section if a plan governs it.
4. **The user's words:** what the user wants next, quoted.
5. **Decisions:** what was decided and why, with its D-number where it has one.
6. **Questions:** everything waiting on the user, each one also on the to do list as `WAITING ON USER`.
7. **Traps:** errors hit, what was tried and failed, and what NOT to do.
8. **Checks:** how to check the work is right, and what has and has not been verified.

Write it for a reader with no memory of this session. Name things exactly (a task ID with what it is, full paths, commit hashes, the user's own words), and never trade detail for brevity. A part with nothing in it says so in a few words ("No decisions this session"), so the reader knows it was checked, not forgotten.

**The cold-read test.** Before a handover counts as written, read it back as an agent that has never seen this session. Could you carry on from it alone, without asking the user anything or rediscovering something this session already found? If not, add what is missing. A handover that fails the test is not finished.

**`/start` checks the handover** against git and the two lists, and reports every gap or mismatch before any work begins.

## PRESERVE USER COMMENTS: MANDATORY

Every comment the user makes in conversation MUST reach `COMMENTS.md` verbatim, with timestamp and session ID: directions, feedback, decisions, preferences, corrections, and anything else they say. `/save` and `/end` write them from the conversation. Failure to preserve comments is as dangerous to the project as deleting core files. Comments can be archived once actioned (turned into decisions, tasks, or file changes).

## USER AUDITS YOUR WORK

The user can call `/audit` at ANY moment to verify your work. Every task must be traceable back to a plan, a decision, or a user comment. Unexplained work WILL be flagged. Be prepared for this at all times.

## INCREMENTAL COMMIT PROTOCOL

When a block of work is completed and the user has approved it, commit the work immediately. Do not wait for /end. Approval includes any positive acknowledgement: "looks good", "nice", "cool, let's move on", "yes", accepting the output and giving a new instruction, etc. Explicit "please commit" is NOT required. The commit carries the approved work and the task list rows that changed with it; the other Context Guard files still wait for `/save` or `/end`.

Before committing, verify:
1. The changes match what was discussed and approved in the conversation
2. No half-finished or unapproved changes are included in the staged files
3. The commit message accurately describes the approved work

Tag the commit if it completes a distinct task. This applies even if more work follows in the same session.

If a session ends without /end (context overflow, crash, rate limit):
- The incremental commits preserve all approved work
- The next /start will detect any remaining uncommitted changes

If a session has multiple user-approved task completions but zero commits, something is wrong.

## AUTOMATIC PRE-COMPACTION BACKUP

A PreCompact hook backs up all eight Context Guard files (including LEARNED_BEHAVIOUR.md and RESUME_STATE.md) before the agent's conversation is compressed, into `backups/YYYY-MM-DD_HHMMSS/`. It checks every copy against its original and reports success only when all of them match. It copies files and costs no usage. The hook runs automatically; no action is needed from you or the user.

## RATE LIMIT AWARENESS

Rate limits pause the session but do NOT trigger compaction; context stays intact while waiting. The danger is when a rate limit hits **mid-operation** (e.g. halfway through a multi-file sync or large refactor). When the session resumes, you may lose track of which steps were completed. To protect against this:

1. **Keep the two lists current as you go.** They are the one Context Guard record written as work happens, so a rate limit between step 3 and step 7 of a plan does not lose the record of steps 1 to 3.
2. **After resuming from a rate limit**, re-read the to do list and RESUME_STATE.md (as of the last /save) to confirm where you left off.

## CONTEXT OVERFLOW PROTOCOL

If the conversation is getting very long, tell the user, so they can run `/save` when they choose. Do not save on your own initiative. The two lists are already current, and `/save` writes everything else from the conversation.

## Project Overview

**Project:** {PROJECT_NAME}
**Description:** {PROJECT_DESCRIPTION}

## Git Conventions

- Every commit MUST be tagged with `S{session}-{sequence}_{short-description}`
  - Example: `S5-001_install-deps`, `S5-002_add-auth`
  - Session number from SESSION_LOG.md, sequence starts at 001 per session
  - Tag with: `git tag "S{session}-{sequence}_{short-description}" HEAD`
- **Careful push, never blind.** Confirm the current branch and its upstream; `git fetch` and look at ahead and behind before changing anything; push only this branch, and only the tags you made, by name (`git push origin <tag>`), never `--tags`; replay your commits only onto this branch's own upstream, never onto `main` from another branch; never force-push; never switch branches or touch another agent's work. If git refuses or a conflict appears, stop and ask the user. The full steps are in `/start` Step 2.7.
- All amendment comments use format: `<!-- AMENDMENT vX.Y (YYYY-MM-DD): description -->`

## Version Control

- **Mode:** remote
- **Branch:** main

Commands read this section to determine git behaviour:
- `remote`: commit + push + tags (default)
- `local`: commit + tags only, no push
- `none`: skip all git steps in /start, /save, /end, /audit

## Plan Archiving

After every approved plan is executed, archive it:
1. Copy from `~/.claude/plans/` (where Claude Code keeps plans) to `plans/S{session}-{seq}_{description}.md`
2. Plans are cross-referenced by `/audit` against the two lists
3. **`~/.claude/plans/` is shared across all projects.** Only archive plans whose content references this project by name or file paths. Skip plans belonging to other projects.

## Sync Discipline

When syncing, migrating, relocating, or cleaning up files in any `.claude/` directory, whether Context Guard's files or a project's own:

- **NEVER delete a directory wholesale.** No `rm -rf .claude/skills/`, no `rm -rf .claude/commands/`, no `rm -rf .claude/hooks/`, no matter what.
- **Delete only the specific files you intend to remove, by name.** If a Context Guard migration retires five named commands, delete those five files, not the folder they lived in.
- **If unsure whether a file is yours to touch, leave it alone and surface it to the user.** It's always cheaper to ask than to wipe someone's work.
- **`.claude/` is a shared namespace.** Projects can have their own hooks, skills, commands, and settings sitting right next to Context Guard's. They are not Context Guard's to remove.
- This applies to every agent action, not just Context Guard sync. The same discipline applies to any cleanup or refactor pass that touches another project's files.


## Description Ruleset

Sidecar `.index.md` descriptions (one row per numbered section in a code file) follow this ruleset:

- Active voice, present tense
- States the **job**, not the implementation. Good: `validates email format`. Bad: `uses regex on email`.
- Function-name prefix where applicable: `parseInput(): validates form data and trims whitespace`
- Soft limit ~80 characters, hard limit 120
- One line per entry, no trailing punctuation
- British English spelling

The ruleset is universal across every code file in every project. Hand-written descriptions that follow these rules are sacred. Agents MUST NOT rewrite them merely because they don't match the auto-generated style.

## Index Maintenance

A code file and its `.index.md` sidecar are a **single artefact split into two formats**: the source file holds the code with numbered markers, the sidecar holds the human-readable descriptions and last-edit dates. Either format on its own is incomplete.

**It is not possible to edit one without editing the other.** Editing a numbered section without updating its sidecar entry is a project failure. Adding a new numbered section without adding its sidecar entry is a project failure. Deleting a numbered section without deleting its sidecar entry is a project failure.

After editing a numbered section in the source file, you MUST:

1. Update that entry's `Last edit` date in the sidecar to today (dd/mm/yy)
2. If the section's job changed, rewrite the description following the rules in `## Description Ruleset`
3. If you added new numbered sections, add their entries
4. If you deleted numbered sections, delete their entries

**Hand-written descriptions are sacred.** Do not rewrite a description merely because it doesn't match an auto-generated style. Only rewrite if the description is genuinely inaccurate.

This rule is universal across every project that uses Context Guard. The only exception is if the host project's own `CLAUDE.md` explicitly opts out (e.g. `## Index Maintenance: disabled, see project-specific reasons`).

## Date Convention

All dates written by Context Guard commands (`/start`, `/save`, `/end`, `/audit`, `/itemise`) use **dd/mm/yy** (UK format) going forward. Existing dates in Context Guard files written before this convention are left as-is. Do not retroactively rewrite them. The dd/mm/yy convention applies only to new entries.

## Itemisation Protocol

ITEMISATION: enabled

The Itemisation Protocol adds hierarchical section numbers to code blocks so every part of the codebase is referenceable by address (e.g. "check section 2.3.1"). This reduces the context an agent needs to load: instead of reading an entire file, you can point directly to the relevant block.

**To disable:** change `ITEMISATION: enabled` to `ITEMISATION: disabled` above. The `/itemise` command will halt before making any changes.

`/itemise` records the scope the user approves on an `ITEMISATION SCOPE:` line here, so later runs do not ask again.

### What Gets Numbered

Number logical **blocks** that serve as identifiable, referenceable units, not individual lines.

- **Sections** are top-level logical groups: `// 1. SECTION: Name` ... `// end of 1`
- **Functions and methods**: `// 1.1 functionName()` ... `// end of 1.1`
- **Significant conditionals** are if/else/switch with meaningful business logic: `// 1.1.1 Description`
- **Important loops** are for/while/foreach with non-trivial bodies: `// 1.1.2 Description`
- **Key configuration objects** are complex arrays/objects passed to important calls: `// 1.2.1 Description`
- **Notable parameters** within those, when the parameter itself calls a function or is complex: `// 1.2.1.1 Description`

### What Does NOT Get Numbered

- Individual variable declarations
- Single-line assignments
- Simple imports, requires, or use statements
- Closing braces and trivial boilerplate
- Anything already explained by its parent block's label
- Whole files that must not carry markers: dependencies, generated output, formats without comments (JSON), and files whose exact bytes are checked elsewhere, such as an applied database migration with a recorded checksum

### Comment Syntax by Language

| Language | Format |
|----------|--------|
| JS, TS, PHP, Java, C#, Go | `// 1.1 Description` |
| Python, Ruby, Shell, YAML | `# 1.1 Description` |
| HTML, XML, Vue templates | `<!-- 1.1 Description -->` |
| CSS, SCSS, Less | `/* 1.1 Description */` |
| SQL | `-- 1.1 Description` |

### Applying Itemisation to Existing Code

Run `/itemise` to apply the protocol to existing files. The command will:
1. Confirm the list of files before touching anything (once per project; the approved scope is remembered)
2. Create `{filename}.itemise-backup` copies
3. Add the numbering; a file that is already itemised keeps every existing number, and only new or too-coarse code gets new ones
4. Verify integrity (strips added comment-numbers, then diffs against the backup to confirm no code changed)
5. Delete backups on success; restore on failure

### Cross-References

When a section calls a function or method defined in another numbered section of the same file, the marker includes a `[calls: N.M]` tag:

```
// 3.2 handlePayment() [calls: 1.1, 2.3]
```

- Only track function/method calls, not shared variables or implicit dependencies
- Multiple calls are comma-separated: `[calls: 1.1, 2.3, 5.1]`
- Cross-references are scoped to the same file; cross-file dependencies are out of scope
- References are refreshed automatically when `/itemise` is re-run

### Reading Specific Sections

For itemised files over ~100 lines, prefer targeted section reads over loading the full file. The section markers are grep-friendly anchors that cannot go stale.

**To read a specific section (e.g. section 4.2):**

1. Grep for the start marker to get its line number
2. Grep for the end marker (`end of 4.2`) to get its line number
3. Read only the lines between them (with a line offset and limit)

**If no end marker exists** (short blocks skip them per the protocol), read 20 lines from the start marker and look for the next numbered marker to determine the boundary.

**Nested sections:** Reading a parent section (e.g. `4`) via its start/end markers includes all children (`4.1`, `4.2`, etc.). To read only the parent's preamble, read from the `4` marker to the `4.1` marker.

### Impact Advisories

When modifying a section, grep the file for `[calls: N.M]` references pointing to it. If other sections depend on the one being changed, flag this to the user:

- "Section 4.2 calls this function, so check if it needs updating too"
- "This feature is linked with section 3.1, so consider adding a task to update it"

This is advisory, not blocking. Mention it and move on. The agent may already be aware of the dependency; that's fine. The check costs nothing and occasionally prevents a missed update.
