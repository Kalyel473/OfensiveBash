#!/usr/bin/env bash

session_init_defaults() {
    export TARGET="${TARGET:-}"
    export SCOPE="${SCOPE:-}"
    export MODE="${MODE:-safe}"
    export WORKSPACE="${WORKSPACE:-}"
}

# --- Sanitizacao de alvo (protege contra path traversal) -------------------
# Transforma um alvo arbitrario num nome de diretorio seguro.
sanitize_target_name() {
    local t="$1"
    # mantem apenas chars seguros; troca o resto por _
    t="${t//[^A-Za-z0-9._-]/_}"
    # elimina qualquer sequencia .. que reste
    while [[ "$t" == *..* ]]; do t="${t//../_}"; done
    # remove pontos/hifens/underscores das pontas
    t="${t#[._-]}"; t="${t%[._-]}"
    [[ -z "$t" ]] && t="alvo"
    printf '%s' "$t"
}

# set_target <alvo> — valida, define TARGET e cria/abre o workspace.
set_target() {
    local target="${1:-}"
    if [[ -z "$target" ]]; then
        err "set_target: alvo vazio"
        return "$OFB_EXIT_USAGE"
    fi
    if ! parse_is_valid_target "$target"; then
        err "Alvo invalido: '$target' (esperado dominio, IP ou CIDR)"
        return "$OFB_EXIT_USAGE"
    fi

    export TARGET="$target"
    local safe
    safe="$(sanitize_target_name "$target")"
    export WORKSPACE="$OFB_WORKSPACES_DIR/$safe"

    ws_init "$WORKSPACE"
    # Por conveniencia, o proprio alvo entra no escopo automaticamente.
    add_scope "$target"
    session_save
    ok "Alvo definido: $TARGET  (workspace: $WORKSPACE)"
    return 0
}

# add_scope <dom/cidr> — adiciona um item ao escopo permitido.
add_scope() {
    local item="${1:-}"
    [[ -z "$item" ]] && { err "add_scope: item vazio"; return "$OFB_EXIT_USAGE"; }
    # evita duplicatas
    # SCOPE e separado por espaco, mas o IFS global (bootstrap) nao inclui o
    # espaco: separa explicitamente.
    local existing
    local -a items=()
    IFS=' ' read -r -a items <<< "$SCOPE"
    for existing in "${items[@]}"; do
        [[ "$existing" == "$item" ]] && return 0
    done
    if [[ -z "$SCOPE" ]]; then
        export SCOPE="$item"
    else
        export SCOPE="$SCOPE $item"
    fi
    return 0
}

# set_mode <safe|active|ctf>
set_mode() {
    local m="${1:-}"
    case "$m" in
        safe|active|ctf)
            export MODE="$m"
            session_save 2>/dev/null || true
            ok "Modo: $MODE"
            ;;
        *)
            err "Modo invalido: '$m' (use safe, active ou ctf)"
            return "$OFB_EXIT_USAGE"
            ;;
    esac
}

# in_scope <host> — retorna 0 se o host esta no escopo, 1 caso contrario.
# Casamento: igualdade, sufixo de dominio (sub.alvo.com casa alvo.com), ou
# IP dentro de um CIDR listado.
in_scope() {
    local host="${1:-}"
    [[ -z "$host" ]] && return 1
    local item
    local -a items=()
    IFS=' ' read -r -a items <<< "$SCOPE"
    for item in "${items[@]}"; do
        # casamento exato
        [[ "$host" == "$item" ]] && return 0
        # sufixo de dominio
        [[ "$host" == *".$item" ]] && return 0
        # CIDR (item tem barra e host parece IP)
        if [[ "$item" == */* ]] && parse_is_ipv4 "$host"; then
            if net_ip_in_cidr "$host" "$item"; then
                return 0
            fi
        fi
    done
    return 1
}

# session_save — persiste o estado no workspace atual.
session_save() {
    [[ -z "$WORKSPACE" ]] && return 0
    local f="$WORKSPACE/session.env"
    {
        printf 'TARGET=%q\n' "$TARGET"
        printf 'SCOPE=%q\n'  "$SCOPE"
        printf 'MODE=%q\n'   "$MODE"
        printf 'CRIADO_EM=%q\n' "$(date -u +%Y-%m-%dT%H:%M:%SZ)"
    } > "$f.tmp" 2>/dev/null && mv -f "$f.tmp" "$f" 2>/dev/null || {
        warn "Nao consegui salvar a sessao em $f"
        return 1
    }
    return 0
}

# session_load [alvo] — recarrega o estado de um workspace existente.
session_load() {
    local target="${1:-$TARGET}"
    [[ -z "$target" ]] && { err "session_load: nenhum alvo"; return "$OFB_EXIT_USAGE"; }
    local safe ws
    safe="$(sanitize_target_name "$target")"
    ws="$OFB_WORKSPACES_DIR/$safe"
    local f="$ws/session.env"
    if [[ ! -r "$f" ]]; then
        err "Workspace nao encontrado para '$target'"
        return "$OFB_EXIT_ERROR"
    fi
    # shellcheck source=/dev/null
    source "$f"
    export TARGET SCOPE MODE
    export WORKSPACE="$ws"
    ok "Sessao carregada: $TARGET"
    return 0
}

# session_list — lista os workspaces/alvos existentes.
session_list() {
    [[ -d "$OFB_WORKSPACES_DIR" ]] || { info "Nenhum workspace ainda."; return 0; }
    local d found=0
    for d in "$OFB_WORKSPACES_DIR"/*/; do
        [[ -d "$d" ]] || continue
        found=1
        local name; name="$(basename "$d")"
        printf '  %s\n' "$name"
    done
    [[ "$found" -eq 0 ]] && info "Nenhum workspace ainda."
    return 0
}
