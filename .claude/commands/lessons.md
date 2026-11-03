---
description: "Type /lessons at the end of a session to turn this session's throwaway debug scripts into permanent knowledge, then clear the spent scripts away. Run it after /save, before /end."
allowed-tools: Read, Grep, Glob, Bash, Edit, Write
---

# Context Guard: Lesson Harvest (/lessons)

Run at the END of a session, after `/save` or before `/end`.

Most of what a session learns is thrown away. An agent writes a quick script to poke at something, it fails, the agent writes a second version, that fails differently, the third one works, and then all three are deleted or abandoned, taking with them the only record of what was actually wrong. **The diff between consecutive versions of a throwaway script is a literal record of what the agent believed that turned out to be false.** That is the most valuable thing a debugging session produces, and it is the thing that normally survives least.

This skill mines that record, installs it where a future session will actually meet it, and only then clears the scripts away.

**The governing principle: prefer a helper over prose.** A rule that must be remembered fails. A helper function that gets called, and a LEARNED_BEHAVIOUR entry that a future `/start` surfaces, do not. When a lesson can be expressed as code that makes the wrong answer impossible, write the code. A prose note saying "remember to escape the path" decays, a `safePath()` that escapes it cannot be forgotten.

## Step 0: Locate CCG Root

Same as `/start` Step 0: a `CCG_LOCATION.md` pointer in the working directory first, then the `context-guard/` folder, then an older layout. LEARNED_BEHAVIOUR.md, DECISIONS.md and the archive pages below are all in CCG_ROOT.

## Step 1: Collect THIS session's scripts only

Find the scratch, driver, and debug scripts created or modified **this session**. Match on the session's own naming prefix if the project uses one, or on mtime since the session's first commit.

**Never sweep the back catalogue.** A repo that has been running for months has hundreds of old scratch files. Mining them is a separate, explicitly authorised job, and doing it here turns a five-minute wrap-up into an open-ended excavation and buries the session's actual lessons in noise.

Group the files into series by name stem (`check_auth.js`, `check_auth2.js`, `check_auth_final.js` are one series). Usually the last file in a series is the result and the earlier ones are the path that got there. **The path is the valuable part.**

## Step 2: Read what already exists, BEFORE extracting anything

A duplicate entry makes every future search noisier, so this step is not optional:

1. `LEARNED_BEHAVIOUR.md` and its `## Index of archived LBs`. Is this lesson already logged? If so, cite the LB number and move on.
2. The project's helper library, if it has one. Is this already a function? Same answer.
3. `DECISIONS.md` and its index. A lesson that is really a decision belongs there instead, and may already be there.

**A session that finds nothing new says so.** That is a result, not a failure of the skill. Do not manufacture entries to justify the run.

## Step 3: Diff each series and name what changed

For each consecutive pair of files in a series, answer one question: **what did the agent believe in file N that turned out to be wrong in file N+1?**

Look for a changed selector, wait condition, endpoint, parameter name, assertion, path, encoding, or a guard that suddenly appeared. Ignore cosmetic churn: renamed variables and reformatting are not lessons.

## Step 4: Classify each lesson

| Class | Where it goes | Test for this class |
|---|---|---|
| **HELPER** | a function in the project's helper library, plus a LEARNED_BEHAVIOUR entry naming it | code that calls the helper cannot get the wrong answer |
| **FACT** | a LEARNED_BEHAVIOUR entry | it states what this system does: a selector, a route, an option name, a behaviour |
| **INSTRUMENT FAULT** | a LEARNED_BEHAVIOUR entry, flagged as such | the *check* was wrong while the thing being checked was fine |
| **JUDGEMENT** | a LEARNED_BEHAVIOUR entry, and DECISIONS.md if it constrains future work | no code can catch it; it needs a human to weigh something |

Instrument faults are worth separating out. "The test was broken, not the feature" is the single most expensive lesson to re-learn, because the next agent will believe the failing check and start fixing code that was never wrong.

## Step 5: Put the list to the user BEFORE writing anything

Use `AskUserQuestion`. One plain sentence per lesson, with its class and destination.

A proposed helper must be describable in **one sentence**. If it takes a paragraph, it is not a helper, it is a small system, and it needs its own task rather than being smuggled in during a wrap-up.

**Do not write, install, or delete anything before the user answers.**

## Step 6: Install what was approved

- **LEARNED_BEHAVIOUR entries**: standard format (`## LB-NNN: title (Session N, dd/mm/yy)` with Context / Gotcha / Workaround / Why). Where a helper now enforces the lesson, add an `**Enforced by:**` line naming it. That tells a future reader the rule is already load-bearing in code and does not depend on them remembering it.
- **Helpers**: add to the project's helper library, export it, and **self-test both ways**: prove it fails on a known-broken input and passes on a known-good one. A helper that has only ever been tested on the good case is a guess wearing a function signature.
- **Decisions**: only where the lesson genuinely constrains future work, with a `Category:` field like any other decision.

## Step 7: Only NOW, clear the scripts away

⚠️ **Check git first. Most scratch files have never been committed, so deleting them is permanent and unrecoverable.**

```bash
git ls-files <path-to-script>
```

- Untracked **and** unmined → it stays. No exceptions.
- Delete only files whose lessons are installed, **by name, one at a time**. Never a wildcard, never a directory.
- Keep anything still referenced by a runbook, a ledger row, or another script, and say which.

This ordering is the whole safety property of the skill: the evidence is not destroyed until the lesson it carries is installed and the user has approved it.

## Step 8: Report

One line per lesson: what it was, its LB number or helper name, and how it was proven. Then how many scripts were cleared and how many kept, with reasons.

If nothing new was found, say that in one line and stop.

---

## The failure modes this skill exists to prevent

**Generating entries nobody needs.** Step 2 is not optional. Every duplicate makes the real entries harder to find.

**Becoming a mining operation.** One session's files only. The back catalogue is its own authorised project.

**Deleting evidence.** Nothing goes until its lesson is installed and the user has approved the list.

**Writing prose where code would hold.** If the lesson can be a helper, it should be a helper.
