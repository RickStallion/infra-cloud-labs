# SSH — o que aprendi

Anotações de estudo. Aprendido na prática em 11/08/2026, conectando numa VM
Oracle Linux na Oracle Cloud (OCI).

## O que é um par de chaves

Chave SSH não é uma coisa só — são **duas**, que nascem juntas e só funcionam
uma com a outra:

| Arquivo | Apelido | Onde mora |
|---|---|---|
| `oci_lab.pub` | o **cadeado** | no servidor, dentro de `~/.ssh/authorized_keys` |
| `oci_lab` | a **chave** | no meu PC, e nunca sai dele |

Quando criei a VM, colei o conteúdo da `.pub` no campo *SSH keys* do console da
OCI. A Oracle gravou aquele texto no `authorized_keys` da máquina. A partir daí,
só a chave privada correspondente abre aquele cadeado.

Dá para ver as duas metades:

```bash
# no meu PC
cat ~/.ssh/oci_lab.pub

# dentro da VM
cat ~/.ssh/authorized_keys
```

São idênticos.

**Regras que sigo:**

- **Uma chave por finalidade.** `oci_lab` para a Oracle, `github` para o GitHub.
  Sempre com `-f` e nome próprio, nunca sobrescrevendo a chave padrão.
- **`.pub` pode mostrar para qualquer um.** É pública de propósito.
- **A privada nunca sai da máquina.** Não vai para chat, repositório ou e-mail.
  Quando troquei de computador, gerei uma chave nova em vez de copiar a antiga.
- **Permissão fechada:** `chmod 600` na chave privada e `700` na pasta `.ssh`.
  O SSH recusa a conexão se estiver frouxo — uma chave que outros usuários da
  máquina podem ler já não é secreta.

## Por que "Permission denied (publickey)" não é erro de rede

Foi o erro que me travou. A leitura errada é achar que é firewall ou VM fora do
ar. Mas para essa mensagem chegar até mim, **muita coisa já funcionou**:

- a VM estava ligada e respondeu
- a rota chegou até ela
- a *Security List* liberava a porta 22
- o serviço `sshd` atendeu

O único passo que falhou foi a autenticação.

| Sintoma | Onde está o problema |
|---|---|
| `Connection timed out` | **rede** — Security List/NSG, rota, VM desligada |
| `Permission denied (publickey)` | **credencial** — chave ou usuário errado |

**O que aconteceu comigo:** apontei o `-i` para `id_ed25519`, uma chave que
existe no meu PC mas que nunca foi cadastrada na VM. A VM só conhece a
`oci_lab`. Chave legítima, fechadura errada.

Outra causa comum é o **usuário**: cada imagem tem o seu.

| Sistema | Usuário |
|---|---|
| Oracle Linux | `opc` |
| Ubuntu | `ubuntu` |
| Amazon Linux | `ec2-user` |

Errar o usuário dá exatamente a mesma mensagem.

## Como descobrir o que o SSH vai fazer antes de conectar

```bash
ssh -G lab-ricardo
```

O `-G` mostra a configuração **já resolvida** — o que o SSH realmente vai usar —
**sem conectar em nada**.

Comparando um apelido que existe com um que não existe, fica evidente:

| Campo | apelido inexistente | apelido configurado |
|---|---|---|
| `user` | meu usuário do Windows | `opc` |
| `hostname` | o nome cru, sem virar IP | o IP de verdade |
| `identitiesonly` | `no` | `yes` |
| `identityfile` | 7 chaves padrão | só a `oci_lab` |

**Se os valores vierem no padrão de fábrica, o bloco `Host` não existe no
config.** Foi assim que descobri que `ssh lab` não funcionava: eu tinha criado a
entrada com outro nome. Não era o IP que havia mudado, como eu suspeitava — o
apelido simplesmente não estava lá.

É a mesma filosofia do `terraform plan` antes do `apply`: **ver a decisão antes
de sofrer a consequência**.

## O arquivo `~/.ssh/config`

Em vez de decorar IP, usuário e caminho de chave, escrevo uma vez:

```
Host lab-ricardo
    HostName 129.148.29.148
    User opc
    IdentityFile ~/.ssh/oci_lab
    IdentitiesOnly yes
```

E conecto com `ssh lab-ricardo`. Ganhos:

- quando o IP mudar, edito **uma linha** em vez de reaprender o comando
- o **VS Code Remote-SSH** lê esse mesmo arquivo e lista o host sozinho
- `IdentitiesOnly yes` evita o erro `Too many authentication failures`: sem ele,
  o SSH oferece todas as minhas chaves em sequência, e servidores com
  `MaxAuthTries 6` desconectam antes de chegar na certa. Parece "chave errada",
  mas é "chaves demais"

**Endereço não é identidade.** Destruí uma VM e criei outra: o IP mudou de
`163.176.12.138` para `129.148.29.148`. IP público efêmero muda quando a
instância é recriada — por isso existe *Reserved Public IP*, e por isso o mundo
real usa DNS em vez de IP fixo em arquivo de configuração.

## O prompt diz em qual máquina você está

```
PS C:\WINDOWS\System32>     ← meu PC, Windows
[opc@lab-ricardo ~]$        ← a VM, Oracle Linux, em São Paulo
```

Lendo o prompt do Linux: `usuário@máquina pasta$`. O `~` é a pasta pessoal. Se o
`$` virar `#`, estou como **root** — e aí todo comando é sério.

**Meu erro:** rodei `ssh -G lab` **dentro da VM**, achando que estava no PC. O
comando funcionou e me deu a verdade — só que a verdade daquela máquina, onde o
meu `config` não existe. A própria saída denunciava: caminhos `/home/opc/...` em
vez de `C:\Users\...`.

Custou uma tela de texto. O mesmo deslize com `rm -rf`, `systemctl stop` ou
`docker system prune` custa um domingo. **Executar o comando certo na máquina
errada** é origem clássica de incidente real.

Na dúvida, pergunto para a máquina:

```bash
hostname
```

Em ambiente sério dá para mudar a cor do prompt por máquina — verde no lab,
vermelho em produção — para o olho bater na cor antes de o dedo apertar Enter.

## Confiar no servidor na primeira conexão (TOFU)

Ao conectar num host novo, o SSH avisa que não conhece aquela máquina e mostra
um fingerprint. Isso é **TOFU** — *Trust On First Use*.

O certo é **comparar o fingerprint com o que o dono publica** (no console do
provedor, no caso de uma VM; na documentação oficial, no caso do GitHub). Aceitar
sem conferir é a brecha para um ataque *man-in-the-middle*.

Depois do `yes`, o fingerprint vai para o `~/.ssh/known_hosts`. Se um dia ele
mudar, o SSH grita com `REMOTE HOST IDENTIFICATION HAS CHANGED`.

## Comandos que uso

| Comando | Para quê |
|---|---|
| `ssh-keygen -t ed25519 -C "comentario" -f ~/.ssh/nome` | criar um par de chaves com nome próprio |
| `ssh-keygen -lf ~/.ssh/nome.pub` | ver o fingerprint da chave |
| `cat ~/.ssh/nome.pub` | ler a chave pública (a que se cadastra) |
| `ssh apelido` | conectar usando o `~/.ssh/config` |
| `ssh -G apelido` | ver a configuração resolvida, sem conectar |
| `ssh -v apelido` | acompanhar a negociação passo a passo (diagnóstico) |
| `ssh -T git@github.com` | testar autenticação no GitHub |
| `hostname` | confirmar em qual máquina estou |
| `chmod 600 ~/.ssh/chave` | fechar a permissão da chave privada |

### Lendo a saída do `ssh -v`

| Linha | O que significa |
|---|---|
| `Connection established` | a rede funcionou — não é firewall |
| `Offering public key: ...` | meu PC ofereceu essa chave |
| `Server accepts key` | o servidor aceitou |
| `Authentications that can continue: publickey` | recusou e está pedindo outra coisa |