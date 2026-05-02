---
description: "Type /audit to verify project integrity. Checks all safeguard files, git state, uncommitted work, plan cross-references, and task registry for completeness."
allowed-tools: Read, Grep, Glob, Bash, Write
---

# Context Guard — Project Audit (/audit)

**IMPORTANT: The user is auditing your work. Every task must be traceable back to a plan, a decision, or a user comment. Unexplained work WILL be flagged.**

Execute ALL checks below and report findings.

## 0. Locate CCG Root

Safeguard files may not be in the current working directory — they could be in a subdirectory. Find them first.

1. **Check the working directory:** Try to read `CLAUDE.md` in the current directory.
2. **If not found, search subdirectories:**
   ```bash
   find . -maxdepth 4 -name "CLAUDE.md" -type f 2>/dev/null | head -10
   ```
3. **Filter:** For each result, check it contains `TASK_REGISTRY.md` (confirms it's a Context Guard CLAUDE.md) and does NOT contain `{PROJECT_NAME}` (uninitialized template).
4. **Set CCG_ROOT:** Use the directory of the valid CLAUDE.md found. If multiple, ask the user. If none, warn: "No Context Guard files found. Run /start first."

**All file paths in subsequent steps are relative to CCG_ROOT.** Git operations should also run from CCG_ROOT if it differs from the working directory.

## 1. Git State
- Run `git status` — any uncommitted or untracked files?
- Run `git log --oneline -5` — recent commits with tags
- Run `git log origin/main..HEAD --oneline` — unpushed commits?
- **CRITICAL** if anything is uncommitted or unpushed

## 2. Task Registry Integrity
- Read `TASK_REGISTRY.md`
- Count tasks by status (✅ done / ⏳ pending / 🔄 in-progress / ❌ blocked / 🔁 re-queued)
- Check for stale in-progress tasks (started but never completed)
- Cross-reference with `FEATURE_LIST.json` — features without tasks?

## 3. Plan Cross-Reference
- Read ALL plan files from `plans/` directory
- For EVERY task/step in every plan, verify it exists in TASK_REGISTRY
- If a task from a plan is NOT in the current registry, **check archive pages** (`TASK_REGISTRY_page*.md`) before flagging — it may have been completed and archived
- Flag: tasks in plans NOT in registry AND NOT in any archive = **DROPPED TASK (CRITICAL)**
- Flag: tasks in registry with no plan, decision, or comment source = **UNEXPLAINED TASK**

## 4. User Comments
- Read `COMMENTS.md`
- Check for unactioned comments (no corresponding decision, task, or file change)
- Flag unactioned comments as **NEEDS ATTENTION**

## 5. Decisions Register
- Read `DECISIONS.md`
- Verify decision count
- Check for contradictions between decisions
- **Classification sanity check:** flag any decision missing a `Category:` field. Valid values: `forever-active`, `active-constraint`, `feature-specific`, `superseded`. Report missing categories as **WARNING — needs classification**.
- **Cross-reference check:** for any decision with an `Affects:` field listing task IDs, verify those tasks exist in TASK_REGISTRY (or its archives). Stale task references = **INFO — update Affects: field**.

## 6. Session Log
- Read `SESSION_LOG.md`
- Verify current session is logged
- Check last entry matches what actually happened

## 7. Unarchived Plans
- Check `~/.claude/plans/` for any plan files not yet copied to `plans/`
- **`~/.claude/plans/` is SHARED across all projects.** To identify which plans belong to this project:
  - For each `.md` file (excluding `-agent-` files which are sub-agent plans):
    - Read the first ~500 characters
    - If the content contains the current project name (from CLAUDE.md), OR contains file paths matching this project's directory structure — it belongs to this project.
    - If the content references a different project name — skip it.
    - If ambiguous — skip it. Do not flag plans you can't confidently attribute.
- Flag matched unarchived plans as **NEEDS ARCHIVING**
- Ignore plans from other projects entirely — do NOT report them.

## 8. Safeguard File Existence
- Verify ALL safeguard files exist at their expected paths and are non-empty:
  - `CLAUDE.md`
  - `RESUME_STATE.md`
  - `SESSION_LOG.md`
  - `TASK_REGISTRY.md`
  - `DECISIONS.md`
  - `LEARNED_BEHAVIOUR.md`
  - `COMMENTS.md`
  - `FEATURE_LIST.json`
- **CRITICAL** if any file is missing or empty
- **RESUME_STATE.md integrity:** If `Clean save: false` but the last session has a `## Session` entry in SESSION_LOG.md, something is inconsistent. Flag as **WARNING**.
- Check for archive page files (`*_page*.md`). If they exist:
  - Verify each has a valid header (file name, page number, session/entry range)
  - Report as **INFO**: "N archive pages found for [file] — historical data preserved"

## 9. File Integrity
- Count key files (agents, skills, etc. — project-specific)
- Check for orphaned files not in any index
- Run any project-specific grep checks from CLAUDE.md

## 9.5 Sidecar Index Freshness

For every `<source>.index.md` sidecar in the project (find with `find . -name "*.index.md" -not -path "*/node_modules/*" -not -path "*/.git/*"`):

1. Identify the matching source file (strip the `.index.md` suffix).
2. Get the source file's modification time: `git log -1 --format=%ci -- <source>` (preferred — survives clones) or filesystem mtime as a fallback.
3. For each row in the sidecar table, parse the `Last edit` date (dd/mm/yy).
4. **If the source file has been modified more recently than a row's `Last edit`**, add that row to a `📝 Possibly stale index entries` block in the report. Show: source file, sidecar path, row number, current description, last-edit date, source-file-modified date.

**Do NOT auto-rewrite.** This step is a suggestion only. Surface the row to the user and let them decide:

> 📝 **Possibly stale index entries** — these descriptions may be hand-crafted and still accurate. Only update them if the description is genuinely out of date with the code. The `Last edit` date alone is not proof of staleness — it's a hint that the row deserves a glance.

If `Last edit` parsing fails on a row (corrupt date, missing column, etc.), report it as **WARNING — sidecar row needs manual repair** and continue. Do not stop the audit.

## 9.6 Sidecar Parity

For every `<source>.index.md` sidecar found in 9.5, verify code ↔ sidecar parity:

1. Extract every section number from the source file's start markers (regex: `^\s*(\/\/|#|/\*|<!--|--)\s+([0-9]+(\.[0-9]+)*)`).
2. Extract every `#` value from column 1 of the sidecar table.
3. Compare:
   - **Sidecar row with no matching source marker** → `WARNING — orphan sidecar row [N.M.K] in <sidecar>`
   - **Source marker with no matching sidecar row** → `WARNING — missing sidecar row for [N.M.K] in <sidecar>`
4. Both pass → `INFO: <sidecar> in parity with <source>`.

This catches the most likely failure mode: a coding agent edited the source file (added or removed a numbered section) without updating the sidecar.

## Output Format

```
## Audit Report — [timestamp]

### Passing Checks
- [list of checks that passed]

### Issues Found

**Issue 1: [severity] — [description]**
- Details: [what's wrong]
- Fix: [what to do about it]

**Issue 2: [severity] — [description]**
- Details: [what's wrong]
- Fix: [what to do about it]

[...repeat for each issue independently...]
```

## 10. Save Report

Save the full audit report (exactly as displayed above) to:
`audits/YYYY-MM-DD_HHMMSS.md`

Create the `audits/` directory if it doesn't exist. The timestamp uses the current date/time. This creates a persistent audit trail that survives context loss and can be read by external tools.

### Issue Resolution Rules

1. Present EVERY issue independently — the user chooses which to fix or ignore
2. Severity levels: CRITICAL, WARNING, INFO
3. After the user responds, fix ONLY the issues they chose to fix
4. Ignored issues are NOT logged as failures — the user made a conscious choice
5. If there are zero issues, just show the passing checks and confirm "All clear"
