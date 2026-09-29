# Script-powershell-
Esta script PowerShell automatiza a criação e configuração de uma chave SSH para o sistema de backups SQL, permitindo que a chave pública seja enviada e configurada automaticamente no servidor Debian.
# SQL Backup SSH Key Generator

Script PowerShell para gerar automaticamente um par de chaves SSH **Ed25519** destinado à autenticação de um servidor de backups através de **SFTP**.

O objetivo é facilitar a configuração de autenticação por chave SSH para ferramentas de backup, como o **SQL Backup Master**, sem necessidade de utilizar palavras-passe.

##  Funcionalidades

* Geração automática de uma chave SSH Ed25519.
* Criação da pasta `.ssh` caso não exista.
* Guarda da chave privada e chave pública no perfil do utilizador.
* Verificação da existência de chaves anteriores.
* Apresentação da chave pública no final da execução.
* Utilização da chave pública no servidor SFTP.
* Compatível com autenticação SSH por chave.

##  Como funciona

O script gera duas chaves:

```text
sqlbackup.pri
sqlbackup.pri.pub
```

A chave privada:

```text
sqlbackup.pri
```

deve permanecer **apenas no computador que realiza os backups**.

A chave pública:

```text
sqlbackup.pri.pub
```

é instalada no servidor Debian, no ficheiro:

```text
~backup/.ssh/authorized_keys
```

O servidor utiliza a chave pública para verificar a autenticidade da chave privada apresentada pelo cliente.

>  Nunca partilhe ou copie a chave privada para o servidor.

##  Requisitos

### Cliente

* PowerShell
* OpenSSH Client
* Permissões para executar `ssh-keygen`

### Servidor

* Debian ou outra distribuição Linux com OpenSSH Server
* Conta `backup`
* Serviço SSH ativo
* SFTP através do OpenSSH

##  Instalação

### 1. Instalar o OpenSSH Client

Verifique primeiro se o comando está disponível:

```powershell
ssh-keygen
```

Se aparecer uma mensagem semelhante a:

```text
'ssh-keygen' is not recognized...
```

é necessário instalar/configurar o OpenSSH Client no Windows.

Depois de instalado, confirme novamente:

```powershell
ssh-keygen -V
```

##  Gerar as chaves

Execute o script PowerShell:

```powershell
.\generate-sqlbackup-key.ps1
```

O script irá criar:

```text
%USERPROFILE%\.ssh\sqlbackup.pri
%USERPROFILE%\.ssh\sqlbackup.pri.pub
```

Por exemplo:

```text
C:\Users\Administrator\.ssh\
├── sqlbackup.pri
└── sqlbackup.pri.pub
```

##  Instalar a chave pública no servidor

Visualize a chave pública:

```powershell
Get-Content "$env:USERPROFILE\.ssh\sqlbackup.pri.pub"
```

Copie **toda a linha** apresentada.

No servidor Debian, adicione-a ao:

```bash
/home/backup/.ssh/authorized_keys
```

ou ao caminho configurado no `sshd_config`.

Exemplo:

```bash
sudo nano /home/backup/.ssh/authorized_keys
```

Cole a chave pública numa única linha.

Depois configure as permissões:

```bash
sudo chmod 700 /home/backup/.ssh
sudo chmod 600 /home/backup/.ssh/authorized_keys
sudo chown -R backup:backup /home/backup/.ssh
```

##  Configuração SFTP

O servidor pode ser configurado para permitir que a conta `backup` utilize apenas SFTP.

Exemplo:

```text
Match User backup
    ForceCommand internal-sftp
    PasswordAuthentication no
    PubkeyAuthentication yes
    ChrootDirectory /srv/sftp
```

Depois de alterar a configuração, valide-a:

```bash
sudo sshd -t
```

Se não forem apresentados erros, reinicie o SSH:

```bash
sudo systemctl restart ssh
```

##  Testar a ligação

No Windows, teste a autenticação utilizando a chave privada:

```powershell
sftp -i "$env:USERPROFILE\.ssh\sqlbackup.pri" backup@IP_DO_SERVIDOR
```

Exemplo:

```powershell
sftp -i "$env:USERPROFILE\.ssh\sqlbackup.pri" backup@10.0.3.2
```

Se a autenticação funcionar, deverá aparecer:

```text
sftp>
```

Pode testar:

```text
ls
```

e:

```text
pwd
```

##  Diretório dos backups

No servidor, os backups podem ser armazenados em:

```text
/srv/sftp/backups
```

Quando a conta estiver configurada com:

```text
ChrootDirectory /srv/sftp
```

o utilizador `backup` verá `/srv/sftp` como `/`.

Assim, no cliente SFTP, o diretório:

```text
/srv/sftp/backups
```

pode aparecer simplesmente como:

```text
/backups
```

##  Segurança da chave privada

A chave privada é um ficheiro sensível.

**Nunca:**

* Coloque a chave privada no GitHub.
* Envie a chave privada por email.
* Copie a chave privada para o servidor SFTP.
* Partilhe a chave privada com outros utilizadores.

Apenas a chave pública deve ser instalada no servidor:

```text
sqlbackup.pri.pub
```

A chave privada deve permanecer no computador responsável pelos backups:

```text
sqlbackup.pri
```

##  Estrutura do projeto

```text
SQL-Backup-SSH-Key-Generator/
│
├── generate-sqlbackup-key.ps1
├── README.md
└── LICENSE
```

##  Importante para o Git

Antes de fazer `git push`, recomenda-se adicionar um `.gitignore` para evitar que chaves privadas sejam adicionadas acidentalmente:

```gitignore
# SSH private keys
*.pri
*.pem
*.key

# Public SSH keys
# *.pub
```

A chave pública pode ser incluída no projeto se necessário, mas **a chave privada nunca deve ser incluída**.

##  Licença

Este projeto é disponibilizado sob a licença MIT.
