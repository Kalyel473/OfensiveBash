#!/usr/bin/env bash
# tests/test_helper.bash — helpers compartilhados pelos testes bats.

# Carrega o core do OfensivaBash num ambiente de teste isolado.
load_ofensivabash() {
    OFB_HOME="$(cd "$(dirname "${BATS_TEST_FILENAME}")/.." && pwd)"
    export OFB_HOME
    # workspaces e config isolados por teste (nao poluem o repo nem o $HOME)
    export OFB_WORKSPACES_DIR="${BATS_TEST_TMPDIR}/workspaces"
    export OFB_CONFIG_DIR="${BATS_TEST_TMPDIR}/config"
    export OFB_NO_COLOR=1
    export OFB_QUIET=1
    mkdir -p "$OFB_WORKSPACES_DIR" "$OFB_CONFIG_DIR"
    # shellcheck source=/dev/null
    source "$OFB_HOME/core/bootstrap.sh"
    config_load
    session_init_defaults
}
