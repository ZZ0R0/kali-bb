# Kali-BB — Container Bug Bounty sur mesure

Remplacement d'Exegol par un container Kali Docker optimisé pour AutoBB.
Repo dédié : `ZZ0R0/Kali-BB`

## Pourquoi

Exegol v5.1+ verrouille les images pré-built (`web`, `full`) derrière une licence Pro.
Le build from source est instable (`package_osint` crash). Le profil `light` n'a aucun outil offensif web.

On n'a pas besoin du wrapper Exegol : pas de GUI, pas de VPN intégré (on a notre MCP ProtonVPN), pas de multi-container.
On a besoin d'un container léger avec exactement nos outils, qui se build en 5 min, pas en 2h.

## Architecture

```
kali-bb/
├── Dockerfile              # image unique, multi-stage
├── docker-compose.yml      # run config (volumes, network, privileged)
├── scripts/
│   ├── install-tools.sh    # apt + go install + pip install
│   ├── install-claude.sh   # Claude Code via npm
│   └── entrypoint.sh       # setup PATH, env, exec shell
├── configs/
│   └── zshrc               # prompt minimal, aliases utiles
├── Makefile                 # build / run / shell / update
└── README.md
```

## Image de base

```dockerfile
FROM kalilinux/kali-rolling:latest
```

~500MB de base. Notre image finale visée : **~3-4GB** (vs 15GB pour Exegol full).

## Outils — exactement ce qu'on utilise

### Tier 1 — via `apt` (Kali repos, pré-packagé)

| Outil | Paquet | Usage |
|-------|--------|-------|
| nmap | `nmap` | Network scanning |
| sqlmap | `sqlmap` | SQL injection |
| wpscan | `wpscan` | WordPress audit |
| nikto | `nikto` | Web server scanner |
| mitmproxy | `mitmproxy` | HTTP proxy/intercept |
| seclists | `seclists` | Wordlists (répertoire standard) |
| whatweb | `whatweb` | Web fingerprinting (backup swatter) |
| dirb | `dirb` | Directory bruteforce (backup ffuf) |
| whois | `whois` | Domain info |
| dnsutils | `dnsutils` | dig, nslookup |
| sqlite3 | `sqlite3` | DB local (reported.db, programs.db) |
| wireguard-tools | `wireguard-tools` | WireGuard tunnels (ProtonVPN MCP) |
| iproute2 | `iproute2` | ip route/link (VPN routing) |
| openssl | `openssl` | TLS debug, cert analysis |
| wget | `wget` | HTTP download, .git mirror |
| jq | `jq` | JSON processing |
| curl | `curl` | HTTP client |
| git | `git` | VCS |
| python3 | `python3 python3-pip python3-venv` | Runtime |
| zsh | `zsh` | Shell |

```bash
apt-get install -y -qq \
    nmap sqlmap wpscan nikto mitmproxy whatweb dirb \
    seclists whois dnsutils sqlite3 \
    wireguard-tools iproute2 openssl \
    jq curl wget git \
    python3 python3-pip python3-venv python3-dev \
    zsh tmux build-essential libssl-dev pkg-config
```

### Tier 2 — via `go install` (ProjectDiscovery + outils Go)

Nécessite Go ≥ 1.22. On l'installe via Kali (`apt install golang-go`) ou binaire officiel.

| Outil | Source | Usage |
|-------|--------|-------|
| subfinder | `github.com/projectdiscovery/subfinder/v2/cmd/subfinder` | Subdomain enum |
| httpx | `github.com/projectdiscovery/httpx/cmd/httpx` | HTTP probing |
| katana | `github.com/projectdiscovery/katana/cmd/katana` | Crawling |
| gau | `github.com/lc/gau/v2/cmd/gau` | Wayback URLs |
| ffuf | `github.com/ffuf/ffuf/v2` | Fuzzing |
| gobuster | `github.com/OJ/gobuster/v3` | Dir/DNS bruteforce |
| dalfox | `github.com/hahwul/dalfox/v2` | XSS scanner |
| qsreplace | `github.com/tomnomnom/qsreplace` | Query string manipulation |
| gf | `github.com/tomnomnom/gf` | Pattern grep pour params |
| anew | `github.com/tomnomnom/anew` | Dedup append |

```bash
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
```

### Tier 3 — via `pip` (dans le container, pas de venv)

| Outil | Usage |
|-------|-------|
| playwright | Browser automation (MCP Playwright) |
| git-dumper | Extraction de repos .git/ exposés |

```bash
pip install --break-system-packages playwright git-dumper
PLAYWRIGHT_BROWSERS_PATH=/opt/browsers python3 -m playwright install chromium --with-deps
```

### Tier 4 — injectés par AutoBB au runtime (pas dans l'image)

Ces outils sont spécifiques à AutoBB et installés par `install.sh` via le provisioning :

| Outil | Méthode | Source |
|-------|---------|--------|
| Claude Code | `npm install -g @anthropic-ai/claude-code` | npm |
| swatter | `pip install -e /workspace/swatter` | Volume mount |
| telegram-mcp deps | `pip install -r /workspace/telegram-mcp/requirements.txt` | Volume mount |
| libvpn-mcp | `docker cp` du binaire Rust | Build host |

**Raison** : ces outils changent souvent (swatter en dev actif, claude se met à jour). Les injecter au provision plutôt qu'au build évite de rebuild l'image à chaque update.

## Node.js

Nécessaire pour Claude Code. Installé via NodeSource dans le Dockerfile :

```bash
curl -fsSL https://deb.nodesource.com/setup_22.x | bash -
apt-get install -y -qq nodejs
```

## Entrypoint

```bash
#!/bin/bash
export PATH="/root/go/bin:/opt/browsers:$PATH"
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
```

## Volumes (montés par AutoBB)

| Host | Container | Mode |
|------|-----------|------|
| `~/Documents/AutoBB` | `/workspace` | rw |
| `~/.exegol/seclists` (optionnel) | `/usr/share/seclists` | ro |

## Réseau

`--network host` — On n'a pas besoin d'isolation réseau, et host mode simplifie tout (pas de port mapping, DNS résolu comme sur l'hôte).

## Makefile

```makefile
IMAGE  := kali-bb
TAG    := latest
NAME   := autobb

build:
	docker build -t $(IMAGE):$(TAG) .

run:
	docker run -d --name $(NAME) \
		--network host \
		--privileged \
		-v $(HOME)/Documents/AutoBB:/workspace \
		$(IMAGE):$(TAG) sleep infinity

shell:
	docker exec -it $(NAME) zsh

stop:
	docker stop $(NAME) && docker rm $(NAME)

update: build stop run
	@echo "Rebuilt and restarted"
```

## Intégration avec install.sh

Sections à modifier dans AutoBB `install.sh` :

```
Section 2  : Supprimer installation exegol (pipx install exegol)
Section 9  : Remplacer exegol build → docker build -t kali-bb .
Section 10 : Remplacer exegol start → docker run (voir Makefile)
Section 11 : Garder tel quel (docker exec fonctionne pareil)
```

Le `in_container()` passe de `docker exec "exegol-$CONTAINER"` → `docker exec "$CONTAINER"`.

## Taille estimée

| Composant | Taille |
|-----------|--------|
| Kali base | ~500MB |
| apt tools (nmap, sqlmap, wpscan, nikto, mitmproxy, seclists, wireguard…) | ~1.5GB |
| Go + 10 outils Go | ~500MB |
| Node.js 22 | ~200MB |
| Playwright + Chromium | ~500MB |
| pip (git-dumper, etc.) | ~50MB |
| **Total** | **~3.2GB** |

vs Exegol full = 15GB. **5x plus léger, 10x plus rapide à build.**

## Workflow de migration

1. Créer repo `ZZ0R0/Kali-BB`
2. Écrire Dockerfile + scripts + Makefile
3. Build & test localement
4. Adapter `install.sh` (supprimer exegol, utiliser docker direct)
5. Adapter `.claude/CLAUDE.md` (plus de mention exegol)
6. Cleanup : supprimer refs exegol de `docs/`, `install.sh`, `.claude/`
7. Optionnel : `pipx uninstall exegol` sur l'host