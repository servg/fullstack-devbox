# ============================================================
# Full-Stack Dev Box
# Auth gateway + VS Code in browser + Claude Code
# Java 21 + Maven + Node.js 22 + Python 3 + Docker CLI
# ============================================================
FROM ubuntu:22.04

ARG CODE_SERVER_VERSION=4.109.2
ARG NODE_VERSION=22

ENV DEBIAN_FRONTEND=noninteractive
ENV LANG=C.UTF-8
ENV LC_ALL=C.UTF-8

# ── System packages ──────────────────────────────────────────
RUN apt-get update && apt-get install -y \
    curl wget git sudo \
    python3-pip python3-dev \
    build-essential \
    jq unzip zip \
    gnupg apt-transport-https ca-certificates \
    htop tmux dumb-init \
    ffmpeg \
    libreoffice-writer libreoffice-calc libreoffice-impress \
    pandoc poppler-utils \
    tesseract-ocr tesseract-ocr-rus \
    qpdf fonts-liberation fonts-dejavu-core \
    iputils-ping \
    && rm -rf /var/lib/apt/lists/* \
    && ln -s /usr/bin/python3 /usr/bin/python

# ── Docker Engine (Docker-in-Docker) ──────────────────────────
RUN install -m 0755 -d /etc/apt/keyrings \
    && curl -fsSL https://download.docker.com/linux/ubuntu/gpg \
       | gpg --dearmor -o /etc/apt/keyrings/docker.gpg \
    && echo \
       "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] \
       https://download.docker.com/linux/ubuntu \
       $(. /etc/os-release && echo "$VERSION_CODENAME") stable" \
       > /etc/apt/sources.list.d/docker.list \
    && apt-get update \
    && apt-get install -y --no-install-recommends \
       docker-ce docker-ce-cli containerd.io docker-compose-plugin \
    && rm -rf /var/lib/apt/lists/*

# ── Java 21 (Temurin) + Maven ────────────────────────────────
RUN mkdir -p /etc/apt/keyrings \
    && curl -fsSL https://packages.adoptium.net/artifactory/api/gpg/key/public \
        | gpg --dearmor -o /etc/apt/keyrings/adoptium.gpg \
    && echo "deb [signed-by=/etc/apt/keyrings/adoptium.gpg] https://packages.adoptium.net/artifactory/deb $(awk -F= '/^VERSION_CODENAME/{print$2}' /etc/os-release) main" \
        > /etc/apt/sources.list.d/adoptium.list \
    && apt-get update \
    && apt-get install -y temurin-21-jdk maven \
    && rm -rf /var/lib/apt/lists/*

RUN JAVA_HOME_ACTUAL=$(readlink -f /usr/bin/java | sed 's|/bin/java||') \
    && echo "JAVA_HOME=$JAVA_HOME_ACTUAL" >> /etc/environment

ENV JAVA_HOME=/usr/lib/jvm/temurin-21-jdk-amd64
ENV PATH="${JAVA_HOME}/bin:${PATH}"
ENV MAVEN_OPTS="-Xms256m -Xmx1g -Dmaven.repo.local=/home/coder/.m2/repository"

RUN java --version && javac --version && mvn --version

# ── Node.js 22 ───────────────────────────────────────────────
RUN mkdir -p /etc/apt/keyrings \
    && curl -fsSL https://deb.nodesource.com/gpgkey/nodesource-repo.gpg.key \
        | gpg --dearmor -o /etc/apt/keyrings/nodesource.gpg \
    && echo "deb [signed-by=/etc/apt/keyrings/nodesource.gpg] https://deb.nodesource.com/node_${NODE_VERSION}.x nodistro main" \
        > /etc/apt/sources.list.d/nodesource.list \
    && apt-get update \
    && apt-get install -y nodejs \
    && rm -rf /var/lib/apt/lists/*

# ── code-server (VS Code in browser) ────────────────────────
RUN curl -fsSL https://code-server.dev/install.sh | sh -s -- --version=${CODE_SERVER_VERSION}

# ── File Browser ─────────────────────────────────────────────
RUN curl -fsSL https://raw.githubusercontent.com/filebrowser/get/master/get.sh | bash

# ── Claude Code CLI ──────────────────────────────────────────
RUN npm install -g @anthropic-ai/claude-code@latest

# ── OpenAI Codex CLI ────────────────────────────────────────
RUN npm install -g @openai/codex

# ── MCP servers ──────────────────────────────────────────────
RUN npm install -g \
    @modelcontextprotocol/server-filesystem \
    @modelcontextprotocol/server-sequential-thinking \
    @modelcontextprotocol/server-github

# ── Node.js utilities ────────────────────────────────────────
RUN npm install -g docx pptxgenjs

# ── Python: data + backend toolkit ───────────────────────────
RUN pip3 install --no-cache-dir \
    # PDF / office
    pypdf pdfplumber pdf2image reportlab \
    python-docx python-pptx \
    openpyxl xlrd \
    "markitdown[pptx]" pytesseract \
    # Image / media
    pillow cairosvg imageio imageio-ffmpeg \
    # Data science
    numpy pandas matplotlib seaborn \
    # Web / API
    requests httpx lxml defusedxml PyYAML \
    # Database
    sqlalchemy alembic \
    # AI / MCP
    anthropic mcp \
    # Testing
    pytest pytest-asyncio \
    # Misc
    playwright

# ── User setup ───────────────────────────────────────────────
RUN useradd -m -s /bin/bash -G sudo coder \
    && echo "coder ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers.d/coder \
    && usermod -aG docker coder 2>/dev/null || true

USER coder
WORKDIR /home/coder

# ── Git defaults ─────────────────────────────────────────────
RUN git config --global user.name "Developer" \
    && git config --global user.email "dev@local" \
    && git config --global init.defaultBranch main \
    && git config --global pull.rebase false

# ── VS Code extensions ────────────────────────────────────────
RUN code-server --install-extension vscjava.vscode-java-pack || true
RUN code-server --install-extension vmware.vscode-boot-dev-pack || true
RUN code-server --install-extension eamodio.gitlens || true
RUN code-server --install-extension mhutchie.git-graph || true
RUN code-server --install-extension cweijan.vscode-database-client2 || true
RUN code-server --install-extension humao.rest-client || true
RUN code-server --install-extension redhat.vscode-xml || true
RUN code-server --install-extension redhat.vscode-yaml || true
RUN code-server --install-extension ms-python.python || true
RUN code-server --install-extension ms-vscode.live-server || true
RUN code-server --install-extension tomoki1207.pdf || true
RUN code-server --install-extension GrapeCity.gc-excelviewer || true
RUN code-server --install-extension hediet.vscode-drawio || true

# ── code-server settings ─────────────────────────────────────
RUN mkdir -p /home/coder/.local/share/code-server/User
COPY --chown=coder:coder code-server-settings.json /home/coder/.local/share/code-server/User/settings.json

# ── Claude Code defaults (copied to volume-safe location) ────
RUN mkdir -p /home/coder/.claude-defaults
COPY --chown=coder:coder claude-settings.json /home/coder/.claude-defaults/settings.json
COPY --chown=coder:coder mcp-settings.json /home/coder/.claude-defaults/mcp_settings.json

# ── Auth gateway ─────────────────────────────────────────────
COPY --chown=coder:coder auth-gateway.py /home/coder/auth-gateway.py
COPY --chown=coder:coder login.html /home/coder/login.html

# ── File Browser config ───────────────────────────────────────
RUN mkdir -p /home/coder/.config/filebrowser
RUN filebrowser config init \
    --database /home/coder/.config/filebrowser/filebrowser.db \
    --root /home/coder/workspace \
    --address 127.0.0.1 \
    --port 9090 \
    --baseurl /files \
    --auth.method=noauth \
    --branding.name="Dev Box: Files" \
    && filebrowser users add admin admin-noauth-dummy --perm.admin \
       --database /home/coder/.config/filebrowser/filebrowser.db

# ── Playwright Chromium ───────────────────────────────────────
RUN playwright install --with-deps chromium

# ── Workspace dirs ───────────────────────────────────────────
RUN mkdir -p /home/coder/workspace /home/coder/.m2/repository

# ── Entrypoint ───────────────────────────────────────────────
COPY --chown=coder:coder entrypoint.sh /home/coder/entrypoint.sh
RUN chmod +x /home/coder/entrypoint.sh

EXPOSE 8080

ENV NODE_PATH="/usr/lib/node_modules"
ENV PASSWORD=""
ENV ANTHROPIC_API_KEY=""
ENV ANTHROPIC_BASE_URL=""
ENV API_TIMEOUT_MS="300000"
ENV DOCKER_HOST=unix:///var/run/docker.sock
ENV TESTCONTAINERS_RYUK_DISABLED=true

ENTRYPOINT ["dumb-init", "--", "/home/coder/entrypoint.sh"]
