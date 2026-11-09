#!/usr/bin/env bash

playbook_resolve() {
    local name="${1:-}"
    [[ -z "$name" ]] && return 1
    if [[ -r "$name" ]]; then printf '%s' "$name"; return 0; fi
    if [[ -r "$OFB_PLAYBOOKS_DIR/$name" ]]; then printf '%s' "$OFB_PLAYBOOKS_DIR/$name"; return 0; fi
    if [[ -r "$OFB_PLAYBOOKS_DIR/${name}.playbook" ]]; then printf '%s' "$OFB_PLAYBOOKS_DIR/${name}.playbook"; return 0; fi
    return 1
}

# playbook_run <nome> [--on-fail stop|continue] — executa a cadeia.
playbook_run() {
    local name="${1:-}"; shift || true
    local on_fail="continue"
    while [[ $# -gt 0 ]]; do
        case "$1" in
            --on-fail) on_fail="${2:-continue}"; shift 2 ;;
            *) shift ;;
        esac
    done

    local file
    if ! file="$(playbook_resolve "$name")"; then
        err "Playbook nao encontrado: $name"
        return "$OFB_EXIT_USAGE"
    fi
    if ! require_target; then
        return "$OFB_EXIT_USAGE"
    fi

    section "Playbook: $name"
    local total=0 okc=0 failc=0
    local gstart gend
    gstart="$(date +%s)"

    local line
    while IFS= read -r line || [[ -n "$line" ]]; do
        # remove comentario e espacos nas pontas
        line="${line%%#*}"
        line="${line#"${line%%[![:space:]]*}"}"
        line="${line%"${line##*[![:space:]]}"}"
        [[ -z "$line" ]] && continue

        # separa modulo de args (apos --)
        local mod args_str
        if [[ "$line" == *" -- "* ]]; then
            mod="${line%% -- *}"
            args_str="${line#* -- }"
        else
            mod="$line"
            args_str=""
        fi
        mod="${mod%"${mod##*[![:space:]]}"}"

        # expande $TARGET e $SCOPE nos args, de forma controlada (sem eval).
        args_str="${args_str//\$TARGET/$TARGET}"
        args_str="${args_str//\$SCOPE/$SCOPE}"

        total=$((total + 1))
        # transforma a string de args num array respeitando espacos simples.
        local -a args=()
        if [[ -n "$args_str" ]]; then
            # restaura o espaco no IFS local para separar os args do passo
            local IFS=$' \t\n'
            read -r -a args <<< "$args_str"
        fi

        local rc
        if run_module "$mod" "${args[@]}"; then
            rc=0; okc=$((okc + 1))
        else
            rc=$?; failc=$((failc + 1))
            if [[ "$on_fail" == "stop" ]]; then
                err "Passo falhou (codigo $rc) e politica e 'stop'. Abortando playbook."
                break
            fi
        fi
    done < "$file"

    gend="$(date +%s)"
    section "Resumo do playbook"
    info "Passos: $total | OK: $okc | Falha: $failc | Duracao: $(( gend - gstart ))s"

    # gera o relatorio ao final, por conveniencia
    local rep
    rep="$(report_generate "$TARGET" 2>/dev/null | tail -n1 || true)"
    [[ -n "$rep" ]] && info "Relatorio: $rep"

    [[ "$failc" -eq 0 ]] && return 0
    return "$OFB_EXIT_ERROR"
}
