#!/usr/bin/env bash

_http_base_args() {
    local -n _arr="$1"
    local ua tmo
    ua="$(cfg_get OFB_USER_AGENT "OfensivaBash/${OFB_VERSION}")"
    tmo="$(cfg_get OFB_HTTP_TIMEOUT 10)"
    _arr=(
        --silent --show-error --location
        --max-time "$tmo"
        --connect-timeout "$tmo"
        --user-agent "$ua"
    )
}

# http_get <url> — GET simples, imprime o corpo. Retorna status do curl.
http_get() {
    local url="${1:-}"
    [[ -z "$url" ]] && { err "http_get: url vazia"; return 2; }
    require_tool curl || { warn "curl ausente: http_get indisponivel"; return "$OFB_EXIT_DEP"; }

    local args; _http_base_args args
    local retries; retries="$(cfg_get OFB_HTTP_RETRIES 2)"
    args+=( --retry "$retries" --retry-delay 1 )

    debug "GET $url"
    curl "${args[@]}" -- "$url"
}

# http_head <url> — imprime apenas os headers de resposta (com -I).
http_head() {
    local url="${1:-}"
    [[ -z "$url" ]] && { err "http_head: url vazia"; return 2; }
    require_tool curl || return "$OFB_EXIT_DEP"
    local args; _http_base_args args
    debug "HEAD $url"
    curl "${args[@]}" -I -- "$url"
}

# http_status <url> — imprime apenas o codigo HTTP (ex: 200).
http_status() {
    local url="${1:-}"
    [[ -z "$url" ]] && return 2
    require_tool curl || return "$OFB_EXIT_DEP"
    local args; _http_base_args args
    curl "${args[@]}" -o /dev/null -w '%{http_code}' -- "$url"
}

# http_headers_only <url> — headers de resposta "crus" (uma linha por header),
# seguindo redirects, para auditoria. Usa -D - e descarta o corpo.
http_headers_only() {
    local url="${1:-}"
    [[ -z "$url" ]] && return 2
    require_tool curl || return "$OFB_EXIT_DEP"
    local args; _http_base_args args
    curl "${args[@]}" -D - -o /dev/null -- "$url"
}

# http_get_with_origin <url> <origin> — GET enviando um header Origin custom.
# Usado por checagens de CORS. Imprime headers + status.
http_get_with_origin() {
    local url="${1:-}" origin="${2:-}"
    [[ -z "$url" || -z "$origin" ]] && return 2
    require_tool curl || return "$OFB_EXIT_DEP"
    local args; _http_base_args args
    curl "${args[@]}" -D - -o /dev/null -H "Origin: $origin" -- "$url"
}
