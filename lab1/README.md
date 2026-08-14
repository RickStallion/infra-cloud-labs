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
Ricardo Nogueira de Souza — em transicao para infraestrutura cloud
LinkedIn: https://www.linkedin.com/in/ricardondesouza/
