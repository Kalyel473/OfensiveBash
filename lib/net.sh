#!/usr/bin/env bash
#
# lib/net.sh — rede: resolucao, checagem de porta via /dev/tcp, CIDR, IP privado.
#
# Nada aqui depende de nmap. Usamos o /dev/tcp do proprio Bash para checar
# portas, com fallback para dig/host/nslookup na resolucao.

# net_is_localhost <host>
net_is_localhost() {
    local h="${1:-}"
    case "$h" in
        localhost|127.0.0.1|::1|0.0.0.0) return 0 ;;
        *) return 1 ;;
    esac
}

# net_is_private_ip <ipv4> — RFC1918 + loopback + link-local.
net_is_private_ip() {
    local ip="${1:-}"
    parse_is_ipv4 "$ip" || return 1
    case "$ip" in
        10.*|127.*|192.168.*|169.254.*) return 0 ;;
        172.1[6-9].*|172.2[0-9].*|172.3[0-1].*) return 0 ;;
        *) return 1 ;;
    esac
}

# _net_ip_to_int <ipv4> — converte para inteiro (imprime).
_net_ip_to_int() {
    local ip="${1:-}" a b c d
    IFS=. read -r a b c d <<< "$ip"
    printf '%u' "$(( (a << 24) + (b << 16) + (c << 8) + d ))"
}

# net_ip_in_cidr <ipv4> <cidr> — 0 se o IP pertence ao bloco.
net_ip_in_cidr() {
    local ip="${1:-}" cidr="${2:-}"
    parse_is_ipv4 "$ip" || return 1
    parse_is_cidr "$cidr" || return 1
    local net="${cidr%/*}" bits="${cidr#*/}"
    local ip_i net_i mask
    ip_i="$(_net_ip_to_int "$ip")"
    net_i="$(_net_ip_to_int "$net")"
    if (( bits == 0 )); then
        return 0
    fi
    mask=$(( 0xFFFFFFFF << (32 - bits) & 0xFFFFFFFF ))
    (( (ip_i & mask) == (net_i & mask) ))
}

# net_resolve <host> — imprime IPs resolvidos (um por linha). Usa dig, depois
# host, depois nslookup, depois getent. Vazio se nada funcionar.
net_resolve() {
    local host="${1:-}"
    [[ -z "$host" ]] && return 1
    parse_is_ipv4 "$host" && { printf '%s\n' "$host"; return 0; }

    if command -v dig >/dev/null 2>&1; then
        dig +short A "$host" 2>/dev/null | grep -E '^([0-9]{1,3}\.){3}[0-9]{1,3}$' && return 0
    fi
    if command -v host >/dev/null 2>&1; then
        host "$host" 2>/dev/null | awk '/has address/ {print $NF}' | grep -E '^([0-9]{1,3}\.){3}[0-9]{1,3}$' && return 0
    fi
    if command -v nslookup >/dev/null 2>&1; then
        nslookup "$host" 2>/dev/null | awk '/^Address: /{print $2}' | grep -E '^([0-9]{1,3}\.){3}[0-9]{1,3}$' && return 0
    fi
    if command -v getent >/dev/null 2>&1; then
        getent hosts "$host" 2>/dev/null | awk '{print $1}' | grep -E '^([0-9]{1,3}\.){3}[0-9]{1,3}$' && return 0
    fi
    return 1
}

# net_tcp_check <host> <porta> [timeout] — 0 se a porta TCP esta aberta.
# Usa /dev/tcp (nativo do Bash). Respeita timeout via coreutils 'timeout' se
# disponivel; senao faz o melhor esforco.
net_tcp_check() {
    local host="${1:-}" port="${2:-}" tmo="${3:-2}"
    [[ -z "$host" || -z "$port" ]] && return 2
    if command -v timeout >/dev/null 2>&1; then
        timeout "$tmo" bash -c "exec 3<>/dev/tcp/${host}/${port}" 2>/dev/null
    else
        # sem 'timeout': tentativa direta (pode bloquear conforme o SO)
        ( exec 3<>"/dev/tcp/${host}/${port}" ) 2>/dev/null
    fi
}

# net_tcp_banner <host> <porta> [timeout] — tenta ler um banner inicial.
net_tcp_banner() {
    local host="${1:-}" port="${2:-}" tmo="${3:-3}"
    [[ -z "$host" || -z "$port" ]] && return 2
    if command -v timeout >/dev/null 2>&1; then
        timeout "$tmo" bash -c '
            exec 3<>/dev/tcp/'"$host"'/'"$port"' || exit 1
            # envia uma linha vazia para servicos que esperam input
            printf "\r\n" >&3
            head -c 1024 <&3
        ' 2>/dev/null
    fi
}
