#!/usr/bin/env node
// registry_check.js: Context Guard's checker for a project's TWO task lists.
//   TASK_REGISTRY.md            LIVE: every task not yet finished, in one table under "## LIVE TASKS"
//   TASK_REGISTRY_COMPLETED.md  COMPLETED: every finished task, newest at the top, under "## COMPLETED TASKS"
// /start runs it and gives the user its first line; /save and /end run it and fix or report every flag; /audit reports it.
//
//   node .claude/tools/registry_check.js --root "<CCG_ROOT>" [--session S12]
//
// --root     the folder holding TASK_REGISTRY.md (CCG_ROOT). Defaults to ./context-guard when it exists,
//            otherwise the working directory (older layouts, until the project is upgraded).
// --session  the current session. Defaults to the newest "## Session N" in SESSION_LOG.md plus one, which is right
//            at /start; /save and /end pass it explicitly because the current session is already logged by then.
// Exit codes: 0 both lists clean, 1 rows need fixing, 2 the project still has the old single task list.
'use strict'
const fs = require('fs'), path = require('path')

// 1. SECTION: Arguments and paths
const argv = process.argv
const opt = name => { const i = argv.indexOf(name); return i > 0 && i + 1 < argv.length ? argv[i + 1] : null }
const ROOT = path.resolve(opt('--root') ||
  (fs.existsSync(path.join(process.cwd(), 'context-guard', 'TASK_REGISTRY.md')) ? path.join(process.cwd(), 'context-guard') : process.cwd()))
const LIVE_FILE = 'TASK_REGISTRY.md', DONE_FILE = 'TASK_REGISTRY_COMPLETED.md'
const read = f => fs.readFileSync(path.join(ROOT, f), 'utf8').replace(/\r/g, '')
if (!fs.existsSync(path.join(ROOT, LIVE_FILE))) {
  console.log(`No ${LIVE_FILE} in ${ROOT}. Pass --root with the folder that holds the safeguard files.`)
  process.exit(1)
}
// end of 1

// 2. SECTION: Current session
function currentSession() {
  const given = opt('--session')
  if (given) return Number(String(given).replace(/\D/g, '')) || null
  if (!fs.existsSync(path.join(ROOT, 'SESSION_LOG.md'))) return null
  const nums = [...read('SESSION_LOG.md').matchAll(/^## Session (\d+)/gm)].map(m => Number(m[1]))
  return nums.length ? Math.max(...nums) + 1 : null
}
const CURRENT = currentSession()
// end of 2

// 3. SECTION: Table reader
// Returns every markdown table in a file whose first header cell is "ID", with the "## " heading it sits under.
// Escaped pipes (\|) inside a cell are kept as part of the cell.
function taskTables(file) {
  const out = []
  let section = '', table = null
  read(file).split('\n').forEach((line, i) => {
    if (line.startsWith('## ')) { section = line.slice(3).trim(); table = null; return }
    if (!line.trim().startsWith('|')) { table = null; return }
    const cells = line.trim().replace(/\\\|/g, '\u0000').split('|').slice(1, -1).map(c => c.replace(/\u0000/g, '\\|').trim())
    if (!table) {
      table = { section, header: cells.map(c => c.toLowerCase()), rows: [], line: i + 1 }
      if (table.header[0] === 'id') out.push(table)
      return
    }
    if (cells.every(c => /^:?-+:?$/.test(c))) return
    const header = table.header
    table.rows.push({ cells, line: i + 1, get: name => cells[header.indexOf(name)] || '' })
  })
  return out
}
// end of 3

// 4. SECTION: Old single list detection
const liveText = read(LIVE_FILE)
const converted = /^## LIVE TASKS\s*$/m.test(liveText)
if (!converted && !fs.existsSync(path.join(ROOT, DONE_FILE))) {
  console.log('Old single task list: this project has not been moved to the two lists (LIVE and COMPLETED) yet.')
  process.exit(2)
}
// end of 4

// 5. SECTION: Rows of each list
const flags = []
function rowsOf(file, wantSection, needCols) {
  const rows = []
  for (const t of taskTables(file)) {
    if (t.section !== wantSection) {
      for (const r of t.rows) flags.push(`${file} line ${r.line} ${r.cells[0] || '(no id)'}: a task row outside the "${wantSection}" table`)
      continue
    }
    const missing = needCols.filter(c => !t.header.includes(c))
    if (missing.length) { flags.push(`${file} line ${t.line}: the "${wantSection}" table has no ${missing.join(', ')} column`); continue }
    for (const r of t.rows) {
      r.id = r.cells[0]; r.at = `${file} line ${r.line} ${r.id || '(no id)'}`
      if (!r.id) flags.push(`${r.at}: the row has no ID`)
      rows.push(r)
    }
  }
  return rows
}
const live = rowsOf(LIVE_FILE, 'LIVE TASKS', ['id', 'task', 'status', 'updated'])
if (!converted) flags.push(`${LIVE_FILE} has no "## LIVE TASKS" table`)
const doneExists = fs.existsSync(path.join(ROOT, DONE_FILE))
if (!doneExists) flags.push(`${DONE_FILE} is missing`)
const done = doneExists ? rowsOf(DONE_FILE, 'COMPLETED TASKS', ['id', 'task', 'outcome', 'tested', 'proof']) : []
// end of 5

// 6. SECTION: LIVE checks
let waiting = 0
for (const r of live) {
  const st = r.get('status'), up = r.get('updated')
  if (!/^(PENDING|IN PROGRESS|WAITING ON USER)\b/.test(st)) {
    flags.push(`${r.at}: Status must start with PENDING, IN PROGRESS or WAITING ON USER (a finished task moves to the top of COMPLETED)`)
  } else if (/^WAITING ON USER/.test(st)) waiting++
  if (/\bhanded\b/i.test(st)) flags.push(`${r.at}: Status says "handed"; give the task's real state`)
  const s = Number((up.match(/\bS(\d+)\b/) || [])[1])
  if (!s) flags.push(`${r.at}: Updated has no session number (for example S12 03/11/26)`)
  else if (CURRENT && CURRENT - s >= 2) flags.push(`${r.at}: not re-checked since S${s}; check it against the evidence and update the row`)
}
// end of 6

// 7. SECTION: COMPLETED checks
const TESTED = /^(TESTED BY USER|TESTED INDEPENDENTLY|BUILDER ONLY|NOT TESTED)\b/
const dateKey = s => { const m = String(s).match(/(\d{2})\/(\d{2})\/(\d{2})/); return m ? Number('20' + m[3] + m[2] + m[1]) : null }
let untested = 0, newestAbove = Infinity
for (const r of done) {
  const oc = r.get('outcome'), te = r.get('tested'), pr = r.get('proof')
  if (!/^(DONE|SUPERSEDED|DROPPED) \d{2}\/\d{2}\/\d{2}\b/.test(oc)) flags.push(`${r.at}: Outcome must start DONE, SUPERSEDED or DROPPED and a dd/mm/yy date`)
  if (/^DONE\b/.test(oc)) {
    if (!TESTED.test(te)) flags.push(`${r.at}: Tested must start TESTED BY USER, TESTED INDEPENDENTLY, BUILDER ONLY or NOT TESTED`)
    else if (/^(BUILDER ONLY|NOT TESTED)/.test(te)) untested++
    if (!/[\/\\]|\.[a-z0-9]{1,5}\b|\b[0-9a-f]{7,40}\b/i.test(pr)) flags.push(`${r.at}: DONE without proof (a path or a commit)`)
  } else if (te && !TESTED.test(te) && !/^n\/a\b/i.test(te)) {
    flags.push(`${r.at}: Tested must start TESTED BY USER, TESTED INDEPENDENTLY, BUILDER ONLY, NOT TESTED or n/a`)
  }
  if (/^SUPERSEDED\b/.test(oc) && !/\bby\s+\S+/.test(oc)) flags.push(`${r.at}: SUPERSEDED must name the task that replaced it ("by <id>")`)
  if (/^DROPPED\b/.test(oc) && !/["“][^"”]{3,}["”]/.test(oc + ' ' + pr)) flags.push(`${r.at}: DROPPED without the user's own words in quotation marks`)
  const k = dateKey(oc)
  if (k) {
    if (k > newestAbove) flags.push(`${r.at}: COMPLETED must be newest first (this row is newer than a row above it)`)
    newestAbove = Math.min(newestAbove, k)
  }
}
const liveIds = new Set(live.map(r => r.id).filter(Boolean))
for (const r of done) if (r.id && liveIds.has(r.id)) flags.push(`${r.at}: the same ID is still on LIVE`)
// end of 7

// 8. SECTION: Report
console.log(`Live tasks: ${live.length} (${waiting} waiting on user); completed: ${done.length} (${untested} not independently tested)` +
  (flags.length ? `; ${flags.length} ${flags.length === 1 ? 'row needs' : 'rows need'} fixing` : '; both lists clean'))
for (const f of flags) console.log(' - ' + f)
process.exit(flags.length ? 1 : 0)
// end of 8
