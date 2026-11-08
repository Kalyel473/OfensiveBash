#!/usr/bin/env bats
# tests/modules.bats — testes de modulo com entrada MOCKADA (sem bater em alvo real).

setup() {
    load "test_helper"
    load_ofensivabash
    loader_load_all
    # workspace de teste
    export TARGET="exemplo.com"
    export SCOPE="exemplo.com"
    export MODE="safe"
    export WORKSPACE="${BATS_TEST_TMPDIR}/ws-mod"
    ws_init "$WORKSPACE"
}

@test "recon/ctlogs parseia subdominios a partir de fixture (sem rede)" {
    # Mocka http_get para devolver a fixture, sem tocar a rede.
    http_get() { cat "${OFB_HOME}/tests/fixtures/crtsh.json"; }
    export -f http_get 2>/dev/null || true

    run_module "recon/ctlogs" "exemplo.com"

    local out="$WORKSPACE/recon/subdomains.txt"
    [ -f "$out" ]
    grep -q "www.exemplo.com"  "$out"
    grep -q "api.exemplo.com"  "$out"
    grep -q "mail.exemplo.com" "$out"
    # o curinga *.exemplo.com deve ter virado exemplo.com (sem o *.)
    ! grep -q '\*' "$out"
    # dedup: www aparece uma vez
    [ "$(grep -c 'www.exemplo.com' "$out")" -eq 1 ]
}

@test "runner registra execucao no log.jsonl" {
    http_get() { cat "${OFB_HOME}/tests/fixtures/crtsh.json"; }
    export -f http_get 2>/dev/null || true
    run_module "recon/ctlogs" "exemplo.com"
    [ -s "$WORKSPACE/log.jsonl" ]
    grep -q '"module":"recon/ctlogs"' "$WORKSPACE/log.jsonl"
}

@test "modulo intrusivo e bloqueado fora de escopo no modo safe" {
    export TARGET="fora-de-escopo.com"
    export SCOPE="exemplo.com"
    export MODE="safe"
    export WORKSPACE="${BATS_TEST_TMPDIR}/ws-block"
    ws_init "$WORKSPACE"
    run run_module "scan/ports" "-p" "80"
    [ "$status" -eq "$OFB_EXIT_SCOPE" ]
}

@test "post/report gera report.md" {
    run_module "post/report"
    [ -f "$WORKSPACE/report.md" ]
    grep -q "Relatorio OfensivaBash" "$WORKSPACE/report.md"
}

@test "report inclui aviso de uso autorizado" {
    report_generate "exemplo.com" >/dev/null
    grep -qi "autorizado" "$WORKSPACE/report.md"
}
