#!/usr/bin/env bash
#
# core/bootstrap.sh — ponto de entrada logico do OfensivaBash.
#
# Responsabilidade unica: definir o modo estrito do shell, resolver e exportar
# os paths do projeto, dar source() em todo o core/lib na ordem correta, e
# expor ofb_main() que decide entre REPL e CLI.
#
# Este e o UNICO lugar que liga as flags estritas (set -euo pipefail) para o
# processo principal. Os demais scripts do core sao bibliotecas carregadas aqui.

# Modo estrito. IFS seguro contra word-splitting acidental.
set -euo pipefail
IFS=$'\n\t'

# OFB_HOME deve ter sido exportado pelo entrypoint. Se alguem deu source()
# direto neste arquivo, tenta resolver a partir do proprio BASH_SOURCE.
if [[ -z "${OFB_HOME:-}" ]]; then
    OFB_HOME="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
    export OFB_HOME
fi

# Paths canonicos exportados para o core, libs e modulos.
export OFB_CORE_DIR="$OFB_HOME/core"
export OFB_LIB_DIR="$OFB_HOME/lib"
export OFB_MODULES_DIR="$OFB_HOME/modules"
export OFB_PLAYBOOKS_DIR="$OFB_HOME/playbooks"

# Diretorio de dados do usuario (config, historico). Respeita XDG e Termux.
export OFB_CONFIG_DIR="${OFB_CONFIG_DIR:-${XDG_CONFIG_HOME:-$HOME/.config}/ofensivabash}"

# Raiz dos workspaces (um por alvo). Default dentro do repo; config pode mudar.
export OFB_WORKSPACES_DIR="${OFB_WORKSPACES_DIR:-$OFB_HOME/workspaces}"

# Versao semantica lida do arquivo VERSION.
if [[ -r "$OFB_HOME/VERSION" ]]; then
    OFB_VERSION="$(tr -d '[:space:]' < "$OFB_HOME/VERSION")"
else
    OFB_VERSION="0.0.0-dev"
fi
export OFB_VERSION

# Codigos de saida consistentes (secao 12 da spec).
export OFB_EXIT_OK=0          # sucesso
export OFB_EXIT_ERROR=1       # erro de execucao
export OFB_EXIT_USAGE=2       # erro de uso (flags/args)
export OFB_EXIT_DEP=3         # dependencia obrigatoria ausente
export OFB_EXIT_SCOPE=4       # acao bloqueada: fora de escopo em modo safe

# --- Carga ordenada do core e das libs -------------------------------------
# A ordem importa: ui antes de tudo (todo mundo loga), depois config/session,
# guardas, registry, libs e por fim loader/runner/report/repl/cli/playbook.
_ofb_source() {
    local f="$1"
    if [[ ! -r "$f" ]]; then
        printf 'ofensivabash: arquivo de core ausente: %s\n' "$f" >&2
        exit "$OFB_EXIT_ERROR"
    fi
    # shellcheck source=/dev/null
    source "$f"
}

_ofb_source "$OFB_CORE_DIR/ui.sh"
_ofb_source "$OFB_CORE_DIR/config.sh"
_ofb_source "$OFB_CORE_DIR/session.sh"
_ofb_source "$OFB_CORE_DIR/require.sh"
_ofb_source "$OFB_CORE_DIR/registry.sh"

# Libs compartilhadas (helpers usados pelos modulos).
_ofb_source "$OFB_LIB_DIR/fs.sh"
_ofb_source "$OFB_LIB_DIR/parse.sh"
_ofb_source "$OFB_LIB_DIR/net.sh"
_ofb_source "$OFB_LIB_DIR/http.sh"
_ofb_source "$OFB_LIB_DIR/json.sh"

# Orquestracao (dependem do que veio acima).
_ofb_source "$OFB_CORE_DIR/loader.sh"
_ofb_source "$OFB_CORE_DIR/runner.sh"
_ofb_source "$OFB_CORE_DIR/report.sh"
_ofb_source "$OFB_CORE_DIR/playbook.sh"
_ofb_source "$OFB_CORE_DIR/repl.sh"
_ofb_source "$OFB_CORE_DIR/cli.sh"

# ofb_main — decide o fluxo. Sem argumentos => REPL interativo. Com argumentos
# => CLI. Carrega a config e os modulos antes de qualquer coisa.
ofb_main() {
    config_load
    session_init_defaults
    loader_load_all

    if [[ $# -eq 0 ]]; then
        repl_main
    else
        cli_main "$@"
    fi
}
