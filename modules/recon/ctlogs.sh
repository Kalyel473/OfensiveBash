#!/usr/bin/env bash
#
# modules/recon/ctlogs.sh — subdominios via Certificate Transparency (crt.sh).
#
# Recon PASSIVO: consulta um log publico de CT, nao toca o alvo diretamente.

MODULE_NAME="recon/ctlogs"
MODULE_DESC="Enumera subdominios consultando logs de Certificate Transparency (crt.sh)"
MODULE_CATEGORY="recon"
MODULE_AUTHOR="CyberGuard"
MODULE_REQUIRES="curl"          # jq e opcional, com fallback por grep
MODULE_INTRUSIVE="false"        # consulta passiva a um servico publico
MODULE_ARGS_HELP="<dominio>  (default: TARGET da sessao)"

module_run() {
    local domain="${1:-$TARGET}"
    require_target "$domain" || return 1

    local out; out="$(ws_dir recon)/subdomains.txt" || return 1
    info "Consultando CT logs (crt.sh) para $domain..."

    local raw
    raw="$(http_get "https://crt.sh/?q=%25.${domain}&output=json")" || {
        warn "Falha ao consultar crt.sh (rede/servico)"; return 1; }

    if [[ -z "$raw" ]]; then
        warn "Resposta vazia de crt.sh"; return 1
    fi

    if json_has_jq; then
        printf '%s' "$raw" \
            | jq -r '.[].name_value' 2>/dev/null \
            | tr ',' '\n' | sed 's/^\*\.//' \
            | grep -iE "\.?${domain//./\\.}$" | sort -u > "$out"
    else
        # fallback sem jq: extrai name_value por regex
        printf '%s' "$raw" \
            | grep -oE '"name_value":"[^"]+"' \
            | cut -d'"' -f4 \
            | sed 's/\\n/\n/g' | tr ',' '\n' | sed 's/^\*\.//' \
            | grep -iE "\.?${domain//./\\.}$" | sort -u > "$out"
    fi

    ws_dedup "$out"
    local n; n="$(fs_count_lines "$out")"
    if [[ "$n" -eq 0 ]]; then
        warn "Nenhum subdominio encontrado para $domain"
        return 0
    fi
    ok "$n subdominio(s) salvo(s) em $out"
    return 0
}
