# Lab 1 — Sentinela de disponibilidade em VM Linux

Monitoramento simples de disponibilidade de um site, rodando
automaticamente numa VM Linux na Oracle Cloud.

## O problema

Saber se um serviço saiu do ar sem depender de alguem estar olhando.

## A solucao

Script em Bash que consulta o site a cada 5 minutos, registra o
codigo HTTP retornado e marca OK ou FALHA num arquivo de log.

## Como funciona

cron (a cada 5 min) -> sentinela.sh -> curl no site -> grava em sentinela.log

## Stack

- Ubuntu 24.04 (VM Ampere A1, Oracle Cloud Always Free)
- Bash
- curl
- cron
- Git / GitHub

## Decisoes tecnicas

- **--max-time 10 no curl**: evita que o script fique preso caso o
  site nao responda.
- **Caminho absoluto no log**: o cron executa a partir de outro
  diretorio; caminho relativo gravaria o log no lugar errado.
- **>> em vez de >**: preserva o historico em vez de sobrescrever.
- **Log no .gitignore**: repositorio guarda codigo, nao dado gerado.

## Testes realizados

- Site no ar: registra `200 | OK`
- Dominio inexistente: registra `000 | FALHA`

## Proximos passos

- Enviar alerta no Telegram quando detectar FALHA
- Monitorar mais de um host
- Substituir o log em texto por Prometheus + Grafana (Lab 6)

---

Algumas coisas que aconteceu na prática.


- **VM em UTC, não em horário local**: é o padrão de servidor. Quando o
  log de várias máquinas precisa ser cruzado, fuso único elimina conversão
  mental e a ambiguidade do horário de verão. O custo é converter na
  leitura — troca consciente.

- **`chrony` em vez de acerto manual**: a VM roda suspensa entre sessões,
  e ao retomar o relógio volta atrasado. O `chrony` corrige por *slewing*
  (acelera o relógio de leve até alcançar) e **evita dar salto**, porque
  relógio que pula para trás quebra banco de dados, cron e certificado.
  A janela de salto só existe nas primeiras sincronizações após iniciar —
  então, depois de retomar a VM: `sudo systemctl restart chrony`.

- Site no ar: registra `200 | OK`
- Domínio inexistente: registra `000 | FALHA`
- **VM suspensa por dois dias**: o log não registra nada no período.
  A lacuna entre `14/08 13:00` e `16/08 23:40` é a evidência de que o
  monitor esteve fora do ar.

## O que o log ensinou

O log tem um buraco de dois dias — o tempo em que a VM ficou suspensa.
Isso expõe um limite que todo monitoramento tem:

> **um monitor não distingue "o serviço estava no ar" de "ninguém perguntou".**

Ausência de registro parece silêncio bom, mas pode ser o monitor caído.
Por isso monitoramento sério alerta também sobre a **falta de dados**, e
não só sobre falha — é o que o CloudWatch chama de `INSUFFICIENT_DATA`
e o que se conhece como *dead man's switch*.

No Lab 6 isso é resolvido de verdade, com Prometheus e Alertmanager.

Ricardo Nogueira de Souza — em transicao para infraestrutura cloud

LinkedIn: https://www.linkedin.com/in/ricardondesouza/
