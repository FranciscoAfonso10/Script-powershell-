# gerar-chave-sqlbackup.ps1

Script PowerShell que gera um par de chaves SSH (ED25519) para backups SQL e instala a chave pública no servidor Debian, para o utilizador `backup` (SFTP).

## O que faz

1. Pede o nome do cliente, o IP/hostname do servidor e o utilizador administrativo.
2. Gera o par de chaves em `%USERPROFILE%\.ssh\`:
   - `sqlbackup.pri` (chave privada)
   - `sqlbackup.pri.pub` (chave pública)
   - Sem passphrase, para permitir backups automáticos.
   - O nome do cliente fica no comentário da chave.
3. Envia a chave pública para o servidor via `scp` (ficheiro temporário único em `/tmp`).
4. Instala a chave em `/var/backups/.ssh/authorized_keys`, sem duplicados, com as permissões e o dono corretos (`backup:backup`, `700`/`600`).
5. Apaga o ficheiro temporário do servidor.

A chave privada **nunca** sai do computador local.

## Requisitos

- Windows com PowerShell 5.1 ou 7+
- Cliente OpenSSH instalado (`ssh`, `scp`, `ssh-keygen` no PATH)
- Acesso SSH ao servidor com um utilizador administrativo com `sudo`
- Utilizador `backup` já existente no servidor, com home em `/var/backups`

## Utilização

```powershell
.\gerar-chave-sqlbackup.ps1
```

Introduzir, quando pedido:

| Campo | Exemplo |
|---|---|
| Nome do cliente | `ClienteX` |
| IP ou hostname do servidor | `192.168.1.10` |
| Utilizador administrativo | `admin` |

Será pedida a password do utilizador administrativo (SSH e `sudo`), a não ser que tenha chave própria configurada.

## Configuração opcional

No topo do script:

| Variável | Descrição |
|---|---|
| `$SFTPUser` | Utilizador de destino no servidor (por defeito `backup`) |
| `$SFTPHome` | Home desse utilizador (por defeito `/var/backups`) |
| `$AdminKey` | Caminho para a chave do administrador, se existir |

## Notas

- Se `sqlbackup.pri` ou `sqlbackup.pri.pub` já existirem, o script termina sem os substituir.
- Para gerar chaves para outro cliente, mover ou renomear as existentes primeiro.
- Se o servidor só aceitar chave (`PasswordAuthentication no`), o utilizador administrativo tem de ter acesso por chave ou uma exceção `Match User` no `sshd_config`.

## Segurança

- Guardar `sqlbackup.pri` num local protegido e com permissões restritas.
- Como não tem passphrase, quem tiver o ficheiro tem acesso ao SFTP.
- Recomenda-se restringir a chave no `authorized_keys` (por exemplo, `from="IP"`).

Como Ativar a Execução de Scripts
• Abrir como Administrador: Clique no menu Iniciar, escreva PowerShell, clique com o botão direito em Windows PowerShell e escolha Executar como Administrador.
• Ver o estado atual: Digite Get-ExecutionPolicy e prima Enter para ver a regra ativa (por defeito costuma ser Restricted).
• Permitir scripts: Digite o comando Set-ExecutionPolicy RemoteSigned (ou Unrestricted) e prima Enter.
• Confirmar a alteração: Pressione S (ou Sim) para confirmar a mudança de política.
