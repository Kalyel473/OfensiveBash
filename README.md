# OfensivaBash 🛡

**Framework de pentest e automação ofensiva escrito majoritariamente em Bash** —
leve, modular e em português. Roda de um VPS pelado ao Termux no celular, sem
runtime pesado. Feito para **pentest autorizado**, **bug bounty com escopo** e
**CTF** (HackTheBox, TryHackMe, labs).

> Projeto da **CyberGuard Academy** / canal **Cybersegurança na Prática**.

---

## ⚠️ Aviso ético e legal (leia antes de usar)

**USO AUTORIZADO SOMENTE.** O OfensivaBash é uma ferramenta de **segurança
defensiva e ofensiva autorizada**, com fins **educacionais e profissionais**.
Use-o **exclusivamente** contra:

- alvos para os quais você tem **permissão explícita e por escrito** (contrato de
  pentest, programa de bug bounty dentro do escopo), ou
- **seus próprios sistemas** e **labs/CTF** (HTB, THM, máquinas locais).

Testar sistemas de terceiros sem autorização é **crime** na maioria das
jurisdições (no Brasil, Lei 12.737/2012 e correlatas). O framework roda em
`--safe` por padrão, que **bloqueia ações intrusivas fora do escopo**. Você é o
único responsável pelo uso que fizer dele. Os autores não se responsabilizam por
uso indevido.

O OfensivaBash **não** contém — e **não aceita** — payloads de malware,
persistência maliciosa ou automação de ataque contra alvos sem autorização. O
foco é **recon, enumeração, checagem de configuração, apoio a CTF e relatório**.

---

## Diferenciais

- **Leveza radical** — Bash puro. `coreutils`, `grep`, `sed`, `awk`, `curl` e
  pronto. Dependências como `jq`, `dig`, `openssl`, `nmap` são **opcionais** e
  detectadas em runtime (o módulo avisa e degrada, nunca quebra o framework).
- **UX em português** — mensagens, ajuda e relatórios em PT-BR.
- **Modo CTF nativo** *(roadmap v0.2)* — contexto de máquina, notas, flags, timer.
- **Relatório automático** — todo resultado vira `report.md` organizado por alvo.
- **Extensível pela comunidade** — adicionar um módulo é criar **UM** arquivo
  `.sh` que segue um contrato. **Zero alteração no core.**

---

## Instalação

### Via instalador (recomendado)

```bash
git clone https://github.com/Kalyel473/ofensivabash.git
cd ofensivabash
./install.sh          # linka em ~/.local/bin, cria ~/.config/ofensivabash/
ofensivabash --version
```

No **Termux**, o instalador usa `$PREFIX/bin` automaticamente.

### Sem instalar

```bash
git clone https://github.com/Kalyel473/ofensivabash.git
cd ofensivabash
./ofensivabash --version
```

Sem root obrigatório. Bash 4+.

---

## Uso rápido

### REPL interativo (estilo Metasploit)

```text
$ ofensivabash
ofensivabash > set target exemplo.com
ofensivabash [exemplo.com] > set scope exemplo.com
ofensivabash [exemplo.com] > modules recon
ofensivabash [exemplo.com] > use recon/ctlogs
ofensivabash (recon/ctlogs) [exemplo.com] > run
ofensivabash (recon/ctlogs) [exemplo.com] > report
```

Comandos: `help`, `set target|scope|mode`, `modules [categoria]`, `search`,
`use`, `info`, `run [args]`, `playbook`, `workspace`, `report`, `sessions`,
`banner`, `exit`.

### CLI (scripts e CI)

```bash
ofensivabash -t exemplo.com -m recon/ctlogs
ofensivabash -t exemplo.com -p recon-basico          # roda um playbook
ofensivabash -t 10.10.10.5 --ctf -m scan/ports -- -p 1-1000
ofensivabash --list-modules
ofensivabash --report -t exemplo.com
```

Modos de segurança: `--safe` (default, bloqueia intrusivo fora do escopo),
`--active` (você assume a autorização), `--ctf` (libera labs/IPs privados).

---

## Módulos (v0.1)

| Módulo          | Categoria | Intrusivo | O que faz                                        |
|-----------------|-----------|-----------|--------------------------------------------------|
| `recon/ctlogs`  | recon     | não       | Subdomínios via Certificate Transparency (crt.sh)|
| `recon/dns`     | recon     | não       | Registros A/AAAA/MX/NS/TXT/CNAME                  |
| `scan/ports`    | scan      | **sim**   | Scanner TCP nativo (`/dev/tcp`), sem nmap        |
| `scan/tls`      | scan      | **sim**   | Certificado e protocolos/cifras TLS (openssl)    |
| `enum/http`     | enum      | **sim**   | Fingerprint HTTP: status, headers, tech, título  |
| `enum/headers`  | enum      | **sim**   | Auditoria de headers de segurança + nota         |
| `post/report`   | post      | não       | Gera o relatório Markdown do alvo                 |

Mais módulos (`recon/asn`, `enum/dirs`, `vuln/cors`, `ctf/*`, …) estão no
[roadmap](#roadmap).

---

## Workspaces

Cada alvo ganha um workspace isolado, criado no primeiro `set target`:

```text
workspaces/<alvo>/
├── session.env      # TARGET, SCOPE, MODE
├── recon/ scan/ enum/ vuln/ loot/
├── log.jsonl        # 1 linha JSON por execução de módulo
└── report.md        # gerado pelo report
```

O nome do alvo é **sanitizado** (sem `/`, espaços ou `..`) — proteção contra path
traversal.

---

## Configuração

Copie `ofensivabash.conf.example` para `~/.config/ofensivabash/ofensivabash.conf`.
Chaves principais: `OFB_THREADS`, `OFB_HTTP_TIMEOUT`, `OFB_USER_AGENT`,
`OFB_LOCALE`, wordlists e API keys opcionais (`SHODAN_API_KEY`,
`DISCORD_WEBHOOK_URL`). **API keys nunca são commitadas nem aparecem em logs.**
Precedência: flag de CLI > variável de ambiente > arquivo de config > default.

---

## Contribuindo

Adicionar um módulo é copiar um arquivo e seguir o contrato — **sem tocar no
core**. Veja [`docs/CONTRIBUTING.md`](docs/CONTRIBUTING.md) e o contrato formal em
[`docs/MODULE_SPEC.md`](docs/MODULE_SPEC.md).

```bash
cp modules/_template.sh modules/recon/meurecon.sh
# edite metadados + module_run
make lint && make test
```

Todo PR passa por CI (ShellCheck + shfmt + bats) e exige o checklist ético:
sem payload malicioso, respeita `--safe`, tem teste com fixture.

---

## Desenvolvimento

```bash
make lint      # ShellCheck em todo o código
make fmt       # formata com shfmt
make test      # testes bats
make run       # abre o REPL
```

---

## Roadmap

| Versão | Entrega |
|--------|---------|
| **v0.1** | Core + REPL + CLI + install + 7 módulos MVP + playbook `recon-basico` + relatório Markdown |
| v0.2 | Modo CTF (`ctf/box`, `ctf/quickscan`, `ctf/decode`, `ctf/hashid`) + notes/write-up + timer |
| v0.3 | Mais recon/enum (`asn`, `wayback`, `email`, `subbrute`, `dirs`, `buckets`, `wordpress`, `params`) + playbook `web-full` |
| v0.4 | Módulos `vuln/` (`cors`, `cve-match`, `takeover`, `secrets`, `ratelimit`) + `post/notify` (Discord) |
| v0.5 | CI completo, `CONTRIBUTING`, `MODULE_SPEC`, template, primeiro PR da comunidade |
| v1.0 | Contrato congelado, docs completas, relatório HTML, cobertura de testes, release |

---

## Licença

[MIT](LICENSE). Cada módulo credita seu autor via `MODULE_AUTHOR`.

---

_OfensivaBash — "do recon ao relatório, no seu terminal." Mantenha o pentest
autorizado._
