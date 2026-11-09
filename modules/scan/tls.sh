#!/usr/bin/env bash

MODULE_NAME="scan/tls"
MODULE_DESC="Inspeciona certificado, validade e protocolos/cifras TLS via openssl"
MODULE_CATEGORY="scan"
MODULE_AUTHOR="CyberGuard"
MODULE_REQUIRES="openssl"
MODULE_INTRUSIVE="true"
MODULE_ARGS_HELP="[porta]  (default: 443)"

module_run() {
    local port="${1:-443}"
    require_target || return 1
    require_scope "$TARGET" || return 4

    local out; out="$(ws_dir scan)/tls_${port}.txt" || return 1
    info "Inspecionando TLS de $TARGET:$port..."

    local connect="${TARGET}:${port}"
    local cert
    cert="$(printf 'Q\n' | openssl s_client -connect "$connect" -servername "$TARGET" 2>/dev/null)" || {
        warn "Nao consegui estabelecer TLS com $connect"; return 1; }

    {
        printf '# Inspecao TLS de %s\n' "$connect"
        printf '# %s\n\n' "$(date -u +%Y-%m-%dT%H:%M:%SZ)"

        printf '## Certificado (subject/issuer/validade)\n'
        printf '%s' "$cert" | openssl x509 -noout -subject -issuer -dates -ext subjectAltName 2>/dev/null \
            || printf '(nao foi possivel parsear o certificado)\n'
        printf '\n## Protocolos suportados\n'

        local proto
        for proto in ssl3 tls1 tls1_1 tls1_2 tls1_3; do
            local flag="-$proto"
            if printf 'Q\n' | openssl s_client -connect "$connect" -servername "$TARGET" "$flag" 2>/dev/null \
                | grep -q 'BEGIN CERTIFICATE'; then
                printf '  [+] %s: aceito\n' "$proto"
                case "$proto" in
                    ssl3|tls1|tls1_1) printf '      ^ protocolo obsoleto/inseguro\n' ;;
                esac
            else
                printf '  [-] %s: recusado\n' "$proto"
            fi
        done
    } | ws_write "$out"

    ok "Inspecao TLS salva em $out"
    return 0
}
