#!/usr/bin/env bash
set -euo pipefail

READY=/run/firewall-ready
rm -f "$READY"

if [ "${FIREWALL:-on}" = "off" ]; then
  echo "[firewall] desactivado (FIREWALL=off)"
  touch "$READY"
  exit 0
fi

# Sin telemetría (statsig, sentry): Claude Code no la envía con
# CLAUDE_CODE_DISABLE_NONESSENTIAL_TRAFFIC y cada destino abierto es una vía de salida.
DOMAINS=(
  api.anthropic.com console.anthropic.com
  claude.ai claude.com platform.claude.com
  registry.npmjs.org pypi.org files.pythonhosted.org
  opencode.ai models.dev
  update.code.visualstudio.com vscode.download.prss.microsoft.com marketplace.visualstudio.com
)
ALLOW="${FIREWALL_ALLOW:-}"
read -ra EXTRA <<< "${ALLOW//,/ }"

# Para distinguir "sin internet" de "el cortafuegos rompe el DNS" al final.
dns_antes=no
if getent hosts api.anthropic.com >/dev/null; then dns_antes=si; fi

iptables -F
iptables -X
ipset destroy allowed 2>/dev/null || true
ipset create allowed hash:net

allow() {
  local item=$1 ips
  if [[ $item =~ ^[0-9.]+(/[0-9]+)?$ ]]; then
    ipset add -exist allowed "$item"
    return
  fi
  ips=$(getent ahostsv4 "$item" | awk '{print $1}' | sort -u || true)
  if [ -z "$ips" ]; then
    echo "[firewall] aviso: no se resuelve $item"
    return
  fi
  for ip in $ips; do ipset add -exist allowed "$ip"; done
}

for d in "${DOMAINS[@]}" "${EXTRA[@]}"; do allow "$d"; done

if gh_ranges=$(curl -sf --max-time 10 https://api.github.com/meta \
    | jq -r '(.web + .api + .git)[] | select(contains(":") | not)'); then
  for r in $gh_ranges; do ipset add -exist allowed "$r"; done
else
  echo "[firewall] aviso: no se pudieron obtener las direcciones de GitHub"
fi

# Modelo local (LM Studio, Ollama o llama.cpp): solo su puerto. Ni el resto de
# puertos del PC ni los contenedores de otros proyectos.
allow_modelo() {
  local url="${LOCAL_URL:-http://host.docker.internal:1234}" dir host port ips=""
  dir="${url#*://}"; dir="${dir%%/*}"
  if [[ $dir == \[* ]]; then
    echo "[firewall] aviso: el modelo local por IPv6 no está soportado ($url)"
    return
  fi
  host="${dir%%:*}"; port="${dir##*:}"
  if [ "$port" = "$dir" ]; then
    case "$url" in https://*) port=443 ;; *) port=80 ;; esac
  fi
  if ! [[ $port =~ ^[0-9]+$ ]]; then
    echo "[firewall] aviso: LOCAL_URL no válida ($url)"
    return
  fi
  if [[ $host =~ ^[0-9.]+$ ]]; then
    ips=$host
  elif [[ $host == *.* ]]; then
    ips=$(getent ahostsv4 "$host" | awk '{print $1}' | sort -u || true)
  fi
  if [ -n "$ips" ]; then
    for ip in $ips; do iptables -A OUTPUT -p tcp -d "$ip" --dport "$port" -j ACCEPT; done
  else
    # Otro contenedor (llamacpp): su IP cambia al reiniciarse, así que se permite
    # ese puerto en la red de Docker.
    for net in $(ip -o -f inet addr show | awk '$2 != "lo" {print $4}'); do
      iptables -A OUTPUT -p tcp -d "$net" --dport "$port" -j ACCEPT
    done
  fi
}

# El DNS va por el resolvedor de Docker (127.0.0.11, por lo). No se abre el puerto 53
# hacia fuera: sería un túnel para cualquier protocolo. Si en Docker Desktop hay un DNS
# propio ("dns" en Docker Engine), Docker lo consulta desde el contenedor ("ExtServers"
# sin host(...) en resolv.conf): solo se abre hacia esos servidores.
DNS_PROPIOS=$(sed -n 's/^# ExtServers: \[\(.*\)\]$/\1/p' /etc/resolv.conf | tr ' ' '\n' \
  | grep -E '^[0-9.]+$' || true)
iptables -A OUTPUT -o lo -j ACCEPT
iptables -A OUTPUT -m conntrack --ctstate ESTABLISHED,RELATED -j ACCEPT
for dns in $DNS_PROPIOS; do
  iptables -A OUTPUT -p udp -d "$dns" --dport 53 -j ACCEPT
  iptables -A OUTPUT -p tcp -d "$dns" --dport 53 -j ACCEPT
done
allow_modelo
iptables -A OUTPUT -m set --match-set allowed dst -j ACCEPT
iptables -A OUTPUT -j REJECT --reject-with icmp-admin-prohibited
iptables -P OUTPUT DROP
iptables -P FORWARD DROP

if command -v ip6tables >/dev/null && ip6tables -L >/dev/null 2>&1; then
  ip6tables -F
  ip6tables -A OUTPUT -o lo -j ACCEPT
  ip6tables -P OUTPUT DROP
fi

if curl -s --max-time 5 -o /dev/null https://example.com; then
  echo "[firewall] ERROR: el tráfico no permitido no se bloquea"
  exit 1
fi
# Prueba con un servidor DNS público que no esté permitido a propósito.
for prueba in 1.1.1.1 9.9.9.9; do
  if ipset test allowed "$prueba" 2>/dev/null || grep -qxF "$prueba" <<<"$DNS_PROPIOS"; then continue; fi
  if timeout 3 bash -c "</dev/tcp/$prueba/53" 2>/dev/null; then
    echo "[firewall] ERROR: el puerto 53 hacia fuera no se bloquea"
    exit 1
  fi
  break
done
if [ "$dns_antes" = si ] && ! getent hosts api.anthropic.com >/dev/null; then
  echo "[firewall] ERROR: con el cortafuegos activo no se resuelven nombres"
  echo "[firewall]   → Actualiza Docker Desktop (hace falta Docker Engine 26 o posterior)"
  echo "[firewall]   → Si has puesto un DNS en Docker Desktop (Settings → Docker Engine, \"dns\"), prueba a quitarlo"
  exit 1
fi
if ! curl -s --max-time 10 -o /dev/null https://api.anthropic.com; then
  echo "[firewall] aviso: api.anthropic.com no responde"
fi

touch "$READY"
echo "[firewall] activo"
