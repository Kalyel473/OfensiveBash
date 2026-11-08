# Política de Segurança

## Escopo

Esta política cobre vulnerabilidades **no próprio OfensivaBash** (ex: injeção de
comando via nome de alvo, path traversal no workspace, vazamento de API key em
log). **Não** cobre o uso do framework contra alvos — isso é responsabilidade do
operador e deve ser sempre **autorizado**.

## Reportando uma vulnerabilidade

- **Não** abra uma issue pública para vulnerabilidades.
- Envie os detalhes de forma privada ao mantenedor (canal/Discord da CyberGuard
  Academy, ou pelo contato indicado no perfil do repositório).
- Inclua: descrição, impacto, passos de reprodução e, se possível, uma sugestão
  de correção.

Faremos o possível para confirmar o recebimento e corrigir com prioridade,
creditando quem reportou (se desejar).

## Boas práticas de segurança no código

O OfensivaBash é uma ferramenta ofensiva, então o próprio código precisa ser
seguro:

- Zero `eval` em entrada do usuário.
- Alvo validado/sanitizado (regex de domínio/IP/CIDR) antes de uso em caminho ou
  requisição.
- Proteção contra path traversal no nome do alvo/workspace.
- Argumentos de comando montados via arrays, nunca por concatenação de string.
- Timeouts em toda requisição de rede.
- API keys nunca são logadas nem incluídas no relatório.
