#!/usr/bin/env bash
#
# lib/fs.sh — helpers de filesystem e workspace.
#
# O workspace e a area de trabalho por alvo. Modulos NUNCA escrevem em caminho
# fixo; sempre pedem o diretorio via ws_dir <categoria>.

# ws_init <dir> — cria a estrutura padrao de um workspace.
ws_init() {
    local ws="${1:-$WORKSPACE}"
    [[ -z "$ws" ]] && { err "ws_init: workspace vazio"; return 1; }
    local sub
    for sub in recon scan enum vuln ctf loot; do
        mkdir -p "$ws/$sub" 2>/dev/null || {
            err "Nao consegui criar $ws/$sub"; return 1; }
    done
    # garante o arquivo de log de execucoes SEM truncar um log existente
    # (ws_init e chamado toda vez que o alvo e (re)aberto).
    [[ -f "$ws/log.jsonl" ]] || : > "$ws/log.jsonl" 2>/dev/null || true
    return 0
}

# ws_dir <categoria> — retorna (e cria) o diretorio de saida da categoria no
# workspace atual. Ex: ws_dir recon => <workspace>/recon
ws_dir() {
    local cat="${1:-misc}"
    [[ -z "$WORKSPACE" ]] && { err "Nenhum workspace ativo (defina um alvo)"; return 1; }
    # sanitiza a categoria (sem traversal)
    cat="${cat//[^A-Za-z0-9._-]/_}"
    local d="$WORKSPACE/$cat"
    mkdir -p "$d" 2>/dev/null || { err "Nao consegui criar $d"; return 1; }
    printf '%s' "$d"
}

# ws_write <arquivo> — le stdin e escreve de forma atomica (tmp + mv).
# Uso: printf '%s' "$dados" | ws_write "$(ws_dir recon)/saida.txt"
ws_write() {
    local dest="${1:-}"
    [[ -z "$dest" ]] && { err "ws_write: destino vazio"; return 1; }
    local tmp="${dest}.tmp.$$"
    if cat > "$tmp" 2>/dev/null; then
        mv -f "$tmp" "$dest" 2>/dev/null || { err "ws_write: falha ao mover para $dest"; rm -f "$tmp"; return 1; }
        return 0
    fi
    rm -f "$tmp" 2>/dev/null || true
    err "ws_write: falha ao escrever $dest"
    return 1
}

# ws_dedup <arquivo> — ordena e remove duplicatas in-place (atomico).
ws_dedup() {
    local f="${1:-}"
    [[ -r "$f" ]] || return 0
    local tmp="${f}.tmp.$$"
    if sort -u "$f" > "$tmp" 2>/dev/null; then
        mv -f "$tmp" "$f" 2>/dev/null || rm -f "$tmp"
    else
        rm -f "$tmp" 2>/dev/null || true
    fi
    return 0
}

# fs_count_lines <arquivo> — conta linhas nao-vazias (0 se o arquivo nao existe).
fs_count_lines() {
    local f="${1:-}"
    [[ -r "$f" ]] || { printf '0'; return 0; }
    grep -cve '^[[:space:]]*$' "$f" 2>/dev/null || printf '0'
}
