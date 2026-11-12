#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
VERSION="${1:-}"

usage() {
  cat <<'EOF'
Usage:
  ./release-offline.sh <version> [--output-dir DIR] [exporter options...]

Examples:
  ./release-offline.sh 1.1.1
  ./release-offline.sh 1.1.1 --client-patch /path/to/patch-z.mpq
  ./release-offline.sh 1.1.1 --output-dir /mnt/releases/azerothcore-1.1.1

Exporter options such as --world-container, --database-container and
--client-patch are passed to apps/repack/export.py.
EOF
}

if [[ -z "$VERSION" || "$VERSION" == "-h" || "$VERSION" == "--help" ]]; then
  usage
  [[ "$VERSION" == "-h" || "$VERSION" == "--help" ]] && exit 0
  exit 2
fi
if [[ ! "$VERSION" =~ ^[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
  echo "Version must use numeric MAJOR.MINOR.PATCH format (example: 1.1.1)." >&2
  exit 2
fi

shift
OUTPUT_DIR="$(dirname -- "$ROOT")/AzerothCore-offline-$VERSION"
EXPORT_ARGS=()
while (($#)); do
  case "$1" in
    --output-dir)
      (($# >= 2)) || { echo "Missing value for --output-dir." >&2; exit 2; }
      OUTPUT_DIR="$2"
      shift 2
      ;;
    --)
      shift
      EXPORT_ARGS+=("$@")
      break
      ;;
    *)
      EXPORT_ARGS+=("$1")
      shift
      ;;
  esac
done

if [[ "$OUTPUT_DIR" != /* ]]; then
  OUTPUT_DIR="$ROOT/$OUTPUT_DIR"
fi
OUTPUT_DIR="$(realpath -m -- "$OUTPUT_DIR")"
ARCHIVE="$(dirname -- "$OUTPUT_DIR")/AzerothCore-offline-$VERSION-linux-amd64.tar.gz"
CHECKSUM_FILE="$ARCHIVE.sha256"
TAG="$VERSION"

for tool in git gh docker python3 tar sha256sum realpath; do
  command -v "$tool" >/dev/null 2>&1 || { echo "Required command not found: $tool" >&2; exit 1; }
done

cd "$ROOT"
[[ -f apps/repack/export.py ]] || { echo "Run this script from the AzerothCore source repository." >&2; exit 1; }
[[ -z "$(git status --porcelain)" ]] || {
  echo "The source checkout has uncommitted changes. Commit or discard them before creating a release." >&2
  git status --short >&2
  exit 1
}

UPSTREAM="$(git rev-parse --abbrev-ref --symbolic-full-name '@{upstream}' 2>/dev/null)" || {
  echo "The current branch has no upstream. Push it before creating a release." >&2
  exit 1
}
HEAD_COMMIT="$(git rev-parse HEAD)"
REMOTE_COMMIT="$(git rev-parse "$UPSTREAM")"
[[ "$HEAD_COMMIT" == "$REMOTE_COMMIT" ]] || {
  echo "The current branch differs from $UPSTREAM. Push or synchronize it before creating a release." >&2
  exit 1
}
BRANCH="${UPSTREAM#*/}"
REMOTE_HEAD="$(git ls-remote origin "refs/heads/$BRANCH" | awk 'NR == 1 { print $1 }')"
[[ "$HEAD_COMMIT" == "$REMOTE_HEAD" ]] || {
  echo "The current commit is not the latest commit on origin/$BRANCH. Push or synchronize it before creating a release." >&2
  exit 1
}

gh auth status >/dev/null
REPOSITORY="$(gh repo view --json nameWithOwner --jq .nameWithOwner)"
if gh release view "$TAG" --repo "$REPOSITORY" >/dev/null 2>&1; then
  echo "GitHub release $TAG already exists." >&2
  exit 1
fi
if git ls-remote --exit-code --tags origin "refs/tags/$TAG" >/dev/null 2>&1; then
  echo "Git tag $TAG already exists on origin." >&2
  exit 1
fi
if git rev-parse -q --verify "refs/tags/$TAG" >/dev/null; then
  echo "Git tag $TAG already exists locally." >&2
  exit 1
fi
[[ ! -e "$OUTPUT_DIR" ]] || { echo "Output directory already exists: $OUTPUT_DIR" >&2; exit 1; }
[[ ! -e "$ARCHIVE" && ! -e "$CHECKSUM_FILE" ]] || {
  echo "Release archive or checksum already exists beside the output directory." >&2
  exit 1
}

echo "Exporting offline package for $TAG..."
python3 "$ROOT/apps/repack/export.py" --output "$OUTPUT_DIR" "${EXPORT_ARGS[@]}"

echo "Creating release archive..."
tar -czf "$ARCHIVE" -C "$(dirname -- "$OUTPUT_DIR")" "$(basename -- "$OUTPUT_DIR")"
(cd "$(dirname -- "$ARCHIVE")" && sha256sum "$(basename -- "$ARCHIVE")" > "$CHECKSUM_FILE")

NOTES_FILE="$(mktemp)"
trap 'rm -f "$NOTES_FILE"' EXIT
cat > "$NOTES_FILE" <<EOF
## AzerothCore Offline Repack $TAG

Ready-to-play Linux amd64 package. Extract the archive, then run ./install.sh and follow the prompts.

The SHA-256 checksum is attached as a separate file. Verify it with:

\`\`\`bash
sha256sum -c AzerothCore-offline-$VERSION-linux-amd64.tar.gz.sha256
\`\`\`

## Paquete offline de AzerothCore $TAG

Paquete listo para jugar en Linux amd64. Extrae el archivo, ejecuta ./install.sh y sigue las instrucciones.

El checksum SHA-256 está adjunto por separado. Verifícalo con el comando anterior.
EOF

echo "Publishing GitHub release $TAG to $REPOSITORY..."
gh release create "$TAG" "$ARCHIVE" "$CHECKSUM_FILE" \
  --repo "$REPOSITORY" \
  --target "$HEAD_COMMIT" \
  --title "AzerothCore Offline Repack $TAG" \
  --notes-file "$NOTES_FILE"

echo "Release published: $REPOSITORY/releases/tag/$TAG"
echo "Archive: $ARCHIVE"
echo "Checksum: $CHECKSUM_FILE"
