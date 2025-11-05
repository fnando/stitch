FROM --platform=linux/amd64 ubuntu:latest

RUN apt-get update && \
    apt-get install -y \
    ca-certificates \
    curl \
    ffmpeg \
    fontconfig \
    fonts-emojione \
    fonts-jetbrains-mono \
    fonts-liberation \
    gnupg \
    jq \
    less \
    libasound2t64 \
    libatk-bridge2.0-0t64 \
    libatk1.0-0t64 \
    libatspi2.0-0t64 \
    libcairo2 \
    libcups2t64 \
    libdbus-1-3 \
    libdrm2 \
    libexpat1 \
    libgbm1 \
    libglib2.0-0t64 \
    libgtk-3-0t64 \
    libnspr4 \
    libnss3 \
    libpango-1.0-0 \
    libudev1 \
    libvulkan1 \
    libx11-6 \
    libxcb1 \
    libxcomposite1 \
    libxdamage1 \
    libxext6 \
    libxfixes3 \
    libxkbcommon0 \
    libxrandr2 \
    python3-venv \
    ruby \
    sudo \
    unzip \
    wget \
    xdg-utils \
    xz-utils

RUN apt-get remove -y chromium-browser || true; \
    curl -fsSL https://dl-ssl.google.com/linux/linux_signing_key.pub | gpg --dearmor -o /usr/share/keyrings/google-chrome.gpg && \
    echo "deb [arch=amd64 signed-by=/usr/share/keyrings/google-chrome.gpg] http://dl.google.com/linux/chrome/deb/ stable main" > /etc/apt/sources.list.d/google-chrome.list && \
    apt-get update && \
    apt-get install -y google-chrome-stable && \
    rm -rf /var/lib/apt/lists/*

ARG SLIDES_VERSION=0.9.0
ARG VHS_VERSION=0.10.0
ARG TTYD_VERSION=1.7.7
ARG LL_VERSION=0.0.11
ARG BAT_VERSION=0.26.0
ARG USER=stitch
ARG NODE_VERSION=24.11.0
ARG ELEVENLABS_VERSION=^2.21.0
ENV TERM=xterm-256color
ENV PATH="/venv/bin:/source/bin:/${USER}/bin:/usr/local/node/bin:$PATH"
ENV NODE_PATH="/usr/local/node/lib/node_modules"

RUN mkdir /tmp/download && cd /tmp/download && \
    curl -sSL https://github.com/maaslalani/slides/releases/download/v${SLIDES_VERSION}/slides_${SLIDES_VERSION}_linux_amd64.tar.gz | tar xzO slides > /usr/local/bin/slides && chmod +x /usr/local/bin/slides && \
    curl -sSL https://github.com/charmbracelet/vhs/releases/download/v${VHS_VERSION}/vhs_${VHS_VERSION}_Linux_x86_64.tar.gz | tar xz && find . -name vhs -type f -exec mv {} /usr/local/bin/vhs \; && chmod +x /usr/local/bin/vhs && \
    curl -sSL https://github.com/tsl0922/ttyd/releases/download/${TTYD_VERSION}/ttyd.x86_64 > /usr/local/bin/ttyd && chmod +x /usr/local/bin/ttyd && \
    curl -sSL https://github.com/fnando/ll/releases/download/v${LL_VERSION}/ll-x86_64-unknown-linux-gnu.tar.gz | tar xzO ll > /usr/local/bin/ll && chmod +x /usr/local/bin/ll && \
    curl -sSL https://github.com/sharkdp/bat/releases/download/v${BAT_VERSION}/bat-v${BAT_VERSION}-x86_64-unknown-linux-musl.tar.gz | tar xzO --wildcards '*/bat' > /usr/local/bin/bat && chmod +x /usr/local/bin/bat && \
    mkdir -p /usr/local/node && \
    curl -sSL https://nodejs.org/dist/v${NODE_VERSION}/node-v${NODE_VERSION}-linux-x64.tar.xz | tar xJf - --strip-components=1 -C /usr/local/node && \
    curl -sSL -o JetBrainsMono.zip https://github.com/ryanoasis/nerd-fonts/releases/download/v3.4.0/JetBrainsMono.zip && \
    unzip -j JetBrainsMono.zip '*.ttf' -d /usr/local/share/fonts && \
    fc-cache -f && \
    rm -rf /tmp/download /tmp/node-compile-cache

COPY bin/stitch /usr/local/bin
COPY bin/stitch-voiceover /usr/local/bin
COPY bin/run-stitch /usr/local/bin
RUN chmod +x /usr/local/bin/run-stitch && \
    chmod +x /usr/local/bin/stitch && \
    chmod +x /usr/local/bin/stitch-voiceover

RUN useradd -m -d /${USER} -s /bin/bash -u 1001 ${USER} \
    && chown -R ${USER}:${USER} /${USER} \
    && echo "${USER} ALL=(ALL) NOPASSWD:ALL" > /etc/sudoers.d/${USER} \
    && chmod 0440 /etc/sudoers.d/${USER}
RUN mkdir -p /venv && chown -R ${USER}:${USER} /venv
RUN mkdir -p /${USER}-local && chown -R ${USER}:${USER} /${USER}-local

RUN npm install --prefix=/usr/local/node -g @elevenlabs/elevenlabs-js@${ELEVENLABS_VERSION}

USER ${USER}
WORKDIR /${USER}

RUN python3 -m venv /venv
RUN pip install ffmpeg-normalize

ENTRYPOINT [ "run-stitch" ]
