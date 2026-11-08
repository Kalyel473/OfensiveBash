#!/usr/bin/env bash
#
# modules/_template.sh — MOLDE de modulo do OfensivaBash.
#
# Como contribuir com um modulo:
#   1. Copie este arquivo para modules/<categoria>/<nome>.sh
#   2. Preencha os metadados abaixo.
#   3. Escreva module_run() usando os helpers do core/lib.
#   4. Rode `make lint` e `make test`.
#
# Regras de ouro:
#   - NUNCA chame exit; use return.
#   - Grave saida em "$(ws_dir <categoria>)/...", nunca em caminho fixo.
#   - Toque o alvo apenas apos require_target/require_scope.
#   - Nenhum payload malicioso, persistencia ou exploit-arma. Foco em
#     descoberta, enumeracao, checagem de config, CTF e relatorio.
#
# O loader ignora arquivos iniciados por "_", entao este molde nao e carregado.

# --- Metadados (obrigatorios) ----------------------------------------------
MODULE_NAME="categoria/nome"                 # identificador unico
MODULE_DESC="Descreva em uma linha, em PT-BR, o que o modulo faz"
MODULE_CATEGORY="recon"                       # recon|scan|enum|vuln|ctf|post
MODULE_AUTHOR="SeuNome"

# --- Metadados (opcionais) -------------------------------------------------
MODULE_REQUIRES=""            # bins necessarios, ex: "curl jq"
MODULE_INTRUSIVE="false"      # true se toca o alvo ativamente
MODULE_ARGS_HELP="<arg>  (default: TARGET da sessao)"

# module_help — opcional. Se ausente, o core gera uma ajuda a partir dos metadados.
module_help() {
    cat <<HELP
$MODULE_NAME — $MODULE_DESC
Uso: run $MODULE_ARGS_HELP
HELP
}

# module_run "$@" — obrigatoria. Faz o trabalho e retorna 0 em sucesso.
module_run() {
    local alvo="${1:-$TARGET}"
    require_target "$alvo" || return 1

    local out; out="$(ws_dir "$MODULE_CATEGORY")/exemplo.txt"
    info "Rodando $MODULE_NAME contra $alvo..."

    # ... trabalho do modulo aqui; grave resultados em "$out" ...
    printf 'exemplo\n' | ws_write "$out"

    ok "Saida salva em $out"
    return 0
}
