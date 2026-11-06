#!/bin/sh
# Clone VitruvianGodot (CC0 character, MIT code) at the pinned commit next to this folder.
set -e
cd "$(dirname "$0")"
[ -d upstream ] || git clone --depth 1 https://github.com/ibrews/VitruvianGodot.git upstream
git -C upstream fetch --depth 1 origin 8b643c3e72f39cb2f775ddeeac1612f70a9e1606 2>/dev/null || true
git -C upstream checkout -q 8b643c3e72f39cb2f775ddeeac1612f70a9e1606 2>/dev/null || echo "note: using clone HEAD $(git -C upstream rev-parse --short HEAD)"
echo "upstream at $(git -C upstream rev-parse HEAD)"
