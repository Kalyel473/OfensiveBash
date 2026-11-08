#!/usr/bin/env bash
#
# modules/enum/headers.sh — auditoria de headers de seguranca com nota.
#
# INTRUSIVO (leve): uma requisicao HTTP(S) ao alvo. Checa a presenca de headers
# de seguranca e atribui uma nota simples.
#
# Args: [url|host]  (default: https://TARGET)

MODULE_NAME="enum/headers"
MODULE_DESC="Audita headers de seguranca (HSTS, CSP, X-Frame-Options...) e da uma nota"
MODULE_CATEGORY="enum"
MODULE_AUTHOR="CyberGuard"
MODULE_REQUIRES="curl"
MODULE_INTRUSIVE="true"
MODULE_ARGS_HELP="[url|host]  (default: https://TARGET)"

module_run() {
    local arg="${1:-$TARGET}"
    require_target "$arg" || return 1

    local host="${arg#http://}"; host="${host#https://}"; host="${host%%/*}"
    require_scope "$host" || return 4

    local url
    if [[ "$arg" == http* ]]; then url="$arg"; else url="https://$host"; fi

    local out; out="$(ws_dir enum)/security_headers.txt" || return 1
    info "Auditando headers de seguranca de $url..."

    local headers
    headers="$(http_headers_only "$url" 2>/dev/null)" || {
        warn "Falha ao obter headers de $url"; return 1; }
    # normaliza para minusculas para checagem
    local lc
    lc="$(printf '%s' "$headers" | tr '[:upper:]' '[:lower:]')"

    # headers avaliados (nome:descricao)
    local -a checks=(
        "strict-transport-security|HSTS: forca HTTPS"
        "content-security-policy|CSP: mitiga XSS/injection"
        "x-frame-options|Protege contra clickjacking"
        "x-content-type-options|Impede MIME sniffing"
        "referrer-policy|Controla vazamento de referrer"
        "permissions-policy|Restringe APIs do navegador"
    )

    local present=0 total="${#checks[@]}"
    {
        printf '# Auditoria de headers de seguranca — %s\n' "$url"
        printf '# %s\n\n' "$(date -u +%Y-%m-%dT%H:%M:%SZ)"
        local item name desc
        for item in "${checks[@]}"; do
            name="${item%%|*}"; desc="${item#*|}"
            if printf '%s' "$lc" | grep -q "^${name}:"; then
                printf '  [+] %-28s presente   — %s\n' "$name" "$desc"
                present=$((present + 1))
            else
                printf '  [-] %-28s AUSENTE    — %s\n' "$name" "$desc"
            fi
        done

        # avisa sobre headers que vazam informacao
        printf '\n## Headers que expoem informacao\n'
        local leaky
        for leaky in server x-powered-by x-aspnet-version; do
            local v
            v="$(printf '%s' "$headers" | grep -iE "^${leaky}:" | tr -d '\r' | head -n1)"
            [[ -n "$v" ]] && printf '  [!] %s\n' "$v"
        done

        # nota simples
        local score=$(( present * 100 / total ))
        local grade="F"
        (( score >= 85 )) && grade="A"
        (( score >= 70 && score < 85 )) && grade="B"
        (( score >= 50 && score < 70 )) && grade="C"
        (( score >= 30 && score < 50 )) && grade="D"
        printf '\n## Nota\n'
        printf '  %d/%d headers presentes — score %d%% — nota %s\n' \
            "$present" "$total" "$score" "$grade"
    } | ws_write "$out"

    ok "Auditoria de headers salva em $out ($present/$total presentes)"
    return 0
}
