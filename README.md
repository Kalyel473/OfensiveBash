<div align="center">

# OfensivaBash 🛡

**Framework de pentest e automação ofensiva escrito em Bash  leve, modular e em português.**

_Do recon ao relatório, no seu terminal._

![Versão](https://img.shields.io/badge/vers%C3%A3o-0.1.0-blue)
![Bash](https://img.shields.io/badge/bash-4%2B-4EAA25?logo=gnubash&logoColor=white)
![Licença](https://img.shields.io/badge/licen%C3%A7a-MIT-green)
![Plataformas](https://img.shields.io/badge/plataformas-Linux%20%7C%20macOS%20%7C%20Termux%20%7C%20WSL-lightgrey)
![Idioma](https://img.shields.io/badge/idioma-PT--BR-yellow)

</div>

---

O **OfensivaBash** é um framework de linha de comando para **pentest autorizado**,
**bug bounty dentro do escopo** e **CTF** (HackTheBox, TryHackMe, labs próprios).
Ele organiza todo o fluxo de um teste (definição de alvo e escopo, execução de
módulos, encadeamento por playbooks e geração de relatório) em uma ferramenta
única, sem runtime pesado: roda de um VPS mínimo ao Termux no celular.



## Sumário

- [⚠️ Aviso ético e legal](#️-aviso-ético-e-legal)
- [Principais recursos](#principais-recursos)
- [Requisitos](#requisitos)
- [Instalação](#instalação)
- [Primeiros passos](#primeiros-passos)
- [Utilização](#utilização)
  - [Modo interativo (REPL)](#modo-interativo-repl)
  - [Modo linha de comando (CLI)](#modo-linha-de-comando-cli)
  - [Modos de segurança e escopo](#modos-de-segurança-e-escopo)
  - [Módulos disponíveis](#módulos-disponíveis)
  - [Playbooks](#playbooks)
  - [Workspaces e sessões](#workspaces-e-sessões)
  - [Relatórios](#relatórios)
  - [Códigos de saída](#códigos-de-saída)
  - [Exemplos de fluxo completo](#exemplos-de-fluxo-completo)
- [Configuração](#configuração)
- [Arquitetura do projeto](#arquitetura-do-projeto)
- [Criando um módulo](#criando-um-módulo)
- [Desenvolvimento e testes](#desenvolvimento-e-testes)
- [Solução de problemas](#solução-de-problemas)
- [Roadmap](#roadmap)
- [Contribuindo](#contribuindo)
- [Segurança](#segurança)
- [Licença](#licença)

---

## ⚠️ Aviso ético e legal

> [!WARNING]
> **USO AUTORIZADO SOMENTE.** Leia esta seção antes de usar a ferramenta.

O OfensivaBash é uma ferramenta de segurança com fins **educacionais e
profissionais**. Use-o **exclusivamente** contra:

- alvos para os quais você tem **permissão explícita e por escrito** (contrato de
  pentest, programa de bug bounty dentro do escopo publicado), ou
- **seus próprios sistemas**, **labs** e plataformas de **CTF** (HTB, THM,
  máquinas locais).

Testar sistemas de terceiros sem autorização é **crime** na maioria das
jurisdições (no Brasil, Lei 12.737/2012 e correlatas). O framework roda em modo
`--safe` por padrão, que **bloqueia ações intrusivas fora do escopo**. Você é o
único responsável pelo uso que fizer dele; os autores não se responsabilizam por
uso indevido.

O OfensivaBash **não contém e não aceita** payloads de malware, persistência
maliciosa ou automação de ataque contra alvos sem autorização. O foco é
**reconhecimento, enumeração, checagem de configuração, apoio a CTF e relatório**.

---

## Principais recursos

| Recurso | Descrição |
|---|---|
| **Leveza** | Bash puro com `coreutils`, `grep`, `sed`, `awk` e `curl`. Nada de Python, Ruby ou Go para instalar. |
| **Dependências opcionais** | `jq`, `dig`, `openssl`, `nmap` e outras são detectadas em tempo de execução. Na falta delas, o módulo avisa e degrada, sem derrubar o framework. |
| **Dois modos de uso** | REPL interativo no estilo Metasploit e CLI não interativa para scripts e pipelines de CI. |
| **Segurança por padrão** | Modo `--safe` com controle de escopo por domínio, subdomínio e CIDR. Ações intrusivas fora do escopo são bloqueadas. |
| **Workspaces por alvo** | Cada alvo tem um diretório isolado com resultados, sessão e log de execução em JSON Lines. |
| **Playbooks** | Encadeie módulos em um arquivo de texto simples e rode o fluxo inteiro com um comando. |
| **Relatório automático** | Gera um `report.md` com sessão, linha do tempo de execuções e achados por categoria. |
| **Extensível** | Um módulo novo é **um único arquivo `.sh`** que segue um contrato. Nenhuma alteração no core. |
| **Em português** | Mensagens, ajuda e relatórios em PT-BR. |

---

## Requisitos

**Obrigatórios**

| Ferramenta | Observação |
|---|---|
| `bash` 4.0+ | O framework usa arrays associativos. No macOS, instale um Bash moderno (`brew install bash`). |
| `curl` | Requisições HTTP. |
| `grep`, `sed`, `awk`, `sort`, `find` | Utilitários padrão (`coreutils`/`findutils`). |

**Opcionais** (habilitam ou melhoram módulos específicos)

| Ferramenta | Usada por | Sem ela |
|---|---|---|
| `jq` | `recon/ctlogs`, relatório | Usa fallback com `grep`/`sed`. |
| `dig` | `recon/dns` | Usa `host` ou `nslookup`. |
| `openssl` | `scan/tls` | O módulo `scan/tls` não executa. |
| `nmap`, `whois`, `nc`/`ncat` | Módulos do roadmap | Não afetam a v0.1. |

Não é necessário ter root.

---

## Instalação

### Via instalador (recomendado)

```bash
git clone https://github.com/Kalyel473/ofensivabash.git
cd ofensivabash
./install.sh
ofensivabash --version
```

O instalador:

1. verifica as dependências obrigatórias e lista as opcionais encontradas;
2. cria `~/.config/ofensivabash/ofensivabash.conf` a partir do exemplo (sem
   sobrescrever uma configuração existente);
3. cria um link simbólico do executável em `~/.local/bin/ofensivabash`
   (ou em `$PREFIX/bin` no **Termux**);
4. avisa se o diretório de destino não estiver no seu `PATH`.

Se o aviso de `PATH` aparecer, adicione ao seu `~/.bashrc`:

```bash
export PATH="$HOME/.local/bin:$PATH"
```

### Sem instalar

```bash
git clone https://github.com/Kalyel473/ofensivabash.git
cd ofensivabash
./ofensivabash --version.
```

### Via Makefile

```bash
make install
```

### Atualizando

Como o instalador cria um link simbólico para o repositório, basta atualizar o
clone:

```bash
cd ofensivabash && git pull
```

---

## Primeiros passos

Em menos de um minuto, contra um domínio que você está autorizado a testar:

```bash
# 1. Veja os módulos disponíveis
ofensivabash --list-modules

# 2. Faça um reconhecimento passivo
ofensivabash -t exemplo.com -m recon/ctlogs

# 3. Rode o fluxo de recon completo e gere o relatório
ofensivabash -t exemplo.com -p recon-basico

# 4. Abra o relatório
cat workspaces/exemplo.com/report.md
```

---

## Utilização

O OfensivaBash tem dois modos de operação:

- **sem argumentos**, abre o **REPL interativo**;
- **com argumentos**, executa como **CLI** e encerra ao final.

### Modo interativo (REPL)

```bash
ofensivabash
```

O prompt mostra o estado atual: módulo selecionado entre `()`, alvo entre `[]`
e modo entre `{}` (quando diferente de `safe`).

```text
ofensivabash > set target exemplo.com
[+] Alvo definido: exemplo.com  (workspace: .../workspaces/exemplo.com)
ofensivabash [exemplo.com] > modules recon
ofensivabash [exemplo.com] > use recon/ctlogs
[+] Selecionado: recon/ctlogs
ofensivabash (recon/ctlogs) [exemplo.com] > info
ofensivabash (recon/ctlogs) [exemplo.com] > run
ofensivabash (recon/ctlogs) [exemplo.com] > use scan/ports
ofensivabash (scan/ports) [exemplo.com] > run -p 80,443,8080
ofensivabash (scan/ports) [exemplo.com] > report
ofensivabash (scan/ports) [exemplo.com] > exit
```

#### Referência de comandos

| Comando | Descrição |
|---|---|
| `help [comando]` | Ajuda geral ou de um comando específico. |
| `set target <alvo>` | Define o alvo (domínio, IP ou CIDR), cria o workspace e adiciona o alvo ao escopo. |
| `set scope <dom/cidr>` | Adiciona um item ao escopo permitido. Pode ser repetido. |
| `set mode safe\|active\|ctf` | Alterna o modo de segurança. |
| `modules [categoria]` | Lista os módulos carregados, com filtro opcional por categoria. |
| `search <termo>` | Busca módulos por nome ou descrição. |
| `use <modulo>` | Seleciona um módulo (ex.: `use enum/headers`). |
| `info` | Mostra descrição, categoria, autor, dependências, se é intrusivo e os argumentos do módulo selecionado. |
| `run [args]` | Executa o módulo selecionado, repassando os argumentos. |
| `playbook <nome>` | Executa um playbook contra o alvo atual. |
| `workspace [alvo]` | Mostra o workspace atual ou carrega o de outro alvo. |
| `sessions` | Lista todos os workspaces existentes. |
| `report` | Gera o relatório do alvo atual. |
| `banner` | Exibe o banner novamente. |
| `exit` \| `quit` | Sai do REPL (`Ctrl+D` também). |

**Atalhos:** o REPL tem edição de linha e histórico (setas ↑/↓), salvo em
`~/.config/ofensivabash/history`. `Ctrl+C` cancela a linha atual ou interrompe o
módulo em execução sem fechar o REPL.

### Modo linha de comando (CLI)

```text
ofensivabash -t <alvo> -m <modulo> [-- args do módulo...]
ofensivabash -t <alvo> -p <playbook>
ofensivabash --report -t <alvo>
ofensivabash --list-modules
```

#### Opções

| Flag | Descrição |
|---|---|
| `-t`, `--target <alvo>` | Alvo: domínio, IP ou CIDR. |
| `-m`, `--module <nome>` | Executa um módulo (ex.: `recon/dns`). |
| `-p`, `--playbook <nome>` | Executa um playbook (nome em `playbooks/` ou caminho de arquivo). |
| `-s`, `--scope <dom/cidr>` | Adiciona um item ao escopo. Pode ser repetida. |
| `--safe` | Modo seguro (**padrão**). |
| `--active` | Modo ativo: permite ações intrusivas em qualquer host. |
| `--ctf` | Modo CTF: libera IPs privados e de laboratório. |
| `--list-modules` | Lista os módulos carregados e sai. |
| `--report` | Gera o relatório do alvo e sai. |
| `-o`, `--output <dir>` | Diretório raiz dos workspaces. |
| `-q`, `--quiet` | Saída mínima. |
| `-v`, `--verbose` | Saída detalhada (debug). |
| `--no-color` | Desativa as cores. |
| `--version` | Mostra a versão e sai. |
| `-h`, `--help` | Mostra a ajuda. |
| `--` | Tudo o que vier depois é repassado ao módulo, sem interpretação. |

Quando mais de uma ação é informada, a prioridade é
`--report` > `--module` > `--playbook`.

#### Exemplos

```bash
# Reconhecimento passivo de subdomínios
ofensivabash -t exemplo.com -m recon/ctlogs

# Registros DNS
ofensivabash -t exemplo.com -m recon/dns

# Scan das portas 1-1000 em uma máquina de CTF
ofensivabash -t 10.10.10.5 --ctf -m scan/ports -- -p 1-1000

# TLS em porta alternativa
ofensivabash -t exemplo.com -m scan/tls -- 8443

# Auditoria de headers de uma URL específica
ofensivabash -t exemplo.com -m enum/headers -- https://app.exemplo.com/login

# Escopo ampliado com subdomínios e uma faixa de IPs
ofensivabash -t exemplo.com -s exemplo.com -s 203.0.113.0/24 -p recon-basico

# Saída silenciosa e workspaces em outro diretório (útil em CI)
ofensivabash -q --no-color -o /tmp/ofb -t exemplo.com -p recon-basico

# Apenas gerar o relatório de um alvo já testado
ofensivabash --report -t exemplo.com
```

### Modos de segurança e escopo

Toda execução de um módulo **intrusivo** (que toca o alvo ativamente) passa por
uma checagem de escopo. Módulos passivos, como `recon/ctlogs`, não são
bloqueados. O comportamento depende do modo:

| Modo | Flag | Módulos intrusivos são permitidos quando… | Uso indicado |
|---|---|---|---|
| `safe` | `--safe` (padrão) | o host está no escopo ou é `localhost`. | Pentest e bug bounty com escopo definido. |
| `ctf` | `--ctf` | o host é IP privado, `localhost` ou está no escopo. | HackTheBox, TryHackMe, labs locais e VPN. |
| `active` | `--active` | sempre. **Você assume a responsabilidade pela autorização.** | Testes com autorização ampla e documentada. |

**Como o escopo funciona:**

- o alvo definido com `set target` / `-t` entra no escopo automaticamente;
- itens extras são adicionados com `set scope` / `-s`;
- um host está no escopo se for **igual** a um item, se for **subdomínio** dele
  (`api.exemplo.com` casa com `exemplo.com`) ou, no caso de IPv4, se estiver
  **dentro de um CIDR** listado (`10.0.0.7` casa com `10.0.0.0/24`).

Quando uma ação é bloqueada, o framework explica o motivo, registra o evento no
log e retorna o código de saída `4`:

```text
[-] Bloqueado pelo modo --safe: 'outro.com' fora do escopo.
[-] Adicione ao escopo (set scope <dom/cidr>) ou use --active se autorizado.
```

### Módulos disponíveis

| Módulo | Intrusivo | Requer | Argumentos | Saída no workspace |
|---|:---:|---|---|---|
| `recon/ctlogs` | não | `curl` (`jq` opcional) | `[dominio]` (padrão: alvo) | `recon/subdomains.txt` |
| `recon/dns` | não | `dig`, `host` ou `nslookup` | `[dominio]` (padrão: alvo) | `recon/dns.txt` |
| `scan/ports` | **sim** | nativo (`/dev/tcp` + `xargs`) | `-p top` \| `-p 80,443` \| `-p 1-1024` (padrão: `top`) | `scan/ports.txt` |
| `scan/tls` | **sim** | `openssl` | `[porta]` (padrão: `443`) | `scan/tls_<porta>.txt` |
| `enum/http` | **sim** | `curl` | `[url\|host]` (padrão: `https://` e `http://` do alvo) | `enum/http.txt` |
| `enum/headers` | **sim** | `curl` | `[url\|host]` (padrão: `https://` do alvo) | `enum/security_headers.txt` |
| `post/report` | não | nenhum | nenhum | `report.md` |

**O que cada módulo faz:**

- **`recon/ctlogs`**: enumera subdomínios a partir de logs de Certificate
  Transparency (crt.sh). É passivo e não envia tráfego ao alvo.
- **`recon/dns`**: coleta registros `A`, `AAAA`, `MX`, `NS`, `TXT` e `CNAME`.
- **`scan/ports`**: scanner TCP nativo via `/dev/tcp`, sem depender de nmap, com
  conexões paralelas (`OFB_THREADS`). A lista `top` cobre cerca de 30 portas
  comuns (FTP, SSH, HTTP/S, SMB, RDP, bancos de dados, painéis web etc.).
- **`scan/tls`**: inspeciona o certificado (subject, emissor, validade, SANs) e
  testa os protocolos aceitos (SSLv3 a TLS 1.3), sinalizando os obsoletos.
- **`enum/http`**: fingerprint HTTP com status, headers, servidor e tecnologia,
  título da página e presença de `robots.txt`.
- **`enum/headers`**: audita headers de segurança (HSTS, CSP, X-Frame-Options e
  outros) e atribui uma nota.
- **`post/report`**: gera o relatório Markdown do alvo atual.

Para detalhes de um módulo, use `use <modulo>` seguido de `info` no REPL.

### Playbooks

Um playbook é um arquivo de texto em `playbooks/` com **um módulo por linha**.
Argumentos vêm depois de ` -- `, e linhas iniciadas com `#` são comentários.

```text
# playbooks/meu-fluxo.playbook
recon/ctlogs
recon/dns
scan/ports    -- -p 80,443,8080,8443
enum/http
enum/headers  -- https://$TARGET
scan/tls      -- 443
```

- As variáveis `$TARGET` e `$SCOPE` são expandidas nos argumentos (sem `eval`).
- Se um passo falhar, o playbook **continua** com os próximos.
- Ao final, é exibido um resumo (total, OK, falhas e duração) e o **relatório é
  gerado automaticamente**.
- Os passos continuam sujeitos às regras do modo de segurança.

**Playbooks incluídos:**

| Playbook | Conteúdo |
|---|---|
| `recon-basico` | CT logs, DNS, portas web (80, 443, 8080, 8443), fingerprint HTTP, headers, TLS e relatório. |
| `web-full` | CT logs, DNS, portas 1-1024, TLS, fingerprint HTTP, headers e relatório. |

```bash
ofensivabash -t exemplo.com -p recon-basico          # pelo nome
ofensivabash -t exemplo.com -p ./meus/fluxo.playbook  # por caminho
```

### Workspaces e sessões

Cada alvo recebe um workspace isolado, criado no primeiro `set target`:

```text
workspaces/<alvo>/
├── session.env      # TARGET, SCOPE, MODE e data de criação
├── recon/           # resultados de reconhecimento
├── scan/            # resultados de scan
├── enum/            # resultados de enumeração
├── vuln/            # achados de vulnerabilidade
├── ctf/             # anotações e artefatos de CTF
├── loot/            # artefatos coletados
├── log.jsonl        # uma linha JSON por execução de módulo
└── report.md        # relatório gerado
```

- O diretório padrão é `workspaces/` dentro do repositório. Altere com
  `-o <dir>` ou com a variável `OFB_WORKSPACES_DIR`.
- O nome do alvo é **sanitizado** (sem `/`, espaços ou `..`) para evitar path
  traversal. Por exemplo, `10.0.0.0/24` vira `10.0.0.0_24`.
- No REPL, `sessions` lista os workspaces e `workspace <alvo>` restaura alvo,
  escopo e modo de uma sessão anterior.

Exemplo de linha do `log.jsonl`:

```json
{"ts":"2026-11-09T14:02:11Z","module":"scan/ports","target":"exemplo.com","status":"ok","duration":7}
```

O campo `status` pode ser `"ok"`, `"scope-blocked"`, `"dep-missing"` ou o
código de saída numérico do módulo.

### Relatórios

O relatório é gerado em `workspaces/<alvo>/report.md` por qualquer uma destas
formas:

```bash
ofensivabash --report -t exemplo.com      # CLI
ofensivabash -t exemplo.com -m post/report
```

Ou com `report` no REPL. Ele também é gerado ao final de todo playbook.

**Conteúdo do relatório:**

1. **Sessão**: alvo, escopo, modo e workspace;
2. **Linha do tempo**: cada execução com horário (UTC), módulo, status e duração;
3. **Achados por categoria**: arquivos gerados em `recon`, `scan`, `enum`,
   `vuln` e `loot`, com contagem de linhas;
4. **Ferramentas ausentes**: dependências opcionais que fizeram módulos degradarem.

### Códigos de saída

| Código | Significado |
|:---:|---|
| `0` | Sucesso. |
| `1` | Erro de execução. |
| `2` | Erro de uso (flag, argumento ou alvo inválido). |
| `3` | Dependência obrigatória do módulo ausente. |
| `4` | Ação bloqueada: alvo fora do escopo. |

Esses códigos permitem usar o OfensivaBash em scripts e pipelines:

```bash
if ! ofensivabash -q -t exemplo.com -m enum/headers; then
    echo "Falha na auditoria de headers (código $?)"
fi
```

### Exemplos de fluxo completo

**Bug bounty (escopo definido, modo seguro):**

```bash
ofensivabash -t exemplo.com -s exemplo.com -p recon-basico
less workspaces/exemplo.com/recon/subdomains.txt
ofensivabash -t exemplo.com -m enum/headers -- https://api.exemplo.com
ofensivabash --report -t exemplo.com
```

**CTF (HackTheBox / TryHackMe):**

```text
$ ofensivabash
ofensivabash > set mode ctf
ofensivabash {ctf} > set target 10.10.11.23
ofensivabash [10.10.11.23] {ctf} > use scan/ports
ofensivabash (scan/ports) [10.10.11.23] {ctf} > run -p 1-10000
ofensivabash (scan/ports) [10.10.11.23] {ctf} > use enum/http
ofensivabash (enum/http) [10.10.11.23] {ctf} > run http://10.10.11.23
ofensivabash (enum/http) [10.10.11.23] {ctf} > report
```

---

## Configuração

O arquivo do usuário fica em `~/.config/ofensivabash/ofensivabash.conf` (o
instalador o cria a partir de [`ofensivabash.conf.example`](ofensivabash.conf.example)).
O formato é `chave=valor`, com comentários iniciados por `#`.

| Chave | Padrão | Descrição |
|---|---|---|
| `OFB_THREADS` | `20` | Conexões paralelas (ex.: `scan/ports`). |
| `OFB_HTTP_TIMEOUT` | `10` | Timeout das requisições HTTP, em segundos. |
| `OFB_HTTP_RETRIES` | `2` | Tentativas extras em caso de falha HTTP. |
| `OFB_USER_AGENT` | `OfensivaBash/<versão> (+https://github.com/Kalyel473)` | User-Agent das requisições. |
| `OFB_LOCALE` | `pt_BR` | Idioma. |
| `OFB_WORDLIST_SUBS` | vazio | Wordlist de subdomínios (módulos do roadmap). |
| `OFB_WORDLIST_DIRS` | vazio | Wordlist de diretórios (módulos do roadmap). |
| `SHODAN_API_KEY` | vazio | API key do Shodan (opcional). |
| `DISCORD_WEBHOOK_URL` | vazio | Webhook para notificações (opcional). |

**Ordem de precedência** (a primeira vence):

1. flags da CLI;
2. variáveis de ambiente (ex.: `OFB_THREADS=50 ofensivabash ...`);
3. `~/.config/ofensivabash/ofensivabash.conf`;
4. `ofensivabash.conf` na raiz do repositório;
5. valores padrão embutidos.

**Variáveis de ambiente de caminho:**

| Variável | Padrão | Descrição |
|---|---|---|
| `OFB_CONFIG_DIR` | `$XDG_CONFIG_HOME/ofensivabash` ou `~/.config/ofensivabash` | Configuração e histórico do REPL. |
| `OFB_WORKSPACES_DIR` | `<repositório>/workspaces` | Raiz dos workspaces. |
| `OFB_NO_COLOR` | não definida | Com `1`, desativa as cores (equivale a `--no-color`). |
| `OFB_QUIET` / `OFB_VERBOSE` | não definidas | Com `1`, equivalem a `-q` / `-v`. |

> [!IMPORTANT]
> Chaves sensíveis (`*_API_KEY`, `*TOKEN`, `*SECRET`, `*WEBHOOK*`, `*PASSWORD`)
> são mascaradas e **nunca aparecem em logs ou relatórios**. O arquivo
> `ofensivabash.conf` real está no `.gitignore`; **nunca o versione**.

---

## Arquitetura do projeto

```text
ofensivabash/
├── ofensivabash              # executável (entrypoint)
├── install.sh                # instalador
├── ofensivabash.conf.example # configuração de exemplo
├── core/                     # núcleo do framework
│   ├── bootstrap.sh          #   carga ordenada, paths e códigos de saída
│   ├── cli.sh                #   modo não interativo (flags)
│   ├── repl.sh               #   shell interativo
│   ├── config.sh             #   leitura de configuração e precedência
│   ├── session.sh            #   alvo, escopo, modo e workspace
│   ├── require.sh            #   guardas de dependência, alvo e escopo
│   ├── loader.sh             #   descoberta e validação de módulos
│   ├── registry.sh           #   tabela de módulos carregados
│   ├── runner.sh             #   execução de módulos com guardas e log
│   ├── playbook.sh           #   encadeamento de módulos
│   ├── report.sh             #   geração do relatório
│   └── ui.sh                 #   saída, cores e banner
├── lib/                      # helpers compartilhados pelos módulos
│   ├── fs.sh  http.sh  json.sh  net.sh  parse.sh
├── modules/                  # módulos, um arquivo por módulo
│   ├── _template.sh          #   molde para novos módulos
│   ├── recon/  scan/  enum/  post/
├── playbooks/                # cadeias de módulos (.playbook)
├── tests/                    # testes bats com fixtures
├── docs/                     # CONTRIBUTING e MODULE_SPEC
└── workspaces/               # resultados por alvo (ignorado pelo git)
```

**Fluxo de execução de um módulo:** o `loader` valida cada módulo num subshell
isolado (um módulo com defeito é ignorado com aviso e não derruba o framework).
O `runner` então checa as dependências declaradas (`MODULE_REQUIRES`) e, se o
módulo for intrusivo, aplica a política de escopo. Em seguida, executa o módulo,
mede a duração e registra o resultado no `log.jsonl`.

---

## Criando um módulo

Adicionar um módulo é criar **um arquivo** em `modules/<categoria>/<nome>.sh`,
sem tocar no core:

```bash
cp modules/_template.sh modules/recon/meurecon.sh
```

```bash
#!/usr/bin/env bash

MODULE_NAME="recon/meurecon"
MODULE_DESC="Descrição curta em uma linha"
MODULE_CATEGORY="recon"            # recon | scan | enum | vuln | ctf | post
MODULE_AUTHOR="Seu Nome"
MODULE_REQUIRES="curl"             # binários necessários (opcional)
MODULE_INTRUSIVE="false"           # true se toca o alvo ativamente
MODULE_ARGS_HELP="[dominio]  (default: TARGET)"

module_run() {
    local alvo="${1:-$TARGET}"
    local out; out="$(ws_dir recon)/meurecon.txt" || return 1
    # ... faça o trabalho e grave no workspace
    printf '%s\n' "$alvo" | ws_write "$out"
    return 0
}
```

O módulo é carregado automaticamente na próxima execução. O contrato completo
(variáveis, funções, helpers disponíveis e regras) está em
[`docs/MODULE_SPEC.md`](docs/MODULE_SPEC.md).

---

## Desenvolvimento e testes

| Comando | Descrição |
|---|---|
| `make install` | Instala o framework (roda `install.sh`). |
| `make lint` | Roda o ShellCheck em todo o código. |
| `make fmt` | Formata o código com `shfmt`. |
| `make test` | Roda a suíte de testes [bats](https://github.com/bats-core/bats-core). |
| `make run` | Abre o REPL. |

Os testes ficam em `tests/` e usam **fixtures mockadas**: nenhum teste faz
requisição a alvos reais. Todo pull request passa pela CI (ShellCheck, shfmt e
bats).

---

## Solução de problemas

| Sintoma | Causa provável e solução |
|---|---|
| `ofensivabash: command not found` | `~/.local/bin` não está no `PATH`. Adicione `export PATH="$HOME/.local/bin:$PATH"` ao `~/.bashrc`. |
| Erros com `declare -A` no macOS | O macOS traz Bash 3.2. Instale o Bash 4+ com `brew install bash`. |
| `Bloqueado pelo modo --safe` (código 4) | O host não está no escopo. Use `set scope` / `-s`, ou `--ctf` em labs. |
| `Modulo '...' precisa de: ...` (código 3) | Falta uma dependência declarada pelo módulo. Instale a ferramenta indicada. |
| `Nenhum alvo definido` (código 2) | Defina um alvo com `-t <alvo>` ou `set target <alvo>`. |
| Módulo não aparece em `--list-modules` | O arquivo não cumpre o contrato. Procure o aviso `Modulo ignorado (contrato invalido...)` na saída e confira o [`MODULE_SPEC`](docs/MODULE_SPEC.md). |
| Cores estranhas no terminal ou em logs | Use `--no-color` ou `OFB_NO_COLOR=1`. |

---

## Roadmap

| Versão | Entrega |
|---|---|
| **v0.1** ✅ | Core, REPL, CLI, instalador, 7 módulos MVP, playbooks e relatório Markdown. |
| v0.2 | Modo CTF (`ctf/box`, `ctf/quickscan`, `ctf/decode`, `ctf/hashid`), notas e write-up, timer. |
| v0.3 | Mais recon/enum (`asn`, `wayback`, `email`, `subbrute`, `dirs`, `buckets`, `wordpress`, `params`). |
| v0.4 | Módulos `vuln/` (`cors`, `cve-match`, `takeover`, `secrets`, `ratelimit`) e `post/notify` (Discord). |
| v0.5 | CI completa, guias de contribuição e o primeiro PR da comunidade. |
| v1.0 | Contrato de módulo congelado, documentação completa, relatório HTML, cobertura de testes e release estável. |

---

## Contribuindo

Contribuições são bem-vindas, principalmente **novos módulos**. Antes de abrir um
PR, leia:

- [`docs/CONTRIBUTING.md`](docs/CONTRIBUTING.md): fluxo de contribuição e padrões de código;
- [`docs/MODULE_SPEC.md`](docs/MODULE_SPEC.md): contrato formal de módulo;
- [`CODE_OF_CONDUCT.md`](CODE_OF_CONDUCT.md): código de conduta.

Todo PR precisa passar na CI e cumprir o **checklist ético**: nenhum payload
malicioso, respeito ao modo `--safe` e teste com fixture.

---

## Segurança

Encontrou uma vulnerabilidade **no próprio OfensivaBash**? Não abra uma issue
pública. Siga as instruções de divulgação responsável em
[`SECURITY.md`](SECURITY.md).

---

## Licença

Distribuído sob a licença [MIT](LICENSE). Cada módulo credita seu autor por meio
de `MODULE_AUTHOR`.

<div align="center">

**OfensivaBash**: do recon ao relatório, no seu terminal.
Mantenha o pentest autorizado. 🛡

</div>
