#!/usr/bin/env bash

declare -gA OFB_REG_DESC=()      # nome -> descricao
declare -gA OFB_REG_CAT=()       # nome -> categoria
declare -gA OFB_REG_AUTHOR=()    # nome -> autor
declare -gA OFB_REG_FILE=()      # nome -> caminho do arquivo .sh
declare -gA OFB_REG_REQUIRES=()  # nome -> bins necessarios
declare -gA OFB_REG_INTRUSIVE=() # nome -> true|false
declare -gA OFB_REG_ARGSHELP=()  # nome -> ajuda de argumentos
declare -ga OFB_REG_ORDER=()     # ordem de insercao (nomes)

# registry_add — registra um modulo. Chamado pelo loader.
# Args: nome desc categoria autor arquivo requires intrusive argshelp
registry_add() {
    local name="$1" desc="$2" cat="$3" author="$4" file="$5"
    local requires="${6:-}" intrusive="${7:-false}" argshelp="${8:-}"
    if [[ -n "${OFB_REG_FILE[$name]:-}" ]]; then
        warn "Modulo duplicado ignorado: $name (ja veio de ${OFB_REG_FILE[$name]})"
        return 1
    fi
    OFB_REG_DESC["$name"]="$desc"
    OFB_REG_CAT["$name"]="$cat"
    OFB_REG_AUTHOR["$name"]="$author"
    OFB_REG_FILE["$name"]="$file"
    OFB_REG_REQUIRES["$name"]="$requires"
    OFB_REG_INTRUSIVE["$name"]="$intrusive"
    OFB_REG_ARGSHELP["$name"]="$argshelp"
    OFB_REG_ORDER+=("$name")
    return 0
}

# registry_has <nome> — 0 se o modulo existe.
registry_has() {
    [[ -n "${OFB_REG_FILE[${1:-}]:-}" ]]
}

# registry_desc <nome> — imprime a descricao.
registry_desc() {
    printf '%s' "${OFB_REG_DESC[${1:-}]:-}"
}

# registry_file <nome> — imprime o caminho do arquivo.
registry_file() {
    printf '%s' "${OFB_REG_FILE[${1:-}]:-}"
}

# registry_names — imprime todos os nomes, em ordem de insercao, ordenados.
registry_names() {
    [[ ${#OFB_REG_ORDER[@]} -eq 0 ]] && return 0
    printf '%s\n' "${OFB_REG_ORDER[@]}" | sort
}

# registry_list [categoria] — lista formatada (nome + descricao), filtrando
# por categoria se informada.
registry_list() {
    local filter="${1:-}"
    local name
    while IFS= read -r name; do
        [[ -z "$name" ]] && continue
        if [[ -n "$filter" && "${OFB_REG_CAT[$name]}" != "$filter" ]]; then
            continue
        fi
        local marker=''
        [[ "${OFB_REG_INTRUSIVE[$name]}" == "true" ]] && marker=' [intrusivo]'
        printf '  %-22s %s%s\n' "$name" "${OFB_REG_DESC[$name]}" "$marker"
    done < <(registry_names)
}

# registry_search <termo> — lista modulos cujo nome ou descricao contem o termo.
registry_search() {
    local term="${1:-}"
    [[ -z "$term" ]] && { registry_list; return 0; }
    local lterm name hay
    lterm="$(printf '%s' "$term" | tr '[:upper:]' '[:lower:]')"
    while IFS= read -r name; do
        [[ -z "$name" ]] && continue
        hay="$(printf '%s %s' "$name" "${OFB_REG_DESC[$name]}" | tr '[:upper:]' '[:lower:]')"
        if [[ "$hay" == *"$lterm"* ]]; then
            printf '  %-22s %s\n' "$name" "${OFB_REG_DESC[$name]}"
        fi
    done < <(registry_names)
}

# registry_count — quantidade de modulos carregados.
registry_count() {
    printf '%d' "${#OFB_REG_ORDER[@]}"
}
