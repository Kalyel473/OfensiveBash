#!/usr/bin/env bash
#
# lib/parse.sh — validacao e extracao por regex (urls, ips, emails, segredos).
#
# Funcoes de validacao retornam 0/1. Funcoes de extracao imprimem os matches,
# um por linha, lendo de stdin.

# --- Validacao --------------------------------------------------------------

# parse_is_ipv4 <str>
parse_is_ipv4() {
    local ip="${1:-}"
    [[ "$ip" =~ ^([0-9]{1,3})\.([0-9]{1,3})\.([0-9]{1,3})\.([0-9]{1,3})$ ]] || return 1
    local o
    for o in "${BASH_REMATCH[@]:1:4}"; do
        (( o >= 0 && o <= 255 )) || return 1
    done
    return 0
}

# parse_is_cidr <str>  (ex: 10.0.0.0/8)
parse_is_cidr() {
    local cidr="${1:-}"
    [[ "$cidr" == */* ]] || return 1
    local ip="${cidr%/*}" bits="${cidr#*/}"
    parse_is_ipv4 "$ip" || return 1
    [[ "$bits" =~ ^[0-9]{1,2}$ ]] || return 1
    (( bits >= 0 && bits <= 32 )) || return 1
    return 0
}

# parse_is_domain <str> — valida um FQDN simples.
parse_is_domain() {
    local d="${1:-}"
    [[ ${#d} -le 253 ]] || return 1
    [[ "$d" =~ ^([A-Za-z0-9](-?[A-Za-z0-9])*\.)+[A-Za-z]{2,}$ ]]
}

# parse_is_valid_target <str> — aceita dominio, IPv4 ou CIDR.
parse_is_valid_target() {
    local t="${1:-}"
    [[ -z "$t" ]] && return 1
    parse_is_domain "$t" && return 0
    parse_is_ipv4 "$t" && return 0
    parse_is_cidr "$t" && return 0
    return 1
}

# --- Extracao (lê stdin) ----------------------------------------------------

# parse_extract_ips — imprime IPv4 encontrados na entrada.
parse_extract_ips() {
    grep -oE '([0-9]{1,3}\.){3}[0-9]{1,3}' 2>/dev/null | sort -u || true
}

# parse_extract_urls — imprime URLs http(s) encontradas.
parse_extract_urls() {
    grep -oE 'https?://[A-Za-z0-9._~:/?#@!$&'"'"'()*+,;=%-]+' 2>/dev/null | sort -u || true
}

# parse_extract_emails — imprime emails encontrados.
parse_extract_emails() {
    grep -oE '[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}' 2>/dev/null | sort -u || true
}

# parse_extract_domains <base> — imprime subdominios do dominio base.
parse_extract_domains() {
    local base="${1:-}"
    if [[ -n "$base" ]]; then
        grep -oiE "([A-Za-z0-9_-]+\.)+${base//./\\.}" 2>/dev/null | tr '[:upper:]' '[:lower:]' | sort -u || true
    else
        grep -oiE '([A-Za-z0-9_-]+\.)+[A-Za-z]{2,}' 2>/dev/null | tr '[:upper:]' '[:lower:]' | sort -u || true
    fi
}

# parse_grep_secrets — heuristica simples para segredos hardcoded (lê stdin).
# NAO e um scanner completo; serve de apoio a code review.
parse_grep_secrets() {
    grep -nEi \
        -e '(api[_-]?key|secret|passwd|password|token|bearer)[[:space:]]*[:=][[:space:]]*["'"'"'][^"'"'"']{6,}' \
        -e 'AKIA[0-9A-Z]{16}' \
        -e '-----BEGIN [A-Z ]*PRIVATE KEY-----' \
        2>/dev/null || true
}
