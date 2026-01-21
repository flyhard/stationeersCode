#!/usr/bin/env bash
set -euo pipefail

# Enforce maximum size for all .ic10 files in the repo
# Default limit: 4096 bytes (can override via IC10_SIZE_LIMIT env var)

limit="${IC10_SIZE_LIMIT:-4096}"
root_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")"/.. && pwd)"

printf "Checking .ic10 file sizes (limit %s bytes)\n" "$limit"

fail_count=0
found_any=0

while IFS= read -r -d '' f; do
  found_any=1
  size=$(wc -c < "$f" | tr -d ' ')
  rel=${f#"$root_dir/"}
  if [[ "$size" -le "$limit" ]]; then
    printf "  PASS  %-40s %6s bytes\n" "$rel" "$size"
  else
    printf "  FAIL  %-40s %6s bytes (over by %s)\n" "$rel" "$size" "$((size - limit))"
    fail_count=$((fail_count + 1))
  fi
done < <(find "$root_dir" -type f -name "*.ic10" -print0)

if [[ "$found_any" -eq 0 ]]; then
  echo "No .ic10 files found."
  exit 0
fi

if [[ $fail_count -gt 0 ]]; then
  printf "\n%d file(s) exceed the %s-byte limit.\n" "$fail_count" "$limit"
  exit 1
fi

printf "\nAll .ic10 files are within the %s-byte limit.\n" "$limit"
