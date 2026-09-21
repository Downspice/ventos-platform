#!/usr/bin/env bash
# Copy to clone-all.sh and set ORG + host (GitHub or Cursor).
set -euo pipefail
ORG="${ORG:-your-org}"
BASE="${BASE:-..}"
repos=(ventos-backend ventos-web ventos-admin ventos-pos-desktop ventos-shared)
for r in "${repos[@]}"; do
  git clone "git@github.com:${ORG}/${r}.git" "${BASE}/${r}"
done
