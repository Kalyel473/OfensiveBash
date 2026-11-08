#!/usr/bin/env bash
#
# core/require.sh — guardas reutilizaveis pelos modulos.
#
# TODAS retornam codigo de status; NENHUMA chama exit. Um modulo que falha
# numa guarda apenas retorna, sem derrubar o framework.
#
#   require_tool <bin>    — a ferramenta esta no PATH? registra se faltar.
#   require_target [val]  — ha um alvo definido (ou um valor nao-vazio)?
#   require_scope <host>  — o host pode ser tocado no modo atual?

# Lista de ferramentas que faltaram durante a sessao (para o relatorio/aviso).
declare -gA OFB_MISSING_TOOLS=()

# require_tool <bin> — retorna 0 se existe, OFB_EXIT_DEP se nao.
require_tool() {
    local bin="${1:-}"
    [[ -z "$bin" ]] && return "$OFB_EXIT_USAGE"
    if command -v "$bin" >/dev/null 2>&1; then
        return 0
    fi
    OFB_MISSING_TOOLS["$bin"]=1
    debug "ferramenta ausente: $bin"
    return "$OFB_EXIT_DEP"
}

# require_target [valor] — garante alvo. Se um valor for passado, valida ele;
# senao exige que TARGET da sessao esteja definido.
require_target() {
    local val="${1:-$TARGET}"
    if [[ -z "$val" ]]; then
        err "Nenhum alvo definido. Use 'set target <alvo>' ou -t <alvo>."
        return "$OFB_EXIT_USAGE"
    fi
    return 0
}

# require_scope <host> — aplica a politica de escopo conforme o MODE.
#   - MODE=active  : permite qualquer host (operador assumiu a responsabilidade)
#   - MODE=ctf     : permite labs; so bloqueia se o host estiver claramente fora
#                    e nao for IP privado/localhost
#   - MODE=safe    : so permite localhost ou hosts dentro do SCOPE
# Retorna 0 se permitido, OFB_EXIT_SCOPE se bloqueado.
require_scope() {
    local host="${1:-$TARGET}"
    [[ -z "$host" ]] && { err "require_scope: host vazio"; return "$OFB_EXIT_USAGE"; }

    # localhost e sempre permitido.
    if net_is_localhost "$host"; then
        return 0
    fi

    case "$MODE" in
        active)
            return 0
            ;;
        ctf)
            # Em CTF, IPs privados/labs sao liberados; o resto exige escopo.
            if parse_is_ipv4 "$host" && net_is_private_ip "$host"; then
                return 0
            fi
            if in_scope "$host"; then
                return 0
            fi
            err "Fora de escopo no modo CTF: $host (adicione com 'set scope')"
            return "$OFB_EXIT_SCOPE"
            ;;
        safe|*)
            if in_scope "$host"; then
                return 0
            fi
            err "Bloqueado pelo modo --safe: '$host' fora do escopo."
            err "Adicione ao escopo (set scope <dom/cidr>) ou use --active se autorizado."
            return "$OFB_EXIT_SCOPE"
            ;;
    esac
}

# require_tools <lista> — checa varias ferramentas; retorna DEP se qualquer
# uma faltar. Usado pelo runner a partir de MODULE_REQUIRES.
require_tools() {
    local missing=0 t
    for t in "$@"; do
        require_tool "$t" || missing=1
    done
    [[ "$missing" -eq 0 ]] && return 0
    return "$OFB_EXIT_DEP"
}
