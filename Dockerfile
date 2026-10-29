FROM node:22-bookworm-slim

# Versión de la imagen. iniciar.ps1 la compara con la suya y, si no coincide,
# descarga o reconstruye la imagen. Súbela cuando cambie algo de esta imagen.
LABEL entorno-ia.version="5"
LABEL org.opencontainers.image.source="https://github.com/abarriuso/claude-code-local-llm-docker"

RUN apt-get update \
 && apt-get install -y --no-install-recommends \
      git curl ca-certificates openssh-client gnupg less nano jq ripgrep procps python3 python3-venv python3-pip \
      iptables ipset iproute2 \
 && curl -fsSL https://cli.github.com/packages/githubcli-archive-keyring.gpg \
      -o /usr/share/keyrings/githubcli-archive-keyring.gpg \
 && echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/githubcli-archive-keyring.gpg] https://cli.github.com/packages stable main" \
      > /etc/apt/sources.list.d/github-cli.list \
 && apt-get update && apt-get install -y --no-install-recommends gh \
 && rm -rf /var/lib/apt/lists/*

RUN npm install -g @anthropic-ai/claude-code opencode-ai \
 && npm cache clean --force

COPY scripts/ia scripts/entrypoint.sh scripts/firewall.sh /usr/local/bin/
COPY plantillas/ /usr/local/share/entorno-ia/
RUN sed -i 's/\r$//' /usr/local/bin/ia /usr/local/bin/entrypoint.sh /usr/local/bin/firewall.sh \
      /usr/local/share/entorno-ia/* \
 && chmod +x /usr/local/bin/ia /usr/local/bin/entrypoint.sh /usr/local/bin/firewall.sh \
 && mkdir -p /etc/claude-code /etc/opencode \
 && cp /usr/local/share/entorno-ia/ENTORNO.md /etc/claude-code/CLAUDE.md \
 && cp /usr/local/share/entorno-ia/politica-claude.json /etc/claude-code/managed-settings.json \
 && cp /usr/local/share/entorno-ia/politica-opencode.json /etc/opencode/opencode.json \
 && mkdir -p /workspace && chown node:node /workspace

# OpenCode no carga la configuración, los agentes ni los plugins que traiga el
# repositorio: podrían saltarse /etc/opencode/opencode.json o ejecutar código al abrirlo.
# Las instrucciones del proyecto (AGENTS.md, CLAUDE.md) sí se leen desde esa política.
ENV HOME=/home/node \
    OPENCODE_DISABLE_PROJECT_CONFIG=1
WORKDIR /workspace

HEALTHCHECK --interval=5s --timeout=3s --start-period=60s --retries=3 CMD ["test", "-f", "/run/firewall-ready"]

ENTRYPOINT ["entrypoint.sh"]
CMD ["sleep", "infinity"]
