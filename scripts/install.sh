#!/usr/bin/env bash
# Copyright 2026 Emilian Scibisz
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
# =============================================================================
# install.sh — CloudPanel Turnstile installer
#
# Installs Cloudflare Turnstile protection on the CloudPanel login page.
# Safe to re-run at any time. Also used as reapply script after CloudPanel updates.
#
# Usage:
#   chmod +x install.sh
#   TURNSTILE_SITE_KEY=<your-site-key> TURNSTILE_SECRET=<your-secret> ./install.sh
#
# Test keys (always pass, use during development):
#   TURNSTILE_SITE_KEY=1x00000000000000000000AA
#   TURNSTILE_SECRET=1x0000000000000000000000000000000AA
# =============================================================================

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

CLP_PUBLIC="/home/clp/htdocs/app/files/public"
CLP_LOGIN_TWIG="/home/clp/htdocs/app/files/templates/Frontend/Login/login.html.twig"
CLP_CACHE_DIR="/home/clp/htdocs/app/files/var/cache/prod"
CLP_CONSOLE="/home/clp/htdocs/app/files/bin/console"
CLP_USER="clp"

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m'

info()    { echo -e "${GREEN}[INFO]${NC} $*"; }
warn()    { echo -e "${YELLOW}[WARN]${NC} $*"; }
error()   { echo -e "${RED}[ERROR]${NC} $*" >&2; exit 1; }

# ---- Interactive key input (unless already set via env) -----------------------

echo ""
echo -e "${CYAN}╔══════════════════════════════════════════════════╗${NC}"
echo -e "${CYAN}║   CloudPanel Turnstile Installer                 ║${NC}"
echo -e "${CYAN}╚══════════════════════════════════════════════════╝${NC}"
echo ""
echo -e "Get your keys at: ${CYAN}https://dash.cloudflare.com → Turnstile${NC}"
echo -e "Leave blank to use ${YELLOW}test keys${NC} (red 'testing only' banner)."
echo ""

if [ -z "${TURNSTILE_SITE_KEY:-}" ]; then
    read -rp "  Site Key   (public):  " INPUT_SITE_KEY
    SITE_KEY="${INPUT_SITE_KEY:-1x00000000000000000000AA}"
else
    SITE_KEY="$TURNSTILE_SITE_KEY"
fi

if [ -z "${TURNSTILE_SECRET:-}" ]; then
    read -rsp "  Secret Key (private): " INPUT_SECRET
    echo ""
    SECRET="${INPUT_SECRET:-1x0000000000000000000000000000000AA}"
else
    SECRET="$TURNSTILE_SECRET"
fi

echo ""

if [ "$SITE_KEY" = "1x00000000000000000000AA" ]; then
    warn "Using TEST keys — widget will show a red 'testing only' banner."
else
    info "Using production keys."
fi
echo ""

# ---- Checks ------------------------------------------------------------------

[ "$(id -u)" -eq 0 ] || error "Run as root."
[ -d "$CLP_PUBLIC" ]  || error "CloudPanel public dir not found: $CLP_PUBLIC"

# ---- Deploy ts-verify.php ----------------------------------------------------

info "Deploying ts-verify.php..."
sed "s|1x0000000000000000000000000000000AA|${SECRET}|g" \
    "${SCRIPT_DIR}/src/ts-verify.php" > "${CLP_PUBLIC}/ts-verify.php"
chown "${CLP_USER}:${CLP_USER}" "${CLP_PUBLIC}/ts-verify.php"
chmod 640 "${CLP_PUBLIC}/ts-verify.php"
info "ts-verify.php deployed to ${CLP_PUBLIC}/ts-verify.php"

# ---- Patch login.html.twig ---------------------------------------------------

info "Patching login.html.twig..."

# Backup current twig (only once — don't overwrite existing backup)
BACKUP="${CLP_LOGIN_TWIG}.orig"
if [ ! -f "$BACKUP" ]; then
    cp "$CLP_LOGIN_TWIG" "$BACKUP"
    chown root:root "$BACKUP"
    info "Original backed up to ${BACKUP}"
fi

sed "s|{{ turnstile_site_key }}|${SITE_KEY}|g" \
    "${SCRIPT_DIR}/src/login.html.twig" > "$CLP_LOGIN_TWIG"
chown "${CLP_USER}:${CLP_USER}" "$CLP_LOGIN_TWIG"
chmod 664 "$CLP_LOGIN_TWIG"
info "login.html.twig patched."

# ---- Clear Symfony cache (as clp user) ---------------------------------------

info "Clearing Symfony cache..."
rm -rf "$CLP_CACHE_DIR"
sudo -u "$CLP_USER" php "$CLP_CONSOLE" cache:warmup --env=prod --no-debug -q
info "Cache rebuilt."

echo ""
echo -e "${GREEN}✓ Cloudflare Turnstile installed successfully!${NC}"
echo ""
echo "  Login page:   https://<your-domain>/login"
echo "  Verify API:   https://<your-domain>/ts-verify.php"
echo ""
echo "  Site key used: ${SITE_KEY}"
echo ""
echo -e "${YELLOW}Note:${NC} After each CloudPanel update, re-run this script:"
echo "  TURNSTILE_SITE_KEY=${SITE_KEY} TURNSTILE_SECRET=<secret> ./install.sh"
