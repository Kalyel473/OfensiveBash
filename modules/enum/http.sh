#!/usr/bin/env bash
#
# modules/enum/http.sh — fingerprint HTTP: status, headers, tech, robots, titulo.
#
# INTRUSIVO (leve): faz requisicoes HTTP(S) ao alvo. Degrada se curl faltar.
#
# Args: [url ou host]  (default: http(s)://TARGET)

MODULE_NAME="enum/http"
MODULE_DESC="Fingerprint HTTP: status, headers, servidor/tech, robots.txt e titulo"
MODULE_CATEGORY="enum"
MODULE_AUTHOR="CyberGuard"
MODULE_REQUIRES="curl"
MODULE_INTRUSIVE="true"
MODULE_ARGS_HELP="[url|host]  (default: https://TARGET e http://TARGET)"

_http_normalize_url() {
    local in="$1"
    if [[ "$in" == http://* || "$in" == https://* ]]; then
        printf '%s' "$in"
    else
        printf 'https://%s' "$in"
    fi
}

module_run() {
    local arg="${1:-$TARGET}"
    require_target "$arg" || return 1

    local host="${arg#http://}"; host="${host#https://}"; host="${host%%/*}"
    require_scope "$host" || return 4

    local url; url="$(_http_normalize_url "$arg")"
    local out; out="$(ws_dir enum)/http.txt" || return 1
    info "Fingerprint HTTP de $url..."

    local headers
    headers="$(http_headers_only "$url" 2>/dev/null)" || {
        warn "Sem resposta em $url; tentando http://..."
        url="http://$host"
        headers="$(http_headers_only "$url" 2>/dev/null)" || {
            warn "Falha ao conectar em $host via HTTP/HTTPS"; return 1; }
    }

    local status server powered title body
    status="$(printf '%s' "$headers" | grep -iE '^HTTP/' | tail -n1 | tr -d '\r')"
    server="$(printf '%s' "$headers" | grep -iE '^Server:' | tail -n1 | tr -d '\r')"
    powered="$(printf '%s' "$headers" | grep -iE '^X-Powered-By:' | tail -n1 | tr -d '\r')"

    body="$(http_get "$url" 2>/dev/null || true)"
    title="$(printf '%s' "$body" | grep -oiE '<title>[^<]*</title>' | head -n1 | sed -E 's/<[^>]+>//g' | tr -d '\r\n')"

    local robots
    robots="$(http_status "${url%/}/robots.txt" 2>/dev/null || echo '?')"

    {
        printf '# Fingerprint HTTP de %s\n' "$url"
        printf '# %s\n\n' "$(date -u +%Y-%m-%dT%H:%M:%SZ)"
        printf 'Status:      %s\n' "${status:-?}"
        printf 'Server:      %s\n' "${server:-(nao informado)}"
        printf 'X-Powered-By:%s\n' "${powered:+ ${powered#*: }}"
        printf 'Titulo:      %s\n' "${title:-(sem titulo)}"
        printf 'robots.txt:  HTTP %s\n' "$robots"
        printf '\n## Headers de resposta\n'
        printf '%s\n' "$headers" | tr -d '\r'
    } | ws_write "$out"

    ok "Fingerprint HTTP salvo em $out"
    return 0
}
