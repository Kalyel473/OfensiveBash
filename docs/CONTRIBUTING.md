# Contribuindo com o OfensivaBash

Obrigado por querer contribuir! O maior diferencial do projeto é **plugar
módulos sem medo** — sem tocar no core. Este guia mostra como.

---

## Princípio: core fino, módulos gordos

O core só **orquestra** (carrega, roteia, guarda estado, reporta). Toda lógica
ofensiva vive em **módulos isolados**. Você quase nunca precisa mexer em `core/`.

---

## Passo a passo para um novo módulo

1. **Copie o molde:**
   ```bash
   cp modules/_template.sh modules/<categoria>/<nome>.sh
   ```
   Categorias: `recon`, `scan`, `enum`, `vuln`, `ctf`, `post`.

2. **Preencha os metadados** (`MODULE_NAME`, `MODULE_DESC`, `MODULE_CATEGORY`,
   `MODULE_AUTHOR`, e opcionalmente `MODULE_REQUIRES`, `MODULE_INTRUSIVE`,
   `MODULE_ARGS_HELP`). Veja [`MODULE_SPEC.md`](MODULE_SPEC.md).

3. **Escreva `module_run`** usando os helpers do core/lib. Nada de `exit`;
   grave saída em `$(ws_dir <categoria>)`.

4. **Escreva um teste bats** com **fixture** (entrada mockada, **sem bater em
   alvo real**) em `tests/`. Veja `tests/modules.bats` como exemplo: mocke
   `http_get`/`net_*` e verifique o arquivo de saída.

5. **Rode localmente:**
   ```bash
   make lint     # ShellCheck sem warning
   make fmt      # shfmt -i 4 -ci
   make test     # bats
   ```

6. **Abra o PR.** O CI valida contrato, lint e testes automaticamente.

---

## Padrão de código (Bash)

- Shebang `#!/usr/bin/env bash` em todo arquivo executável.
- `set -euo pipefail` é responsabilidade do core — **não** o coloque em módulos.
- **Sempre cite variáveis:** `"$var"`, `"${arr[@]}"`.
- `local` em toda variável de função.
- Cheque comandos com `command -v` / `require_tool`, nunca assuma PATH.
- Monte argumentos de comando com **arrays** (`cmd=(curl -s …); "${cmd[@]}"`),
  nunca por concatenação de string.
- **Zero `eval`** em entrada do usuário.
- **Timeouts** em toda requisição de rede.
- Comentários em **PT-BR**, funções pequenas e com uma responsabilidade.

---

## Checklist ético (obrigatório no PR)

Seu PR **precisa** marcar que o módulo:

- [ ] **não é "arma pronta"** — sem payload malicioso, malware ou persistência;
- [ ] **respeita `--safe`** — se intrusivo, declara `MODULE_INTRUSIVE=true` e usa
      `require_scope`;
- [ ] tem **teste com fixture** (não bate em alvo real no CI);
- [ ] passa no **ShellCheck** e **shfmt**.

Módulos que não cumprem o checklist não são aceitos. Isso mantém o projeto ético
e de qualidade à medida que cresce.

---

## Rodando os testes

```bash
# instale o bats-core: https://github.com/bats-core/bats-core
bats tests/
```

Os testes isolam workspaces e config em diretórios temporários — não tocam seu
`$HOME` nem a rede.

---

## Dúvidas

Abra uma issue. Para reportar **vulnerabilidade no próprio OfensivaBash**, veja
[`SECURITY.md`](../SECURITY.md).
