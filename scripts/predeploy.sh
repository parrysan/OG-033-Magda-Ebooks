#!/usr/bin/env bash
# scripts/predeploy.sh — gated, traceable deploy of docs/client-area/ to Firebase Hosting.
#
# Reference implementation: OG-002-03-STR-MabV.
# Scaffolded by ~/.claude/skills/og-deploy/templates/predeploy.sh.template.
#
# Gates:
#   Gate 1  Refuses to deploy from any branch other than main.
#   Gate 2  Refuses to deploy with a dirty working tree (uncommitted or untracked).
#   Gate 3  Requires HEAD to carry a version tag like v1.8 — the tag IS the
#           version of record. No more hand-typed labels.
#   Gate 4  (Optional content gate) — e.g. scripts/check-svg-fonts.sh refuses
#           logo SVGs that reference a font. Add your own content gates here.
#   VStamp  Single source of truth for any project version (brand kit, etc.)
#           is the git tag at HEAD ($VERSION). At deploy time the script
#           rewrites version-bearing surfaces in staging (zip filenames,
#           <a href>s, <span data-brand-version> content) to derive from
#           that one tag. Source-tree values are placeholders. Never
#           hand-edit version numbers in HTML or zip filenames.
#   Inject  Stamps every deployed HTML with <meta name="x-version"> and
#           <meta name="x-build">. View-source on any live page and you can
#           trace it back to the exact commit.
#   Stage   Deploys from a temporary docs/client-area.deploy/ copy so the source
#           tree stays clean. firebase.json is swapped, then restored.
#
# Usage:
#   git tag v1.8 && git push origin v1.8
#   ./scripts/predeploy.sh
#
# Overrides (use sparingly):
#   PREDEPLOY_ALLOW_DIRTY=1  ./scripts/predeploy.sh   # bypass tree-clean check
#   PREDEPLOY_ALLOW_UNTAGGED=1 ./scripts/predeploy.sh # bypass tag-at-HEAD check

set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$REPO_ROOT"

SOURCE_DIR="docs/client-area"
DEPLOY_DIR="docs/client-area.deploy"
HOSTING_CONFIG_FILE="firebase.json"
HOSTING_CONFIG_BACKUP="${HOSTING_CONFIG_FILE}.predeploy.bak"

# === Cleanup trap (always restores hosting config and removes deploy dir) ===
cleanup() {
  if [[ -f "$HOSTING_CONFIG_BACKUP" ]]; then
    mv "$HOSTING_CONFIG_BACKUP" "$HOSTING_CONFIG_FILE"
  fi
  rm -rf "$DEPLOY_DIR"
}
trap cleanup EXIT

# === Gate 1: branch === ##########################################
BRANCH=$(git rev-parse --abbrev-ref HEAD)
if [[ "$BRANCH" != "main" ]]; then
  echo "✗ Refusing to deploy from branch '$BRANCH' — deploys go from main only." >&2
  exit 1
fi
echo "✓ branch = main"

# === Gate 2: clean tree === #######################################
if [[ "${PREDEPLOY_ALLOW_DIRTY:-0}" != "1" ]]; then
  if ! git diff --quiet || ! git diff --cached --quiet; then
    echo "✗ Working tree has uncommitted changes. Commit or stash first." >&2
    git status -s
    exit 1
  fi
  if [[ -n "$(git ls-files --others --exclude-standard)" ]]; then
    echo "✗ Untracked files present. Commit, .gitignore, or remove them." >&2
    git status -s --untracked-files=normal
    exit 1
  fi
  echo "✓ working tree clean"
else
  echo "⚠  PREDEPLOY_ALLOW_DIRTY=1 — skipping clean-tree check"
fi

# === Gate 3: version tag at HEAD === ##############################
TAG_AT_HEAD=$(git tag --points-at HEAD | grep -E '^v[0-9]' | head -1 || true)
if [[ -z "$TAG_AT_HEAD" ]]; then
  if [[ "${PREDEPLOY_ALLOW_UNTAGGED:-0}" == "1" ]]; then
    TAG_AT_HEAD="$(git describe --tags --always --dirty 2>/dev/null || echo "untagged")-untagged"
    echo "⚠  PREDEPLOY_ALLOW_UNTAGGED=1 — using synthetic version '$TAG_AT_HEAD'"
  else
    LATEST_TAG=$(git describe --tags --abbrev=0 2>/dev/null | grep -E '^v[0-9]' || echo "")
    echo "✗ No version tag at HEAD." >&2
    if [[ -n "$LATEST_TAG" ]]; then
      echo "  Latest version tag is '$LATEST_TAG'. Tag this commit before deploying." >&2
    else
      echo "  Tag this commit with a version (e.g. v1.8) before deploying." >&2
    fi
    echo "  Example:  git tag v1.8 && git push origin v1.8 && $0" >&2
    exit 1
  fi
fi
VERSION="$TAG_AT_HEAD"
SHA=$(git rev-parse --short HEAD)
DATE=$(date +%Y-%m-%d)
BUILD="$SHA · $DATE"
echo "✓ version = $VERSION  build = $BUILD"

# === Gate 4: content gates (opt-in) === ###########################
# Uncomment + add gates here. Example for projects with logo SVGs:
# if ! "$REPO_ROOT/scripts/check-svg-fonts.sh"; then
#   echo "✗ Gate 4 failed — refusing to deploy logo SVGs that reference fonts." >&2
#   exit 1
# fi

# === Stage deploy directory === ###################################
echo "→ Staging $DEPLOY_DIR/ from $SOURCE_DIR/"
rm -rf "$DEPLOY_DIR"
cp -r "$SOURCE_DIR" "$DEPLOY_DIR"

# Build a human-readable version label like 'v1.8 — May 2026'
MONTH_YEAR=$(date +"%B %Y")
VERSION_LABEL="$VERSION — $MONTH_YEAR"

# Inject meta tags after <head> in every HTML file
META_LINE_1="  <meta name=\"x-version\" content=\"$VERSION_LABEL\">"
META_LINE_2="  <meta name=\"x-build\" content=\"$BUILD\">"

HTML_COUNT=0
while IFS= read -r f; do
  awk -v m1="$META_LINE_1" -v m2="$META_LINE_2" '
    /<head>/ && !injected { print; print m1; print m2; injected=1; next }
    { print }
  ' "$f" > "$f.tmp" && mv "$f.tmp" "$f"
  HTML_COUNT=$((HTML_COUNT + 1))
done < <(find "$DEPLOY_DIR" -name "*.html" -type f)
echo "✓ injected meta tags into $HTML_COUNT HTML files"

# === Version-stamp downloadable artefacts (opt-in) =================
# Single source of truth for the project version: the git tag at HEAD.
# Every visible version surface — zip filenames, <a href>s, <span
# data-brand-version> elements — is rewritten in the staging copy from
# that single source. Remove or adapt this block if your project doesn't
# ship a versioned zip in $SOURCE_DIR/downloads/.
DOWNLOADS_DIR="$DEPLOY_DIR/downloads"
if [[ -d "$DOWNLOADS_DIR" ]]; then
  ZIP_COUNT=0
  for zip_path in "$DOWNLOADS_DIR"/*-v*.zip; do
    [[ -f "$zip_path" ]] || continue
    old_base=$(basename "$zip_path")
    prefix=$(echo "$old_base" | sed -E 's/-v[0-9]+(\.[0-9]+)*\.zip$//')
    new_base="${prefix}-${VERSION}.zip"
    if [[ "$old_base" != "$new_base" ]]; then
      mv "$zip_path" "$DOWNLOADS_DIR/$new_base"
      find "$DEPLOY_DIR" -name "*.html" -type f -exec sed -i '' "s|${old_base}|${new_base}|g" {} +
      echo "  renamed: $old_base → $new_base"
    fi
    ZIP_COUNT=$((ZIP_COUNT + 1))
  done
  if (( ZIP_COUNT > 0 )); then
    echo "✓ version-stamped $ZIP_COUNT zip(s) + href references"
  fi
fi

# Rewrite the content of any <span data-brand-version> elements to the
# current "$VERSION · Month YYYY". Source HTML keeps a placeholder; this
# is the only place the displayed value is decided.
find "$DEPLOY_DIR" -name "*.html" -type f -exec sed -i '' -E \
  "s|<span data-brand-version>[^<]*</span>|<span data-brand-version>${VERSION} \&middot; ${MONTH_YEAR}</span>|g" {} +

# === Swap hosting config === ######################################
echo "→ Swapping $HOSTING_CONFIG_FILE → $DEPLOY_DIR"
cp "$HOSTING_CONFIG_FILE" "$HOSTING_CONFIG_BACKUP"
# Adapt this JSON path for your hosting platform.
# Firebase: data['hosting']['public']
# Netlify: TOML, not JSON — different mechanism
# Vercel:  outputDirectory in vercel.json
python3 -c "
import json
with open('$HOSTING_CONFIG_FILE') as f: data = json.load(f)
data['hosting']['public'] = '$DEPLOY_DIR'
with open('$HOSTING_CONFIG_FILE', 'w') as f: json.dump(data, f, indent=2)
"

# === Deploy === ###################################################
echo "→ firebase deploy --only hosting"
echo ""
firebase deploy --only hosting

echo ""
echo "✓ Deploy successful: $VERSION_LABEL · $BUILD"
echo "  Verify: curl -s https://og-033-magda-ebooks.web.app/ | grep x-build"
