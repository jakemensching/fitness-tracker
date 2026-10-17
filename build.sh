#!/usr/bin/env sh
# Builds index.html for GitHub Pages: the phone-app head (manifest, iOS tags,
# base styles, service worker) followed by the app source in src/app.html.
set -e
cd "$(dirname "$0")"
cat head.html src/app.html > index.html
echo "Built index.html"
