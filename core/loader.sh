#!/usr/bin/env bash
#
# core/loader.sh — descobre e carrega os modulos.
#
# Varre modules/**/*.sh. Para cada arquivo:
#   1. valida o contrato num SUBSHELL isolado (nao polui o ambiente principal);
#   2. se valido, da source() de verdade e registra no registry;
#   3. se invalido/malformado, avisa com warn e SEGUE (nunca derruba o load).
#
# O contrato minimo: variaveis MODULE_NAME, MODULE_DESC, MODULE_CATEGORY,
# MODULE_AUTHOR e a funcao module_run.

# _loader_validate <arquivo> — roda num subshell; imprime os metadados numa
# linha "chave=valor" separada por TAB se o contrato for cumprido; retorna !=0
# se nao. Assim o processo principal nao e contaminado por erros do modulo.
_loader_validate() {
    local file="$1"
    (
        set +euo pipefail 2>/dev/null || true
        # Zera variaveis de contrato para nao herdar de um modulo anterior.
        unset MODULE_NAME MODULE_DESC MODULE_CATEGORY MODULE_AUTHOR \
              MODULE_REQUIRES MODULE_INTRUSIVE MODULE_ARGS_HELP
        # shellcheck source=/dev/null
        if ! source "$file" 2>/dev/null; then
            exit 10
        fi
        # variaveis obrigatorias
        [[ -n "${MODULE_NAME:-}" ]]     || exit 11
        [[ -n "${MODULE_DESC:-}" ]]     || exit 12
        [[ -n "${MODULE_CATEGORY:-}" ]] || exit 13
        [[ -n "${MODULE_AUTHOR:-}" ]]   || exit 14
        # funcao obrigatoria
        declare -F module_run >/dev/null || exit 15
        # categoria valida
        case "$MODULE_CATEGORY" in
            recon|scan|enum|vuln|ctf|post) ;;
            *) exit 16 ;;
        esac
        # emite os metadados numa unica linha, campos separados pelo unit
        # separator (\037). Nao e whitespace, entao campos vazios (ex:
        # MODULE_REQUIRES ausente) sao preservados pelo read, sem colapsar.
        printf '%s\037%s\037%s\037%s\037%s\037%s\037%s\n' \
            "$MODULE_NAME" "$MODULE_DESC" "$MODULE_CATEGORY" "$MODULE_AUTHOR" \
            "${MODULE_REQUIRES:-}" "${MODULE_INTRUSIVE:-false}" "${MODULE_ARGS_HELP:-}"
    )
}

# loader_load_all — ponto de entrada chamado pelo bootstrap.
loader_load_all() {
    local count=0 file
    [[ -d "$OFB_MODULES_DIR" ]] || { warn "Diretorio de modulos ausente: $OFB_MODULES_DIR"; return 0; }

    while IFS= read -r file; do
        [[ -r "$file" ]] || continue
        local base; base="$(basename "$file")"
        # ignora o template e arquivos iniciados por _
        [[ "$base" == _* ]] && continue

        local meta rc
        meta="$(_loader_validate "$file")" && rc=0 || rc=$?
        if [[ "$rc" -ne 0 ]]; then
            warn "Modulo ignorado (contrato invalido, codigo $rc): $file"
            continue
        fi

        # separa os metadados pelo unit separator (\037)
        local name desc cat author requires intrusive argshelp
        IFS=$'\037' read -r name desc cat author requires intrusive argshelp <<< "$meta"

        # agora carrega de verdade no ambiente principal
        # shellcheck source=/dev/null
        if ! source "$file"; then
            warn "Falha ao carregar modulo (source): $file"
            continue
        fi
        registry_add "$name" "$desc" "$cat" "$author" "$file" \
            "$requires" "$intrusive" "$argshelp" && count=$((count + 1))
    done < <(find "$OFB_MODULES_DIR" -type f -name '*.sh' 2>/dev/null | sort)

    debug "$count modulo(s) carregado(s)."
    return 0
}
