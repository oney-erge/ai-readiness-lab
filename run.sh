#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "${BASH_SOURCE[0]}")"
action=run;case "${1:-}" in run|doctor|repair|docker|stop|logs)action=$1;shift;;esac
no_browser=0;for arg in "$@";do [ "$arg" = --no-browser ]&&no_browser=1||{ echo "unknown option: $arg" >&2;exit 2;};done
uv_version=0.12.5;node_version=24.15.0;url=http://127.0.0.1:8123
find_uv(){ command -v uv 2>/dev/null||{ [ -x "$HOME/.local/bin/uv" ]&&{ echo "$HOME/.local/bin/uv";return;};[ -x "$HOME/.cargo/bin/uv" ]&&{ echo "$HOME/.cargo/bin/uv";return;};return 1;};}
retry(){ local label=$1;shift;for n in 1 2 3;do "$@"&&return;[ "$n" -eq 3 ]&&{ echo "$label failed" >&2;return 1;};sleep $((1<<(n-1)));done;}
install_uv(){ local file;file=$(mktemp);if command -v curl>/dev/null 2>&1;then retry "uv download" curl -fsSL "https://astral.sh/uv/${uv_version}/install.sh" -o "$file";else retry "uv download" wget -qO "$file" "https://astral.sh/uv/${uv_version}/install.sh";fi;sh "$file";rm -f "$file";find_uv;}
ensure_node(){
  if command -v node>/dev/null 2>&1&&node -e 'const [a,b,c]=process.versions.node.split(".").map(Number);process.exit(a>22||(a===22&&(b>22||(b===22&&c>=2)))?0:1)';then command -v npm;return;fi
  local os arch archive root expected actual file checksums
  case "$(uname -s)" in Darwin)os=darwin;;Linux)os=linux;;*)echo "Unsupported platform for portable Node.js." >&2;return 1;;esac
  case "$(uname -m)" in x86_64|amd64)arch=x64;;arm64|aarch64)arch=arm64;;*)echo "Unsupported CPU architecture." >&2;return 1;;esac
  archive="node-v${node_version}-${os}-${arch}.tar.xz";root="$PWD/.runtime/node-v${node_version}-${os}-${arch}"
  [ -x "$root/bin/npm" ]&&{ echo "$root/bin/npm";return;};mkdir -p .runtime;file=$(mktemp);checksums=$(mktemp)
  if command -v curl>/dev/null 2>&1;then retry "Node.js download" curl -fsSL "https://nodejs.org/dist/v${node_version}/${archive}" -o "$file";retry "Node.js checksum download" curl -fsSL "https://nodejs.org/dist/v${node_version}/SHASUMS256.txt" -o "$checksums";else retry "Node.js download" wget -qO "$file" "https://nodejs.org/dist/v${node_version}/${archive}";retry "Node.js checksum download" wget -qO "$checksums" "https://nodejs.org/dist/v${node_version}/SHASUMS256.txt";fi
  expected=$(awk -v name="$archive" '$2==name{print $1}' "$checksums");[ -n "$expected" ]||{ echo "Official checksum is missing." >&2;return 1;}
  if command -v sha256sum>/dev/null 2>&1;then actual=$(sha256sum "$file"|cut -d' ' -f1);else actual=$(shasum -a 256 "$file"|cut -d' ' -f1);fi;[ "$actual" = "$expected" ]||{ echo "Node.js archive checksum mismatch." >&2;return 1;}
  rm -rf "$root.tmp";mkdir -p "$root.tmp";tar -xJf "$file" -C "$root.tmp" --strip-components=1;mv "$root.tmp" "$root";rm -f "$file" "$checksums";echo "$root/bin/npm"
}
check(){ if command -v curl>/dev/null 2>&1;then curl -fsS --max-time 2 "$url/health">/dev/null;else wget -qO- --timeout=2 "$url/health">/dev/null;fi;}
wait_ready(){ for _ in $(seq 1 120);do check 2>/dev/null&&return;sleep .5;done;return 1;}
open_url(){ [ "$no_browser" -eq 1 ]&&return;command -v open>/dev/null 2>&1&&open "$url"||command -v xdg-open>/dev/null 2>&1&&xdg-open "$url"||true;}
case "$action" in docker|stop|logs)command -v docker>/dev/null 2>&1||{ echo "Docker is not installed." >&2;exit 1;};docker info>/dev/null 2>&1||{ echo "Docker engine is not running." >&2;exit 1;};[ "$action" = stop ]&&exec docker compose down;[ "$action" = logs ]&&exec docker compose logs --follow;docker compose up -d --build;wait_ready||{ docker compose logs;exit 1;};echo "AI Readiness Lab is ready at $url";open_url;exit 0;;esac
if [ "$action" = doctor ];then [ -x .venv/bin/python ]&&[ -f frontend/dist/index.html ]||{ echo "Environment incomplete. Run ./run.sh once." >&2;exit 1;};check 2>/dev/null&&echo "Server: $url"||echo "Server: not running";exit 0;fi
uv=$(find_uv||true);[ -n "$uv" ]||uv=$(install_uv);"$uv" python install 3.11;[ -x .venv/bin/python ]||"$uv" venv --python 3.11 .venv
pip_args=(pip install --python .venv/bin/python --requirement backend/requirements-desktop.txt);[ "$action" = repair ]&&pip_args+=(--reinstall);retry "Python dependency synchronization" "$uv" "${pip_args[@]}"
npm=$(ensure_node);export PATH="$(dirname "$npm"):$PATH";if command -v sha256sum>/dev/null 2>&1;then hash=$(sha256sum frontend/package-lock.json|cut -d' ' -f1);else hash=$(shasum -a 256 frontend/package-lock.json|cut -d' ' -f1);fi;stored=$(cat frontend/node_modules/.airl-build 2>/dev/null||true);if [ "$action" = repair ]||[ "$stored" != "$hash" ]||[ ! -f frontend/dist/index.html ];then(cd frontend&&retry "frontend dependency installation" "$npm" ci&&"$npm" run build);printf %s "$hash">frontend/node_modules/.airl-build;fi
export PYTHONPATH="$PWD/backend"
if [ "$no_browser" -eq 1 ];then cd backend;exec ../.venv/bin/python -m uvicorn app.main:app --host 127.0.0.1 --port 8123;fi
exec .venv/bin/python desktop/launcher.py
