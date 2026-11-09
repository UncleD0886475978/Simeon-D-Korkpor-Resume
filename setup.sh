#!/usr/bin/env bash
# setup.sh — Simeon-D-Korkpor-Resume
# Verified from package.json: this is a TypeScript Shopify Hydrogen
# (Remix + Vite) app — package name "hydrogen-storefront".
# Scripts in package.json: build = "remix vite:build" (exists, so it is
# run below), dev = "shopify hydrogen dev --codegen",
# preview = "netlify serve", typecheck = "tsc", lint = eslint.
# Engines: node >= 18.
# VM bootstrap: on a fresh Ubuntu/Debian VM this script INSTALLS its own
# prerequisites (git/curl base tools, then Node.js 20.x from NodeSource)
# and builds end-to-end. On non-apt platforms it falls back to
# check-and-guide.
set -e

REPO_NAME="Simeon-D-Korkpor-Resume"
OWNER="UncleD0886475978"
REPO_URL="https://github.com/${OWNER}/${REPO_NAME}.git"
RUN_ONELINE="curl -fsSL https://raw.githubusercontent.com/${OWNER}/${REPO_NAME}/main/setup.sh | bash"

if [ -f "$0" ]; then
  SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
else
  SCRIPT_DIR="$PWD"
fi
# SCRIPT_DIR is only informational here (locate-or-clone below uses $PWD /
# ~/repos); it keeps the curl|bash case ($0 = "bash") from misbehaving.
echo "    Script dir: ${SCRIPT_DIR}"

echo "==> Step 1/6: Platform check + base bootstrap (git, curl)"
SUDO=""
if [ "$(id -u)" -ne 0 ]; then
  if command -v sudo >/dev/null 2>&1; then
    SUDO="sudo"
  else
    echo "ERROR: this script needs root or sudo to install packages."
    exit 1
  fi
fi
APT=0
if [ "$(uname -s)" = "Linux" ] && command -v apt-get >/dev/null 2>&1; then APT=1; fi
INSTALLED=""
APT_UPDATED=""
note_installed() { INSTALLED="${INSTALLED} $1"; }
apt_update_once() {
  if [ -z "${APT_UPDATED}" ]; then $SUDO apt-get update -y; APT_UPDATED=1; fi
}
apt_install() {
  apt_update_once
  DEBIAN_FRONTEND=noninteractive $SUDO apt-get install -y "$@"
}
if [ "${APT}" -eq 1 ]; then
  BASE_PKGS=""
  command -v git >/dev/null 2>&1 || BASE_PKGS="${BASE_PKGS} git"
  command -v curl >/dev/null 2>&1 || BASE_PKGS="${BASE_PKGS} curl"
  [ -f /etc/ssl/certs/ca-certificates.crt ] || BASE_PKGS="${BASE_PKGS} ca-certificates"
  command -v gpg >/dev/null 2>&1 || BASE_PKGS="${BASE_PKGS} gnupg"
  if [ -n "${BASE_PKGS}" ]; then
    echo "    Installing base tools:${BASE_PKGS}"
    # shellcheck disable=SC2086
    apt_install ${BASE_PKGS}
    note_installed "${BASE_PKGS}"
  else
    echo "    Base tools already present (git, curl, ca-certificates, gnupg)."
  fi
else
  echo "    Non-apt platform detected — bootstrap will only CHECK tools and print install guidance."
fi

install_node() {
  if command -v node >/dev/null 2>&1 && command -v npm >/dev/null 2>&1; then echo "    node + npm: already present ($(node --version))"; return 0; fi
  [ "${APT}" -eq 1 ] || return 1
  echo "    Installing Node.js 20.x from NodeSource..."
  if [ -n "${SUDO}" ]; then
    curl -fsSL https://deb.nodesource.com/setup_20.x | $SUDO -E bash -
  else
    curl -fsSL https://deb.nodesource.com/setup_20.x | bash -
  fi
  apt_install nodejs
  note_installed "nodejs"
}

echo "==> Step 2/6: Locate the repo"
if [ -f "package.json" ] && [ -f "vite.config.ts" ]; then
  REPO_DIR="$PWD"
  echo "    Already inside the repo checkout: $REPO_DIR"
else
  if ! command -v git >/dev/null 2>&1; then
    echo "    ERROR: git not found. Install it from: https://git-scm.com/downloads"
    exit 1
  fi
  REPO_DIR="$HOME/repos/$REPO_NAME"
  if [ -d "$REPO_DIR/.git" ]; then
    echo "    Existing checkout found — pulling latest..."
    git -C "$REPO_DIR" pull --ff-only || true
  else
    echo "    Cloning $REPO_URL into $REPO_DIR ..."
    mkdir -p "$HOME/repos"
    git clone "$REPO_URL" "$REPO_DIR"
  fi
fi
cd "$REPO_DIR"

echo "==> Step 3/6: Bootstrap prerequisites (Node.js + npm; need Node >= 18, per package.json engines)"
MISSING_LIST=""
install_node || MISSING_LIST="${MISSING_LIST} node(https://nodejs.org — install the LTS)"
if [ -n "${MISSING_LIST}" ]; then
  echo "ERROR: could not auto-install on this platform. Missing:${MISSING_LIST}"
  echo "Install the tool(s) manually, then re-run this script."
  exit 1
fi
echo "    node: $(node --version)   npm: $(npm --version)"
NODE_MAJOR=$(node --version | sed 's/^v//' | cut -d. -f1)
if [ "$NODE_MAJOR" -lt 18 ]; then
  echo "    WARNING: package.json requires Node >= 18; you have $(node --version). Expect build failures — upgrade at https://nodejs.org"
fi

echo "==> Step 4/6: Environment file"
if [ ! -f ".env" ] && [ -f ".env.example" ]; then
  cp .env.example .env
  echo "    Created .env from .env.example — edit it and set your store values"
  echo "    (PUBLIC_STORE_DOMAIN can be 'mock.shop' to try the demo store)."
else
  echo "    .env already present (or no .env.example) — leaving it as-is."
fi

echo "==> Step 5/6: Install dependencies (npm install)"
npm install

echo "==> Step 6/6: Build (npm run build — 'remix vite:build', defined in package.json)"
npm run build
echo "    Build output is in: $REPO_DIR/dist (netlify.toml publishes dist/client)"

cat <<EOF

=================== BOOTSTRAP SUMMARY ===================
Installed during this run:${INSTALLED:- (nothing — all tools were already present)}
Working copy: ${REPO_DIR}
Next time, set up from scratch on any fresh Ubuntu VM with one line:
  ${RUN_ONELINE}
=========================================================
EOF

echo ""
echo "============================================================"
echo "Done. Build succeeded for $REPO_NAME (Shopify Hydrogen / Remix / TypeScript)."
echo ""
echo "Next commands:"
echo "  Run (dev):     npm run dev        # 'shopify hydrogen dev --codegen' — prints a local URL (usually http://localhost:3000)"
echo "  Run (preview): npm run preview    # 'netlify serve' — serves the production build locally"
echo "  Checks:        npm run typecheck  # tsc"
echo "                 npm run lint       # eslint"
echo "  Stop:          Ctrl+C in the terminal running the dev/preview server"
echo "  Logs:          Dev/preview server output stays in that same terminal"
echo "============================================================"
