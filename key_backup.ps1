# ==========================================
# Gerar e enviar chave SSH para SQL Backup
# ==========================================

$ErrorActionPreference = "Stop"

Write-Host ""
Write-Host "==========================================" -ForegroundColor Cyan
Write-Host "    GERADOR DE CHAVE SQL BACKUP"
Write-Host "==========================================" -ForegroundColor Cyan
Write-Host ""

# ------------------------------------------
# CONFIGURAÇÃO DO SERVIDOR DEBIAN
# ------------------------------------------

$DebianIP = "azazaz.bejinfor.pt"
$DebianAdmin = "debian"
$SFTPUser = "backup"

# ------------------------------------------
# PEDIR NOME DO CLIENTE
# ------------------------------------------

$Cliente = Read-Host "Introduza o nome do cliente"

if ([string]::IsNullOrWhiteSpace($Cliente)) {
    Write-Host ""
    Write-Host "ERRO: O nome do cliente não pode ficar vazio." -ForegroundColor Red
    exit 1
}

# ------------------------------------------
# CAMINHOS DA CHAVE
# ------------------------------------------

$SSHDir = Join-Path $env:USERPROFILE ".ssh"

$PrivateKey = Join-Path $SSHDir "sqlbackup.pri"
$PublicKey  = Join-Path $SSHDir "sqlbackup.pub"

# Criar .ssh se não existir
if (-not (Test-Path $SSHDir)) {
    New-Item -ItemType Directory -Path $SSHDir -Force | Out-Null
}

Write-Host ""
Write-Host "Cliente: $Cliente"
Write-Host "Chave privada: $PrivateKey"
Write-Host "Chave pública: $PublicKey"
Write-Host ""

# ------------------------------------------
# VERIFICAR SE JÁ EXISTE
# ------------------------------------------

if (Test-Path $PrivateKey) {

    Write-Host "ERRO: Já existe uma chave em:" -ForegroundColor Red
    Write-Host $PrivateKey -ForegroundColor Red
    Write-Host ""

    Write-Host "A chave existente NÃO será substituída." -ForegroundColor Yellow

    exit 1
}

# ------------------------------------------
# VERIFICAR SSH-KEYGEN
# ------------------------------------------

if (-not (Get-Command ssh-keygen -ErrorAction SilentlyContinue)) {

    Write-Host ""
    Write-Host "ERRO: ssh-keygen não está instalado ou não está no PATH." -ForegroundColor Red
    exit 1
}

# ------------------------------------------
# GERAR CHAVE
# ------------------------------------------

Write-Host ""
Write-Host "A gerar a chave ED25519..." -ForegroundColor Yellow
Write-Host ""

ssh-keygen `
    -t ed25519 `
    -f "$PrivateKey" `
    -C "$Cliente"

if ($LASTEXITCODE -ne 0) {

    Write-Host ""
    Write-Host "ERRO: Não foi possível criar a chave." -ForegroundColor Red

    exit 1
}

# ------------------------------------------
# MOSTRAR CHAVES
# ------------------------------------------

Write-Host ""
Write-Host "==========================================" -ForegroundColor Green
Write-Host "       CHAVE CRIADA COM SUCESSO"
Write-Host "==========================================" -ForegroundColor Green
Write-Host ""

Write-Host "Chave PRIVADA:" -ForegroundColor Yellow
Write-Host $PrivateKey

Write-Host ""
Write-Host "Chave PÚBLICA:" -ForegroundColor Yellow
Write-Host $PublicKey

Write-Host ""
Write-Host "Conteúdo da chave pública:" -ForegroundColor Cyan
Write-Host ""

Get-Content $PublicKey

# ------------------------------------------
# ENVIAR CHAVE PARA O DEBIAN
# ------------------------------------------

Write-Host ""
Write-Host "==========================================" -ForegroundColor Cyan
Write-Host "        ENVIO PARA O SERVIDOR DEBIAN"
Write-Host "==========================================" -ForegroundColor Cyan
Write-Host ""

Write-Host "Servidor: $DebianIP"
Write-Host "Utilizador administrativo: $DebianAdmin"
Write-Host ""

Write-Host "A enviar sqlbackup.pub para o Debian..." -ForegroundColor Yellow
Write-Host ""

scp "$PublicKey" "${DebianAdmin}@${DebianIP}:/tmp/sqlbackup.pub"

if ($LASTEXITCODE -ne 0) {

    Write-Host ""
    Write-Host "ERRO: Não foi possível enviar a chave para o Debian." -ForegroundColor Red
    exit 1
}

Write-Host ""
Write-Host "Chave pública enviada para /tmp/sqlbackup.pub" -ForegroundColor Green

# ------------------------------------------
# INSTALAR NO AUTHORIZED_KEYS
# ------------------------------------------

Write-Host ""
Write-Host "A instalar a chave para o utilizador '$SFTPUser'..." -ForegroundColor Yellow
Write-Host ""

$RemoteCommand = @"
sudo mkdir -p /var/backups/.ssh
sudo touch /var/backups/.ssh/authorized_keys
sudo chmod 700 /var/backups/.ssh
sudo chmod 600 /var/backups/.ssh/authorized_keys
sudo chown -R backup:backup /var/backups/.ssh
sudo grep -qxF "`$(cat /tmp/sqlbackup.pub)" /var/backups/.ssh/authorized_keys || sudo sh -c 'cat /tmp/sqlbackup.pub >> /var/backups/.ssh/authorized_keys'
sudo chown -R backup:backup /var/backups/.ssh
sudo chmod 700 /var/backups/.ssh
sudo chmod 600 /var/backups/.ssh/authorized_keys
sudo rm -f /tmp/sqlbackup.pub
"@

ssh "${DebianAdmin}@${DebianIP}" $RemoteCommand

if ($LASTEXITCODE -ne 0) {

    Write-Host ""
    Write-Host "ERRO: Não foi possível instalar a chave no Debian." -ForegroundColor Red
    exit 1
}

# ------------------------------------------
# FINAL
# ------------------------------------------

Write-Host ""
Write-Host "==========================================" -ForegroundColor Green
Write-Host "       CONFIGURAÇÃO CONCLUÍDA"
Write-Host "==========================================" -ForegroundColor Green
Write-Host ""

Write-Host "Chave privada:" -ForegroundColor Yellow
Write-Host $PrivateKey

Write-Host ""
Write-Host "Chave pública enviada para o Debian." -ForegroundColor Green

Write-Host ""
Write-Host "A chave foi instalada em:" -ForegroundColor Green
Write-Host "/var/backups/.ssh/authorized_keys"

Write-Host ""
Write-Host "IMPORTANTE:" -ForegroundColor Red
Write-Host "A chave privada sqlbackup.pri NÃO foi enviada para o Debian."
Write-Host "Mantenha-a neste computador."
Write-Host ""