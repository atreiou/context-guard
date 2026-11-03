---
description: "Type /audit to verify project integrity. Checks all safeguard files, git state, uncommitted work, plan cross-references, archive index integrity, and the two task lists."
allowed-tools: Read, Grep, Glob, Bash, Write
---

# Context Guard: Project Audit (/audit)

**IMPORTANT: The user is auditing your work. Every task must be traceable back to a plan, a decision, or a user comment. Unexplained work WILL be flagged.**

Execute ALL checks below and report findings.

## 0. Locate CCG Root

Safeguard files may not be in the current working directory; they could be in a subdirectory. Find them first.

0. **Check for a pointer file first:** if `CCG_LOCATION.md` exists at the working-directory root, it names CCG_ROOT directly. Trust it and skip the search below.
1. **Check the working directory:** Try to read `CLAUDE.md` in the current directory.
2. **If not found, search subdirectories:**
   ```bash
   find . -maxdepth 4 -name "CLAUDE.md" -type f 2>/dev/null | head -10
   ```
3. **Filter:** For each result, check it contains `TASK_REGISTRY.md` (confirms it's a Context Guard CLAUDE.md) and does NOT contain `{PROJECT_NAME}` (uninitialized template).
4. **Set CCG_ROOT:** Use the directory of the valid CLAUDE.md found. If multiple, ask the user. If none, warn: "No Context Guard files found. Run /start first."

**All file paths in subsequent steps are relative to CCG_ROOT.** Git operations should also run from CCG_ROOT if it differs from the working directory.

## 1. Git State
- Run `git status`. Any uncommitted or untracked files?
- Run `git log --oneline -5` for recent commits with tags
- Run `git log origin/main..HEAD --oneline`. Any unpushed commits?
- **CRITICAL** if anything is uncommitted or unpushed

## 2. Task Lists Integrity
- Run the checker: `node .claude/tools/registry_check.js --root "<CCG_ROOT>"`
- Report its first line, and every row it flags as a **WARNING** (a row outside the two tables, or the same ID on both lists, is **CRITICAL**: a task is being tracked in two places or none)
- Count LIVE rows by status (PENDING / IN PROGRESS / WAITING ON USER) and COMPLETED rows by Outcome and by Tested
- Check for stale IN PROGRESS rows (started but never finished)
- Check that no other safeguard file is keeping its own list of open tasks (a "pending" or "backlog" table in SESSION_LOG, RESUME_STATE or a handover that is not also on LIVE) = **WARNING, second task list**
- Cross-reference with `FEATURE_LIST.json`. Any features without tasks?
- **Old single list** (exit code 2, no `TASK_REGISTRY_COMPLETED.md`): report as **INFO**, "the two-list build is still waiting on the user", and audit the old file as it stands

## 3. Plan Cross-Reference
- Read ALL plan files from `plans/` directory
- For EVERY task/step in every plan, verify it is on LIVE or COMPLETED
- If a task from a plan is on neither, **check the archive pages** (`TASK_REGISTRY_COMPLETED_page*.md`, and `TASK_REGISTRY_page*.md` from before the two lists) before flagging, since it may have been completed and archived
- Flag: tasks in plans on neither list AND NOT in any archive = **DROPPED TASK (CRITICAL)**
- Flag: tasks on either list with no plan, decision, or comment source = **UNEXPLAINED TASK**

## 4. User Comments
- Read `COMMENTS.md`
- Check for unactioned comments (no corresponding decision, task, or file change)
- Flag unactioned comments as **NEEDS ATTENTION**

## 5. Decisions Register
- Read `DECISIONS.md`
- Verify decision count
- Check for contradictions between decisions
- **Classification sanity check:** flag any decision missing a `Category:` field. Valid values: `forever-active`, `active-constraint`, `feature-specific`, `superseded`. Report missing categories as **WARNING: needs classification**.
- **Cross-reference check:** for any decision with an `Affects:` field listing task IDs, verify those tasks exist on LIVE, on COMPLETED, or in an archive page. Stale task references = **INFO: update the Affects field**.

## 5.5 Archive Index Integrity

Rotation moves decisions and learned behaviours out of the main files and leaves a one-line index entry behind. Those index lines are the ONLY way a future session finds an archived rule, so a missing line is a silently lost rule, which is exactly the failure this audit exists to catch.

For DECISIONS and LEARNED_BEHAVIOUR:
- Enumerate every entry ID in the `_page*.md` archives.
- Enumerate every ID listed in the main file's `## Index of archived decisions` / `## Index of archived LBs`.
- **In an archive but NOT in the index** = **CRITICAL, LOST RULE.** The entry exists but nothing points at it; no future session will ever find it. Report the ID, the page it is on, and its category.
- **In the index but NOT in any archive** = **CRITICAL, BROKEN POINTER.** The index promises an entry that is not there. It was either deleted or never moved.
- **Listed on the wrong page** = **WARNING, stale pointer.** The entry exists, but the index names a page it is not on.
- **Duplicated**: the same ID in both the main file and an archive = **WARNING, double entry.** Two copies drift; say which is which.

Also check that no ID is missing from the sequence across main file + all archives. A gap in `D-041, D-043` means D-042 was deleted rather than archived. Report as **CRITICAL, DELETED DECISION**.

## 6. Session Log
- Read `SESSION_LOG.md`
- Verify current session is logged
- Check last entry matches what actually happened

## 7. Unarchived Plans
- Check `~/.claude/plans/` for any plan files not yet copied to `plans/`
- **`~/.claude/plans/` is SHARED across all projects.** To identify which plans belong to this project:
  - For each `.md` file (excluding `-agent-` files which are sub-agent plans):
    - Read the first ~500 characters
    - If the content contains the current project name (from CLAUDE.md), OR contains file paths matching this project's directory structure, it belongs to this project.
    - If the content references a different project name, skip it.
    - If ambiguous, skip it. Do not flag plans you can't confidently attribute.
- Flag matched unarchived plans as **NEEDS ARCHIVING**
- Ignore plans from other projects entirely. Do NOT report them.

## 8. Safeguard File Existence
- Verify ALL safeguard files exist at their expected paths and are non-empty:
  - `CLAUDE.md`
  - `RESUME_STATE.md`
  - `SESSION_LOG.md`
  - `TASK_REGISTRY.md`
  - `TASK_REGISTRY_COMPLETED.md` (absent only in a project still on the old single list, which section 2 reports)
  - `DECISIONS.md`
  - `LEARNED_BEHAVIOUR.md`
  - `COMMENTS.md`
  - `FEATURE_LIST.json`
- **CRITICAL** if any file is missing or empty
- **RESUME_STATE.md integrity:** If `Clean save: false` but the last session has a `## Session` entry in SESSION_LOG.md, something is inconsistent. Flag as **WARNING**.
- Check for archive page files (`*_page*.md`). If they exist:
  - Verify each has a valid header (file name, page number, session/entry range)
  - Report as **INFO**: "N archive pages found for [file], historical data preserved"

## 9. File Integrity
- Count key files (agents, skills, and so on, which are project-specific)
- Check for orphaned files not in any index
- Run any project-specific grep checks from CLAUDE.md

## 9.5 Sidecar Index Freshness

For every `<source>.index.md` sidecar in the project (find with `find . -name "*.index.md" -not -path "*/node_modules/*" -not -path "*/.git/*"`):

1. Identify the matching source file (strip the `.index.md` suffix).
2. Get the source file's modification time: `git log -1 --format=%ci -- <source>` (preferred, because it survives clones) or filesystem mtime as a fallback.
3. For each row in the sidecar table, parse the `Last edit` date (dd/mm/yy).
4. **If the source file has been modified more recently than a row's `Last edit`**, add that row to a `📝 Possibly stale index entries` block in the report. Show: source file, sidecar path, row number, current description, last-edit date, source-file-modified date.

**Do NOT auto-rewrite.** This step is a suggestion only. Surface the row to the user and let them decide:

> 📝 **Possibly stale index entries.** These descriptions may be hand-crafted and still accurate. Only update them if the description is genuinely out of date with the code. The `Last edit` date alone is not proof of staleness; it's a hint that the row deserves a glance.

If `Last edit` parsing fails on a row (corrupt date, missing column, etc.), report it as **WARNING: sidecar row needs manual repair** and continue. Do not stop the audit.

## 9.6 Sidecar Parity

For every `<source>.index.md` sidecar found in 9.5, verify code ↔ sidecar parity:

1. Extract every section number from the source file's start markers (regex: `^\s*(\/\/|#|/\*|<!--|--)\s+([0-9]+(\.[0-9]+)*)`).
2. Extract every `#` value from column 1 of the sidecar table.
3. Compare:
   - **Sidecar row with no matching source marker** → `WARNING: orphan sidecar row [N.M.K] in <sidecar>`
   - **Source marker with no matching sidecar row** → `WARNING: missing sidecar row for [N.M.K] in <sidecar>`
4. Both pass → `INFO: <sidecar> in parity with <source>`.

This catches the most likely failure mode: a coding agent edited the source file (added or removed a numbered section) without updating the sidecar.

## Output Format

```
## Audit Report: [timestamp]

### Passing Checks
- [list of checks that passed]

### Issues Found

**Issue 1: [severity]. [description]**
- Details: [what's wrong]
- Fix: [what to do about it]

**Issue 2: [severity]. [description]**
- Details: [what's wrong]
- Fix: [what to do about it]

[...repeat for each issue independently...]
```

## 10. Save Report

Save the full audit report (exactly as displayed above) to:
`audits/YYYY-MM-DD_HHMMSS.md`

Create the `audits/` directory if it doesn't exist. The timestamp uses the current date/time. This creates a persistent audit trail that survives context loss and can be read by external tools.

### Issue Resolution Rules

1. Present EVERY issue independently, so the user chooses which to fix or ignore
2. Severity levels: CRITICAL, WARNING, INFO
3. After the user responds, fix ONLY the issues they chose to fix
4. Ignored issues are NOT logged as failures, because the user made a conscious choice
5. If there are zero issues, just show the passing checks and confirm "All clear"
