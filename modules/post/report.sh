#!/usr/bin/env bash
#
# modules/post/report.sh — dispara o report.sh para o alvo atual.
#
# Modulo de pos-processamento: agrega o workspace num report.md. Nao toca o alvo.

MODULE_NAME="post/report"
MODULE_DESC="Gera o relatorio Markdown do alvo atual a partir do workspace"
MODULE_CATEGORY="post"
MODULE_AUTHOR="CyberGuard"
MODULE_REQUIRES=""
MODULE_INTRUSIVE="false"
MODULE_ARGS_HELP="(sem args; usa o TARGET da sessao)"

module_run() {
    require_target || return 1
    report_generate "$TARGET" >/dev/null || return 1
    return 0
}
