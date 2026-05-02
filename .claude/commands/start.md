---
description: "Type /start at the beginning of every session. Reads all safeguard files, recovers context, cross-references plans against task registry, and summarises project state."
allowed-tools: Read, Grep, Glob, Bash, Write, Edit
---

# Context Guard — Session Recovery (/start)

You are starting or resuming a session. Follow these steps EXACTLY:

**Date convention:** all dates written by this skill use **dd/mm/yy** (UK format). Do not retroactively rewrite older dates already in safeguard files; only new entries follow this rule.

## Step 0: Locate CCG Root

Context Guard safeguard files may not be in the current working directory — they could be in a subdirectory (e.g. the working directory is a parent folder that contains the actual project). Find them before doing anything else.

1. **Check the working directory first:** Try to read `CLAUDE.md` in the current directory.
2. **If not found, search subdirectories:**
   ```bash
   find . -maxdepth 4 -name "CLAUDE.md" -type f 2>/dev/null | head -10
   ```
3. **Filter results:** For each CLAUDE.md found, check if it contains `TASK_REGISTRY.md` (which confirms it's a Context Guard CLAUDE.md, not an unrelated file). Ignore any that contain the placeholder `{PROJECT_NAME}` — those are uninitialized templates.
4. **Set CCG_ROOT:**
   - If exactly one valid CLAUDE.md is found → use its directory as CCG_ROOT
   - If multiple valid CLAUDE.md files are found → list them and ask the user which project to recover
   - If none found → this is a **first run**. Set CCG_ROOT to the current working directory and go to the First-Run Setup below.

**CRITICAL: All safeguard file paths in ALL subsequent steps are relative to CCG_ROOT, not the working directory.** When this skill says "read SESSION_LOG.md", it means `{CCG_ROOT}/SESSION_LOG.md`. When it says "run git status", `cd` into CCG_ROOT first if it differs from the working directory.

## Step 0.5: First-Run Detection

If Step 0 found a valid CLAUDE.md:
- If it **contains the placeholder text `{PROJECT_NAME}`** — this is a **first run**. Go to the First-Run Setup below.
- Otherwise — this is a normal session. Skip to Step 1.

### First-Run Setup

**IMPORTANT: First-run setup is procedural, not a design task. Do NOT enter plan mode. Proceed directly with creating safeguard files. If plan mode is active, exit it before continuing.**

1. **Check for templates:** Look for a `templates/` folder in CCG_ROOT. If it doesn't exist, also search subdirectories: `find . -maxdepth 4 -name "templates" -type d`. If still not found, tell the user: "No templates/ folder found. Please run install.sh first or copy the templates/ folder from the Context Guard repo." Then stop.

2. **Ask for project details:**
   > "Welcome to Context Guard! Let's set up your project."
   > "What is your **project name**?"

   Wait for their answer. Then ask:
   > "Brief description (one line, or say 'skip'):"

3. **Create safeguard files from templates:**
   - Copy `templates/CLAUDE.md` → `CLAUDE.md` (project root)
   - Copy `templates/SESSION_LOG.md` → `SESSION_LOG.md`
   - Copy `templates/TASK_REGISTRY.md` → `TASK_REGISTRY.md`
   - Copy `templates/DECISIONS.md` → `DECISIONS.md`
   - Copy `templates/COMMENTS.md` → `COMMENTS.md`
   - Copy `templates/FEATURE_LIST.json` → `FEATURE_LIST.json`
   - Copy `templates/LEARNED_BEHAVIOUR.md` → `LEARNED_BEHAVIOUR.md`
   - Copy `templates/RESUME_STATE.md` → `RESUME_STATE.md`
   - Create `plans/` directory if it doesn't exist

4. **Populate placeholders in CLAUDE.md:**
   - Replace `{PROJECT_NAME}` with the user's project name
   - Replace `{PROJECT_DESCRIPTION}` with their description (or "TODO" if skipped)
   - Replace `{DATE}` with today's date in dd/mm/yy format

4.5. **Configure version control:**

   Ask:
   > "How would you like version control handled?"
   > 1. **Local git + remote** — commit and push (most common)
   > 2. **Local git only** — commit but never push
   > 3. **No git** — skip all version control

   Based on their answer, update the `## Version Control` section in CLAUDE.md:
   - Option 1: set Mode to `remote`
   - Option 2: set Mode to `local`
   - Option 3: set Mode to `none`

5. **Initialise SESSION_LOG.md:**
   - Add a Session 1 entry (date in dd/mm/yy):
   ```
   ## Session 1 — [today's date in dd/mm/yy] (Project Setup)

   **What happened:**
   - Project initialised with Context Guard
   - Safeguard files created from templates

   **Tasks completed:** Context Guard setup
   **Tasks remaining:** None yet
   ```

6. **Report to the user:**
   ```
   ## Context Guard — First-Run Setup Complete

   ### Files Created
   - CLAUDE.md — project instructions (auto-read every session)
   - SESSION_LOG.md — session history
   - TASK_REGISTRY.md — task tracker
   - DECISIONS.md — architectural decisions register (with Category field)
   - LEARNED_BEHAVIOUR.md — tactical knowledge / platform gotchas log
   - COMMENTS.md — user comments log
   - FEATURE_LIST.json — QA tracker (manually-verified features)
   - RESUME_STATE.md — in-flight state for rate-limit / mid-task recovery
   - plans/ — plan archive directory

   ### Next Steps
   - Type /start at the beginning of every session for full context recovery
   - Type /save during a session to checkpoint progress without ending
   - Type /audit at any time to verify integrity
   - Type /end when you're done for the day (optional clean save point)

   ### Would you like to run /itemise?
   The Itemisation Protocol adds numbered section markers to your code files,
   making every block referenceable by address (e.g. "check section 2.3.1").
   It's optional — toggle it off in CLAUDE.md at any time.
   Type /itemise to run it now, or skip and come back to it later.
   ```

7. **Stop here.** Do NOT continue to Step 1. The user is starting fresh — there are no previous sessions to recover from.

---

## Step 1: Read Safeguard Files

Read files in this order:

0. **`RESUME_STATE.md` — READ THIS FIRST.** This file holds only the in-flight state from the last /save. If `Clean save: false`, the previous session was interrupted mid-task — the In-flight and Next step sections are your handoff note. Surface this in the Step 5 summary under a `🔄 Resume from last session` heading so the user knows you picked it up. If `Clean save: true`, the previous session ended cleanly and RESUME_STATE is empty — skip ahead.
1. `CLAUDE.md` — project rules and architecture. Parse the `## Custom Context Files` section for any project-specific files to load.
2. `SESSION_LOG.md` — what happened in recent sessions
3. `TASK_REGISTRY.md` — active and recent tasks, find the PENDING ones
4. `DECISIONS.md` — architectural decisions with Category field, never contradict these
5. `LEARNED_BEHAVIOUR.md` — tactical knowledge, platform gotchas, workarounds (if present — skip if not initialised yet)
6. `COMMENTS.md` — user's verbatim comments, check for unactioned ones
7. `FEATURE_LIST.json` — QA pass/fail tracker (manually-verified features, NOT task-completion mirror)

**Custom context files:** After reading `CLAUDE.md`, scan its `## Custom Context Files` section. For every declared entry (lines matching `- path/to/file.md — purpose`), read the referenced file. Skip any that don't exist — don't fail the startup.

**Archive awareness:** After reading each file, check for `_page*.md` archives (e.g. `SESSION_LOG_page1.md`, `TASK_REGISTRY_page1.md`, `DECISIONS_page1.md`, `LEARNED_BEHAVIOUR_page1.md`). If archives exist:
- Do NOT read them — they contain older history that was rotated out to save context
- Note them in your Step 5 summary: "📁 N archive pages available for [file]"
- Only read archives if the user explicitly asks you to, or if you genuinely feel something is missing and cannot make sense of the current files without historical context

## Step 2: Check Git State

Run: `git log --oneline --decorate -10 && echo "===" && git status && echo "===" && git log origin/main..HEAD --oneline`

Report: any uncommitted files, any unpushed commits.

## Step 2.5: Detect Unlogged Sessions

After checking git state, detect potential orphaned work:

1. Get the date of the last session entry in SESSION_LOG.md
2. Get the date of the most recent git commit: `git log -1 --format=%ci`
3. If the last commit is AFTER the last session log date, warn:

> ⚠️ **ORPHANED SESSION DETECTED**
> Last session logged: S[N] on [date]
> Last git commit: [hash] on [date] — "[message]"
> Work was done after the last logged session. This may mean a session ended without /end.
> Recommend: Review git log and reconstruct the missing session entry.

If the dates match or the session log is current, continue normally.

## Step 2.7: Commit Orphaned Work

Check CLAUDE.md "Version Control" section:
- If mode is "none" → skip this entire step
- If mode is "local" → commit only, no push
- If mode is "remote" → commit and push (default behaviour if no Version Control section exists)

If Step 2 found **uncommitted changes** (modified or untracked files), a previous session likely ended without `/end` (context overflow, rate limit, crash). This work must be committed before proceeding.

1. **Run `git status`** to see all uncommitted and untracked files
2. **Review the changes** — run `git diff` and `git diff --cached` to understand what was done
3. **Cross-reference with TASK_REGISTRY.md and SESSION_LOG.md** — identify which session produced these changes, what tasks they relate to, and confirm the work was approved (completed tasks, user-acknowledged output, etc.)
4. **Stage and commit** with a descriptive message summarising the orphaned work:
   ```
   git add [relevant files]
   git commit -m "Recover uncommitted work from session [N] — [brief summary]"
   ```
5. **Push** to remote: `git push`
6. **Report** what was committed:
   > ✅ **Orphaned work committed:** [commit hash] — [summary of what was recovered]

If there are **unpushed commits** (committed but not pushed), push them now: `git push && git push --tags`

If the working tree is clean and all commits are pushed, skip this step.

**IMPORTANT:** Do NOT proceed to Step 3 until `git status` shows a clean working tree (no modified or untracked project files, excluding gitignored files). All orphaned work must be committed first.

## Step 3: Cross-Reference Plans

Read the **last 3 plan files** from the `plans/` directory IN FULL.

For each plan:
- Check every task/step mentioned against TASK_REGISTRY.md
- Flag any task that appears in a plan but NOT in the registry (DROPPED TASK — critical)
- Note: completed tasks may have been archived to `TASK_REGISTRY_page*.md` by pagination. If flagged tasks seem like they were likely completed in older sessions, mention this possibility rather than treating it as critical. Full archive cross-referencing is the `/audit` skill's job.
- Flag any task in the registry with no corresponding plan, decision, or user comment (UNEXPLAINED TASK)

## Step 4: Determine Session Number

The new session number = last session in SESSION_LOG.md + 1.

## Step 5: Summarise

### Internal context acknowledgement (do NOT output to user)

Silently complete this checklist before composing the user summary. This is a self-check to confirm you absorbed the context — the output goes into your own working memory, not the chat:

- Active decisions loaded: [N] (most recent: D-xx from S[yy])
- Forever-active rules: [N] (brief mental list — style, brand, philosophy)
- Feature QA status: [X passing / Y failing / Z untested]
- Learned behaviours loaded: [N entries]
- Custom context files loaded: [list from CLAUDE.md Custom Context Files section]
- Decisions revised in the last 3 sessions: [list, or "none"]
- New learned behaviours since last /start: [list, or "none"]
- Resume state: [Clean / Interrupted — resume from RESUME_STATE.md]

Any non-empty recent item → surface in the user summary below. Otherwise stay silent on it — no "None" placeholders, that's noise.

### User-visible summary

Present a clear summary. Only include sections that have content — omit empty ones.

```
## Session [N] — Context Recovery

### 🔄 Resume from last session (only if RESUME_STATE.md Clean save: false)
[Prepend the In-flight and Next step content verbatim from RESUME_STATE.md]

### Last Session ([N-1])
[What was done]

### Pending Tasks
[List from TASK_REGISTRY with pending status]

### ⚠️ Recently revised (only if non-empty)
[Decisions revised in the last 3 sessions, with D-number and reason — these are the highest-risk source of contradictions in today's work]

### 🆕 Newly learned (only if non-empty)
[Learned behaviours added since the last /start]

### Unactioned Comments
[Any user comments not yet turned into decisions/tasks/changes]

### Cross-Reference Results
[Any dropped or unexplained tasks found]

### Git State
[Clean / uncommitted files / unpushed commits]

### Ready to proceed?
```

The user does NOT want full decision/feature/learned-behaviour listings echoed back. The internal acknowledgement above is for YOU. Only surface items that genuinely need the user's attention (recent revisions, new tactical knowledge).

## Step 6: Wait

Do NOT start any work until the user confirms. Wait for their go-ahead.
