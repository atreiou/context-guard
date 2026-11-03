---
description: "Type /end to wrap up a session. Saves every Context Guard file in full, confirms both lists are correct, rotates anything older than 5 sessions into the archive folder, commits, and leaves a clean handoff."
allowed-tools: Read, Grep, Glob, Bash, Edit, Write
---

# Context Guard: Session End (/end)

The user wants to wrap up this session cleanly. Your job is to create a save point so the next session can pick up seamlessly via `/start`.

**CRITICAL: /end is a SAVE-ONLY operation.** Do not start new work, execute plans, or make code changes beyond updating safeguard files. If a plan was approved this session but not yet executed, put its tasks on the to do list (TO_DO_LIST.md) as PENDING and note it in the "Next session" field of the report. The next session will pick it up via /start.

**Date convention:** all dates written by this skill use **dd/mm/yy** (UK format). Do not retroactively rewrite older dates already in safeguard files; only new entries follow this rule.

## Step 0: Locate CCG Root

CCG_ROOT is the folder that holds the Context Guard files: in the current layout, the `context-guard/` folder in the project root (with `archive/`, `plans/`, `audits/`, `backups/` and `templates/` inside it). Find it in this order and stop at the first match:

0. **Pointer file:** `CCG_LOCATION.md` in the working directory names CCG_ROOT directly. Trust it.
1. **`./context-guard/`**, holding `TO_DO_LIST.md`.
2. **One level down**, when the working directory is a parent folder: `*/context-guard/TO_DO_LIST.md`. If several projects match, ask the user which one.
3. **An older layout**, until the project is upgraded: `find . -maxdepth 4 \( -name "TO_DO_LIST.md" -o -name "TASK_REGISTRY.md" \) -not -path "*/templates/*" -not -path "*/archive/*" -not -path "*backups*"`; CCG_ROOT is the folder holding the match.
4. **None found:** warn "No Context Guard files found. Run /start first." and stop.

**All Context Guard paths below are relative to CCG_ROOT.** Archive pages go in `archive/` and plans in `plans/`; on an older layout, keep them where that project already keeps them until it is upgraded. `CLAUDE.md` means the project's own, in the project root. Run git from the project root.

**/end saves everything in full.** Between saves only the two lists are written as work happens; everything else since the last `/save` is written now, from the conversation.

## Step 0.5: Completeness Check (never opt for brevity)

Before saving, verify nothing from this session is missing. Log anything missing BEFORE proceeding to Step 1.

- Every user comment from this session → COMMENTS.md, verbatim, timestamped.
- Every task worked on → its to do list row brought up to date, or, if it finished, moved to the top of the done list.
- Every decision made → DECISIONS.md, with its `Category:` field.
- Every non-obvious gotcha, workaround, or >15-minute debug → LEARNED_BEHAVIOUR.md.
- **Did this session create or delete any credentials, accounts, or test fixtures?** If so, the FULL details (usernames, passwords, IDs, which are real identities and which are fixtures) must be recorded in the project's designated record (see CLAUDE.md; commonly `docs/TEST_USERS.md`) **and** in the session log **before this session counts as cleanly saved**. Not summarised, not deferred. A save that omits them blocks the next session outright: it cannot log in, and the information has to be recreated from scratch.

Brevity is not a virtue here. Trimming a detail because it feels secondary is a decision to withhold information nobody authorised you to withhold.

## Step 1: Gather Session Context

Review what was done this session:
- What tasks were worked on?
- What files were created or modified?
- What decisions were made?
- What user comments were given?

## Step 2: Update Safeguard Files

Check and update ALL of these:

### RESUME_STATE.md
- This is a SAVE-ONLY wipe. Overwrite RESUME_STATE.md with the clean template:
  ```
  # RESUME_STATE.md
  # Overwritten by /save. Wiped by /end. Read first by /start.
  # This file holds ONLY current in-flight state, not history. History lives in SESSION_LOG.md.

  **Session:** S[N+1]
  **Last updated:** dd/mm/yy HH:MM
  **Clean save:** true

  ## In-flight
  (No work in flight. This file is in its clean state.)

  ## Next step
  (Nothing pending.)
  ```
- `Clean save: true` tells the next `/start` that the previous session ended cleanly, so no mid-flight recovery is needed. The next-session intent still lives in SESSION_LOG.md's "Next step" field.
- **The "Next step" section is the next session's only plan pointer, so make it precise.** `/start` no longer reads plan files, so whatever you write here is all the next agent gets. Name the exact task IDs, and if a plan governs the work, name the exact plan file *and the section within it* they should open. "Continue the migration" is useless. "Resume S12-004 at `plans/S11-002_auth-migration.md` §3 (session token rotation), where the schema change is done and the middleware is not" is a handoff.

### SESSION_LOG.md
- Add an entry for this session (or update the existing one)
- Include: what happened, commits made, tasks completed, tasks remaining
- **Next step:** Capture what the user wants done next, using their own words where possible. Not just a list of pending tasks, but the actual direction, priority, and intent. This is what the next session's /start will read to understand where to pick up.
- **Errors encountered:** If any significant errors, blockers, or unexpected issues were hit during the session, log what happened and how it was resolved. Skip this if nothing notable occurred, and don't force empty sections. This prevents future sessions from repeating the same mistakes.

### The two lists (TO_DO_LIST.md is the to do list, DONE_LIST.md is the done list)

**/end confirms both lists are correct.** Nothing is carried forward on trust.

- **New tasks** from this session go on the to do list: ID, Task, a Status starting `PENDING`, `IN PROGRESS` or `WAITING ON USER` followed by one sentence of what is left, Updated as `S<N> dd/mm/yy`, and in Notes `Governed by: D-xx, D-yy` for any decisions that constrain the work.
- **Tasks worked on:** bring their to do list Status and Updated up to date.
- **Finished tasks** should already have moved in the turn they finished. Any that has not moves now: delete its to do list row and add it at the TOP of the done list with Outcome (`DONE dd/mm/yy`, `SUPERSEDED dd/mm/yy by <id>`, or `DROPPED dd/mm/yy` with the user's own words quoted), Tested (`TESTED BY USER`, `TESTED INDEPENDENTLY`, `BUILDER ONLY` or `NOT TESTED`, then where the record is), and Proof (a path or a commit, then the completion record).

  Example Proof: `commit 3f2a9c1; Files: widgets/favourite.php, blocks/fav-block.js | Approach: ACF flexible content with REST cache | Governed by: D-055`
- **Handovers:** every open task and every question for the user that arrived in a handover this session is on the to do list. The handover itself stays as it is.
- **Ensure NO tasks are missing.** Cross-reference the to do list and the done list with what was actually done this session.
- **Run the checker:**
  `node .claude/tools/registry_check.js --root "<CCG_ROOT>" --session S<N>`
  Fix every row it flags. A row flagged "not re-checked" is checked against the evidence now: still open, update its Status and Updated; finished, move it to the done list. Run the checker again until it reports both lists clean. Any flag you genuinely cannot fix goes to the user in the Step 6 report, with the reason.
- **A project still on the old single list** (no `TO_DO_LIST.md`, only the old `TASK_REGISTRY.md`): update the old rows in place, do NOT rotate or archive any of them, and say in the Step 6 report that the two-list build is still waiting on the user.

### COMMENTS.md
- Verify all user comments from this session are logged verbatim
- If any are missing, add them now with timestamps

### DECISIONS.md
- If any architectural decisions were made this session, log them
- **Mandatory Category field** on every new entry: `forever-active`, `active-constraint`, `feature-specific`, or `superseded`. Default to `active-constraint` if uncertain.
- If a new decision supersedes an earlier one, mark the old `Category: superseded` with a pointer to the new D-number.

### LEARNED_BEHAVIOUR.md
- Log any non-obvious workaround, platform quirk, version-specific gotcha, or ">15 minutes debugging this" discovery from this session.
- Format:
  ```
  ## LB-NNN: [Short title] (Session N, dd/mm/yy)
  **Context:** Where this surfaces (platform, plugin, version)
  **Gotcha:** What fails and how
  **Workaround:** What actually works
  **Why:** Root cause if known
  **Related:** Tasks/decisions (optional)
  ```
- Do NOT log ordinary coding knowledge; only things a fresh agent would re-discover the hard way.

### FEATURE_LIST.json
- **Semantics:** FEATURE_LIST is a QA tracker, NOT a task-completion mirror. Only flip `passes: true` when the user has **manually verified** the feature works end-to-end. Task completion is tracked in the two lists.
- If the user reports a feature broken, flip `passes: false` with a `notes` description of the failing case.

## Step 2.5: Rotate Safeguard Files (Pagination)

**Always run this step.** You have full session context right now, so use it to make smart archival decisions. Archive anything older than 5 sessions or fully actioned, regardless of file size. Don't wait for files to get large; keep them lean proactively.

### SESSION_LOG.md
1. Count `## Session` headers. Keep the **last 5 sessions** in the main file.
2. Everything above the 5th-from-last `## Session` header → move to archive.
3. Determine the next page number: check for existing `archive/SESSION_LOG_page*.md` files. New page = highest existing + 1 (or 1 if none exist).
4. Create `archive/SESSION_LOG_pageN.md` (create `archive/` if it is missing) with header:
   ```
   # SESSION_LOG: Archive Page N (Sessions X to Y)
   # Current sessions: see SESSION_LOG.md
   ---
   [archived content]
   ```
5. Trim `SESSION_LOG.md`: keep the file header (lines before the first `## Session`) + the last 5 sessions.
6. Add/update an archive reference line after the file header: `# 📁 Archives: archive/SESSION_LOG_page1.md, archive/SESSION_LOG_page2.md, ...`
7. If 5 or fewer sessions exist, there is nothing to archive. Skip.

### TO_DO_LIST.md (the to do list): never rotates

A task stays on the to do list until it finishes, however old it is. Nothing on the to do list is archived, carried into a backlog section, or trimmed. Rotation of the old single list is exactly what once hid hundreds of open rows in sections no session read.

### DONE_LIST.md
1. Rotate only when the main file holds more than 500 rows. Otherwise skip.
2. Move the oldest rows beyond 500 (the bottom of the table), verbatim and in order, to the next `archive/DONE_LIST_pageN.md`, under the same `## DONE` header row.
3. Add/update the archive reference line in the main file's header, so a search for an earlier proof still finds the page.

### DECISIONS.md

Decisions rotate on the same 5-session window as everything else, but with one extra step that makes it safe: **the main file keeps a one-line index of every decision that has been archived.**

1. Move decisions older than the last 5 sessions into `archive/DECISIONS_pageN.md`, full text intact.
2. For each one moved, add a line to the main file's `## Index of archived decisions` section:
   `D-042: Sigil images are WebP-only [active-constraint] → archive/DECISIONS_page3.md`
   ID, title, category, and which page holds it. Nothing more: the index has to stay cheap to read.
3. If a decision has no `Category:` field, treat it as `active-constraint` (safe default) and flag it for classification in your end report.
4. Mark `superseded` decisions as such (with a pointer to the D-number that replaced them) before archiving. They still archive, because a superseded decision explains why the current one exists.
5. Add/update the archive reference line.

**Archiving does not revoke a decision.** `forever-active` and `active-constraint` decisions govern from the archive exactly as they did from the main file, and the index is how future sessions find them. This is the whole reason the index exists: without it, the only way to keep a binding rule discoverable was to never archive it, and DECISIONS.md grew without limit until it swallowed the context window at every `/start`.

### LEARNED_BEHAVIOUR.md

Same mechanism as decisions.

1. Move entries older than the last 5 sessions into `archive/LEARNED_BEHAVIOUR_pageN.md`, full text intact.
2. For each one moved, add a line to the main file's `## Index of archived LBs` section:
   `LB-017: WPFC cache clear needs a fresh nonce → archive/LEARNED_BEHAVIOUR_page2.md`
3. An entry whose underlying platform or library has been removed, or upgraded past the bug, can be marked `resolved` in the index, so it stays findable but no longer needs reading.
4. Add/update the archive reference line.

An archived learned behaviour is still true. The index line is what stops a future session re-discovering it the hard way.

### COMMENTS.md
1. Review each comment using your session context. Identify:
   - **Actioned comments**: turned into decisions, tasks, or file changes
   - **Curiosity questions**: exploratory/informational, not project directives
2. Move both categories → `archive/COMMENTS_pageN.md`.
3. Keep all unactioned project directives in the main file.
4. Add/update archive reference line.

**FEATURE_LIST.json**: skip, stays compact.

## Step 2.8: Verify Update Completion

Before proceeding to git, confirm every safeguard file was addressed. Output this checklist:

**Update verification:**
- RESUME_STATE.md: wiped to clean state (Clean save: true)
- SESSION_LOG.md: [updated / already current, with the reason]
- The two lists: [the checker's line, which must say both lists clean; N added to the to do list, M moved to the done list, K re-checked / no task changes, with the reason]
- COMMENTS.md: [N comments logged / no new comments this session]
- DECISIONS.md: [N decisions logged (all have Category field) / no new decisions, checked: no architecture choices, algorithm choices, UI patterns, data model changes, naming conventions, or approach reversals this session]
- LEARNED_BEHAVIOUR.md: [N entries logged / no new tactical knowledge, checked: no gotchas, workarounds, or >15min debugs this session]
- FEATURE_LIST.json: [N features verified / no QA updates, checked: user did not verify or report broken any features this session]

**Decision trigger check:** Were ANY of these made this session?
  Architecture choices, algorithm/approach selections, UI/UX pattern decisions,
  data model changes, naming conventions, technology selections, approach reversals,
  workflow changes, configuration decisions.
  If yes and DECISIONS.md wasn't updated → go back and update it now. Every new decision MUST have a `Category:` field.

**Learned behaviour trigger check:** Did the session surface any non-obvious workaround, platform quirk, version-specific gotcha, or ">15 minutes debugging this" discovery?
  If yes and LEARNED_BEHAVIOUR.md wasn't updated → update it now.

**Feature trigger check:** Did the user **manually verify** any feature working end-to-end this session, or report one broken? Task completion does NOT count; only human verification does.
  If yes and FEATURE_LIST.json wasn't updated → go back and update it now.

**List check:** Did the checker report both lists clean? If not → go back to Step 2 and fix the flagged rows. Only a flag that genuinely cannot be fixed now may remain, and it goes in the Step 6 report with the reason.

If any file shows 0 changes, the reason must be specific (not "no changes needed").
"No changes needed" without explanation is not acceptable. State what you checked.

## Step 3: Archive Plans

- Check `~/.claude/plans/` for plans belonging to this project
- **`~/.claude/plans/` (where Claude Code keeps plans) is SHARED across all projects.** Plans from other projects will be in this folder. Do not touch them. To identify which plans belong to this project:
  - For each `.md` file (excluding `-agent-` files which are sub-agent plans):
    - Read the first ~500 characters
    - If the content contains the current project name (from CLAUDE.md), OR contains file paths matching this project's directory structure, it belongs to this project. Archive it.
    - If the content clearly references a different project name, skip it.
    - If ambiguous (no project name found), skip it. Do not archive plans you can't confidently attribute.
- Copy matched plans to `plans/S{session}-{seq}_{description}.md`
- **DO NOT EXECUTE archived plans.** /end is a save point, not an execution trigger. If a plan was approved but not yet implemented, put its tasks on the to do list as PENDING and record it in SESSION_LOG.md's "Next step" field so /start picks it up.

**Internal verification:** Check the **5 most recently modified** `.md` files in `~/.claude/plans/`. Read each file's first ~500 characters, match against the project name, and archive any that belong to this project. Do not output the verification details. Just report the result: either "Archived N plans: [list]" or "No new project plans found to archive."

## Step 4: Git Commit & Push

Check CLAUDE.md "Version Control" section:
- If mode is "none" → skip this entire step
- If mode is "local" → commit and tag only, no push
- If mode is "remote" → commit, tag, push (default behaviour if no Version Control section exists)

**Stage explicit paths only. NEVER `git add -A` or `git add .`.** The working tree may be shared with other agents or with a paused lane of work, and a blanket stage sweeps their files into your commit. Name every path you stage.

1. Run `git status` to see ALL modified and untracked files
2. For EVERY modified file shown, cross-reference with the conversation to confirm the changes were approved (any positive acknowledgement counts, such as "looks good", "cool", or accepting and moving on):
   - If approved this session → stage it by name
   - If from a prior session (orphaned work) → check SESSION_LOG/TASK_REGISTRY for approval context. If the work was part of a completed task, stage it AND note in the commit message: "Includes orphaned work from S[N]"
   - If unapproved or unclear → ask the user before staging
   - If it belongs to another agent's lane → leave it alone entirely and surface it in the report
   - If it should NOT be committed (temp files, diagnostics) → explicitly list it as excluded with reason
3. For EVERY untracked file shown:
   - If it's project code or safeguard files you can attribute to this session → stage it by name
   - If it's a temp/diagnostic file → add to .gitignore or explicitly exclude with reason
   - If you cannot attribute it → leave it, and say so
4. Commit with a descriptive message
5. Tag with the project's commit tagging convention
6. Run `git status` AFTER committing. It MUST show a clean tree, excluding gitignored files and any untracked lane you deliberately left alone
7. If the tree is NOT clean for any other reason → something was missed, go back
8. Push with the careful push in `/start` Step 2.7: confirm the current branch and its upstream, `git fetch` and look at ahead and behind before changing anything, push only this branch and only the tag you just made, by name, rebase only onto this branch's own upstream, never force, and stop and ask the user if git refuses or a conflict appears.
- **Backup remote (CCG only):** This step applies only to the Context Guard source-of-truth repo, which uses a dual-remote setup: `origin` (public) + `backup` (private dev). Most projects have a single `origin` remote, and that IS their backup. If you're on a project with only `origin`, skip this step. Do NOT flag a missing `backup` remote as an issue.
  If a `backup` remote exists: `git push backup main:dev`, which moves the backup's `dev` forward to `main` without switching branches. If the backup refuses it as not a fast-forward, stop and ask the user; never force it.

## Step 5: Verify Clean State

Run these checks:
- `git status` should be clean (no uncommitted changes)
- `git log @{u}..HEAD --oneline` should be empty (nothing unpushed on this branch)
- All Context Guard files should be up to date

## Step 6: Report

Present the session summary in EXACTLY this format. Do not vary the structure, headings, or field names:

```
## Session [N]: Save Point

**What was done:** [1-2 sentence summary of the session's main accomplishments]

**Tasks:** [the checker's line]; [X] finished this session
- Waiting on user: [list task IDs and names, or "None"]
- In progress: [list task IDs and names, or "None"]
- Pending: [list task IDs and names, or "None"]

**Commits:** [list of commit hashes, or "None, working tree clean"]

**Repos pushed:**
- [repo name]: [commit hash] ✅ (or ❌ if not pushed, with reason)

**Next session:** [What /start will find. User's stated intent for next session, or "No pending work."]
```

Do not add extra sections. Do not add "Files Modified" unless the session had no commits (uncommitted work needs visibility). Keep it scannable: this is a status report, not a narrative.
