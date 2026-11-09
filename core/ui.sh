#!/usr/bin/env bash

_ui_use_color() {
    # Desliga cor se: NO_COLOR setado, OFB_NO_COLOR=1, ou stdout nao e um tty.
    [[ -n "${NO_COLOR:-}" ]] && return 1
    [[ "${OFB_NO_COLOR:-0}" == "1" ]] && return 1
    [[ -t 1 ]] || return 1
    return 0
}

if _ui_use_color; then
    if command -v tput >/dev/null 2>&1 && tput setaf 1 >/dev/null 2>&1; then
        OFB_C_RESET="$(tput sgr0)"
        OFB_C_RED="$(tput setaf 1)"
        OFB_C_GREEN="$(tput setaf 2)"
        OFB_C_YELLOW="$(tput setaf 3)"
        OFB_C_BLUE="$(tput setaf 4)"
        OFB_C_MAGENTA="$(tput setaf 5)"
        OFB_C_CYAN="$(tput setaf 6)"
        OFB_C_BOLD="$(tput bold)"
    else
        OFB_C_RESET=$'\033[0m'
        OFB_C_RED=$'\033[31m'
        OFB_C_GREEN=$'\033[32m'
        OFB_C_YELLOW=$'\033[33m'
        OFB_C_BLUE=$'\033[34m'
        OFB_C_MAGENTA=$'\033[35m'
        OFB_C_CYAN=$'\033[36m'
        OFB_C_BOLD=$'\033[1m'
    fi
else
    OFB_C_RESET='' OFB_C_RED='' OFB_C_GREEN='' OFB_C_YELLOW=''
    OFB_C_BLUE='' OFB_C_MAGENTA='' OFB_C_CYAN='' OFB_C_BOLD=''
fi

# --- Log estruturado (JSON lines) ------------------------------------------
# Escapa uma string para uso seguro dentro de aspas JSON.
_ui_json_escape() {
    local s="$1"
    s="${s//\\/\\\\}"
    s="${s//\"/\\\"}"
    s="${s//$'\n'/\\n}"
    s="${s//$'\t'/\\t}"
    s="${s//$'\r'/}"
    printf '%s' "$s"
}

# Se OFB_JSONLOG estiver setado (caminho de arquivo), grava uma linha JSON.
_ui_jsonlog() {
    local level="$1" msg="$2"
    [[ -n "${OFB_JSONLOG:-}" ]] || return 0
    local ts
    ts="$(date -u +%Y-%m-%dT%H:%M:%SZ)"
    printf '{"ts":"%s","level":"%s","msg":"%s"}\n' \
        "$ts" "$level" "$(_ui_json_escape "$msg")" >> "$OFB_JSONLOG" 2>/dev/null || true
}

# --- Funcoes publicas de saida ---------------------------------------------
# Tudo vai para stderr, exceto dados "de verdade" que os modulos imprimem
# diretamente. Assim o stdout fica limpo para pipes/JSON quando necessario.

info() {
    [[ "${OFB_QUIET:-0}" == "1" ]] && { _ui_jsonlog info "$*"; return 0; }
    printf '%s[*]%s %s\n' "$OFB_C_BLUE" "$OFB_C_RESET" "$*" >&2
    _ui_jsonlog info "$*"
}

ok() {
    [[ "${OFB_QUIET:-0}" == "1" ]] && { _ui_jsonlog ok "$*"; return 0; }
    printf '%s[+]%s %s\n' "$OFB_C_GREEN" "$OFB_C_RESET" "$*" >&2
    _ui_jsonlog ok "$*"
}

warn() {
    # warn aparece mesmo em modo quiet (avisos importam).
    printf '%s[!]%s %s\n' "$OFB_C_YELLOW" "$OFB_C_RESET" "$*" >&2
    _ui_jsonlog warn "$*"
}

err() {
    printf '%s[-]%s %s\n' "$OFB_C_RED" "$OFB_C_RESET" "$*" >&2
    _ui_jsonlog error "$*"
}

debug() {
    [[ "${OFB_VERBOSE:-0}" == "1" ]] || { _ui_jsonlog debug "$*"; return 0; }
    printf '%s[d]%s %s\n' "$OFB_C_MAGENTA" "$OFB_C_RESET" "$*" >&2
    _ui_jsonlog debug "$*"
}

# Titulo de secao, util em relatorios de tela.
section() {
    [[ "${OFB_QUIET:-0}" == "1" ]] && return 0
    printf '\n%s%s=== %s ===%s\n' "$OFB_C_BOLD" "$OFB_C_CYAN" "$*" "$OFB_C_RESET" >&2
}

# banner — ASCII art + versao. Suprimido em modo quiet.
banner() {
    [[ "${OFB_QUIET:-0}" == "1" ]] && return 0
    printf '%s%s' "$OFB_C_BOLD" "$OFB_C_CYAN" >&2
    cat >&2 <<'BANNER'
   ___  __               _          ___           __
  / _ \/ _| ___ _ _  ___(_)_ _____ / _ ) ___ ___ / /
 | (_) | _|/ -_) ' \(_-< | | '_/ -_) _ \/ _ (_-</ _ \
  \___/|_| \___|_||_/__/_|_|_| \___|____/\__/__/_//_/
BANNER
    printf '%s' "$OFB_C_RESET" >&2
    printf '  %sframework de pentest em bash%s  %sv%s%s\n' \
        "$OFB_C_MAGENTA" "$OFB_C_RESET" "$OFB_C_BOLD" "$OFB_VERSION" "$OFB_C_RESET" >&2
    printf '  %sUSO AUTORIZADO SOMENTE%s — recon, enum, config-check, CTF e relatorio\n\n' \
        "$OFB_C_YELLOW" "$OFB_C_RESET" >&2
}

# prompt_line — imprime um prompt (sem newline) no stderr. Usado pelo REPL.
prompt_line() {
    printf '%s' "$1" >&2
}

# die — erro fatal com codigo de saida. Usado apenas no fluxo principal
# (CLI/bootstrap), NUNCA dentro de modulos (modulos usam return).
die() {
    local code="$1"; shift
    err "$*"
    exit "$code"
}
