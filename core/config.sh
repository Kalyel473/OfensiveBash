#!/usr/bin/env bash

declare -gA OFB_CFG=()

# Defaults embutidos (secao 10 da spec).
_config_defaults() {
    OFB_CFG[OFB_THREADS]="20"
    OFB_CFG[OFB_HTTP_TIMEOUT]="10"
    OFB_CFG[OFB_HTTP_RETRIES]="2"
    OFB_CFG[OFB_USER_AGENT]="OfensivaBash/${OFB_VERSION} (+https://github.com/Kalyel473)"
    OFB_CFG[OFB_LOCALE]="pt_BR"
    OFB_CFG[OFB_WORDLIST_SUBS]=""
    OFB_CFG[OFB_WORDLIST_DIRS]=""
    OFB_CFG[SHODAN_API_KEY]=""
    OFB_CFG[DISCORD_WEBHOOK_URL]=""
}

# Chaves consideradas sensiveis: nunca sao ecoadas por cfg_dump nem logadas.
_config_is_secret() {
    case "$1" in
        *API_KEY|*TOKEN|*SECRET|*WEBHOOK*|*PASSWORD) return 0 ;;
        *) return 1 ;;
    esac
}

# Le um arquivo conf no formato chave=valor (ignora comentarios e linhas vazias).
_config_read_file() {
    local file="$1"
    [[ -r "$file" ]] || return 0
    local line key val
    while IFS= read -r line || [[ -n "$line" ]]; do
        # remove comentario de linha inteira e espacos nas pontas
        line="${line#"${line%%[![:space:]]*}"}"   # ltrim
        [[ -z "$line" || "${line:0:1}" == "#" ]] && continue
        [[ "$line" != *"="* ]] && continue
        key="${line%%=*}"
        val="${line#*=}"
        # trim da chave
        key="${key//[[:space:]]/}"
        # remove aspas opcionais do valor
        val="${val#\"}"; val="${val%\"}"
        val="${val#\'}"; val="${val%\'}"
        [[ -n "$key" ]] && OFB_CFG["$key"]="$val"
    done < "$file"
}

# config_load — chamada no bootstrap. Monta o mapa seguindo a precedencia.
config_load() {
    _config_defaults

    # arquivo do repo (menor precedencia dentre os arquivos)
    _config_read_file "$OFB_HOME/ofensivabash.conf"
    # arquivo do usuario (vence o do repo)
    _config_read_file "$OFB_CONFIG_DIR/ofensivabash.conf"

    # variaveis de ambiente OFB_* e chaves sensiveis conhecidas vencem arquivos
    local k
    for k in "${!OFB_CFG[@]}"; do
        if [[ -n "${!k:-}" ]]; then
            OFB_CFG["$k"]="${!k}"
        fi
    done
}

# cfg_get <chave> [default] — retorna o valor da config ou o default.
cfg_get() {
    local key="$1" def="${2:-}"
    if [[ -n "${OFB_CFG[$key]:-}" ]]; then
        printf '%s' "${OFB_CFG[$key]}"
    else
        printf '%s' "$def"
    fi
}

# cfg_dump — imprime a config para debug, mascarando segredos.
cfg_dump() {
    local k v
    for k in $(printf '%s\n' "${!OFB_CFG[@]}" | sort); do
        v="${OFB_CFG[$k]}"
        if _config_is_secret "$k" && [[ -n "$v" ]]; then
            v="***(definido)***"
        fi
        printf '%s=%s\n' "$k" "$v"
    done
}
