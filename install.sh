#!/usr/bin/env bash
#
# install.sh — instalador do OfensivaBash.
#
# O que faz:
#   - cria ~/.config/ofensivabash/ e copia o conf.example (se ainda nao existir)
#   - linka o entrypoint em ~/.local/bin (ou $PREFIX/bin no Termux)
#   - valida dependencias base e avisa sobre as opcionais
#
# Sem root obrigatorio. Instalacao alternativa: git clone + rodar ./ofensivabash.

set -euo pipefail
IFS=$'\n\t'

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ENTRY="$REPO_DIR/ofensivabash"

# cores simples (so para o instalador)
if [[ -t 1 && -z "${NO_COLOR:-}" ]]; then
    C_G=$'\033[32m'; C_Y=$'\033[33m'; C_R=$'\033[31m'; C_B=$'\033[34m'; C_0=$'\033[0m'
else
    C_G=''; C_Y=''; C_R=''; C_B=''; C_0=''
fi
say()  { printf '%s[*]%s %s\n' "$C_B" "$C_0" "$*"; }
ok()   { printf '%s[+]%s %s\n' "$C_G" "$C_0" "$*"; }
warn() { printf '%s[!]%s %s\n' "$C_Y" "$C_0" "$*"; }
die()  { printf '%s[-]%s %s\n' "$C_R" "$C_0" "$*" >&2; exit 1; }

# Destino do bin: Termux usa $PREFIX/bin; demais usam ~/.local/bin.
if [[ -n "${PREFIX:-}" && -d "${PREFIX}/bin" ]]; then
    BIN_DIR="$PREFIX/bin"
else
    BIN_DIR="$HOME/.local/bin"
fi

CONFIG_DIR="${XDG_CONFIG_HOME:-$HOME/.config}/ofensivabash"

say "Instalando OfensivaBash a partir de: $REPO_DIR"

# 1. valida dependencias base
say "Checando dependencias base..."
missing=()
for bin in bash curl grep sed awk sort find; do
    command -v "$bin" >/dev/null 2>&1 || missing+=("$bin")
done
if [[ ${#missing[@]} -gt 0 ]]; then
    die "Dependencias base ausentes: ${missing[*]} — instale e rode de novo."
fi
ok "Dependencias base OK."

# avisa sobre opcionais
say "Checando dependencias OPCIONAIS (nao obrigatorias)..."
for bin in jq dig openssl nmap whois nc ncat; do
    if command -v "$bin" >/dev/null 2>&1; then
        ok "  $bin encontrado"
    else
        warn "  $bin ausente (modulos que o usam vao degradar com aviso)"
    fi
done

# 2. config
mkdir -p "$CONFIG_DIR"
if [[ -f "$CONFIG_DIR/ofensivabash.conf" ]]; then
    warn "Config ja existe: $CONFIG_DIR/ofensivabash.conf (mantida)"
else
    cp "$REPO_DIR/ofensivabash.conf.example" "$CONFIG_DIR/ofensivabash.conf"
    ok "Config criada: $CONFIG_DIR/ofensivabash.conf"
fi

# 3. linka o binario
mkdir -p "$BIN_DIR"
chmod +x "$ENTRY" 2>/dev/null || true
ln -sf "$ENTRY" "$BIN_DIR/ofensivabash"
ok "Link criado: $BIN_DIR/ofensivabash -> $ENTRY"

# 4. PATH?
case ":$PATH:" in
    *":$BIN_DIR:"*) ok "$BIN_DIR ja esta no PATH." ;;
    *) warn "Adicione ao PATH:  export PATH=\"$BIN_DIR:\$PATH\"  (coloque no seu ~/.bashrc)" ;;
esac

printf '\n'
ok "Instalacao concluida."
say "Teste com:  ofensivabash --version   e depois:  ofensivabash"
warn "USO AUTORIZADO SOMENTE. Use apenas contra alvos que voce tem permissao para testar."
