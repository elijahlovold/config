#!/bin/sh

NOTES_PATH="$HOME/vault/daily_notes"
TEMPLATE="$NOTES_PATH/_daily_template.md"
TODAY="$(date +%F)"
OUTFILE="$NOTES_PATH/$TODAY.md"

# if not exist, create file with proper date header
if [ ! -f "$OUTFILE" ]; then
    HEADER="# $(date '+%A, %B %-d, %Y')"
    echo -e "$HEADER\n$(tail -n +2 $TEMPLATE)" > "$OUTFILE"
fi

exec "$TERM" -e nvim "$OUTFILE"
