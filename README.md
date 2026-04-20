# Kali-BB

Container Docker Kali optimisé pour le bug bounty — remplacement d'Exegol pour AutoBB.

## Quick Start

```bash
# Build l'image
make build

# Lancer le container
make run

# Ouvrir un shell
make shell

# Arrêter et supprimer
make stop

# Rebuild + restart
make update
```

## Outils inclus

### Tier 1 — apt (Kali repos)
nmap, sqlmap, wpscan, nikto, mitmproxy, whatweb, dirb, seclists, whois, dnsutils, sqlite3, wireguard-tools, iproute2, openssl, wget, jq, curl, git, python3, zsh

### Tier 2 — Go
subfinder, httpx, katana, gau, ffuf, gobuster, dalfox, qsreplace, gf, anew

### Tier 3 — pip
playwright (+ Chromium), git-dumper

### Tier 4 — injectés au runtime par AutoBB
Claude Code, swatter, telegram-mcp, libvpn-mcp

## Volumes

| Host | Container | Mode |
|------|-----------|------|
| `~/Documents/AutoBB` | `/workspace` | rw |

## Réseau

`--network host` — pas d'isolation, DNS hôte, pas de port mapping nécessaire.

## Taille

~3.2 GB (vs 15 GB Exegol full)

## docker-compose

```bash
docker compose up -d
docker compose exec autobb zsh
```
