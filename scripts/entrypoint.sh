#!/usr/bin/env bash
set -euo pipefail

/usr/local/bin/firewall.sh

# La clave de API solo la puede leer root; el proxy la añade a las peticiones de Claude
# Code con API (ver firewall.sh y scripts/ia).
SECRETO=/run/secrets/anthropic_api_key
if [ -e "$SECRETO" ]; then
  chmod 0400 "$SECRETO" || true
  if [ "$(stat -c %u%a "$SECRETO")" != "0400" ]; then
    echo "[entorno] ERROR: la clave de API sería legible por los agentes ($SECRETO)"
    exit 1
  fi
fi

as_node() { setpriv --reuid=node --regid=node --init-groups -- "$@"; }

git_config() { as_node git config --global "$@" || echo "[entorno] aviso: no se pudo fijar git $1"; }

if [ -n "${GIT_USER_NAME:-}" ]; then git_config user.name "$GIT_USER_NAME"; fi
if [ -n "${GIT_USER_EMAIL:-}" ]; then git_config user.email "$GIT_USER_EMAIL"; fi
git_config init.defaultBranch main
git_config core.autocrlf input

exec setpriv --reuid=node --regid=node --init-groups -- "$@"
