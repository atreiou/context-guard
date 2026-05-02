# Context Guard

**Persistent context protection for Claude Code projects.**

Stop losing work to rate limits, session restarts, and context rot. Context Guard gives Claude Code a memory system that survives across sessions — so every restart picks up exactly where you left off.

## The Problem

Claude Code sessions get cut off by rate limits, context compaction, and crashes. Each new session starts fresh with no memory of what happened before. Tasks get dropped, decisions get forgotten, and you waste time re-explaining your project.

This is a known issue. [Anthropic's own engineering team](https://www.anthropic.com/engineering/effective-harnesses-for-long-running-agents) documented the same failure modes and recommended external state files as the solution.

> **Note:** Context Guard is NOT the same as Claude Code's built-in "context compaction." Compaction is Claude Code's automatic process that compresses your conversation when it gets too long — it happens whether or not you have Context Guard installed. What Context Guard does is ensure that when compaction happens (or when you start a fresh session), nothing important gets lost. The `/start` command reads your safeguard files and rebuilds full context from them, so compaction becomes a non-event instead of a disaster.

## My Solution

Context Guard creates a set of safeguard files that persist across sessions, plus five slash commands:

- **`/start`** — Type this at the start of every session. Claude reads all safeguard files, cross-references recent plans against the task registry, flags any dropped or unexplained tasks, detects and commits orphaned work from crashed sessions, and summarises the project state. Works from parent directories — automatically locates your project's Context Guard files in subdirectories. One command, full recovery.

- **`/audit`** — Your personal safeguard. Call this at ANY moment to verify Claude's work. It runs a comprehensive integrity check across all files, plans, git state, and archived safeguard pages.

- **`/save`** — Mid-session checkpoint. Saves all progress to safeguard files, commits, and pushes. Automatically paginates safeguard files that have grown too large — archiving older content to keep context lean for future sessions. Use during long sessions or any time you want an explicit save point.

- **`/end`** — Optional session save point. When you're done for the day, type `/end` and Claude will update all safeguard files, paginate if needed, archive plans, commit, push (including to backup remotes if configured), and report a clean summary. Not required — `/start` handles recovery regardless — but useful when you want an explicit clean handoff.

- **`/itemise`** — Apply the Itemisation Protocol to your code files. Numbers sections, functions, and meaningful blocks so every part of the code is referenceable by address. Backs up files first, verifies nothing changed except the added numbers, then removes backups. Can be toggled off in `CLAUDE.md` for projects that don't want it.

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
2. Copy the `templates/` folder into your project root

### First Run

Open Claude Code in your project and type `/start`. On first run, it will:
1. Detect this is a new project (no safeguard files yet)
2. Ask for your project name and description
3. Create all safeguard files from the templates
4. Offer to run `/itemise` for numbered code addressing (optional)

From then on, `/start` reads your existing safeguard files and recovers full context — one command, full recovery.

### What Gets Created

| File | Purpose |
|------|---------|
| `CLAUDE.md` | Auto-read every session. Project rules and pointers to other files |
| `SESSION_LOG.md` | Running history of what happened each session. Auto-paginated when large |
| `TASK_REGISTRY.md` | Every task ever created, with status. Nothing gets dropped. Auto-paginated when large |
| `DECISIONS.md` | Architectural decisions register. The "why" behind every choice. Auto-paginated when large |
| `COMMENTS.md` | Your verbatim comments logged as a safety net. Auto-paginated when large |
| `FEATURE_LIST.json` | Pass/fail feature tracker (JSON — harder for LLMs to accidentally overwrite) |
| `plans/` | Archived plans from every session, cross-referenced by /start and /audit |
| `*_page*.md` | Auto-generated archive pages when safeguard files exceed 300 lines |

### What Gets Configured

| Component | Purpose |
|-----------|---------|
| `/start` skill | Session recovery — one command to restore full context |
| `/audit` skill | On-demand integrity check — verify Claude's work at any moment |
| `/save` skill | Mid-session checkpoint — update safeguard files, commit, push, and paginate |
| `/end` skill | Optional session save point — clean wrap-up with commit, push, and backup sync |
| `/itemise` skill | Itemisation Protocol — numbered code addressing with backup and integrity verification |
| Pre-commit hook | Reminds Claude to update safeguard files before every git commit |
| Pre-compaction hook | Automatically saves all progress before context compression — no data loss |

## How It Works

### Session Start (`/start`)

1. Locates Context Guard files — searches subdirectories up to 4 levels deep, so you can launch from a parent directory
2. Reads all current safeguard files (paginated archives are noted but not loaded — keeping context lean)
3. Checks git state — detects and commits orphaned work from crashed or overflowed sessions
4. Reads the last 3 archived plans **in full**
5. Cross-references every plan item against the task registry
6. Flags dropped tasks (in plan but not in registry) and unexplained tasks (in registry but no source)
7. Summarises everything and waits for your confirmation

### On-Demand Audit (`/audit`)

Everything `/start` does, plus:
- Checks for stale in-progress tasks
- Verifies decisions aren't contradicted
- Checks for unarchived plans
- File integrity checks
- Reports passing, warnings, and critical issues

### Session End (`/end`) — Optional

When you're ready to stop working, type `/end`. Claude will:
1. Review everything done this session
2. Update all safeguard files (session log, task registry, comments, decisions, features)
3. Paginate any safeguard files over 300 lines — archiving older content to keep future `/start` loads lean
4. Archive any unarchived plans
5. Commit and push all changes (including backup remotes if configured)
6. Verify clean git state
7. Report a summary of the session and what's pending for next time

This is entirely optional — `/start` will recover context regardless. But `/end` gives you a guaranteed clean save point.

### Mid-Session Checkpoint (`/save`)

A durable save point you can run at any time during a session. Claude will:
1. Check for any unlogged comments, tasks, or decisions
2. Update all safeguard files with current progress
3. Paginate any safeguard files over 300 lines — archiving older content automatically
4. Add a checkpoint marker to the session log with an "in flight" handoff note
5. Commit and push all changes
6. Confirm what was saved

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

**To disable:** set `ITEMISATION: disabled` in your project's `CLAUDE.md`. The `/itemise` command will halt before making any changes. Many developers won't want or need this protocol — the toggle is prominently placed at the top of the Itemisation Protocol section in `CLAUDE.md`.

**Safety:** `/itemise` creates `{filename}.itemise-backup` copies before touching anything, verifies integrity after (strips added comment-numbers and diffs against the backup to confirm no code changed), and restores from backup on any failure.

### Sidecar Indexing

Every itemised source file gets a paired `<source_filename>.index.md` sidecar — a compact table mapping each section number to a one-line description of what that block does:

```
# auth.js — Context Guard Sidecar Index
This file is interwoven with auth.js. Edit one, edit the other (see CLAUDE.md → Index Maintenance).

| #     | Description                                                  | Last edit |
|-------|--------------------------------------------------------------|-----------|
| 1     | Module imports and constants                                 | 02/05/26  |
| 2.1   | parseInput() — validates form data and trims whitespace      | 02/05/26  |
| 2.1.1 | rejects empty username                                       | 02/05/26  |
| 2.2   | hashPassword() — argon2id with project-default cost params   | 02/05/26  |
```

**Why this exists:** a number on its own (e.g. `2.1`) is a coordinate without a label. With the sidecar, an agent answering "where is the code that does X?" reads the small sidecar (cheap), picks the matching number, then greps the source for that number's start/end markers and reads only those bytes. Token usage scopes to exactly the relevant code instead of the whole file.

**The contract — non-optional:** the source file and the sidecar are a single artefact split into two formats for token economy. Editing the source without updating the sidecar (or vice versa) breaks the contract. The full rule lives in your project's `CLAUDE.md` under `## Index Maintenance`.

**Description quality on legacy codebases.** When `/itemise` runs on a file for the first time, it auto-generates descriptions only for sections under 50 lines. Anything 50 lines or longer is left as `_(blank — fill on first edit)_` — the next coding agent that touches the section fills it in. **This is a deliberate token-saving choice.** Auto-generated descriptions on long sections tend to flatten branching logic and miss edge cases; an inaccurate description costs more tokens (agents spend tokens fixing their own confusion) than no description. On large existing codebases, descriptions accumulate as real coding work happens — calibration scaffolding first, accuracy with each first-edit pass.

**Date format.** Sidecar `Last edit` dates use dd/mm/yy (UK format). All Context Guard skills write dates in this format going forward.

**Stale detection via `/audit`.** When a source file has been modified more recently than a sidecar row's `Last edit`, `/audit` surfaces the row under a `📝 Possibly stale index entries` block — as a *suggestion*, not an auto-fix. Hand-written descriptions are often still accurate even when the date is old; the human (or the next editing agent) owns the rewrite decision.


### Safeguard File Pagination

As projects grow, safeguard files accumulate history that eats into the context window on every `/start`. Context Guard handles this automatically — when any safeguard file exceeds 300 lines, `/save` and `/end` archive older content into numbered page files:

- `SESSION_LOG_page1.md`, `SESSION_LOG_page2.md`, etc.
- `TASK_REGISTRY_page1.md`, etc.

Each file type has its own archival strategy:

| File | What stays in the main file | What gets archived |
|------|---------------------------|-------------------|
| SESSION_LOG | Last 3 sessions | Older session entries |
| TASK_REGISTRY | All active tasks (pending/in-progress/blocked) + last 3 sessions of done tasks | Older completed tasks |
| DECISIONS | Active/unactioned decisions | Fully implemented decisions |
| COMMENTS | Unactioned project directives | Actioned comments and curiosity questions |

Archives are never deleted — they're available for reference via `/audit` or when explicitly requested. `/start` notes their existence but doesn't read them, keeping context lean for actual work.

### Automatic Pre-Compaction Save

When Claude Code is about to compress your conversation (context compaction), a `PreCompact` hook fires automatically and backs up all safeguard files to a timestamped `compaction-backups/` directory. This is a safety net — if safeguard files weren't fully up to date when compaction hit, the backup preserves the last known state.

Combined with the auto-checkpoint protocol (which keeps safeguard files current throughout the session), this means compaction is a non-event. Your progress is either already saved to the safeguard files, or captured in the backup.

### Pre-Commit Safety

Before every git commit, a hook reminds Claude to update:
- COMMENTS.md (any new user feedback)
- TASK_REGISTRY.md (any new or completed tasks)
- SESSION_LOG.md (if significant milestone)
- FEATURE_LIST.json (if feature status changed)
- plans/ (any unarchived plans)

## Git Conventions

Context Guard uses a tagging convention for human-readable git history:

```
S{session}-{sequence}_{short-description}
```

Examples: `S5-001_install-deps`, `S5-002_add-auth`, `S6-001_fix-login-bug`

## Design Principles

Context Guard was born from three years of practical experience fighting context rot across LLM-assisted projects. The approach — external state files, cross-referencing, and audit trails — was developed empirically before being validated by [Anthropic's own research on long-running agents](https://www.anthropic.com/engineering/effective-harnesses-for-long-running-agents) and the [Recursive Language Models paper](https://arxiv.org/abs/2512.24601) (MIT CSAIL). The core principles:

1. **External state over in-context memory** — files survive, context windows don't
2. **JSON for structured data** — LLMs are less likely to accidentally overwrite JSON than markdown
3. **Cross-referencing over trust** — verify plans against registries, don't assume tasks were completed
4. **Minimal context loading** — read current files only, archive old content automatically, fetch specifics only when needed
5. **User can audit at any time** — transparency and accountability built in
6. **Referenceable code** — every block has an address, LLMs don't need full file context to find it

## License

MIT
