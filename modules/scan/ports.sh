#!/usr/bin/env bash

MODULE_NAME="scan/ports"
MODULE_DESC="Scanner TCP nativo (/dev/tcp), sem nmap; paraleliza e detecta portas abertas"
MODULE_CATEGORY="scan"
MODULE_AUTHOR="CyberGuard"
MODULE_REQUIRES=""              # usa recursos nativos do Bash + xargs
MODULE_INTRUSIVE="true"
MODULE_ARGS_HELP="[-p 80,443 | -p 1-1024 | -p top]  (default: top)"

# top ~ portas comuns para um primeiro recon.
_ports_top_list() {
    printf '%s\n' 21 22 23 25 53 80 110 111 135 139 143 443 445 \
        993 995 1723 3306 3389 5432 5900 6379 8000 8080 8443 8888 9000 9200 27017
}

# _ports_expand <spec> — imprime uma porta por linha a partir de "top",
# "a,b,c" ou "ini-fim".
_ports_expand() {
    local spec="${1:-top}"
    if [[ "$spec" == "top" ]]; then _ports_top_list; return 0; fi
    local part
    local -a parts=()
    IFS=',' read -r -a parts <<< "$spec"
    for part in "${parts[@]}"; do
        if [[ "$part" == *-* ]]; then
            local a="${part%-*}" b="${part#*-}"
            [[ "$a" =~ ^[0-9]+$ && "$b" =~ ^[0-9]+$ ]] || continue
            (( a < 1 )) && a=1; (( b > 65535 )) && b=65535
            local p
            for (( p=a; p<=b; p++ )); do printf '%d\n' "$p"; done
        elif [[ "$part" =~ ^[0-9]+$ ]]; then
            printf '%d\n' "$part"
        fi
    done
}

module_run() {
    local spec="top"
    # parse de args: -p <spec>
    while [[ $# -gt 0 ]]; do
        case "$1" in
            -p|--ports) spec="${2:-top}"; shift 2 ;;
            *) shift ;;
        esac
    done

    require_target || return 1
    # guarda extra de escopo (o runner ja aplica, mas reforcamos a semantica).
    require_scope "$TARGET" || return 4

    local out; out="$(ws_dir scan)/ports.txt" || return 1
    local threads; threads="$(cfg_get OFB_THREADS 20)"
    info "Scan TCP de $TARGET (portas: $spec, threads: $threads)..."

    # Exporta o helper e o alvo para os subprocessos do xargs.
    local probe
    probe="$(cat <<'PROBE'
host="$1"; port="$2"
if command -v timeout >/dev/null 2>&1; then
    if timeout 2 bash -c "exec 3<>/dev/tcp/${host}/${port}" 2>/dev/null; then
        printf '%s\n' "$port"
    fi
else
    if (exec 3<>"/dev/tcp/${host}/${port}") 2>/dev/null; then
        printf '%s\n' "$port"
    fi
fi
PROBE
)"

    local open
    open="$(_ports_expand "$spec" \
        | xargs -P "$threads" -I '{}' bash -c "$probe" _ "$TARGET" '{}' 2>/dev/null \
        | sort -n)"

    {
        printf '# Portas TCP abertas em %s\n' "$TARGET"
        printf '# Portas testadas: %s | %s\n\n' "$spec" "$(date -u +%Y-%m-%dT%H:%M:%SZ)"
        if [[ -n "$open" ]]; then
            printf '%s\n' "$open"
        else
            printf '# nenhuma porta aberta detectada\n'
        fi
    } | ws_write "$out"

    local n=0
    [[ -n "$open" ]] && n="$(printf '%s\n' "$open" | grep -c .)"
    ok "$n porta(s) aberta(s). Resultado em $out"
    [[ -n "$open" ]] && printf '%s\n' "$open" | tr '\n' ' ' | sed 's/^/  abertas: /; s/$/\n/' >&2
    return 0
}
