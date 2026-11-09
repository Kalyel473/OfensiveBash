#!/usr/bin/env bats

setup() {
    load "test_helper"
    load_ofensivabash
}

@test "loader registra os modulos do MVP" {
    loader_load_all
    registry_has "recon/ctlogs"
    registry_has "recon/dns"
    registry_has "scan/ports"
    registry_has "scan/tls"
    registry_has "enum/http"
    registry_has "enum/headers"
    registry_has "post/report"
}

@test "loader ignora o _template.sh" {
    loader_load_all
    run registry_has "categoria/nome"
    [ "$status" -ne 0 ]
}

@test "registry_count retorna numero positivo" {
    loader_load_all
    run registry_count
    [ "$output" -ge 7 ]
}

@test "sanitize_target_name bloqueia path traversal" {
    run sanitize_target_name "../../etc/passwd"
    [ "$status" -eq 0 ]
    [[ "$output" != *".."* ]]
    [[ "$output" != *"/"* ]]
}

@test "sanitize_target_name preserva dominio valido" {
    run sanitize_target_name "exemplo.com"
    [ "$output" = "exemplo.com" ]
}

@test "in_scope reconhece o alvo e subdominios" {
    export SCOPE="exemplo.com"
    in_scope "exemplo.com"
    in_scope "api.exemplo.com"
    run in_scope "outrodominio.com"
    [ "$status" -ne 0 ]
}

@test "in_scope reconhece IP dentro de CIDR" {
    export SCOPE="10.10.0.0/16"
    in_scope "10.10.5.7"
    run in_scope "10.11.5.7"
    [ "$status" -ne 0 ]
}

@test "require_scope bloqueia fora de escopo no modo safe" {
    export MODE="safe"
    export SCOPE="exemplo.com"
    export TARGET="exemplo.com"
    run require_scope "malicioso.com"
    [ "$status" -eq "$OFB_EXIT_SCOPE" ]
}

@test "require_scope permite localhost sempre" {
    export MODE="safe"
    export SCOPE=""
    require_scope "127.0.0.1"
    require_scope "localhost"
}

@test "require_scope em modo active libera qualquer host" {
    export MODE="active"
    export SCOPE=""
    require_scope "qualquercoisa.com"
}

@test "require_tool detecta ferramenta inexistente" {
    run require_tool "ferramenta_que_nao_existe_xyz123"
    [ "$status" -eq "$OFB_EXIT_DEP" ]
}

@test "require_tool encontra o bash" {
    require_tool "bash"
}
