#!/usr/bin/env bash
# Build the Payback update feed for a release and sign it — the family
# single-file wrapper (taskly baseline, shared spec: taskly
# shared/spec/UPDATE.md).
#
# Usage: scripts/make-update-manifest.sh <tag> <dist-dir> <key-der-path>
#   <tag>          release tag, e.g. v1.5.0 (must match the VERSION file,
#                  rivet.rktd, and app/version.rkt — release jobs run
#                  scripts/check-release-version.sh before packaging)
#   <dist-dir>     directory containing the release artifacts, i.e. the
#                 names the release pipeline produces:
#                   payback-<version>-macos-arm64.dmg
#                   payback-<version>-macos-x64.dmg
#                   payback-<version>-windows-x64.msi
#                   payback-<version>-linux-x64.tar.gz
#   <key-der-path> Ed25519 private key in DER (OneAsymmetricKey) form; the
#                  CI secret stores it base64-encoded.
#
# Emits <dist-dir>/update-manifest.json — a single self-contained signed
# wrapper carrying every platform × architecture — plus the byte-identical
# update-stable.json alias and <dist-dir>/SHA256SUMS over all files.
#
# Feed policy (differs from taskly on purpose): payback's update semantics
# are installer-based (macOS mounts the DMG, Windows runs the MSI), so the
# feed carries the dmg/msi/targz installers. The portable .zip assets are
# for humans, not for the feed. The native Linux installers (deb/rpm/
# AppImage) upgrade through their own owners, so the feed keeps carrying
# only the Linux tar.gz.
#
# Env overrides: RELEASE_ASSET_BASE_URL, RIVET_UPDATE_KEY_ID.
set -euo pipefail

TAG="${1:?usage: make-update-manifest.sh <tag> <dist-dir> <key-der-path>}"
DIST="${2:?usage: make-update-manifest.sh <tag> <dist-dir> <key-der-path>}"
KEY_PATH="${3:?usage: make-update-manifest.sh <tag> <dist-dir> <key-der-path>}"
VERSION="${TAG#v}"
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
DIST="$(cd "$DIST" && pwd)"
cd "$ROOT"
KEY_ID="${RIVET_UPDATE_KEY_ID:-payback-2026-09}"
BASE_URL="${RELEASE_ASSET_BASE_URL:-https://github.com/turlamai/payback/releases/download/$TAG}"

raco rivet check-release-version "$TAG"

BUILD="$(sed -nE 's/.*\(build \. ([0-9]+)\).*/\1/p' "$ROOT/rivet.rktd" | head -n1)"
[[ -n "$BUILD" ]] || {
  echo "error: could not read build from rivet.rktd" >&2
  exit 1
}
[[ -f "$KEY_PATH" ]] || {
  echo "error: missing signing key $KEY_PATH" >&2
  exit 1
}

raco rivet sign-manifest \
  --application-id site.jrtx.payback \
  --version "$VERSION" \
  --build "$BUILD" \
  --channel stable \
  --base-url "$BASE_URL" \
  --key-id "$KEY_ID" \
  --private-key "$KEY_PATH" \
  --output "$DIST/update-manifest.json" \
  --alias "$DIST/update-stable.json" \
  --artifact "macos:arm64:dmg:$DIST/payback-$VERSION-macos-arm64.dmg:app" \
  --artifact "macos:x64:dmg:$DIST/payback-$VERSION-macos-x64.dmg:app" \
  --artifact "windows:x64:msi:$DIST/payback-$VERSION-windows-x64.msi:app" \
  --artifact "linux:x64:targz:$DIST/payback-$VERSION-linux-x64.tar.gz:app" \
  --rollback-allowed

# ---- checksums (paths relative to the dist dir, so --check works from it) ----
( cd "$DIST" && find . -maxdepth 1 -type f ! -name SHA256SUMS -print0 \
    | sort -z | xargs -0 shasum -a 256 ) > "$DIST/SHA256SUMS"

echo "manifest: $DIST/update-manifest.json + update-stable.json alias (4 artifacts, key-id $KEY_ID)"
echo "checksums: $DIST/SHA256SUMS"
