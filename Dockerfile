# Kali-BB — Container Bug Bounty optimisé pour AutoBB
# Image unique multi-stage

FROM kalilinux/kali-rolling:latest AS base

ENV DEBIAN_FRONTEND=noninteractive
ENV GOPATH=/root/go
ENV PATH="/root/go/bin:/usr/local/go/bin:/opt/browsers:$PATH"
ENV PLAYWRIGHT_BROWSERS_PATH="/opt/browsers"

# ─── Tier 1 : apt packages ───────────────────────────────────────────────────
RUN apt-get update && apt-get install -y -qq --no-install-recommends \
    nmap sqlmap wpscan nikto mitmproxy whatweb dirb \
    seclists whois dnsutils sqlite3 \
    wireguard-tools iproute2 openssl \
    jq curl wget git \
    python3 python3-pip python3-venv python3-dev \
    zsh tmux build-essential libssl-dev pkg-config \
    golang-go \
    ca-certificates gnupg \
    && rm -rf /var/lib/apt/lists/*

# ─── Node.js 22 (pour Claude Code) ───────────────────────────────────────────
RUN curl -fsSL https://deb.nodesource.com/setup_22.x | bash - \
    && apt-get install -y -qq nodejs \
    && rm -rf /var/lib/apt/lists/*

# ─── Tier 2 : Go tools (ProjectDiscovery + tomnomnom + ffuf) ─────────────────
RUN go install -v github.com/projectdiscovery/subfinder/v2/cmd/subfinder@latest \
    && go install -v github.com/projectdiscovery/httpx/cmd/httpx@latest \
    && go install -v github.com/projectdiscovery/katana/cmd/katana@latest \
    && go install -v github.com/lc/gau/v2/cmd/gau@latest \
    && go install -v github.com/ffuf/ffuf/v2@latest \
    && go install -v github.com/OJ/gobuster/v3@latest \
    && go install -v github.com/hahwul/dalfox/v2@latest \
    && go install -v github.com/tomnomnom/qsreplace@latest \
    && go install -v github.com/tomnomnom/gf@latest \
    && go install -v github.com/tomnomnom/anew@latest \
    && rm -rf /root/go/pkg /root/go/src /tmp/*

# ─── Tier 3 : pip packages ───────────────────────────────────────────────────
RUN pip install --break-system-packages playwright git-dumper \
    && python3 -m playwright install chromium --with-deps \
    && rm -rf /root/.cache/pip

# ─── Configs ─────────────────────────────────────────────────────────────────
COPY configs/zshrc /root/.zshrc
COPY scripts/entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

WORKDIR /workspace

ENTRYPOINT ["/entrypoint.sh"]
CMD ["zsh"]
