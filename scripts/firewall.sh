#!/usr/bin/env bash
set -euo pipefail

# Cortafuegos de salida. Los agentes (usuario node) no tienen ni DNS ni salida directa:
# solo pueden hablar con un proxy (Squid, usuario proxy) que únicamente conecta con los
# dominios permitidos. Filtrar por IP no basta: npm, Anthropic y PyPI están detrás de
# CDN (Cloudflare, Fastly) que sirven miles de webs desde las mismas direcciones.

READY=/run/firewall-ready
rm -f "$READY"

CONF=/etc/bulkhead-proxy       # root:proxy 2750 (Dockerfile): node no puede entrar
DATOS=/var/lib/bulkhead-proxy  # proxy:proxy 0750
CA=/usr/local/share/ca-certificates/bulkhead-proxy.crt
SECRETO=/run/secrets/anthropic_api_key

LIBRE=no
if [ "${FIREWALL:-on}" = "off" ]; then LIBRE=si; fi

# Sin telemetría (statsig, sentry): Claude Code no la envía con
# CLAUDE_CODE_DISABLE_NONESSENTIAL_TRAFFIC y cada destino abierto es una vía de salida.
# Un punto delante permite también los subdominios.
DOMAINS=(
  api.anthropic.com console.anthropic.com
  claude.ai claude.com platform.claude.com
  registry.npmjs.org pypi.org files.pythonhosted.org
  github.com api.github.com codeload.github.com uploads.github.com .githubusercontent.com
  update.code.visualstudio.com vscode.download.prss.microsoft.com marketplace.visualstudio.com
)
# Fastly atiende cualquier web suya aunque la conexión se abra con el nombre de un
# dominio permitido (basta otra cabecera Host). En estos el proxy descifra la conexión
# para comprobar también la cabecera. El resto (Cloudflare, GitHub, Azure) la rechaza.
INSPECCIONAR=(pypi.org files.pythonhosted.org vscode.download.prss.microsoft.com)

ALLOW="${FIREWALL_ALLOW:-}"
read -ra EXTRA <<< "${ALLOW//,/ }"
IPS_EXTRA=()
for item in "${EXTRA[@]}"; do
  if [[ $item =~ ^[0-9.]+(/[0-9]+)?$ ]]; then
    IPS_EXTRA+=("$item")
  elif [[ $item =~ ^(\*?\.)?[A-Za-z0-9-]+(\.[A-Za-z0-9-]+)+$ ]]; then
    DOMAINS+=("${item#\*}")
  else
    echo "[firewall] aviso: se ignora '$item' en FIREWALL_ALLOW (no es un dominio ni una IP)"
  fi
done

como_proxy() { setpriv --reuid=proxy --regid=proxy --init-groups -- "$@"; }
como_node() { setpriv --reuid=node --regid=node --init-groups -- "$@"; }

# Para distinguir "sin internet" de "el cortafuegos rompe el DNS" al final.
dns_antes=no
if getent hosts api.anthropic.com >/dev/null; then dns_antes=si; fi

# Modelo local (LM Studio, Ollama o llama.cpp): solo su IP y su puerto. Ni el resto de
# puertos del PC ni los contenedores de otros proyectos. Como el agente no tiene DNS,
# el nombre va a /etc/hosts.
MODELO_HOST="" MODELO_PUERTO="" MODELO_IPS=""
resolver_modelo() {
  local url="${LOCAL_URL:-http://host.docker.internal:1234}" dir hosts
  hosts=$(grep -v '# bulkhead$' /etc/hosts || true)
  printf '%s\n' "$hosts" > /etc/hosts
  dir="${url#*://}"; dir="${dir%%/*}"
  if [[ $dir == \[* ]]; then
    echo "[firewall] aviso: el modelo local por IPv6 no está soportado ($url)"
    return
  fi
  MODELO_HOST="${dir%%:*}"; MODELO_PUERTO="${dir##*:}"
  if [ "$MODELO_PUERTO" = "$dir" ]; then
    case "$url" in https://*) MODELO_PUERTO=443 ;; *) MODELO_PUERTO=80 ;; esac
  fi
  if ! [[ $MODELO_PUERTO =~ ^[0-9]+$ && $MODELO_HOST =~ ^[A-Za-z0-9.-]+$ ]]; then
    echo "[firewall] aviso: LOCAL_URL no válida ($url)"
    MODELO_HOST=""
    return
  fi
  if [[ $MODELO_HOST =~ ^[0-9.]+$ ]]; then
    MODELO_IPS=$MODELO_HOST
    return
  fi
  MODELO_IPS=$(getent ahostsv4 "$MODELO_HOST" | awk '{print $1}' | sort -u || true)
  if [ -z "$MODELO_IPS" ]; then
    echo "[firewall] aviso: no se resuelve $MODELO_HOST (modelo local)"
    return
  fi
  if ! getent -s files hosts "$MODELO_HOST" >/dev/null; then
    echo "${MODELO_IPS%%$'\n'*} $MODELO_HOST # bulkhead" >> /etc/hosts
  fi
}

configurar_proxy() {
  local d e clave api=no
  umask 027
  rm -f "${CONF:?}"/*
  # Autoridad propia de este contenedor, nueva en cada arranque, para descifrar los
  # dominios de INSPECCIONAR. Solo la reconoce este contenedor.
  openssl req -x509 -newkey rsa:2048 -nodes -days 3650 -subj "/CN=bulkhead proxy" \
    -addext "basicConstraints=critical,CA:TRUE" -addext "keyUsage=critical,keyCertSign,cRLSign" \
    -keyout "$CONF/ca.key" -out "$CONF/ca.pem" 2>/dev/null
  chmod 0640 "$CONF/ca.key" "$CONF/ca.pem"
  install -m 0644 "$CONF/ca.pem" "$CA"
  update-ca-certificates >/dev/null 2>&1

  printf '%s\n' "${DOMAINS[@]}" | sort -u > "$CONF/permitidos"
  printf '%s\n' "${INSPECCIONAR[@]}" > "$CONF/inspeccionar"
  for d in "${DOMAINS[@]}"; do
    e=${d#.}; e=${e//./\\.}
    if [[ $d == .* ]]; then echo "(^|\.)$e(:443)?\$"; else echo "^$e(:443)?\$"; fi
  done | sort -u > "$CONF/host-permitido"

  # La clave de API no llega a los agentes: el proxy la añade a las peticiones que
  # Claude Code con API envía a 127.0.0.1:3129 (ver "ia claude-api").
  if [ -s "$SECRETO" ]; then
    clave=$(cat "$SECRETO")
    if [[ $clave =~ ^[A-Za-z0-9_-]+$ ]]; then
      printf 'request_header_add X-Api-Key "%s" puerto_api\n' "$clave" > "$CONF/clave.conf"
      api=si
    else
      echo "[firewall] aviso: ANTHROPIC_API_KEY tiene caracteres no válidos: no se usa"
    fi
  fi

  {
    cat <<EOF
http_port 127.0.0.1:3128 ssl-bump tls-cert=$CONF/ca.pem tls-key=$CONF/ca.key generate-host-certificates=on dynamic_cert_mem_cache_size=4MB
sslcrtd_program /usr/lib/squid/security_file_certgen -s $DATOS/certs -M 4MB
sslcrtd_children 4 startup=1 idle=1
pid_filename $DATOS/squid.pid
cache_log $DATOS/cache.log
coredump_dir $DATOS
umask 022
cache deny all
cache_mem 8 MB
logfile_rotate 0
forwarded_for delete
via off
httpd_suppress_version_string on
shutdown_lifetime 1 seconds
logformat bulkhead %tl %Ss/%>Hs %rm %ru host=%{Host}>h sni=%ssl::>sni
access_log stdio:/var/log/bulkhead-proxy/conexiones.log logformat=bulkhead
pinger_enable off

acl CONNECT method CONNECT
acl puerto443 port 443
acl cifrado proto HTTPS
acl paso1 at_step SslBump1
EOF
    if [ "$api" = si ]; then
      cat <<EOF
http_port 127.0.0.1:3129 accel defaultsite=api.anthropic.com no-vhost name=api
acl puerto_api myportname api
cache_peer api.anthropic.com parent 443 0 no-query no-digest originserver tls tls-domain=api.anthropic.com forcedomain=api.anthropic.com name=anthropic
cache_peer_access anthropic allow puerto_api
cache_peer_access anthropic deny all
never_direct allow puerto_api
request_header_access X-Api-Key deny puerto_api
request_header_access Authorization deny puerto_api
include $CONF/clave.conf
http_access allow puerto_api !CONNECT
http_access deny puerto_api
EOF
    fi
    if [ -n "$MODELO_HOST" ]; then
      # Por si una herramienta manda al proxy lo que va al modelo local en vez de ir directa.
      if [[ $MODELO_HOST =~ ^[0-9.]+$ ]]; then echo "acl modelo dst $MODELO_HOST"
      else echo "acl modelo dstdomain -n $MODELO_HOST"; fi
      echo "acl puerto_modelo port $MODELO_PUERTO"
      echo "http_access allow modelo puerto_modelo !CONNECT"
    fi
    if [ "$LIBRE" = si ]; then
      cat <<EOF
http_access allow all
ssl_bump splice all
EOF
    else
      cat <<EOF
acl permitidos dstdomain -n "$CONF/permitidos"
acl permitidos_sni ssl::server_name "$CONF/permitidos"
acl inspeccionar ssl::server_name "$CONF/inspeccionar"
acl inspeccionar_destino dstdomain -n "$CONF/inspeccionar"
acl host_permitido req_header Host -i "$CONF/host-permitido"
http_access deny CONNECT !puerto443
http_access allow CONNECT permitidos
http_access allow cifrado permitidos host_permitido
http_access deny all
# El nombre que el programa pone en la conexión cifrada (SNI) también tiene que estar
# permitido: si no, se podría pedir un dominio permitido y hablar con otra web de la CDN.
ssl_bump peek paso1
ssl_bump bump inspeccionar
ssl_bump bump inspeccionar_destino
ssl_bump splice permitidos_sni
ssl_bump terminate all
EOF
    fi
  } > "$CONF/squid.conf"
  umask 022
}

arrancar_proxy() {
  local salida
  como_proxy rm -rf "$DATOS/certs" "$DATOS/squid.pid"
  como_proxy /usr/lib/squid/security_file_certgen -c -s "$DATOS/certs" -M 4MB >/dev/null
  if ! salida=$(como_proxy squid -k parse -f "$CONF/squid.conf" 2>&1); then
    echo "$salida" | tail -n 20
    echo "[firewall] ERROR: la configuración del proxy no es válida"
    exit 1
  fi
  como_proxy squid -f "$CONF/squid.conf"
  for _ in $(seq 50); do
    if timeout 1 bash -c '</dev/tcp/127.0.0.1/3128' 2>/dev/null; then return; fi
    sleep 0.2
  done
  tail -n 20 "$DATOS/cache.log" 2>/dev/null || true
  echo "[firewall] ERROR: el proxy no arranca"
  exit 1
}

if [ "$LIBRE" = si ]; then
  echo "[firewall] desactivado (FIREWALL=off)"
  iptables -F || true
  iptables -P OUTPUT ACCEPT || true
  configurar_proxy
  arrancar_proxy
  touch "$READY"
  exit 0
fi

resolver_modelo

# El DNS va por el resolvedor de Docker (127.0.0.11) y solo para root y el proxy: el
# DNS es un túnel para cualquier dato. Si en Docker Desktop hay un DNS propio ("dns"
# en Docker Engine), Docker lo consulta desde el contenedor ("ExtServers" sin host(...)
# en resolv.conf): solo se abre hacia esos servidores, y para los mismos usuarios.
DNS_PROPIOS=$(sed -n 's/^# ExtServers: \[\(.*\)\]$/\1/p' /etc/resolv.conf | tr ' ' '\n' \
  | grep -E '^[0-9.]+$' || true)
iptables -F
iptables -X
for u in 0 proxy; do
  iptables -A OUTPUT -o lo -d 127.0.0.11 -m owner --uid-owner "$u" -j ACCEPT
done
iptables -A OUTPUT -o lo -d 127.0.0.11 -j REJECT
iptables -A OUTPUT -o lo -j ACCEPT
iptables -A OUTPUT -m conntrack --ctstate ESTABLISHED,RELATED -j ACCEPT
for dns in $DNS_PROPIOS; do
  for u in 0 proxy; do
    iptables -A OUTPUT -p udp -d "$dns" --dport 53 -m owner --uid-owner "$u" -j ACCEPT
    iptables -A OUTPUT -p tcp -d "$dns" --dport 53 -m owner --uid-owner "$u" -j ACCEPT
  done
done
for ip in $MODELO_IPS; do
  iptables -A OUTPUT -p tcp -d "$ip" --dport "$MODELO_PUERTO" -j ACCEPT
done
for ip in "${IPS_EXTRA[@]}"; do iptables -A OUTPUT -d "$ip" -j ACCEPT; done
iptables -A OUTPUT -p tcp --dport 443 -m owner --uid-owner proxy -j ACCEPT
iptables -A OUTPUT -j REJECT --reject-with icmp-admin-prohibited
iptables -P OUTPUT DROP
iptables -P FORWARD DROP

if command -v ip6tables >/dev/null && ip6tables -L >/dev/null 2>&1; then
  ip6tables -F
  ip6tables -A OUTPUT -o lo -j ACCEPT
  ip6tables -A OUTPUT -j REJECT
  ip6tables -P OUTPUT DROP
fi

configurar_proxy
arrancar_proxy

# Comprobaciones, como el usuario de los agentes. Si alguna falla, no arranca nada.
# Directo a la IP de un dominio permitido (sin DNS, el agente no podría ni buscarla).
ip_prueba=$(getent ahostsv4 registry.npmjs.org | awk 'NR==1{print $1}' || true)
if [ -n "$ip_prueba" ] && como_node curl -s --noproxy '*' --max-time 5 -o /dev/null \
    --resolve "registry.npmjs.org:443:$ip_prueba" https://registry.npmjs.org; then
  echo "[firewall] ERROR: se puede salir sin pasar por el proxy"
  exit 1
fi
if como_node curl -sf -x http://127.0.0.1:3128 --max-time 5 -o /dev/null https://example.com; then
  echo "[firewall] ERROR: el proxy deja pasar un dominio no permitido"
  exit 1
fi
if como_node getent hosts example.com >/dev/null; then
  echo "[firewall] ERROR: los agentes pueden usar el DNS"
  exit 1
fi
# Prueba con un servidor DNS público que no esté permitido a propósito.
for prueba in 1.1.1.1 9.9.9.9; do
  if grep -qxF "$prueba" <<<"$DNS_PROPIOS"; then continue; fi
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
if ! como_node curl -s -x http://127.0.0.1:3128 --max-time 10 -o /dev/null https://api.anthropic.com; then
  echo "[firewall] aviso: api.anthropic.com no responde"
fi

touch "$READY"
echo "[firewall] activo"
