---
description: "Type /save to checkpoint progress mid-session. Updates all safeguard files without ending the session. Protects against context loss during long sessions."
allowed-tools: Read, Grep, Glob, Bash, Edit, Write
---

# Context Guard: Mid-Session Checkpoint (/save)

The user wants to save current progress without ending the session. This is a lightweight checkpoint: no plan archiving, no session wrap-up, no full ledger rotation. Update safeguard files, commit, push, and confirm.

**Date convention:** all dates written by this skill use **dd/mm/yy** (UK format). Do not retroactively rewrite older dates already in safeguard files; only new entries follow this rule.

## Step 0: Locate CCG Root

Safeguard files may not be in the current working directory; they could be in a subdirectory. Find them first.

0. **Check for a pointer file first:** if `CCG_LOCATION.md` exists at the working-directory root, it names CCG_ROOT directly. Trust it and skip the search below.
1. **Check the working directory:** Try to read `CLAUDE.md` in the current directory.
2. **If not found, search subdirectories:**
   ```bash
   find . -maxdepth 4 -name "CLAUDE.md" -type f 2>/dev/null | head -10
   ```
3. **Filter:** For each result, check it contains `TASK_REGISTRY.md` (confirms it's a Context Guard CLAUDE.md) and does NOT contain `{PROJECT_NAME}` (uninitialized template).
4. **Set CCG_ROOT:** Use the directory of the valid CLAUDE.md found. If multiple, ask the user. If none, warn: "No Context Guard files found. Run /start first."

**All safeguard file paths in subsequent steps are relative to CCG_ROOT.** Git operations should also run from CCG_ROOT if it differs from the working directory.

## Step 0.5: Completeness Check (never opt for brevity)

Before saving, check what might be missing. Log anything missing BEFORE proceeding to Step 1.

- Are there any user comments since the last save NOT yet in COMMENTS.md? They go in verbatim.
- Is every task created since the last save on the LIVE list, and has every task that finished already moved from LIVE to the top of COMPLETED?
- Review the recent conversation for any decisions made but not logged in DECISIONS.md.
- Any gotcha, workaround, or debug that ate more than ~15 minutes → LEARNED_BEHAVIOUR.md.
- **Did this session create or delete any credentials, accounts, or test fixtures?** If so, the FULL details (usernames, passwords, IDs, which are real identities and which are fixtures) must be written down in the project's designated record (see CLAUDE.md; commonly `docs/TEST_USERS.md`) **now**, in full. Not summarised, not "I'll remember it". A checkpoint that omits them has failed: the next session cannot log in and the work is blocked until someone recreates the information from scratch.

Brevity is not a virtue here. Trimming a detail because it feels secondary is a decision to withhold information nobody authorised you to withhold.

## Step 1: Gather Current Context

Quickly review what has happened since the last checkpoint or session start:
- What tasks were worked on or completed?
- What files were created or modified?
- What decisions were made?
- What user comments were given?

## Step 2: Update Safeguard Files

Check and update ALL of these:

### RESUME_STATE.md
- Overwrite this file with the current in-flight state. Fields:
  ```
  **Session:** S[N]
  **Last updated:** dd/mm/yy HH:MM
  **Clean save:** false

  ## In-flight
  [What is actively being worked on right now: approach, current state, next micro-step. Handoff note to the next agent.]

  ## Next step
  [User's stated intent in their own words]
  ```
- `Clean save: false` tells the next `/start` that work was mid-flight, so it will surface this under `🔄 Resume from last session`.
- SESSION_LOG.md remains the historical record; RESUME_STATE.md is the current-state slice.

### SESSION_LOG.md
- If no entry exists for this session yet, create one
- If an entry already exists, append a checkpoint marker:
  ```
  **Checkpoint [HH:MM]:** [brief summary of progress since last save]
  **In flight:** [what is actively being worked on right now: the approach, current state, and next micro-step]
  ```
- The "In flight" line is critical: if context is lost after this save, this is what the next session reads to understand exactly where you were mid-thought. Write it like a handoff note to yourself.
- If any significant errors or blockers were hit since the last save, add: `**Error fixed:** [what happened and how it was resolved]`
- If the user has expressed what they want done next, add: `**Next step:** [user's intent in their own words]`
- Do NOT close out the session entry, because work is continuing

### The two task lists (TASK_REGISTRY.md is LIVE, TASK_REGISTRY_COMPLETED.md is COMPLETED)
- **New tasks** since the last save go on LIVE: ID, Task, a Status starting `PENDING`, `IN PROGRESS` or `WAITING ON USER` followed by one sentence of what is left, Updated as `S<N> dd/mm/yy`, and in Notes `Governed by: D-xx, D-yy` for any decisions that constrain the work. This makes constraints visible at the point of execution, not buried in DECISIONS.md.
- **Tasks worked on:** bring their LIVE Status and Updated up to date.
- **Finished tasks** should already have moved in the turn they finished. Any that has not moves now: delete its LIVE row and add it at the TOP of COMPLETED with Outcome (`DONE dd/mm/yy`, `SUPERSEDED dd/mm/yy by <id>`, or `DROPPED dd/mm/yy` with the user's own words quoted), Tested (`TESTED BY USER`, `TESTED INDEPENDENTLY`, `BUILDER ONLY` or `NOT TESTED`, then where the record is), and Proof (a path or a commit, then `Files: 1 to 3 key paths | Approach: one sentence naming the pattern or library | Governed by: D-xx`). Keep it terse: this record is for future queries, not narrative.
- **Handovers:** any open task or question for the user that arrived in a handover since the last save goes on LIVE now. The handover itself stays as it is.
- **Run the checker** and fix every row it flags; anything you cannot fix goes in the Step 4 confirmation:
  `node .claude/tools/registry_check.js --root "<CCG_ROOT>" --session S<N>`
- **A project still on the old single list** (no `TASK_REGISTRY_COMPLETED.md`): update the old rows in place, do NOT rotate or archive any of them, and say in the confirmation that the two-list build is still waiting on the user.

### COMMENTS.md
- Verify all user comments since the last save are logged verbatim
- If any are missing, add them now with timestamps

### DECISIONS.md
- If any architectural decisions were made since the last save, log them
- **Mandatory Category field** on every new entry. Assign one of: `forever-active`, `active-constraint`, `feature-specific`, `superseded`. If uncertain, default to `active-constraint` (safest, since it won't auto-archive).
- If a decision supersedes an earlier one, mark the old one `Category: superseded` with a pointer to the new D-number.

### LEARNED_BEHAVIOUR.md
- If the session surfaced any non-obvious workaround, platform quirk, version-specific gotcha, or "spent >15 minutes debugging this" discovery, log it here.
- Do NOT log ordinary coding knowledge; only things a fresh agent would re-discover the hard way.
- Entry format:
  ```
  ## LB-NNN: [Short title] (Session N, dd/mm/yy)
  **Context:** Where this surfaces (platform, plugin, version)
  **Gotcha:** What fails and how
  **Workaround:** What actually works
  **Why:** Root cause if known
  **Related:** Tasks/decisions (optional)
  ```

### FEATURE_LIST.json
- **Semantics:** FEATURE_LIST is a QA tracker, NOT a task-completion mirror. Only flip `passes: true` when the user has **manually verified** the feature works end-to-end. Task completion is tracked in the two task lists. Do not confuse the two.
- If the user reports a feature broken, flip `passes: false` with a `notes` description of the failing case.

## Step 2.5: Rotate Only If Overgrown

**Full ledger rotation is `/end`'s job, not `/save`'s.** A mid-session checkpoint should be cheap, and re-running the whole pagination pass every time a user types `/save` burns context for no benefit, because nothing has aged since the last one.

Do this instead: check whether any ledger's main file now holds MORE than the last 5 sessions' content. That normally only happens when the current session has just crossed a boundary, or when the previous `/end` was skipped. If one has overgrown, apply `/end` Step 2.5's rotation rules **to that file only**. Otherwise skip this step entirely and say nothing about it. The LIVE task list never rotates.

## Step 2.8: Verify Update Completion

Before proceeding to git, confirm every safeguard file was addressed. Output this checklist:

**Update verification:**
- RESUME_STATE.md: [overwritten with current in-flight / work is between sub-tasks, snapshot captured]
- SESSION_LOG.md: [updated / already current, with the reason]
- Task lists: [the checker's line; N added to LIVE, M moved to COMPLETED / no task changes, with the reason]
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
  Do NOT log ordinary coding knowledge; only things a fresh agent would re-discover the hard way.

**Task list check:** Did the checker come out clean? If not, every remaining flag is listed in the Step 4 confirmation with the reason it could not be fixed now.

**Feature trigger check:** Did the user **manually verify** any feature working end-to-end this session, or report one broken? Task completion does NOT count; only human verification does.
  If yes and FEATURE_LIST.json wasn't updated → go back and update it now.

If any file shows 0 changes, the reason must be specific (not "no changes needed").
"No changes needed" without explanation is not acceptable. State what you checked.

## Step 3: Git Commit & Push

Check CLAUDE.md "Version Control" section:
- If mode is "none" → skip this entire step
- If mode is "local" → commit only, no push
- If mode is "remote" → commit and push (default behaviour if no Version Control section exists)

After updating safeguard files, commit everything to git so the save point is durable:

1. Run `git status` to see ALL modified and untracked files
2. Stage the safeguard files AND any approved code changes since the last commit, **by explicit path**.
   **NEVER `git add -A` or `git add .`.** The working tree may be shared with other agents or with a paused lane of work, and a blanket stage sweeps their files into your commit. Name the paths you are committing. Anything you cannot attribute is left alone and surfaced to the user instead.
3. Commit with a descriptive message: `"Checkpoint: [brief summary]"`
4. Push to remote: `git pull --rebase origin main && git push`
5. If `git status` still shows uncommitted project files after the commit, excluding gitignored files and other agents' untracked lanes, something was missed. Go back.

If there are no changes to commit (everything is already committed), skip this step.

## Step 4: Confirm

Present a brief confirmation. Keep it concise, not a full report:

```
## Checkpoint Saved

- RESUME_STATE.md: in-flight snapshot written (Clean save: false)
- SESSION_LOG.md: [updated/no changes needed]
- Task lists: [the checker's line; N added to LIVE, M moved to COMPLETED / no changes needed]
- COMMENTS.md: [N comments added / no changes needed]
- DECISIONS.md: [N decisions added / no changes needed]
- LEARNED_BEHAVIOUR.md: [N entries added / no changes needed]
- FEATURE_LIST.json: [N features verified / no changes needed]
- Git: [commit hash] pushed / no changes to commit

Progress is saved. Continue working. Run /save again any time, or /end to wrap up.
```

Do NOT perform any of the following (these are /end responsibilities):
- Plan archiving
- Git state verification
- Full session summary report
