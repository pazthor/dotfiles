#!/usr/bin/env bash
# Weekly cleanup: files screenshots and WhatsApp videos by month. Never deletes.
# Usage: weekly-cleanup.sh [--dry-run]
set -euo pipefail
DRY=0; [ "${1:-}" = "--dry-run" ] && DRY=1
LOG="$HOME/.local/state/weekly-cleanup.log"; mkdir -p "$(dirname "$LOG")"
shopt -s nullglob nocaseglob
move() { # src destdir prefix
  local src="$1" dir="$2" prefix="$3" ts ext dest n=1
  ts=$(date -r "$src" +%Y-%m-%d_%H%M%S); ext="${src##*.}"; ext="${ext,,}"
  dir="$dir/$(date -r "$src" +%Y-%m)"
  dest="$dir/${prefix}_${ts}.${ext}"
  while [ -e "$dest" ]; do dest="$dir/${prefix}_${ts}_$n.${ext}"; n=$((n+1)); done
  if [ $DRY -eq 1 ]; then echo "[dry-run] $src -> $dest"
  else mkdir -p "$dir"; mv -n -- "$src" "$dest"; echo "$(date '+%F %T') $src -> $dest" | tee -a "$LOG"; fi
}
for f in "$HOME"/Downloads/[0-9][0-9][0-9][0-9][0-9][0-9][0-9][0-9]_[0-9]*.jpg; do move "$f" "$HOME/Pictures/Phone" "photo"; done
for f in "$HOME"/Downloads/image*.png "$HOME"/Downloads/Screenshot*.png; do
  move "$f" "$HOME/Pictures/Screenshots" "img"; done
for f in "$HOME"/*-whatsapp.mp4 "$HOME"/Downloads/*-whatsapp.mp4 "$HOME"/Downloads/WhatsApp\ Video*.mp4; do
  base=$(basename "$f" .mp4); base="${base%-whatsapp}"
  slug=$(echo "$base" | iconv -f utf-8 -t ascii//TRANSLIT 2>/dev/null | tr -cs '[:alnum:]' '-' | sed 's/^-//;s/-$//' | cut -c1-50)
  move "$f" "$HOME/Videos/WhatsApp" "${slug:-video}"; done
# Invoices and receipts: facturas, Amazon order PDFs (###-#######-#######.pdf), CFDI xml, and files named like invoice/recibo/receipt
for f in "$HOME"/Downloads/*factura* "$HOME"/Downloads/*invoice* "$HOME"/Downloads/*recibo* "$HOME"/Downloads/*receipt* "$HOME"/Downloads/[0-9][0-9][0-9]-[0-9][0-9][0-9][0-9][0-9][0-9][0-9]-[0-9][0-9][0-9][0-9][0-9][0-9][0-9].pdf "$HOME"/Downloads/*.xml; do
  [ -f "$f" ] || continue
  base=$(basename "$f"); base="${base%.*}"
  slug=$(echo "$base" | iconv -f utf-8 -t ascii//TRANSLIT 2>/dev/null | tr -cs '[:alnum:]' '-' | sed 's/^-//;s/-$//' | cut -c1-50)
  move "$f" "$HOME/Documents/Facturas" "${slug:-invoice}"; done
# CFDI invoices named by RFC (e.g. EME950420QV0FE34413.pdf/.xml) go to Facturas; SAT acuses and constancias go to SAT
for f in "$HOME"/Downloads/*.pdf "$HOME"/Downloads/*.PDF; do
  [ -f "$f" ] || continue
  base=$(basename "$f"); stem="${base%.*}"
  if [[ "$stem" =~ ^[A-Z\&]{3,4}[0-9]{6}[A-Z0-9]{3} ]]; then move "$f" "$HOME/Documents/Facturas" "$stem"
  elif [[ "${base,,}" == acuse* || "${base,,}" == constancia* ]]; then
    slug=$(echo "$stem" | iconv -f utf-8 -t ascii//TRANSLIT 2>/dev/null | tr -cs '[:alnum:]' '-' | sed 's/^-//;s/-$//' | cut -c1-50)
    move "$f" "$HOME/Documents/SAT" "$slug"; fi
done
