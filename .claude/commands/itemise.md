---
description: "Type /itemise to number every section, function, and block in your code files so each part is referenceable by address. Creates backups before modifying, verifies integrity after, deletes backups on success."
allowed-tools: Read, Grep, Glob, Bash, Edit, Write
---

# Context Guard — Itemisation Protocol (/itemise)

Applies hierarchical section numbering to code files so every block is referenceable by address (e.g. "check section 2.3.1"). Backs up files first, applies numbering, verifies nothing changed except the added comment numbers, then removes backups.

## Step 0: Check the Toggle

Locate `CLAUDE.md` — check the current directory first, then search subdirectories (`find . -maxdepth 4 -name "CLAUDE.md" -type f`) if not found. Use the one that contains `TASK_REGISTRY.md` (confirms it's a Context Guard CLAUDE.md). Look for a line that starts with `ITEMISATION:`.

- If it says `ITEMISATION: disabled` — stop here. Inform the user: "Itemisation Protocol is disabled. Change `ITEMISATION: disabled` to `ITEMISATION: enabled` in CLAUDE.md to activate it."
- If it says `ITEMISATION: enabled` or the setting is absent — proceed.

## Step 1: Confirm Scope

Ask the user:
> "Which files or directories should I itemise? I'll process all code files by default (`.py`, `.js`, `.ts`, `.tsx`, `.jsx`, `.php`, `.java`, `.cs`, `.go`, `.rb`, `.sh`), excluding `node_modules/`, `vendor/`, `dist/`, `build/`, `.git/`. Or name specific files or folders."

Wait for their answer. Then list the exact files you will process and ask them to confirm before touching anything.

## Step 2: Check for Existing Itemisation

Before creating backups, scan each file for lines matching the pattern `// N.` or `# N.` (itemisation numbers). If any file already has itemisation numbers:

- **If the user invoked `/itemise force`:** skip this warning entirely. Proceed with re-itemisation without prompting.
- **Otherwise:** warn the user: "This file appears to already be itemised. Re-running will renumber everything from scratch." Ask if they want to continue or skip that file.

## Step 3: Create Backups

For each file to be processed, create a backup:

```bash
cp "{filename}" "{filename}.itemise-backup"
```

Report: "Backups created for N files."

**CRLF note (Windows):** The Edit tool outputs LF line endings, but the backup preserves the file's original line endings (which may be CRLF on Windows). The verification command in Step 5 normalises line endings with `tr -d '\r'` on both sides to prevent false diff failures. No manual intervention is needed, but be aware that after itemisation, the file will have LF endings even if it originally had CRLF.

## Step 4: Apply Itemisation

**MANDATORY: Use the Edit tool to insert itemisation comments, NOT the Write tool.**

**DO NOT reorganise, move, reorder, or restructure any code during itemisation.** Itemisation is a labelling pass only. Number the code in the order it already appears. If the code would make more logical sense in a different order, that is a separate refactoring task — never combine it with itemisation. Attempting to move functions between sections while inserting labels is how code gets duplicated or corrupted.

Process each file one at a time. Read the file in full first, then plan all the itemisation labels and end markers you will add. Apply them using **only the Edit tool** — one insertion at a time (or in small batches where edits don't overlap). This ensures every existing character in the file is structurally preserved; you are only ever inserting new lines, never rewriting the file.

**Why Edit, not Write:** When the Write tool rewrites an entire file, it is easy to accidentally merge, paraphrase, or drop existing comments. The Edit tool makes this structurally impossible — if the `old_string` matches, the surrounding content is untouched. *(Validated in Session 1: Write caused comment merging and content loss; Edit eliminated all such failures.)*

**Workflow per file:**
1. Read the file in full
2. Decide where each itemisation label and end marker goes
3. Use Edit to insert each label/marker. The `old_string` should be the existing line(s) at the insertion point, and `new_string` should be those same lines with the new comment line(s) prepended or appended. Never omit any part of `old_string` from `new_string`.
4. Check for cross-references: if the section body calls a function/method defined in another numbered section of the same file, append `[calls: N.M]` to the marker (e.g. `// 3.2 handlePayment() [calls: 1.1, 2.3]`)
5. After all edits, proceed to Step 5 (verification)

### Large File Handling (500+ lines)

Files over 500 lines MUST be delegated to a sub-agent. Direct editing of large files is error-prone when there are 30+ insertion points — Session 1 confirmed this when `config.py` was corrupted by a mismatched edit boundary.

**Sub-agent workflow:**
1. Read the file in full and determine all insertion points (label text + target line)
2. Launch a sub-agent (using the Agent tool) with these strict instructions:
   - "Apply itemisation comments to {filename} using ONLY the Edit tool"
   - "Insert these specific labels at these specific locations: [provide the full list]"
   - "Work bottom-to-top to avoid line number shifts"
   - "Do NOT use Write. Do NOT modify any existing code or comments."
3. After the sub-agent completes, proceed to Step 5 verification as normal
4. If the sub-agent fails (rate limit, timeout), log remaining insertions and retry

For files under 500 lines, proceed with direct editing as described above.

Use the correct comment syntax for the language:

| Language | Comment syntax |
|----------|---------------|
| JS, TS, JSX, TSX, PHP, Java, C#, Go | `// N. Description` |
| Python, Ruby, Shell, YAML | `# N. Description` |
| HTML, XML, Vue (template blocks) | `<!-- N. Description -->` |
| CSS, SCSS, Less | `/* N. Description */` |
| SQL | `-- N. Description` |

### The Numbering Rules

**The principle: one job, one address.** Itemisation is a navigation tool. Its value is proportional to how precisely it can land you on the relevant lines. Every distinct piece of code that does one specific thing — every concern a user might point at and ask "where's the code that does X?" — gets its own referenceable number.

The test for any numbered block is simple: *if a user asked "where's the code that does X?", could you send them to this number, or would you have to direct them to a sub-part?* If you'd have to direct them inside, the block is too coarse — sub-number it. The unit-of-work differs by language (functions in JS/PHP, selector blocks in CSS, statements in SQL) but the principle is universal: one job, one address.

**Number these:**

- **Top-level sections** — logical groups of related code. Use a `SECTION:` label:
  ```
  // 1. SECTION: Authentication
  ...
  // end of 1
  ```
- **Functions and methods** — each significant function body:
  ```
  // 1.1 validateToken()
  function validateToken(request) { ... }
  // end of 1.1
  ```
- **Significant conditionals** — if/else or switch blocks with meaningful business logic (not trivial single-line guards):
  ```
  // 1.1.1 Return 401 if no auth header present
  if (!authHeader) { return error('no_auth') }
  ```
- **Important loops** — for/while/foreach with non-trivial bodies:
  ```
  // 1.2.1 Process each booking slot
  for (const slot of slots) { ... }
  ```
- **Key configuration objects** — important arrays or objects passed to significant calls:
  ```
  // 1.3.2 Localise script with AJAX URL, nonce, and slot config
  wp_localize_script('calendar-js', 'data', array( ... ));
  ```
- **Notable parameters within those** — only when the parameter itself is complex or calls a function:
  ```
  // 1.3.2.1 Slot config: array of {label, start_h, start_m, end_h, end_m} objects
  'slotConfig' => getSlotConfig(),
  ```

**Do NOT number these:**

- Individual variable declarations (`$count = 0;`, `let name = 'Alice';`)
- Single-line assignments
- Simple imports, requires, includes, use statements
- Closing braces or trivial boilerplate
- Lines that are already explained by their parent block's label

### Calibration: matching granularity to the unit of work

The trap is treating "block" as a structural concept (a chunk of code between blank lines) rather than a semantic one (a piece of code that does one job). A 50-line function that does one job is ONE number; five sibling 10-line functions are FIVE numbers, because each does its own job.

**Number ONCE — these all do one job:**
- A 50-line function that handles one operation end-to-end → one number
- A config array passed as a single argument to one call → one number
- A `switch` block where every case is a variation of the same dispatch → one number (sub-number only the genuinely distinct cases)
- Comma-grouped CSS selectors sharing one body (`.btn-primary, .btn-secondary { ... }`) → one number

**Number MULTIPLE times — each piece does its own job:**
- A class with 5 methods → 1 number for the class, 5 sub-numbers for the methods
- A 30-line region containing 3 distinct CSS selector groups (`.header`, `.nav`, `.footer`) → 3 numbers, one per selector — each affects a different part of the page
- A helper function and the main function it serves living adjacent → 2 numbers, because they do different jobs even if related
- A file's top-level structure: imports section, type definitions, exported functions, internal helpers → numbers per logical group, not per line

**Anti-patterns — these defeat the purpose:**
- Numbering every line of code (addresses become noise; nothing is referenceable because everything is referenceable)
- Numbering every variable declaration
- Numbering every closing brace
- Putting multiple unrelated rule blocks under a single number to keep the count low — this is the failure mode the protocol exists to prevent

When in doubt, prefer more granular over less. An over-numbered block is easy to consolidate later; an under-numbered block requires re-itemisation to fix.

### Per-language guidance

The "one job, one address" principle is universal but the unit-of-work differs by language:

**Function-oriented languages** (JS, TS, PHP, Python, Ruby, Java, C#, Go): the unit is the function/method. Each significant function gets its own number. Classes are a parent number with sub-numbers per method.

**CSS, SCSS, Less:** the unit is the selector block.
- Every distinct selector group gets its own number — `.header { ... }` and `.nav { ... }` are TWO numbers, even if they sit adjacent in the file.
- Pseudo-states (`:hover`, `:focus`, `:before`, `:after`, etc.) get their own numbers — a hover state is a different visual job than the base.
- `@media` queries get their own numbers — they describe a separate behavioural context.
- Comma-grouped selectors sharing one body (`.btn-primary, .btn-secondary { ... }`) are ONE number, because they describe one shared job.

**HTML, XML, Vue templates:** the unit is the component/region. Number significant structural regions and reusable component definitions; do not number every element.

**SQL:** the unit is the statement or CTE. Number each top-level statement and each named CTE within a query.

### Numbering Depth

- Aim for 3 levels of depth (`1.2.3`) in most cases
- Only go to 4 levels (`1.2.3.1`) for genuinely complex nested configuration
- If you find yourself writing `1.2.3.4.5`, the code probably needs refactoring, not more numbers
- Number within a block sequentially — if 1.2 contains three notable sub-items, they are 1.2.1, 1.2.2, 1.2.3

### End Markers

Add `// end of N` markers for:
- Every top-level section (`// end of 1`)
- Every named function/method (`// end of 1.1`)
- Every significant conditional or loop that spans more than a few lines (`// end of 1.1.2`)

Skip end markers on very short blocks (2–3 lines) where the closing brace makes the boundary obvious.

**CSS exception:** end markers are required for every numbered CSS block, even short ones. CSS closing braces don't bind to a function or class name, so navigating to the end of section `1.4.2` requires counting braces. Explicit end markers (`/* end of 1.4.2 */`) make boundaries unambiguous.

### Preserving Existing Comments

CRITICAL: Itemisation ONLY ADDS new comment lines. It NEVER removes, replaces, or rewrites existing comments or code.

- If a code block already has a comment above it, add the itemisation label on a NEW line above the existing comment
- If a line has an inline comment, leave it untouched
- The itemisation label and the original comment are separate concerns — both must appear in the output
- **NEVER use the Write tool to apply itemisation.** The Edit tool is mandatory (see Step 4). Write rewrites the entire file and makes it easy to accidentally merge or drop existing comments. Edit structurally prevents this.

**The most common mistake:** seeing an existing comment like `# Copy skills` and "absorbing" it into the itemisation label as `# 4.1 Copy skills`, dropping the original line. This is WRONG. The correct output has BOTH lines:
```
# 4.1 Copy skills
# Copy skills
```

Example — WRONG (existing comment replaced with itemisation label):

Original code:
```
# Only trigger on git commit commands
if [[ "$COMMAND" == *"git commit"* ]]; then
```
Wrong output (original comment deleted, replaced by itemisation label):
```
# 2.1 Check if command is a git commit
if [[ "$COMMAND" == *"git commit"* ]]; then
```
The original comment `# Only trigger on git commit commands` has been destroyed.

Example — RIGHT (itemisation label added, every original character preserved):

Original code:
```
# Only trigger on git commit commands
if [[ "$COMMAND" == *"git commit"* ]]; then
```
Correct output (new label inserted above, original comment untouched):
```
# 2.1 Display checklist if git commit detected
# Only trigger on git commit commands
if [[ "$COMMAND" == *"git commit"* ]]; then
```
The original comment `# Only trigger on git commit commands` is still there, verbatim.

**How to apply this with Edit:** The `old_string` is the existing comment + code line. The `new_string` is the new itemisation label + the same existing comment + the same code line. Every character of `old_string` must appear in `new_string`.

```
old_string: "# Only trigger on git commit commands\nif [[ \"$COMMAND\" == *\"git commit\"* ]]; then"
new_string: "# 2.1 Display checklist if git commit detected\n# Only trigger on git commit commands\nif [[ \"$COMMAND\" == *\"git commit\"* ]]; then"
```

Removing, altering, or rewriting ANY existing character in the file — whether code or comment — is a catastrophic failure. The verification step (Step 5) will catch this, but the Edit-based approach prevents it structurally.

## Step 4.5: Granularity Self-Check

Before running the integrity verification, do a calibration pass over every number you added. For each numbered block, ask:

> *"If a user asked 'where's the code that does X?', could I send them to this number — or would I have to direct them to a sub-part of this block?"*

If you'd have to direct them to a sub-part, the block is too coarse. Sub-number it. Repeat until every numbered block cleanly does one job.

**Why this step is mandatory:** the Step 5 integrity check verifies that no code was changed — it does NOT verify granularity. An agent can apply the rules mechanically and end up with one number covering 30 lines of multiple distinct concerns, and Step 5 will still pass. Granularity is a separate failure mode and must be caught here.

Common cases this catches:
- A CSS section number that turns out to span three different selector groups affecting three different page regions → split into three sub-numbers, one per selector
- A function-level number that contains a clearly-separable helper block doing pre-processing work → either extract as a sub-number or, better, recognise it as its own job and number it accordingly
- A `switch` block where one case has substantial business logic distinct from its siblings → that case earns its own sub-number

When in doubt, prefer more granular over less. An over-numbered block is easy to consolidate later; an under-numbered block requires re-itemisation to fix.

## Step 5: Verify Integrity

After rewriting each file, compare it to its backup to confirm that ONLY comment-number lines were added and NO actual code was changed.

Run this check for each file. The pattern below covers all five comment styles in the language table — `//`, `#`, `/*` (CSS/SCSS/Less), `<!--` (HTML/XML/Vue), and `--` (SQL) — so the same command works for every supported language. The command:
1. Strips itemisation comment lines from **both** the current file and the backup (handles re-itemisation of already-itemised files)
2. Normalises CRLF to LF on both sides (prevents false failures on Windows)
3. Ignores blank line differences with `diff -B` (inserting comment blocks inevitably shifts blank lines)

```bash
PATTERN="^\s*(\/\/|#|/\*|<!--|--)\s+([0-9]+(\.[0-9]+)*(\s|\.)|end of\s+[0-9]+)"
diff -B <(grep -Ev "$PATTERN" "{filename}" | tr -d '\r') <(grep -Ev "$PATTERN" "{filename}.itemise-backup" | tr -d '\r')
```

- If `diff` produces no output: **PASS** — only comment lines (and cosmetic blank lines) were added
- If `diff` produces output: **FAIL** — actual code was changed

Report pass/fail for each file. On any FAIL, immediately restore the backup:

```bash
cp "{filename}.itemise-backup" "{filename}"
```

## Step 6: Clean Up

If ALL files passed:
- Delete all backup files: `rm "{filename}.itemise-backup"` for each
- Report: "Itemisation complete. N files updated. Backups deleted."

If any file failed:
- Restore its backup (already done in Step 5)
- Delete its backup after restoring
- Report which files were restored and what the diff showed
- Leave successfully-itemised files in place

## Step 7: Summary

```
## Itemisation Complete

### Updated Files
- [filename] — N sections, M functions numbered

### Failed / Restored
- [filename] — [reason, diff output]

### Notes
- Run /itemise again after significant code changes to renumber
- Disable with ITEMISATION: disabled in CLAUDE.md

### Usage Tips
- For large files, grep for `# N.M` to find a section's start line and `# end of N.M`
  for its end line, then use Read with offset/limit to load just that section.
- When modifying a section, grep the file for `[calls: N.M]` references pointing to it.
  If other sections depend on the one you're changing, flag it to the user as an advisory.
- See "Reading Specific Sections" and "Impact Advisories" in CLAUDE.md for full details.
```
