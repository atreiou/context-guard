---
description: "Type /start at the beginning of every session. Reads the Context Guard files (last-5-sessions window, plus the whole to do list), checks the two lists, recovers context, and summarises project state."
allowed-tools: Read, Grep, Glob, Bash, Write, Edit
---

# Context Guard: Session Recovery (/start)

You are starting or resuming a session. Follow these steps EXACTLY:

**Date convention:** all dates written by this skill use **dd/mm/yy** (UK format). Do not retroactively rewrite older dates already in Context Guard files; only new entries follow this rule.

**Token discipline:** `/start` is a read-and-summarise operation, and every token it spends is a token the session's real work does not get. Read ONLY the files listed in Step 1. Do **NOT** read archive pages or plan files at session start. RESUME_STATE points at whatever the first task needs, and you open that material when you begin the task, not before.

## Step 0: Locate CCG Root

CCG_ROOT is the folder that holds the Context Guard files. In the current layout it is the `context-guard/` folder in the project root, with `archive/`, `plans/`, `audits/`, `backups/` and `templates/` inside it. The project's `CLAUDE.md` is the one Context Guard file that stays in the project root, because that is where the agent reads it automatically. Find CCG_ROOT in this order and stop at the first match:

0. **Pointer file:** `CCG_LOCATION.md` in the working directory names CCG_ROOT directly. Trust it.
1. **`./context-guard/`**, holding `TO_DO_LIST.md`.
2. **One level down**, when the working directory is a parent folder: `*/context-guard/TO_DO_LIST.md`. If several projects match, ask the user which one.
3. **An older layout**, until the project is upgraded:
   ```bash
   find . -maxdepth 4 \( -name "TO_DO_LIST.md" -o -name "TASK_REGISTRY.md" \) -not -path "*/templates/*" -not -path "*/archive/*" -not -path "*backups*" 2>/dev/null | head -10
   ```
   CCG_ROOT is the folder holding the match (often the project root itself, or a folder named `Context Guard`). Ignore a match whose `CLAUDE.md` still contains `{PROJECT_NAME}`. Note that this project is on an older layout: Step 1 offers the upgrade.
4. **None found:** this is a **first run**. Go to the First-Run Setup below.

**All Context Guard paths in the steps below are relative to CCG_ROOT**: `SESSION_LOG.md` means `{CCG_ROOT}/SESSION_LOG.md`, archive pages are in `{CCG_ROOT}/archive/`, plans in `{CCG_ROOT}/plans/`. On an older layout, files stay where that project already keeps them until it is upgraded. `CLAUDE.md` means the project's own, in the project root. Run git from the project root.

## Step 0.5: First-Run Detection

If the project-root `CLAUDE.md` still contains the placeholder `{PROJECT_NAME}`, setup was started but never finished: go to the First-Run Setup below. Otherwise this is a normal session: skip to Step 1.

### First-Run Setup

**IMPORTANT: First-run setup is procedural, not a design task. Do NOT enter plan mode. Proceed directly with creating the Context Guard files. If plan mode is active, exit it before continuing.**

1. **Find the templates:** `context-guard/templates/` (where `install.sh` puts them) or, after a manual install, `templates/` in the project root. If neither exists, tell the user: "No Context Guard templates found. Please run install.sh first, or copy the templates/ folder from the Context Guard repo into context-guard/templates/." Then stop.

2. **Ask for project details:**
   > "Welcome to Context Guard! Let's set up your project."
   > "What is your **project name**?"

   Wait for their answer. Then ask:
   > "Brief description (one line, or say 'skip'):"

3. **Create the Context Guard folder and its files.** Every Context Guard file lives in one `context-guard/` folder; nothing but `CLAUDE.md` goes loose in the project root.
   - Create `context-guard/` with `archive/`, `plans/`, `audits/` and `backups/` inside it.
   - If the templates were copied to the project root (`templates/`), move that folder to `context-guard/templates/`, but only if it holds nothing except Context Guard templates. A project can have a `templates/` folder of its own: then move only the Context Guard template files, by name.
   - From the templates, create in `context-guard/`: `SESSION_LOG.md`, `TO_DO_LIST.md`, `DONE_LIST.md`, `DECISIONS.md`, `COMMENTS.md`, `FEATURE_LIST.json`, `LEARNED_BEHAVIOUR.md`, `RESUME_STATE.md`.
   - Copy `templates/CLAUDE.md` to `CLAUDE.md` in the project root. If the project already has a `CLAUDE.md` of its own, add the template's sections below its existing content instead of replacing it.

4. **Populate placeholders** in `CLAUDE.md` and the new files:
   - Replace `{PROJECT_NAME}` with the user's project name
   - Replace `{PROJECT_DESCRIPTION}` with their description (or "TODO" if skipped)
   - Replace `{DATE}` with today's date in dd/mm/yy format

4.5. **Configure version control:**

   Ask:
   > "How would you like version control handled?"
   > 1. **Local git + remote**: commit and push (most common)
   > 2. **Local git only**: commit but never push
   > 3. **No git**: skip all version control

   Based on their answer, update the `## Version Control` section in CLAUDE.md:
   - Option 1: set Mode to `remote`
   - Option 2: set Mode to `local`
   - Option 3: set Mode to `none`

5. **Initialise SESSION_LOG.md:**
   - Add a Session 1 entry (date in dd/mm/yy):
   ```
   ## Session 1 ([today's date in dd/mm/yy], Project Setup)

   **What happened:**
   - Project initialised with Context Guard
   - Context Guard files created from templates

   **Tasks completed:** Context Guard setup
   **Tasks remaining:** None yet
   ```

6. **Report to the user:**
   ```
   ## Context Guard: First-Run Setup Complete

   ### Files Created
   - CLAUDE.md (project root): project instructions, read automatically every session
   - context-guard/SESSION_LOG.md: session history
   - context-guard/TO_DO_LIST.md: to do list (every task not yet finished)
   - context-guard/DONE_LIST.md: done list (every finished task, with its tested status and proof)
   - context-guard/DECISIONS.md: architectural decisions register (with Category field)
   - context-guard/LEARNED_BEHAVIOUR.md: tactical knowledge / platform gotchas log
   - context-guard/COMMENTS.md: user comments log
   - context-guard/FEATURE_LIST.json: QA tracker (manually-verified features)
   - context-guard/RESUME_STATE.md: in-flight state written by /save
   - context-guard/archive/, plans/, audits/, backups/, templates/

   ### Next Steps
   - Type /start at the beginning of every session for full context recovery
   - Type /save whenever you want a save point; Context Guard files are written only then and at /end (the two lists are kept current as work happens)
   - Type /audit at any time to verify integrity
   - Type /end when you're done for the day (saves everything in full)

   ### Would you like to run /itemise?
   The Itemisation Protocol adds numbered section markers to your code files,
   making every block referenceable by address (e.g. "check section 2.3.1").
   It's optional; toggle it off in CLAUDE.md at any time.
   Type /itemise to run it now, or skip and come back to it later.
   ```

7. **Stop here.** Do NOT continue to Step 1. The user is starting fresh, so there are no previous sessions to recover from.

---

## Step 1: Read the Context Guard Files

The ledgers are rotated: each main file holds ONLY the last 5 sessions' content (plus, for DECISIONS and LEARNED_BEHAVIOUR, a one-line index of everything archived). They are small by design, so read each in full, in this order:

0. **`RESUME_STATE.md`, READ THIS FIRST.** This file holds only the in-flight state from the last /save. If `Clean save: false`, the previous session was interrupted mid-task, and the In-flight and Next step sections are your handoff note. Surface this in the Step 4 summary under a `🔄 Resume from last session` heading so the user knows you picked it up. If `Clean save: true`, the previous session ended cleanly and RESUME_STATE is empty, so the next-session intent lives in SESSION_LOG's newest "Next step".
0.5. **`CONTEXT_GUARD_UPDATE.md`, if it exists in CCG_ROOT.** A note left when Context Guard itself was updated in this project: what changed, which files, and what to do next. Read it in full, surface it in the Step 4 summary under `🛠 Context Guard was updated`, and do what it asks before other work. It says itself when it may be deleted.
1. `CLAUDE.md` (project root): project rules and architecture. Parse the `## Custom Context Files` section for any project-specific files to load.
2. `SESSION_LOG.md`: the last 5 sessions
3. `TO_DO_LIST.md`: the to do list. Read ALL of it, every row: it is the one list of tasks not yet finished, and nothing on it is ever old enough to skip. Do NOT read `DONE_LIST.md` or any archive page at session start.
4. `DECISIONS.md`: recent decisions in full, **plus the `## Index of archived decisions`**. Never contradict these.
5. `LEARNED_BEHAVIOUR.md`: recent entries in full, **plus the `## Index of archived LBs`** (if present; skip if not initialised yet)
6. `COMMENTS.md`: user's verbatim comments, check for unactioned ones
7. `FEATURE_LIST.json`: QA pass/fail tracker (manually-verified features, NOT task-completion mirror)

**A project not yet upgraded.** If CCG_ROOT is not a `context-guard/` folder (Step 0 found an older layout), or there is no `TO_DO_LIST.md` (the project still has the old single task list, `TASK_REGISTRY.md`), this project is on an older Context Guard. Read the old `TASK_REGISTRY.md` in full as it stands, including any backlog or carried sections. Then, before any other work, put this to the user by AskUserQuestion: Context Guard now keeps all its files in one `context-guard/` folder (archives in their own folder inside it) and keeps two lists, the to do list (everything not yet done, including decisions waiting on the user) and the done list (everything finished, with whether and how it was tested); do they want this project upgraded straight away, or wait? If they say upgrade, follow `templates/UPGRADE.md` (in CCG_ROOT, or in the Context Guard repo). If they say wait, carry on with the project as it is and ask again at the next `/start`.

**Archived entries are still binding.** A decision or learned behaviour that has been rotated into an archive page has NOT stopped applying; only its full text has moved. `forever-active` and `active-constraint` decisions govern from the archive exactly as they did from the main file. The one-line indexes in DECISIONS.md and LEARNED_BEHAVIOUR.md are how you find them: if an index line touches what you are about to work on, open its full text in the archive page **at that point**, not now.

**Custom context files:** After reading `CLAUDE.md`, scan its `## Custom Context Files` section. For every declared entry (lines matching `- path/to/file.md: purpose`), read the referenced file. Skip any that don't exist, and don't fail the startup. Skip anything the section marks read-on-demand.

**Do NOT read at session start:** archive pages wholesale, or any file in `plans/`. Note that archive pages exist; open a specific entry only when the work needs it, per the binding rule above.

## Step 2: Check Git State

Run: `git log --oneline --decorate -10 && echo "===" && git status -sb && echo "===" && git log @{u}..HEAD --oneline`

Report: the current branch, any uncommitted files, any unpushed commits.

## Step 2.5: Detect Unlogged Sessions

After checking git state, detect potential orphaned work:

1. Get the date of the last session entry in SESSION_LOG.md
2. Get the date of the most recent git commit: `git log -1 --format=%ci`
3. If the last commit is AFTER the last session log date, warn:

> ⚠️ **ORPHANED SESSION DETECTED**
> Last session logged: S[N] on [date]
> Last git commit: [hash] on [date], "[message]"
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
2. **Review the changes** by running `git diff --stat` and `git diff --cached --stat` to understand what was done
3. **Cross-reference with the to do list and SESSION_LOG.md** to identify which session produced these changes, what tasks they relate to, and confirm the work was approved (completed tasks, user-acknowledged output, etc.)
4. **Stage and commit** with a descriptive message summarising the orphaned work:
   ```
   git add [explicit paths]
   git commit -m "Recover uncommitted work from session [N]: [brief summary]"
   ```
   **NEVER `git add -A` or `git add .`.** The working tree may be shared with other agents or with a paused lane of work. Stage the specific paths you have attributed and nothing else. Leave files you cannot attribute untouched and surface them to the user instead.
5. **Push carefully**, following the careful push below.
6. **Report** what was committed:
   > ✅ **Orphaned work committed:** [commit hash], [summary of what was recovered]

If there are **unpushed commits** (committed but not pushed), push them with the careful push.

If the working tree is clean and all commits are pushed, skip this step.

**IMPORTANT:** Do NOT proceed until `git status` shows a clean working tree, excluding gitignored files and any untracked files belonging to another agent's lane (see CLAUDE.md). Those are left alone, not flagged as problems.

**Careful push.** Never push blind:
1. `git branch --show-current` and `git rev-parse --abbrev-ref --symbolic-full-name @{u}`: the branch you are on and the remote branch it tracks. Push only this branch. Never switch branches, and never push or rewrite a branch someone else is working on. No upstream set: ask the user before creating one.
2. `git fetch`, then `git status -sb`: are you ahead, behind, or both?
3. **Ahead only:** `git push`, then push only the tags you made, by name (`git push origin <tag>`), never `git push --tags`.
4. **Behind or both:** look at what arrived (`git log --oneline HEAD..@{u}`). Replay your own commits on top of this branch's own upstream with `git pull --rebase`, never onto a different branch such as `main`. If git refuses (uncommitted work in the tree) or the rebase hits a conflict, run `git rebase --abort` if one started, stop, and ask the user. Never stash, reset or check out someone else's uncommitted work to make a pull go through.
5. **Never force-push.**

## Step 3: Determine Session Number

The new session number = last session in SESSION_LOG.md + 1.

## Step 3.5: Check the Task Lists

Run the checker from the working directory (it is installed beside these commands, in `.claude/tools/`):

```bash
node .claude/tools/registry_check.js --root "<CCG_ROOT>" --session S<N>
```

- Its first line (`To do: N (W waiting on user); done: ...`) goes in the Step 4 summary, word for word.
- Every row it flags goes in the summary under `List flags`. They are fixed during the session, and `/end` must leave both lists clean.
- Exit code 2 means the project is still on the old single list: the question in Step 1 covers it.
- If `node` or the checker is missing, say so in the summary. Never report the lists as checked when the checker did not run.

**Plan cross-referencing is NOT done here.** Reading plan files at session start costs thousands of tokens for a check that is only occasionally needed, and RESUME_STATE's "Next step" already names the exact plan file and section the first task requires. The full plan-versus-registry sweep, including DROPPED TASK detection across every plan and every archive page, lives in `/audit` §3, which reads ALL plans rather than a sample. Run `/audit` when you want that check; do not reproduce it here.

## Step 4: Summarise

### Internal context acknowledgement (do NOT output to user)

Silently complete this checklist before composing the user summary. This is a self-check to confirm you absorbed the context, and the output goes into your own working memory, not the chat:

- Active decisions loaded: [N] (most recent: D-xx from S[yy])
- Forever-active rules: [N] (brief mental list: style, brand, philosophy)
- Feature QA status: [X passing / Y failing / Z untested]
- Learned behaviours loaded: [N entries]
- Archived-entry indexes scanned: [N archived decisions, N archived LBs, plus any line that touches today's likely work]
- Custom context files loaded: [list from CLAUDE.md Custom Context Files section]
- Decisions revised in the last 3 sessions: [list, or "none"]
- New learned behaviours since last /start: [list, or "none"]
- Resume state: [Clean / Interrupted, resume from RESUME_STATE.md]
- The two lists: [the checker's line, or "older Context Guard, upgrade question asked"]

Any non-empty recent item → surface in the user summary below. Otherwise stay silent on it. No "None" placeholders, that's noise.

### User-visible summary

Present a clear summary. Only include sections that have content, and omit empty ones.

```
## Session [N]: Context Recovery

### 🔄 Resume from last session (only if RESUME_STATE.md Clean save: false)
[Prepend the In-flight and Next step content verbatim from RESUME_STATE.md]

### 🛠 Context Guard was updated (only if CONTEXT_GUARD_UPDATE.md exists)
[What changed and what it asks, in a few lines]

### Last Session ([N-1])
[What was done]

### To Do
[The checker's first line, then every to do list row: WAITING ON USER first, then IN PROGRESS, then PENDING]

### List flags (only if the checker flagged rows)
[Each flagged row and what is wrong with it]

### ⚠️ Recently revised (only if non-empty)
[Decisions revised in the last 3 sessions, with D-number and reason. These are the highest-risk source of contradictions in today's work]

### 🆕 Newly learned (only if non-empty)
[Learned behaviours added since the last /start]

### Unactioned Comments
[Any user comments not yet turned into decisions/tasks/changes]

### Git State
[Clean / recovered orphan work / anything surfaced]

### Ready to proceed?
```

The user does NOT want full decision/feature/learned-behaviour listings echoed back. The internal acknowledgement above is for YOU. Only surface items that genuinely need the user's attention (recent revisions, new tactical knowledge).

## Step 5: Wait

Do NOT start any work until the user confirms. Wait for their go-ahead.
