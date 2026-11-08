#!/usr/bin/env bash
#
# core/runner.sh — executa UM modulo com guardas, logging e medicao.
#
# Importante: todos os modulos definem a funcao module_run, entao o loader
# acaba deixando apenas a ultima no ambiente. Por isso o runner RE-CARREGA
# (source) o arquivo do modulo selecionado imediatamente antes de executar,
# ligando module_run/MODULE_* ao modulo certo.
#
# Passos: valida existencia -> re-source -> require_tools (MODULE_REQUIRES) ->
# require_scope (se intrusivo) -> cria saida no workspace -> mede tempo ->
# captura exit code -> grava linha em log.jsonl.

# _runner_log <module> <status> <duration> — acrescenta uma linha no log.jsonl.
_runner_log() {
    local module="$1" status="$2" dur="$3"
    [[ -z "$WORKSPACE" ]] && return 0
    local logf="$WORKSPACE/log.jsonl"
    local ts; ts="$(date -u +%Y-%m-%dT%H:%M:%SZ)"
    printf '{"ts":"%s","module":"%s","target":"%s","status":%s,"duration":%s}\n' \
        "$ts" "$(json_escape "$module")" "$(json_escape "$TARGET")" \
        "$status" "$dur" >> "$logf" 2>/dev/null || true
}

# run_module <nome> [args...] — orquestra a execucao. Retorna o codigo do modulo
# (ou um codigo de erro do framework). Nunca mata o processo principal.
run_module() {
    local name="${1:-}"; shift || true
    if [[ -z "$name" ]]; then
        err "run_module: nome do modulo ausente"
        return "$OFB_EXIT_USAGE"
    fi
    if ! registry_has "$name"; then
        err "Modulo desconhecido: $name (use 'modules' para listar)"
        return "$OFB_EXIT_USAGE"
    fi

    local file; file="$(registry_file "$name")"
    if [[ ! -r "$file" ]]; then
        err "Arquivo do modulo ilegivel: $file"
        return "$OFB_EXIT_ERROR"
    fi

    # Re-carrega o modulo para ligar module_run/MODULE_* a este modulo.
    unset -f module_run module_help 2>/dev/null || true
    unset MODULE_NAME MODULE_DESC MODULE_CATEGORY MODULE_AUTHOR \
          MODULE_REQUIRES MODULE_INTRUSIVE MODULE_ARGS_HELP 2>/dev/null || true
    # shellcheck source=/dev/null
    if ! source "$file"; then
        err "Falha ao carregar $name"
        return "$OFB_EXIT_ERROR"
    fi

    # Guarda: dependencias declaradas.
    if [[ -n "${MODULE_REQUIRES:-}" ]]; then
        # shellcheck disable=SC2086
        if ! require_tools $MODULE_REQUIRES; then
            local miss=""
            local t
            for t in $MODULE_REQUIRES; do
                command -v "$t" >/dev/null 2>&1 || miss+=" $t"
            done
            warn "Modulo '$name' precisa de:${miss}. Instale e tente de novo."
            _runner_log "$name" "\"dep-missing\"" 0
            return "$OFB_EXIT_DEP"
        fi
    fi

    # Guarda: escopo, apenas para modulos intrusivos.
    if [[ "${MODULE_INTRUSIVE:-false}" == "true" ]]; then
        local host="${TARGET:-${1:-}}"
        if [[ -n "$host" ]] && ! require_scope "$host"; then
            _runner_log "$name" "\"scope-blocked\"" 0
            return "$OFB_EXIT_SCOPE"
        fi
    fi

    # Trap para limpar filhos se o usuario interromper durante o modulo.
    local _old_int
    _old_int="$(trap -p INT || true)"
    trap '_runner_on_int' INT

    section "Executando $name"
    local start end dur rc
    start="$(date +%s)"
    # Executa o modulo capturando o codigo sem deixar o set -e derrubar tudo.
    if module_run "$@"; then
        rc=0
    else
        rc=$?
    fi
    end="$(date +%s)"
    dur=$(( end - start ))

    # restaura o trap anterior de INT
    if [[ -n "$_old_int" ]]; then eval "$_old_int"; else trap - INT; fi

    if [[ "$rc" -eq 0 ]]; then
        ok "Modulo '$name' concluido em ${dur}s"
        _runner_log "$name" "\"ok\"" "$dur"
    else
        warn "Modulo '$name' retornou codigo $rc (${dur}s)"
        _runner_log "$name" "$rc" "$dur"
    fi
    return "$rc"
}

# _runner_on_int — handler de Ctrl+C durante um modulo: mata jobs em background.
_runner_on_int() {
    warn "Interrompido. Encerrando tarefas em background..."
    local j
    for j in $(jobs -p 2>/dev/null); do
        kill "$j" 2>/dev/null || true
    done
    return 130
}
