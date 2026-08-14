#!/bin/bash
# sentinela.sh - verifica se um site esta no ar

SITE="https://www.sankhya.com.br"
LOG="/home/ricardo/lab1/lab1/sentinela.log"

AGORA=$(date '+%d/%m/%Y %H:%M:%S')
CODIGO=$(curl -s -o /dev/null -w "%{http_code}" --max-time 10 "$SITE")

if [ "$CODIGO" = "200" ]; then
    echo "$AGORA | $SITE | $CODIGO | OK" >> "$LOG"
else
    echo "$AGORA | $SITE | $CODIGO | FALHA" >> "$LOG"
fi
