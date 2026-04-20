#!/bin/bash
# install-tools.sh — Script d'installation des outils (utilisable standalone)
set -e

echo "[*] Updating apt..."
apt-get update

echo "[*] Installing Tier 1 — apt packages..."
apt-get install -y -qq --no-install-recommends \
    nmap sqlmap wpscan nikto mitmproxy whatweb dirb \
    seclists whois dnsutils sqlite3 \
    wireguard-tools iproute2 openssl \
    jq curl wget git \
    python3 python3-pip python3-venv python3-dev \
    zsh tmux build-essential libssl-dev pkg-config \
    golang-go \
    ca-certificates gnupg

echo "[*] Installing Node.js 22..."
curl -fsSL https://deb.nodesource.com/setup_22.x | bash -
apt-get install -y -qq nodejs

echo "[*] Installing Tier 2 — Go tools..."
go install -v github.com/projectdiscovery/subfinder/v2/cmd/subfinder@latest
go install -v github.com/projectdiscovery/httpx/cmd/httpx@latest
go install -v github.com/projectdiscovery/katana/cmd/katana@latest
go install -v github.com/lc/gau/v2/cmd/gau@latest
go install -v github.com/ffuf/ffuf/v2@latest
go install -v github.com/OJ/gobuster/v3@latest
go install -v github.com/hahwul/dalfox/v2@latest
go install -v github.com/tomnomnom/qsreplace@latest
go install -v github.com/tomnomnom/gf@latest
go install -v github.com/tomnomnom/anew@latest

echo "[*] Installing Tier 3 — pip packages..."
pip install --break-system-packages playwright git-dumper
PLAYWRIGHT_BROWSERS_PATH=/opt/browsers python3 -m playwright install chromium --with-deps

echo "[*] Cleaning up..."
apt-get clean
rm -rf /var/lib/apt/lists/* /root/.cache/pip /root/go/pkg /root/go/src /tmp/*

echo "[+] All tools installed successfully."
