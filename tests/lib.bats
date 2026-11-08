#!/usr/bin/env bats
# tests/lib.bats — testes das libs parse, net e fs.

setup() {
    load "test_helper"
    load_ofensivabash
}

@test "parse_is_ipv4 aceita IP valido e rejeita invalido" {
    parse_is_ipv4 "192.168.0.1"
    run parse_is_ipv4 "999.1.1.1"
    [ "$status" -ne 0 ]
    run parse_is_ipv4 "nao-e-ip"
    [ "$status" -ne 0 ]
}

@test "parse_is_domain valida FQDN" {
    parse_is_domain "exemplo.com"
    parse_is_domain "api.sub.exemplo.com.br"
    run parse_is_domain "semponto"
    [ "$status" -ne 0 ]
}

@test "parse_is_cidr valida blocos" {
    parse_is_cidr "10.0.0.0/8"
    run parse_is_cidr "10.0.0.0/40"
    [ "$status" -ne 0 ]
}

@test "parse_is_valid_target aceita dominio, ip e cidr" {
    parse_is_valid_target "exemplo.com"
    parse_is_valid_target "1.2.3.4"
    parse_is_valid_target "1.2.3.0/24"
    run parse_is_valid_target "'; rm -rf /"
    [ "$status" -ne 0 ]
}

@test "parse_extract_ips extrai de texto" {
    run bash -c 'printf "host 10.0.0.1 e 8.8.8.8\n" | source '"$OFB_HOME"'/lib/parse.sh; printf "host 10.0.0.1 e 8.8.8.8\n" | parse_extract_ips'
    [[ "$output" == *"10.0.0.1"* ]]
    [[ "$output" == *"8.8.8.8"* ]]
}

@test "net_is_private_ip reconhece RFC1918" {
    net_is_private_ip "10.1.2.3"
    net_is_private_ip "192.168.1.1"
    net_is_private_ip "172.16.0.1"
    run net_is_private_ip "8.8.8.8"
    [ "$status" -ne 0 ]
}

@test "net_ip_in_cidr calcula pertencimento" {
    net_ip_in_cidr "192.168.1.50" "192.168.1.0/24"
    run net_ip_in_cidr "192.168.2.50" "192.168.1.0/24"
    [ "$status" -ne 0 ]
}

@test "ws_init cria estrutura e ws_dir retorna caminho" {
    export WORKSPACE="${BATS_TEST_TMPDIR}/ws-teste"
    ws_init "$WORKSPACE"
    [ -d "$WORKSPACE/recon" ]
    [ -d "$WORKSPACE/loot" ]
    run ws_dir recon
    [ "$output" = "$WORKSPACE/recon" ]
}

@test "ws_write escreve atomico e ws_dedup remove duplicatas" {
    export WORKSPACE="${BATS_TEST_TMPDIR}/ws-teste2"
    ws_init "$WORKSPACE"
    f="$WORKSPACE/recon/x.txt"
    printf 'b\na\na\nb\n' | ws_write "$f"
    ws_dedup "$f"
    run cat "$f"
    [ "${lines[0]}" = "a" ]
    [ "${lines[1]}" = "b" ]
    [ "${#lines[@]}" -eq 2 ]
}
