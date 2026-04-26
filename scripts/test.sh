#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"

section() {
  printf '\n== %s ==\n' "$1"
}

pick() {
  for name in "$@"; do
    if command -v "$name" >/dev/null 2>&1; then
      command -v "$name"
      return 0
    fi
  done
  return 1
}

section "Lua syntax"
LUAC="${LUAC:-$(pick luac5.2 luac || true)}"
if [ -z "${LUAC:-}" ]; then
  echo "SKIP: luac not found. Install: sudo apt install lua5.2"
else
  echo "using $LUAC"
  find craftmind -name '*.lua' -print0 | xargs -0 -n1 "$LUAC" -p
fi

section "Luacheck"
if command -v luacheck >/dev/null 2>&1; then
  luacheck craftmind
else
  echo "SKIP: luacheck not found. Install: sudo luarocks install luacheck"
fi

section "Manifest/install consistency"
if command -v python3 >/dev/null 2>&1; then
  python3 - <<'PY'
from pathlib import Path
import re

root = Path('.')
manifest = Path('craftmind/manifest.lua').read_text()
install = Path('install.lua').read_text()

def lua_files_list(text, marker):
    start = text.index(marker)
    start = text.index('{', start) + 1
    depth = 1
    i = start
    while i < len(text):
        c = text[i]
        if c == '{':
            depth += 1
        elif c == '}':
            depth -= 1
            if depth == 0:
                block = text[start:i]
                return re.findall(r'"([^"]+)"', block)
        i += 1
    raise SystemExit(f'cannot parse {marker}')

manifest_files = lua_files_list(manifest, 'files =')
install_files = lua_files_list(install, 'local files =')
missing = [p for p in manifest_files if not (root / 'craftmind' / p).exists()]
if missing:
    raise SystemExit('manifest lists missing files:\n' + '\n'.join(missing))
expected_install = ['manifest.lua'] + manifest_files
missing_install = [p for p in expected_install if p not in install_files]
extra_install = [p for p in install_files if p not in expected_install]
if missing_install or extra_install:
    msg = []
    if missing_install: msg.append('install.lua missing: ' + ', '.join(missing_install))
    if extra_install: msg.append('install.lua extra: ' + ', '.join(extra_install))
    raise SystemExit('\n'.join(msg))
versions = {
    'config.lua': re.search(r'version\s*=\s*"([^"]+)"', Path('craftmind/config.lua').read_text()).group(1),
    'manifest.lua': re.search(r'version\s*=\s*"([^"]+)"', manifest).group(1),
    'install.lua': re.search(r'REMOTE_VERSION\s*=\s*"([^"]+)"', install).group(1),
}
if len(set(versions.values())) != 1:
    raise SystemExit('version mismatch: ' + repr(versions))
print(f'OK: {len(manifest_files)} manifest files, version {next(iter(versions.values()))}')
PY
else
  echo "SKIP: python3 not found"
fi

section "ComputerCraft smoke test"
rm -rf .craftos-test
mkdir -p .craftos-test/data .craftos-test/workspace
if command -v craftos >/dev/null 2>&1; then
  timeout 30s craftos \
    --headless \
    --directory "$ROOT/.craftos-test/data" \
    --mount-ro craftmind="$ROOT/craftmind" \
    --mount-ro tests="$ROOT/tests" \
    --mount-rw workspace="$ROOT/.craftos-test/workspace" \
    --script "$ROOT/tests/computercraft-ci.lua"
elif command -v flatpak >/dev/null 2>&1 && flatpak list --app 2>/dev/null | grep -q 'cc.craftos_pc.CraftOS-PC'; then
  timeout 30s flatpak run \
    --filesystem="$ROOT":ro \
    --filesystem="$ROOT/.craftos-test":rw \
    cc.craftos_pc.CraftOS-PC \
    --headless \
    --directory "$ROOT/.craftos-test/data" \
    --mount-ro craftmind="$ROOT/craftmind" \
    --mount-ro tests="$ROOT/tests" \
    --mount-rw workspace="$ROOT/.craftos-test/workspace" \
    --script "$ROOT/tests/computercraft-ci.lua"
else
  echo "SKIP: CraftOS-PC not detected. Install flatpak app: flatpak install flathub cc.craftos_pc.CraftOS-PC"
fi

section "Done"
