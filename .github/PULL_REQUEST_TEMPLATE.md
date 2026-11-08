# Pull Request

## Descrição

<!-- O que este PR faz? Se adiciona um módulo, qual e por quê. -->

## Tipo

- [ ] Novo módulo
- [ ] Correção de bug
- [ ] Melhoria no core/lib
- [ ] Documentação
- [ ] Outro:

## Checklist ético e de qualidade (obrigatório)

- [ ] O módulo **não é "arma pronta"** — sem payload malicioso, malware ou persistência.
- [ ] Se intrusivo, declara `MODULE_INTRUSIVE=true` e usa `require_scope` (respeita `--safe`).
- [ ] Grava saída em `$(ws_dir <categoria>)`, nunca em caminho fixo.
- [ ] **Não** chama `exit` (usa `return`).
- [ ] Dependências opcionais checadas com `require_tool` + fallback/aviso.
- [ ] Tem **teste bats com fixture** (não bate em alvo real).
- [ ] `make lint` passa (ShellCheck sem warning).
- [ ] `make fmt` aplicado (shfmt).
- [ ] `make test` passa.

## Contrato de módulo (se aplicável)

- `MODULE_NAME`:
- `MODULE_CATEGORY`:
- `MODULE_REQUIRES`:
- `MODULE_INTRUSIVE`:

## Observações

<!-- Qualquer contexto adicional para quem revisa. -->
