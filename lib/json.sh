#!/usr/bin/env bash
#
# lib/json.sh — helpers de JSON com degradacao graciosa (jq opcional).
#
# Se jq existe, usamos jq. Se nao, caimos para grep/sed para os casos simples.
# Modulos devem SEMPRE preferir estes helpers a assumir jq.

# json_has_jq — 0 se jq esta disponivel.
json_has_jq() { command -v jq >/dev/null 2>&1; }

# json_field <campo> — extrai um campo escalar de cada objeto (lê stdin).
# Com jq: usa .campo. Sem jq: regex "campo":"valor" por grep.
# Ex: printf '%s' "$json" | json_field name_value
json_field() {
    local field="${1:-}"
    [[ -z "$field" ]] && return 2
    if json_has_jq; then
        jq -r --arg f "$field" '.. | objects | .[$f]? // empty' 2>/dev/null
    else
        grep -oE "\"${field}\"[[:space:]]*:[[:space:]]*\"[^\"]*\"" 2>/dev/null \
            | sed -E "s/.*:[[:space:]]*\"([^\"]*)\"/\1/"
    fi
}

# json_array_field <campo> — para um array de objetos no topo, extrai .campo
# de cada elemento (lê stdin). Fallback identico ao json_field.
json_array_field() {
    local field="${1:-}"
    [[ -z "$field" ]] && return 2
    if json_has_jq; then
        jq -r --arg f "$field" '.[]? | .[$f]? // empty' 2>/dev/null
    else
        grep -oE "\"${field}\"[[:space:]]*:[[:space:]]*\"[^\"]*\"" 2>/dev/null \
            | sed -E "s/.*:[[:space:]]*\"([^\"]*)\"/\1/"
    fi
}

# json_escape <str> — escapa uma string para embutir em JSON (imprime).
json_escape() {
    local s="$1"
    s="${s//\\/\\\\}"; s="${s//\"/\\\"}"
    s="${s//$'\n'/\\n}"; s="${s//$'\t'/\\t}"; s="${s//$'\r'/}"
    printf '%s' "$s"
}
