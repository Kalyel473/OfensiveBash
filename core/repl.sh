#!/usr/bin/env bash

OFB_SELECTED=""

# _repl_prompt — monta a string do prompt conforme o estado.
_repl_prompt() {
    local p="ofensivabash"
    [[ -n "$OFB_SELECTED" ]] && p+=" ($OFB_SELECTED)"
    [[ -n "$TARGET" ]] && p+=" [$TARGET]"
    [[ "$MODE" != "safe" ]] && p+=" {$MODE}"
    printf '%s > ' "$p"
}

# _repl_complete — funcao de autocomplete para 'read -e'.
# (Registra comandos e nomes de modulo.)
_repl_setup_completion() {
    # bash readline completion so funciona bem com 'read -e'; montamos uma
    # lista estatica de palavras para o compgen padrao do shell interativo.
    :  # a completacao fina depende de bind; mantemos simples e robusto.
}

# _repl_help — ajuda geral ou de um comando.
_repl_help() {
    local cmd="${1:-}"
    if [[ -z "$cmd" ]]; then
        cat >&2 <<'HELP'
Comandos do OfensivaBash (REPL):
  help [comando]          ajuda geral ou de um comando
  set target <alvo>       define o alvo e cria o workspace
  set scope <dom/cidr>    adiciona um item ao escopo permitido
  set mode safe|active|ctf alterna o modo de seguranca
  modules [categoria]     lista modulos (filtra por categoria)
  search <termo>          busca modulo por nome/descricao
  use <modulo>            seleciona um modulo
  info                    descreve o modulo selecionado e seus args
  run [args]              executa o modulo selecionado
  playbook <nome>         roda uma cadeia de modulos
  workspace [alvo]        mostra/troca o workspace
  report                  gera o relatorio do alvo atual
  sessions                lista workspaces/alvos
  banner                  reexibe o banner
  exit | quit             sai
HELP
        return 0
    fi
    case "$cmd" in
        set)     printf 'set target|scope|mode <valor>\n' >&2 ;;
        use)     printf 'use <modulo>  — seleciona um modulo (ver "modules")\n' >&2 ;;
        run)     printf 'run [args]    — executa o modulo selecionado com args opcionais\n' >&2 ;;
        playbook)printf 'playbook <nome>  — executa um playbook de playbooks/\n' >&2 ;;
        *)       printf 'Sem ajuda especifica para "%s". Veja "help".\n' "$cmd" >&2 ;;
    esac
}

# _repl_info — mostra detalhes do modulo selecionado.
_repl_info() {
    if [[ -z "$OFB_SELECTED" ]]; then
        warn "Nenhum modulo selecionado. Use 'use <modulo>'."
        return 1
    fi
    local n="$OFB_SELECTED"
    printf '%sModulo:%s   %s\n' "$OFB_C_BOLD" "$OFB_C_RESET" "$n" >&2
    printf 'Descricao: %s\n' "${OFB_REG_DESC[$n]}" >&2
    printf 'Categoria: %s\n' "${OFB_REG_CAT[$n]}" >&2
    printf 'Autor:     %s\n' "${OFB_REG_AUTHOR[$n]}" >&2
    printf 'Requer:    %s\n' "${OFB_REG_REQUIRES[$n]:-(nada)}" >&2
    printf 'Intrusivo: %s\n' "${OFB_REG_INTRUSIVE[$n]}" >&2
    printf 'Args:      %s\n' "${OFB_REG_ARGSHELP[$n]:-(nenhum)}" >&2
    return 0
}

# _repl_dispatch <linha> — interpreta e executa um comando do REPL.
_repl_dispatch() {
    local line="$1"
    # tokeniza respeitando espacos simples. O bootstrap deixa IFS=$'\n\t' por
    # seguranca, entao restauramos o espaco localmente so para esta separacao.
    local -a tok=()
    local IFS=$' \t\n'
    read -r -a tok <<< "$line"
    [[ ${#tok[@]} -eq 0 ]] && return 0
    local cmd="${tok[0]}"

    case "$cmd" in
        help) _repl_help "${tok[1]:-}" ;;
        banner) banner ;;
        set)
            case "${tok[1]:-}" in
                target) set_target "${tok[2]:-}" || true ;;
                scope)  add_scope "${tok[2]:-}" && ok "Escopo: $SCOPE" || true ;;
                mode)   set_mode "${tok[2]:-}" || true ;;
                *) warn "Uso: set target|scope|mode <valor>" ;;
            esac
            ;;
        modules) registry_list "${tok[1]:-}" >&2 ;;
        search)  registry_search "${tok[1]:-}" >&2 ;;
        use)
            local m="${tok[1]:-}"
            if registry_has "$m"; then
                OFB_SELECTED="$m"; ok "Selecionado: $m"
            else
                err "Modulo desconhecido: $m"
            fi
            ;;
        info) _repl_info || true ;;
        run)
            if [[ -z "$OFB_SELECTED" ]]; then
                warn "Nenhum modulo selecionado. Use 'use <modulo>'."
            else
                run_module "$OFB_SELECTED" "${tok[@]:1}" || true
            fi
            ;;
        playbook) playbook_run "${tok[1]:-}" || true ;;
        workspace)
            if [[ -n "${tok[1]:-}" ]]; then
                session_load "${tok[1]}" || true
            else
                info "Workspace atual: ${WORKSPACE:-(nenhum)}"
            fi
            ;;
        report)   report_generate "$TARGET" >/dev/null || true ;;
        sessions) session_list >&2 ;;
        exit|quit) return 99 ;;
        "") : ;;
        *) warn "Comando desconhecido: $cmd (veja 'help')" ;;
    esac
    return 0
}

# repl_main — laco principal do REPL.
repl_main() {
    banner
    _repl_setup_completion

    local histfile="$OFB_CONFIG_DIR/history"
    mkdir -p "$OFB_CONFIG_DIR" 2>/dev/null || true
    history -r "$histfile" 2>/dev/null || true

    # Ctrl+C cancela a linha atual sem sair do REPL.
    trap ':' INT

    info "Bem-vindo. Digite 'help' para os comandos. Ctrl+D para sair."

    local line rc
    while true; do
        # read -e habilita edicao de linha e historico.
        if ! IFS= read -r -e -p "$(_repl_prompt)" line; then
            # Ctrl+D (EOF)
            printf '\n' >&2
            break
        fi
        [[ -z "${line//[[:space:]]/}" ]] && continue
        history -s "$line" 2>/dev/null || true
        _repl_dispatch "$line" && rc=0 || rc=$?
        [[ "$rc" -eq 99 ]] && break
    done

    history -w "$histfile" 2>/dev/null || true
    trap - INT
    ok "Ate a proxima. Mantenha o pentest autorizado. 🛡"
    return 0
}
