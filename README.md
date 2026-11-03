# Context Guard

**Persistent context protection for AI coding agents.**

Stop losing work to rate limits, session restarts, and context rot. Context Guard gives your coding agent a memory system that survives across sessions, so every restart picks up exactly where you left off. It ships as Claude Code slash commands, and its files and rules work with any agent that can read an instruction file (Codex, for example, via AGENTS.md).

## The Problem

Coding agent sessions get cut off by rate limits, context compaction, and crashes. Each new session starts fresh with no memory of what happened before. Tasks get dropped, decisions get forgotten, and you waste time re-explaining your project.

This is a known issue. [Anthropic's own engineering team](https://www.anthropic.com/engineering/effective-harnesses-for-long-running-agents) documented the same failure modes and recommended external state files as the solution.

> **Note:** Context Guard is NOT the same as Claude Code's built-in "context compaction." Compaction is Claude Code's automatic process that compresses your conversation when it gets too long, and it happens whether or not you have Context Guard installed. What Context Guard does is ensure that when compaction happens (or when you start a fresh session), nothing important gets lost. The `/start` command reads your safeguard files and rebuilds full context from them, so compaction becomes a non-event instead of a disaster.

## My Solution

Context Guard creates a set of safeguard files that persist across sessions, all in one `context-guard/` folder, plus six slash commands. The files are written when you ask, with `/save` or `/end`, so the agent never spends your usage saving on its own; the one exception is the two lists, which stay current as work happens.

- **`/start`**: Type this at the start of every session. The agent reads your safeguard files, detects and commits orphaned work from crashed sessions, and summarises the project state. It reads the last five sessions' worth of content and nothing more: archives and plan files stay closed, so recovery costs a predictable, small number of tokens no matter how old the project is. Works from parent directories, automatically locating your project's Context Guard files in subdirectories. One command, full recovery.

- **`/audit`**: Your personal safeguard. Call this at ANY moment to verify the agent's work. It runs a comprehensive integrity check across all files, plans, git state, and archived safeguard pages.

- **`/save`**: Your save point, whenever you want one. Writes everything since the last save to the safeguard files, commits, and pushes, and writes an "in flight" handoff note so an interrupted session can be picked up mid-thought. Deliberately lightweight: it does not run the full archive rotation, because nothing has aged since the last one. Use during long sessions or any time you want an explicit save point.

- **`/end`**: Optional session save point. When you're done for the day, type `/end` and the agent will save every safeguard file in full, rotate anything older than five sessions into the archives, archive plans, commit, push (including to backup remotes if configured), and report a clean summary. Not required, since `/start` handles recovery regardless, but useful when you want an explicit clean handoff.

- **`/lessons`**: Optional end-of-session harvest. Most of what a debugging session learns is thrown away with the throwaway scripts that learned it. `/lessons` diffs this session's scratch scripts against each other, because the diff between version 2 and version 3 is a literal record of what the agent believed that turned out to be false, proposes each finding to you for approval, installs the approved ones as learned behaviours or helper functions, and only then clears the spent scripts away.

- **`/itemise`**: Apply the Itemisation Protocol to your code files. Numbers sections, functions, and meaningful blocks so every part of the code is referenceable by address. Backs up files first, verifies nothing changed except the added numbers, then removes backups. Can be toggled off in `CLAUDE.md` for projects that don't want it.

## Installation

### Option 1: One-Command Install

```bash
git clone https://github.com/atreiou/context-guard.git
cd context-guard
./install.sh /path/to/your/project
```

> **Windows users:** Run this in Git Bash or WSL, not PowerShell or CMD.

### Option 2: Manual Install

1. Copy the `.claude/` folder into your project root
2. Copy the `templates/` folder to `context-guard/templates/` in your project root

### First Run

Open your coding agent (Claude Code) in your project and type `/start`. On first run, it will:
1. Detect this is a new project (no safeguard files yet)
2. Ask for your project name and description
3. Create the `context-guard/` folder and all safeguard files in it from the templates
4. Offer to run `/itemise` for numbered code addressing (optional)

From then on, `/start` reads your existing safeguard files and recovers full context. One command, full recovery.

### What Gets Created

Everything goes in one `context-guard/` folder, so nothing of Context Guard's is scattered through your project root. `CLAUDE.md` is the one exception: it stays in the root, because that is where the agent reads it automatically.

| File | Purpose |
|------|---------|
| `CLAUDE.md` (project root) | Read automatically every session. Project rules and pointers to the other files |
| `context-guard/SESSION_LOG.md` | Running history of what happened each session. Rotated into the archive as it ages |
| `context-guard/TO_DO_LIST.md` | The to do list: every task not yet finished, read in full at every `/start`. Never rotated |
| `context-guard/DONE_LIST.md` | The done list: every finished task, newest first, with whether and how it was tested and its proof |
| `context-guard/DECISIONS.md` | Architectural decisions register. The "why" behind every choice |
| `context-guard/LEARNED_BEHAVIOUR.md` | Tactical knowledge: platform quirks and workarounds found the hard way |
| `context-guard/COMMENTS.md` | Your verbatim comments logged as a safety net |
| `context-guard/FEATURE_LIST.json` | Pass/fail feature tracker (JSON is harder for LLMs to accidentally overwrite) |
| `context-guard/RESUME_STATE.md` | What was in flight at the last `/save` |
| `context-guard/archive/` | Archive pages holding everything older than the last 5 sessions |
| `context-guard/plans/`, `audits/`, `backups/`, `templates/` | Archived plans, saved audit reports, automatic backups, and the templates the project was set up from |

### What Gets Configured

| Component | Purpose |
|-----------|---------|
| `/start` skill | Session recovery: one command to restore full context |
| `/audit` skill | On-demand integrity check: verify the agent's work at any moment |
| `/save` skill | Your save point: write the safeguard files and an in-flight handoff note, commit, push |
| `/end` skill | Optional session save point: clean wrap-up with archive rotation, commit, push, backup sync |
| `/lessons` skill | Turns a session's throwaway debug scripts into learned behaviours and helpers, then clears them |
| `/itemise` skill | Itemisation Protocol: numbered code addressing with backup and integrity verification |
| List checker | `.claude/tools/registry_check.js`: confirms the two lists follow their rules, run by `/start`, `/save`, `/end` and `/audit` (needs Node.js) |
| Pre-commit hook | Reminds the agent before every git commit that the two lists must be current |
| Pre-compaction hook | Copies all eight safeguard files before context compression and checks every copy, so nothing is lost |

## How It Works

### Session Start (`/start`)

1. Locates the `context-guard/` folder, in the project or one level down, so you can launch from a parent directory (older layouts are still found until the project is upgraded)
2. Reads the current safeguard files: the last five sessions of history, the one-line indexes of everything archived, and the whole to do list
3. Checks git state, detecting and committing orphaned work from crashed or overflowed sessions
4. Runs the list checker and gives you its line: `To do: N (W waiting on user)`
5. Summarises everything and waits for your confirmation

**What `/start` deliberately does NOT read:** archive pages, and plan files. Both are expensive and rarely needed at the moment a session opens. The archive indexes tell the agent what exists, and `RESUME_STATE.md` names the exact plan file and section the first task needs, so the relevant material gets opened when the work starts rather than before it. The full plan-versus-registry sweep, which catches dropped and unexplained tasks across every plan and every archive, lives in `/audit`, where it reads *all* plans rather than a sample.

### On-Demand Audit (`/audit`)

Everything `/start` does, plus:
- Checks for stale in-progress tasks
- Verifies decisions aren't contradicted
- Checks for unarchived plans
- File integrity checks
- Reports passing, warnings, and critical issues

### Session End (`/end`), optional

When you're ready to stop working, type `/end`. The agent will:
1. Review everything done this session
2. Save every safeguard file in full (session log, comments, decisions, learned behaviour, features), and confirm with the checker that both lists are correct
3. Rotate every ledger except the to do list: anything older than the last five sessions moves into an archive page, leaving a one-line index entry behind
4. Archive any unarchived plans
5. Commit and push carefully: only the current branch and its own tag, after checking the remote for divergence, never forced
6. Verify clean git state
7. Report a summary of the session and what's pending for next time

This is entirely optional, since `/start` will recover context regardless. But `/end` gives you a guaranteed clean save point.

### Mid-Session Save (`/save`)

The safeguard files are written only when you ask. Agents left to themselves save constantly, which spends usage for nothing; `/save` puts that under your control. Between saves only the two lists change, as tasks are created and finished. When you run `/save`, the agent will:
1. Go back through the conversation for every comment, task, decision, or credential since the last save
2. Write all of it to the safeguard files
3. Add a save marker to the session log with an "in flight" handoff note
4. Commit and push carefully
5. Confirm what was saved

`/save` skips the archive rotation on purpose. Running the full pass on every save costs context and archives nothing new, because no content has aged since the last one. Rotation is `/end`'s job; `/save` only touches a ledger that has visibly overgrown its window.

Use it when a session is running long, before a risky operation, or any time you want peace of mind.

### Itemisation Protocol (`/itemise`)

The Itemisation Protocol adds hierarchical section numbers to code files, making every block referenceable by address. Instead of loading an entire file into context, you can say "check section 2.3.1" and point directly to the relevant code.

Numbers are added as comments using the correct syntax for each language:

```php
// 1. SECTION: Enqueue Scripts and Styles

// 1.1 Enqueue parent theme stylesheet
add_action('wp_enqueue_scripts', function() {
    wp_enqueue_style('parent-style', get_template_directory_uri() . '/style.css');
});
// end of 1.1

// 1.2 Conditional enqueue for calendar assets
add_action('wp_enqueue_scripts', function() {
    if (is_page('book-now') || is_page('booking-confirmation')) {
        wp_enqueue_style('app-calendar', get_stylesheet_directory_uri() . '/app-calendar.css');
        wp_enqueue_script('app-calendar-js', get_stylesheet_directory_uri() . '/app-calendar.js', [], null, true);

        // 1.2.1 Localise script with AJAX URL, nonce, and slot config
        wp_localize_script('app-calendar-js', 'appData', array(
            'ajaxUrl'    => admin_url('admin-ajax.php'),
            'nonce'      => wp_create_nonce('app_booking_nonce'),
            // 1.2.1.1 Slot config: array of {label, start_h, start_m, end_h, end_m} objects
            'slotConfig' => get_slot_config(),
        ));
    }
});
// end of 1.2

// end of 1
```

**What gets numbered:** sections, functions, significant conditionals, important loops, key config objects.
**What doesn't:** variable declarations, single-line assignments, imports, trivial boilerplate.
**Depth:** aim for 3 levels (`1.2.3`) in most cases, 4 only for genuinely complex nested config.

**To disable:** set `ITEMISATION: disabled` in your project's `CLAUDE.md`. The `/itemise` command will halt before making any changes. Many developers won't want or need this protocol, so the toggle is prominently placed at the top of the Itemisation Protocol section in `CLAUDE.md`.

**Safety:** `/itemise` creates `{filename}.itemise-backup` copies before touching anything, verifies integrity after (strips added comment-numbers and diffs against the backup to confirm no code changed), and restores from backup on any failure.

### Sidecar Indexing

Every itemised source file gets a paired `<source_filename>.index.md` sidecar: a compact table mapping each section number to a one-line description of what that block does:

```
# auth.js: Context Guard Sidecar Index
This file is interwoven with auth.js. Edit one, edit the other (see CLAUDE.md → Index Maintenance).

| #     | Description                                                  | Last edit |
|-------|--------------------------------------------------------------|-----------|
| 1     | Module imports and constants                                 | 02/05/26  |
| 2.1   | parseInput(): validates form data and trims whitespace     | 02/05/26  |
| 2.1.1 | rejects empty username                                       | 02/05/26  |
| 2.2   | hashPassword(): argon2id with project-default cost params  | 02/05/26  |
```

**Why this exists:** a number on its own (e.g. `2.1`) is a coordinate without a label. With the sidecar, an agent answering "where is the code that does X?" reads the small sidecar (cheap), picks the matching number, then greps the source for that number's start/end markers and reads only those bytes. Token usage scopes to exactly the relevant code instead of the whole file.

**The contract, non-optional:** the source file and the sidecar are a single artefact split into two formats for token economy. Editing the source without updating the sidecar (or vice versa) breaks the contract. The full rule lives in your project's `CLAUDE.md` under `## Index Maintenance`.

**Description quality on legacy codebases.** When `/itemise` runs on a file for the first time, it auto-generates descriptions only for sections under 50 lines. Anything 50 lines or longer is left as `_(blank, fill on first edit)_`, and the next coding agent that touches the section fills it in. **This is a deliberate token-saving choice.** Auto-generated descriptions on long sections tend to flatten branching logic and miss edge cases; an inaccurate description costs more tokens (agents spend tokens fixing their own confusion) than no description. On large existing codebases, descriptions accumulate as real coding work happens: calibration scaffolding first, accuracy with each first-edit pass.

**Date format.** Sidecar `Last edit` dates use dd/mm/yy (UK format). All Context Guard skills write dates in this format going forward.

**Stale detection via `/audit`.** When a source file has been modified more recently than a sidecar row's `Last edit`, `/audit` surfaces the row under a `📝 Possibly stale index entries` block as a *suggestion*, not an auto-fix. Hand-written descriptions are often still accurate even when the date is old; the human (or the next editing agent) owns the rewrite decision.


### Ledger Rotation: the 5-session rule

As projects grow, safeguard files accumulate history that eats into the context window on every `/start`. Context Guard bounds this: **every ledger's main file holds only the last five sessions' content.** Everything older moves, verbatim, into numbered archive pages in `context-guard/archive/` (`SESSION_LOG_page1.md`, `DECISIONS_page2.md`, and so on), which are append-only and never deleted. The to do list is the one exception.

`/end` runs the rotation every session, using the full session context it has right there to make the archival calls well.

| File | What stays in the main file | What gets archived |
|------|---------------------------|-------------------|
| SESSION_LOG | Last 5 sessions | Older session entries |
| TASK_REGISTRY (the to do list) | Every task not yet finished, however old | Nothing, ever |
| DONE_LIST | The newest 500 finished tasks | Older finished tasks, once the file passes 500 rows |
| DECISIONS | Last 5 sessions of decisions, **plus a one-line index of every archived decision** | Older decisions, full text |
| LEARNED_BEHAVIOUR | Last 5 sessions of entries, **plus a one-line index of every archived entry** | Older entries, full text |
| COMMENTS | Unactioned project directives | Actioned comments and curiosity questions |

**The archive index is what makes this safe.** When a decision is moved out, a single line stays behind in the main file giving its ID, title, category, and which page holds it:

```
D-042: Sigil images are WebP-only [active-constraint] → archive/DECISIONS_page3.md
```

**Archiving a decision does not revoke it.** A `forever-active` or `active-constraint` decision governs from the archive exactly as it did from the main file. The index is how a future session finds it: `/start` reads the index, and if a line touches the work about to be done, the agent opens that one archive entry at that point.

Without the index, the only way to keep a binding rule discoverable was to never archive it, which meant DECISIONS.md grew without limit until it swallowed the context window at every session start. With it, the main file stays small and nothing stops applying.

**Pending tasks are never rotated at all.** An unfinished task stays on the to do list until it finishes, however old it is. Rotating open tasks into backlog sections is how they get lost: the sections fill up, no session reads them, and work that was finished elsewhere is never closed on its own row. See [Two Task Lists](#two-task-lists-live-and-completed) below.

`/audit` also verifies index integrity in both directions: an entry sitting in an archive with no index line is a **lost rule**, and an index line pointing at an entry that is not there is a **broken pointer**. Both are reported as critical.

### Two Task Lists: the to do list and the done list

Every project keeps exactly two lists, and no task is kept anywhere else.

| List | File | Holds | Columns |
|------|------|-------|---------|
| the to do list | `TO_DO_LIST.md` | Every task not yet finished | `ID \| Task \| Status \| Updated \| Notes` |
| the done list | `DONE_LIST.md` | Every finished task, newest at the top | `ID \| Task \| Outcome \| Tested \| Proof` |

- **Status** starts with `PENDING`, `IN PROGRESS` or `WAITING ON USER`, then one sentence of what is left. **Updated** is the session and date the row was last checked against the evidence.
- **Outcome** is `DONE`, `SUPERSEDED` (by a named task) or `DROPPED` (only with the user's own words quoted), with a date. **Tested** is `TESTED BY USER`, `TESTED INDEPENDENTLY`, `BUILDER ONLY` or `NOT TESTED`, with where the record is. **Proof** is a path or a commit.
- **The moment a task finishes**, its row comes off the to do list and goes to the top of the done list, in that same turn. Nothing is saved up for `/end`.
- **The done list is also the tested list.** Something already proved there is not retested unless its files have changed since.
- **A handover's tasks are merged into the to do list**, so there is only ever one list of pending tasks; the handover itself still stands for everything else it explains.
- **`/start` reads only the to do list, all of it. `/save` and `/end` confirm both lists are correct** with the checker, `.claude/tools/registry_check.js`, which flags a status outside the three words, a row not re-checked for two sessions, a task row outside the two tables, a DONE with no proof, a DROPPED with no quote, the done list out of date order, and the same task on both lists.

**Upgrading an existing project.** A project installed before these changes keeps its files where they were and has one `TO_DO_LIST.md`. `/start` notices and asks whether to upgrade straight away or wait. The upgrade follows `templates/UPGRADE.md`: it moves every Context Guard file into the `context-guard/` folder (archive pages into `archive/`), then builds the two lists, keeping the old list whole in an archive page and checking every row against the evidence before it is placed, because a row in the old list may say pending when the work was finished and recorded somewhere else.

### Automatic Pre-Compaction Backup

When the agent's conversation is about to be compressed (context compaction), a `PreCompact` hook fires automatically and copies all eight safeguard files, LEARNED_BEHAVIOUR.md and RESUME_STATE.md included, into a dated folder in `context-guard/backups/`. It checks every copy against its original, byte for byte, and reports success only when all of them match; a failed copy is reported as a failure, never as a backup. It only copies files, so it costs no usage.

### Pre-Commit Reminder

Before every git commit, a hook reminds the agent that the two lists must already be current: every new task on the to do list, every finished one moved to the top of the done list. It asks for nothing else, because the other safeguard files wait for `/save` and `/end`.

## Git Conventions

Context Guard uses a tagging convention for human-readable git history:

```
S{session}-{sequence}_{short-description}
```

Examples: `S5-001_install-deps`, `S5-002_add-auth`, `S6-001_fix-login-bug`

## Design Principles

Context Guard was born from three years of practical experience fighting context rot across LLM-assisted projects. The approach, built on external state files, cross-referencing and audit trails, was developed empirically before being validated by [Anthropic's own research on long-running agents](https://www.anthropic.com/engineering/effective-harnesses-for-long-running-agents) and the [Recursive Language Models paper](https://arxiv.org/abs/2512.24601) (MIT CSAIL). The core principles:

1. **External state over in-context memory.** Files survive, context windows don't
2. **JSON for structured data.** LLMs are less likely to accidentally overwrite JSON than markdown
3. **Cross-referencing over trust.** Verify plans against registries, don't assume tasks were completed
4. **Minimal context loading.** Read current files only, archive old content automatically, fetch specifics only when needed
5. **User can audit at any time.** Transparency and accountability built in
6. **Referenceable code.** Every block has an address, and LLMs don't need full file context to find it

## License

MIT
