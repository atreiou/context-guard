# LEARNED_BEHAVIOUR.md: {PROJECT_NAME} Tactical Knowledge Log
# Non-obvious workarounds, platform quirks, version-specific gotchas, and hard-won discoveries.
# This is the tactical equivalent of DECISIONS.md, for things a fresh agent would otherwise re-discover the hard way.
#
# WHAT TO LOG:
# - Platform/library gotchas that cost >15 minutes to debug
# - Version-specific quirks (e.g. "PHP 8.1 breaks X when Y is enabled")
# - Non-obvious workarounds that actually work after obvious approaches failed
# - Environment-specific behaviours (dev vs prod, OS-specific, shell-specific)
#
# WHAT NOT TO LOG:
# - Ordinary coding knowledge (how loops work, standard API usage)
# - One-off typos or trivial mistakes
# - Anything already documented in the platform's official docs and easy to find
#
# ROTATION: entries older than the last 5 sessions move, full text intact, into
# archive/LEARNED_BEHAVIOUR_page1.md, etc. during /end. Each one leaves a one-line entry in the index
# below. An archived entry is still true. The index line is what stops a future session
# re-discovering it the hard way. Mark an entry `resolved` in the index once the underlying
# platform or library has been removed or upgraded past the bug.
#
# 📁 Archives: (none yet)

---

## Index of archived LBs

<!-- One line per archived entry. Format:
     LB-001: Short title → archive/LEARNED_BEHAVIOUR_page1.md
     Add [resolved] where the underlying bug no longer exists. -->

(Nothing archived yet.)

---

## LB-001: [Example entry, delete when real entries begin] (Session 0, YYYY-MM-DD)
**Context:** Where this surfaces (platform, plugin, version)
**Gotcha:** What fails and how (symptom)
**Workaround:** What actually works
**Why:** Root cause if known
**Related:** Tasks/decisions this connects to (optional)
