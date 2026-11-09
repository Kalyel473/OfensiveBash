#!/usr/bin/env bash

cli_usage() {
    cat >&2 <<USAGE
OfensivaBash v${OFB_VERSION} — framework de pentest em Bash (USO AUTORIZADO SOMENTE)

Uso:
  ofensivabash                             abre o REPL interativo
  ofensivabash -t <alvo> -m <modulo> [-- args...]
  ofensivabash -t <alvo> -p <playbook>
  ofensivabash --list-modules
  ofensivabash --report -t <alvo>

Flags:
  -t, --target <alvo>      alvo (dominio, IP ou CIDR)
  -m, --module <nome>      executa um modulo (ex: recon/ctlogs)
  -p, --playbook <nome>    executa um playbook (ex: recon-basico)
  -s, --scope <dom/cidr>   adiciona ao escopo (repetivel)
      --safe               modo seguro (default): bloqueia intrusivo fora de escopo
      --active             modo ativo: permite acoes intrusivas (voce assume a autorizacao)
      --ctf                modo CTF: libera labs/IPs privados
      --list-modules       lista os modulos carregados e sai
      --report             gera o relatorio do alvo e sai
  -o, --output <dir>       diretorio raiz dos workspaces
  -q, --quiet              saida minima
  -v, --verbose            saida detalhada (debug)
      --no-color           desliga cores
      --version            mostra a versao e sai
  -h, --help               esta ajuda
  --                       tudo depois vai cru para o modulo
USAGE
}

# cli_main "$@" — parseia flags e despacha a acao.
cli_main() {
    local opt_target="" opt_module="" opt_playbook="" opt_report=0
    local opt_list=0 opt_mode="safe"
    local -a opt_scopes=()
    local -a mod_args=()

    while [[ $# -gt 0 ]]; do
        case "$1" in
            -t|--target)   opt_target="${2:-}"; shift 2 ;;
            -m|--module)   opt_module="${2:-}"; shift 2 ;;
            -p|--playbook) opt_playbook="${2:-}"; shift 2 ;;
            -s|--scope)    opt_scopes+=("${2:-}"); shift 2 ;;
            --safe)        opt_mode="safe"; shift ;;
            --active)      opt_mode="active"; shift ;;
            --ctf)         opt_mode="ctf"; shift ;;
            --list-modules) opt_list=1; shift ;;
            --report)      opt_report=1; shift ;;
            -o|--output)   export OFB_WORKSPACES_DIR="${2:-}"; shift 2 ;;
            -q|--quiet)    export OFB_QUIET=1; shift ;;
            -v|--verbose)  export OFB_VERBOSE=1; shift ;;
            --no-color)    export OFB_NO_COLOR=1; shift ;;
            --version)     printf 'OfensivaBash v%s\n' "$OFB_VERSION"; return 0 ;;
            -h|--help)     cli_usage; return 0 ;;
            --)            shift; mod_args=("$@"); break ;;
            -*)            err "Flag desconhecida: $1"; cli_usage; return "$OFB_EXIT_USAGE" ;;
            *)             err "Argumento inesperado: $1"; cli_usage; return "$OFB_EXIT_USAGE" ;;
        esac
    done

    # modo
    set_mode "$opt_mode" >/dev/null 2>&1 || export MODE="$opt_mode"

    # --list-modules nao precisa de alvo
    if [[ "$opt_list" -eq 1 ]]; then
        banner
        registry_list >&2
        return 0
    fi

    # alvo + escopo
    if [[ -n "$opt_target" ]]; then
        set_target "$opt_target" || return "$OFB_EXIT_USAGE"
    fi
    local sc
    for sc in "${opt_scopes[@]}"; do
        [[ -n "$sc" ]] && add_scope "$sc"
    done

    # acoes (prioridade: report > module > playbook)
    if [[ "$opt_report" -eq 1 ]]; then
        require_target || return "$OFB_EXIT_USAGE"
        report_generate "$TARGET" >/dev/null
        return $?
    fi

    if [[ -n "$opt_module" ]]; then
        require_target || { err "Modulo exige alvo: use -t <alvo>"; return "$OFB_EXIT_USAGE"; }
        run_module "$opt_module" "${mod_args[@]}"
        return $?
    fi

    if [[ -n "$opt_playbook" ]]; then
        require_target || { err "Playbook exige alvo: use -t <alvo>"; return "$OFB_EXIT_USAGE"; }
        playbook_run "$opt_playbook"
        return $?
    fi

    # Nada para fazer: mostra ajuda.
    cli_usage
    return "$OFB_EXIT_USAGE"
}
