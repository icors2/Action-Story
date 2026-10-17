#!/usr/bin/env bash
# Idempotent Cloud / CI install: Godot 4.7.2-stable on PATH, uv if missing.
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
VERSION_FILE="${ROOT}/.godot-version"
VERSION="4.7.2-stable"
if [[ -f "${VERSION_FILE}" ]]; then
	VERSION="$(tr -d '[:space:]' < "${VERSION_FILE}")"
fi

BIN_DIR="${HOME}/.local/bin"
GODOT_DIR="${HOME}/.local/share/godot/${VERSION}"
mkdir -p "${BIN_DIR}" "${GODOT_DIR}"

if [[ ! -x "${GODOT_DIR}/godot" ]]; then
	ARCHIVE="Godot_v${VERSION}_linux.x86_64.zip"
	URL="https://github.com/godotengine/godot-builds/releases/download/${VERSION}/${ARCHIVE}"
	TMP="$(mktemp -d)"
	curl -fsSL "${URL}" -o "${TMP}/${ARCHIVE}"
	unzip -qo "${TMP}/${ARCHIVE}" -d "${TMP}"
	BIN="$(find "${TMP}" -maxdepth 1 -type f -name 'Godot_v*' | head -n 1)"
	cp "${BIN}" "${GODOT_DIR}/godot"
	chmod +x "${GODOT_DIR}/godot"
	rm -rf "${TMP}"
fi

# Official x86_64 builds require SSE4.2. Wrap with qemu on older lab CPUs.
cat > "${BIN_DIR}/godot" <<EOF
#!/usr/bin/env bash
set -euo pipefail
REAL="${GODOT_DIR}/godot"
if grep -qw sse4_2 /proc/cpuinfo 2>/dev/null; then
	exec "\$REAL" "\$@"
fi
QEMU="\${HOME}/.local/share/qemu-x86_64-static"
if [[ -x "\$QEMU" ]]; then
	exec "\$QEMU" -cpu max "\$REAL" "\$@"
fi
echo "Godot 4.7 needs SSE4.2, or qemu-x86_64-static at \$QEMU" >&2
exit 1
EOF
chmod +x "${BIN_DIR}/godot"

if ! command -v uv >/dev/null 2>&1; then
	curl -LsSf https://astral.sh/uv/install.sh | sh
fi

if ! command -v python3 >/dev/null 2>&1; then
	echo "python3 is required" >&2
	exit 1
fi

echo "Skyrope env ready: godot=${BIN_DIR}/godot uv=$(command -v uv || true)"
