#!/usr/bin/env bash
#
# modules/recon/dns.sh — registros DNS (A/AAAA/MX/NS/TXT/CNAME) via dig.
#
# Recon PASSIVO: consulta DNS publico. Degrada para host/nslookup se dig faltar.

MODULE_NAME="recon/dns"
MODULE_DESC="Coleta registros A/AAAA/MX/NS/TXT/CNAME do dominio"
MODULE_CATEGORY="recon"
MODULE_AUTHOR="CyberGuard"
MODULE_REQUIRES=""              # usa dig se houver, senao host/nslookup (fallback)
MODULE_INTRUSIVE="false"
MODULE_ARGS_HELP="<dominio>  (default: TARGET da sessao)"

module_run() {
    local domain="${1:-$TARGET}"
    require_target "$domain" || return 1

    local out; out="$(ws_dir recon)/dns.txt" || return 1
    info "Coletando registros DNS de $domain..."

    local types="A AAAA MX NS TXT CNAME SOA"
    local have_dig=0
    require_tool dig 2>/dev/null && have_dig=1

    {
        printf '# Registros DNS de %s\n' "$domain"
        printf '# Gerado em %s\n\n' "$(date -u +%Y-%m-%dT%H:%M:%SZ)"
        local t
        for t in $types; do
            printf '[%s]\n' "$t"
            if [[ "$have_dig" -eq 1 ]]; then
                dig +short "$t" "$domain" 2>/dev/null || true
            elif command -v host >/dev/null 2>&1; then
                host -t "$t" "$domain" 2>/dev/null || true
            elif command -v nslookup >/dev/null 2>&1; then
                nslookup -query="$t" "$domain" 2>/dev/null | sed -n '/^Name\|Address\|text\|exchanger\|server/p' || true
            fi
            printf '\n'
        done
    } | ws_write "$out"

    if [[ "$have_dig" -eq 0 ]]; then
        warn "dig ausente — usei fallback (host/nslookup). Instale 'dnsutils' para resultado completo."
    fi
    ok "Registros DNS salvos em $out"
    return 0
}
