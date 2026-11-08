#!/usr/bin/env bash
#
# core/report.sh — agrega o workspace do alvo num report.md (e opcional .html).
#
# Monta: cabecalho, sumario da sessao, timeline (do log.jsonl), achados por
# categoria (lista de arquivos de saida) e ferramentas ausentes.

# report_generate [alvo] — gera <workspace>/report.md para o alvo atual.
report_generate() {
    local target="${1:-$TARGET}"
    if [[ -z "$target" ]]; then
        err "report: nenhum alvo. Defina um alvo primeiro."
        return "$OFB_EXIT_USAGE"
    fi
    local ws="$WORKSPACE"
    if [[ -z "$ws" || "$target" != "$TARGET" ]]; then
        local safe; safe="$(sanitize_target_name "$target")"
        ws="$OFB_WORKSPACES_DIR/$safe"
    fi
    if [[ ! -d "$ws" ]]; then
        err "Workspace inexistente para '$target'"
        return "$OFB_EXIT_ERROR"
    fi

    local out="$ws/report.md"
    local now; now="$(date -u +%Y-%m-%dT%H:%M:%SZ)"

    {
        printf '# Relatorio OfensivaBash — %s\n\n' "$target"
        printf '> Gerado em %s por OfensivaBash v%s.\n' "$now" "$OFB_VERSION"
        printf '> **Uso autorizado somente.** Este relatorio documenta atividade de teste autorizado.\n\n'

        printf '## Sessao\n\n'
        printf '| Campo | Valor |\n|---|---|\n'
        printf '| Alvo | `%s` |\n' "$target"
        printf '| Escopo | `%s` |\n' "${SCOPE:-(nao definido)}"
        printf '| Modo | `%s` |\n' "${MODE:-safe}"
        printf '| Workspace | `%s` |\n\n' "$ws"

        # Timeline a partir do log.jsonl
        printf '## Timeline de execucoes\n\n'
        if [[ -s "$ws/log.jsonl" ]]; then
            printf '| Horario (UTC) | Modulo | Status | Duracao |\n|---|---|---|---|\n'
            _report_timeline "$ws/log.jsonl"
            printf '\n'
        else
            printf '_Nenhuma execucao registrada._\n\n'
        fi

        # Achados por categoria
        printf '## Achados por categoria\n\n'
        local cat
        for cat in recon scan enum vuln loot; do
            local dir="$ws/$cat"
            [[ -d "$dir" ]] || continue
            # ha algum arquivo nao-vazio?
            local files
            files="$(find "$dir" -type f ! -empty 2>/dev/null | sort)"
            [[ -z "$files" ]] && continue
            printf '### %s\n\n' "$cat"
            local f rel lines
            while IFS= read -r f; do
                [[ -z "$f" ]] && continue
                rel="${f#"$ws"/}"
                lines="$(fs_count_lines "$f")"
                printf '%s\n' "- \`$rel\` ($lines linha(s))"
            done <<< "$files"
            printf '\n'
        done

        # Ferramentas ausentes observadas na sessao
        if [[ ${#OFB_MISSING_TOOLS[@]} -gt 0 ]]; then
            printf '## Ferramentas opcionais ausentes\n\n'
            printf 'Alguns modulos degradaram por falta de:\n\n'
            local tool
            for tool in $(printf '%s\n' "${!OFB_MISSING_TOOLS[@]}" | sort); do
                printf '%s\n' "- \`$tool\`"
            done
            printf '\n'
        fi

        printf -- '---\n\n'
        printf '_OfensivaBash — CyberGuard Academy / Cybersegurança na Prática._\n'
    } > "$out.tmp" && mv -f "$out.tmp" "$out"

    ok "Relatorio gerado: $out"
    printf '%s\n' "$out"
    return 0
}

# _report_timeline <log.jsonl> — transforma o log em linhas de tabela markdown.
# Usa jq se disponivel; senao faz parsing simples por sed.
_report_timeline() {
    local logf="$1"
    if json_has_jq; then
        jq -r '"| \(.ts) | \(.module) | \(.status) | \(.duration // 0)s |"' "$logf" 2>/dev/null && return 0
    fi
    # fallback sem jq: extrai campos conhecidos de cada linha.
    local line ts mod st dur
    while IFS= read -r line; do
        [[ -z "$line" ]] && continue
        ts="$(printf '%s' "$line"  | sed -nE 's/.*"ts":"([^"]*)".*/\1/p')"
        mod="$(printf '%s' "$line" | sed -nE 's/.*"module":"([^"]*)".*/\1/p')"
        st="$(printf '%s' "$line"  | sed -nE 's/.*"status":("?[^,}]*"?).*/\1/p')"
        dur="$(printf '%s' "$line" | sed -nE 's/.*"duration":([0-9]+).*/\1/p')"
        printf '| %s | %s | %s | %ss |\n' "${ts:-?}" "${mod:-?}" "${st:-?}" "${dur:-0}"
    done < "$logf"
}
