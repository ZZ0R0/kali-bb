#!/bin/bash
# install-claude.sh — Install Claude Code via npm (runtime injection)
set -e

echo "[*] Installing Claude Code..."
npm install -g @anthropic-ai/claude-code

echo "[+] Claude Code installed: $(claude --version 2>/dev/null || echo 'check PATH')"
