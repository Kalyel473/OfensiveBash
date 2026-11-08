# Contrato de Módulo — OfensivaBash (MODULE_SPEC)

**Versão do contrato: 1.0** (v0.x; congelado em v1.0).

Todo módulo é **um único arquivo `.sh`** em `modules/<categoria>/<nome>.sh`. Ele
declara metadados e expõe funções de contrato. O **loader rejeita** qualquer
módulo que não cumpra este contrato — e o faz num subshell isolado, então um
módulo malformado é ignorado com aviso, **nunca derruba o framework**.

---

## 1. Variáveis obrigatórias

| Variável           | Formato / valores                         | Exemplo                      |
|--------------------|-------------------------------------------|------------------------------|
| `MODULE_NAME`      | `categoria/nome` (único)                   | `recon/ctlogs`               |
| `MODULE_DESC`      | uma linha, PT-BR                           | `Enumera subdomínios...`     |
| `MODULE_CATEGORY`  | `recon` \| `scan` \| `enum` \| `vuln` \| `ctf` \| `post` | `recon`         |
| `MODULE_AUTHOR`    | crédito do contribuidor                    | `CyberGuard`                 |

## 2. Variáveis opcionais

| Variável            | Significado                                                        |
|---------------------|-------------------------------------------------------------------|
| `MODULE_REQUIRES`   | bins necessários, separados por espaço (ex: `"curl jq"`). O runner checa **antes** de executar. |
| `MODULE_INTRUSIVE`  | `true` se toca o alvo ativamente. Bloqueado em `--safe` fora do escopo. Default `false`. |
| `MODULE_ARGS_HELP`  | descrição dos argumentos do módulo.                               |

## 3. Funções de contrato

### `module_run "$@"` — **obrigatória**

Recebe os argumentos, faz o trabalho, grava saída no workspace via helpers, e
**retorna 0 em sucesso** (código ≠ 0 em falha).

### `module_help` — opcional

Imprime uso detalhado. Se ausente, o core gera uma ajuda a partir dos metadados.

---

## 4. Regras que `module_run` DEVE seguir

1. **Nunca chamar `exit`.** Use `return`. Chamar `exit` derrubaria o framework.
2. **Guardas antes de tocar o alvo:** `require_target` e, para módulos
   intrusivos, `require_scope "$host"`.
3. **Gravar em `$(ws_dir <categoria>)`**, nunca em caminho fixo. Ex:
   `out="$(ws_dir recon)/subdomains.txt"`.
4. **Saída humana** via `info`/`ok`/`warn`/`err`; **dados estruturados** em
   arquivo no workspace.
5. **Dependências opcionais** sempre checadas com `require_tool <bin>` e com
   fallback ou aviso — nunca assuma que uma ferramenta opcional existe.
6. **Sem exploit-arma.** Foco em descoberta, enumeração, checagem de config, CTF
   e relatório. Nada de malware, persistência maliciosa ou payload pronto.

---

## 5. Helpers do core/lib disponíveis

### Saída (`core/ui.sh`)
`info`, `ok`, `warn`, `err`, `debug`, `section`.

### Guardas (`core/require.sh`)
`require_tool <bin>`, `require_target [valor]`, `require_scope <host>`.

### Sessão (`core/session.sh`)
Variáveis `TARGET`, `SCOPE`, `MODE`, `WORKSPACE`; `in_scope <host>`.

### Workspace (`lib/fs.sh`)
`ws_dir <categoria>`, `ws_write <arquivo>` (lê stdin, escrita atômica),
`ws_dedup <arquivo>`, `fs_count_lines <arquivo>`.

### HTTP (`lib/http.sh`)
`http_get <url>`, `http_head <url>`, `http_status <url>`,
`http_headers_only <url>`, `http_get_with_origin <url> <origin>`.

### Rede (`lib/net.sh`)
`net_resolve <host>`, `net_tcp_check <host> <porta> [timeout]`,
`net_is_private_ip`, `net_ip_in_cidr`, `net_is_localhost`.

### Parsing (`lib/parse.sh`)
`parse_is_ipv4`, `parse_is_domain`, `parse_is_cidr`, `parse_is_valid_target`,
`parse_extract_ips|urls|emails|domains`, `parse_grep_secrets`.

### JSON (`lib/json.sh`)
`json_has_jq`, `json_field <campo>`, `json_array_field <campo>`,
`json_escape <str>` — todos com fallback sem `jq`.

---

## 6. Exemplo mínimo

```bash
#!/usr/bin/env bash
MODULE_NAME="recon/exemplo"
MODULE_DESC="Faz algo passivo e grava no workspace"
MODULE_CATEGORY="recon"
MODULE_AUTHOR="SeuNome"
MODULE_REQUIRES="curl"
MODULE_INTRUSIVE="false"
MODULE_ARGS_HELP="<dominio>  (default: TARGET da sessao)"

module_run() {
    local domain="${1:-$TARGET}"
    require_target "$domain" || return 1
    local out; out="$(ws_dir recon)/exemplo.txt" || return 1
    info "Processando $domain..."
    http_get "https://api.exemplo/$domain" | ws_write "$out"
    ok "Salvo em $out"
    return 0
}
```

Veja o molde comentado completo em [`modules/_template.sh`](../modules/_template.sh).

---

## 7. Códigos de saída (padrão do framework)

| Código | Significado                        |
|--------|------------------------------------|
| 0      | sucesso                            |
| 1      | erro de execução                   |
| 2      | erro de uso (args/flags)           |
| 3      | dependência obrigatória ausente    |
| 4      | ação bloqueada: fora de escopo (safe) |

Um módulo retorna esses códigos; o runner os registra em `log.jsonl` e os
propaga, sem matar o framework.
