FROM node:22-bookworm-slim

# Versión de la imagen. iniciar.ps1 la compara con la suya y, si no coincide,
# descarga o reconstruye la imagen. Súbela cuando cambie algo de esta imagen.
LABEL bulkhead.version="7"
LABEL org.opencontainers.image.source="https://github.com/abarriuso/bulkhead"

RUN apt-get update \
 && apt-get install -y --no-install-recommends \
      git curl ca-certificates openssh-client gnupg less nano jq ripgrep procps python3 python3-venv python3-pip \
      iptables iproute2 squid-openssl openssl \
 && curl -fsSL https://cli.github.com/packages/githubcli-archive-keyring.gpg \
      -o /usr/share/keyrings/githubcli-archive-keyring.gpg \
 && echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/githubcli-archive-keyring.gpg] https://cli.github.com/packages stable main" \
      > /etc/apt/sources.list.d/github-cli.list \
 && apt-get update && apt-get install -y --no-install-recommends gh \
 && rm -rf /var/lib/apt/lists/*

RUN npm install -g @anthropic-ai/claude-code opencode-ai \
 && npm cache clean --force

COPY scripts/ia scripts/entrypoint.sh scripts/firewall.sh /usr/local/bin/
COPY plantillas/ /usr/local/share/bulkhead/
RUN sed -i 's/\r$//' /usr/local/bin/ia /usr/local/bin/entrypoint.sh /usr/local/bin/firewall.sh \
      /usr/local/share/bulkhead/* \
 && chmod +x /usr/local/bin/ia /usr/local/bin/entrypoint.sh /usr/local/bin/firewall.sh \
 && mkdir -p /etc/claude-code /etc/opencode \
 && cp /usr/local/share/bulkhead/ENTORNO.md /etc/claude-code/CLAUDE.md \
 && cp /usr/local/share/bulkhead/politica-claude.json /etc/claude-code/managed-settings.json \
 && cp /usr/local/share/bulkhead/politica-opencode.json /etc/opencode/opencode.json \
 && mkdir -p /workspace && chown node:node /workspace \
 && install -d -o root -g proxy -m 2750 /etc/bulkhead-proxy \
 && install -d -o proxy -g proxy -m 0750 /var/lib/bulkhead-proxy \
 && install -d -o proxy -g proxy -m 0755 /var/log/bulkhead-proxy

# OpenCode no carga la configuración, los agentes ni los plugins que traiga el
# repositorio: podrían saltarse /etc/opencode/opencode.json o ejecutar código al abrirlo.
# Las instrucciones del proyecto (AGENTS.md, CLAUDE.md) sí se leen desde esa política.
# Tampoco descarga el catálogo de modelos ni busca actualizaciones: solo usa el modelo local.
ENV HOME=/home/node \
    OPENCODE_DISABLE_PROJECT_CONFIG=1 \
    OPENCODE_DISABLE_MODELS_FETCH=1 \
    OPENCODE_DISABLE_AUTOUPDATE=1

# Toda la salida a internet pasa por el proxy del cortafuegos (scripts/firewall.sh). Su
# autoridad de certificados se crea al arrancar el contenedor; pip y Python no usan la
# del sistema si no se les dice.
ENV HTTPS_PROXY=http://127.0.0.1:3128 https_proxy=http://127.0.0.1:3128 \
    HTTP_PROXY=http://127.0.0.1:3128 http_proxy=http://127.0.0.1:3128 \
    NO_PROXY=localhost,127.0.0.1,::1,host.docker.internal,llamacpp \
    no_proxy=localhost,127.0.0.1,::1,host.docker.internal,llamacpp \
    NODE_EXTRA_CA_CERTS=/usr/local/share/ca-certificates/bulkhead-proxy.crt \
    PIP_CERT=/etc/ssl/certs/ca-certificates.crt \
    REQUESTS_CA_BUNDLE=/etc/ssl/certs/ca-certificates.crt \
    SSL_CERT_FILE=/etc/ssl/certs/ca-certificates.crt
WORKDIR /workspace

HEALTHCHECK --interval=5s --timeout=3s --start-period=60s --retries=3 CMD ["test", "-f", "/run/firewall-ready"]

ENTRYPOINT ["entrypoint.sh"]
CMD ["sleep", "infinity"]
