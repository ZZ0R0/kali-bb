#!/bin/bash
# entrypoint.sh — Kali-BB container entrypoint
export PATH="/root/go/bin:/opt/browsers:/usr/local/go/bin:$PATH"
export PLAYWRIGHT_BROWSERS_PATH="/opt/browsers"
export BB_ROOT="/workspace"

# Setup gf patterns (tomnomnom + community)
if [[ ! -d /root/.gf ]]; then
    mkdir -p /root/.gf
    git clone --depth 1 https://github.com/tomnomnom/gf /tmp/gf-repo 2>/dev/null
    cp /tmp/gf-repo/examples/*.json /root/.gf/ 2>/dev/null
    # Community patterns (ssrf, lfi, rce, idor, sqli...)
    git clone --depth 1 https://github.com/1ndianl33t/Gf-Patterns /tmp/gf-community 2>/dev/null
    cp /tmp/gf-community/*.json /root/.gf/ 2>/dev/null
    rm -rf /tmp/gf-repo /tmp/gf-community
fi

exec "$@"
