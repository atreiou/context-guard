#!/bin/bash
# Context Guard: Pre-Compaction Backup Hook
# Fires before context compaction. Copies every Context Guard file into a dated backup folder,
# checks each copy byte for byte against its original, and only then reports success.
# A failed or partial backup is never reported as a good one.

# 1. SECTION: Locate the Context Guard folder
ROOT="${CLAUDE_PROJECT_DIR:-$PWD}"
if [ -d "$ROOT/context-guard" ]; then
  CG="$ROOT/context-guard"; DEST="$CG/backups"
elif [ -d "$ROOT/Context Guard" ]; then
  # Older folder name, until the project is upgraded
  CG="$ROOT/Context Guard"; DEST="$CG/compaction-backups"
else
  # Older layout, until the project is upgraded: the files sit loose in the project root
  CG="$ROOT"; DEST="$ROOT/compaction-backups"
fi
# end of 1

# 2. SECTION: Copy into a partial folder, verify every copy, then mark it complete
FILES=(RESUME_STATE.md SESSION_LOG.md TASK_REGISTRY.md TASK_REGISTRY_COMPLETED.md DECISIONS.md LEARNED_BEHAVIOUR.md COMMENTS.md FEATURE_LIST.json)
STAMP="$(date +%Y-%m-%d_%H%M%S)"
PARTIAL="$DEST/$STAMP.partial"
if ! mkdir -p "$PARTIAL"; then
  echo "Context Guard: backup FAILED, could not create $PARTIAL. No backup was made." >&2
  exit 1
fi
COPIED=0
for f in "${FILES[@]}"; do
  [ -f "$CG/$f" ] || continue
  if cp "$CG/$f" "$PARTIAL/" && cmp -s "$CG/$f" "$PARTIAL/$f"; then
    COPIED=$((COPIED + 1))
  else
    echo "Context Guard: backup FAILED on $f. The partial copy is left in $PARTIAL and no backup is claimed." >&2
    exit 1
  fi
done
if [ "$COPIED" -eq 0 ]; then
  rmdir "$PARTIAL" "$DEST" 2>/dev/null
  echo "Context Guard: no Context Guard files found in $CG, so nothing was backed up." >&2
  exit 1
fi
if ! mv "$PARTIAL" "$DEST/$STAMP"; then
  echo "Context Guard: backup FAILED, could not finish $PARTIAL. No backup is claimed." >&2
  exit 1
fi
echo "Context Guard: backed up and verified $COPIED files in $DEST/$STAMP" >&2
exit 0
# end of 2
