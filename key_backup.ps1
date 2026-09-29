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
 
$DebianIP    = "azazaz.bejinfor.pt"
$DebianAdmin = "debian"
$SFTPUser    = "backup"
$SFTPHome    = "/var/backups"
 
# Opcional: chave do admin (deixar vazio para usar password ou a chave por defeito)
$AdminKey = ""
 
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
$PublicKey  = "$PrivateKey.pub"   # o ssh-keygen cria sempre <ficheiro>.pub
 
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
 
if ((Test-Path $PrivateKey) -or (Test-Path $PublicKey)) {
    Write-Host "ERRO: Já existe uma chave em:" -ForegroundColor Red
    Write-Host $PrivateKey -ForegroundColor Red
    Write-Host ""
    Write-Host "A chave existente NÃO será substituída." -ForegroundColor Yellow
    exit 1
}
 
# ------------------------------------------
# VERIFICAR FERRAMENTAS
# ------------------------------------------
 
foreach ($cmd in @("ssh-keygen", "ssh", "scp")) {
    if (-not (Get-Command $cmd -ErrorAction SilentlyContinue)) {
        Write-Host ""
        Write-Host "ERRO: '$cmd' não está instalado ou não está no PATH." -ForegroundColor Red
        exit 1
    }
}
 
# ------------------------------------------
# GERAR CHAVE (sem passphrase, para automação)
# ------------------------------------------
 
Write-Host ""
Write-Host "A gerar a chave ED25519..." -ForegroundColor Yellow
Write-Host ""
 
# Windows PowerShell 5.1 precisa de '""'; PowerShell 7.3+ precisa de ''
$EmptyPass = if ($PSVersionTable.PSVersion.Major -ge 7) { '' } else { '""' }
 
ssh-keygen -t ed25519 -f $PrivateKey -C $Cliente -N $EmptyPass
 
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
 
# Nome temporário único no servidor (evita colisões entre clientes)
$RemoteTmp = "/tmp/sqlbackup_$([guid]::NewGuid().ToString('N')).pub"
 
$SshOpts = @()
if (-not [string]::IsNullOrWhiteSpace($AdminKey)) {
    $SshOpts += @("-i", $AdminKey)
}
 
Write-Host "A enviar a chave pública para o Debian..." -ForegroundColor Yellow
Write-Host ""
 
scp @SshOpts $PublicKey "${DebianAdmin}@${DebianIP}:$RemoteTmp"
 
if ($LASTEXITCODE -ne 0) {
    Write-Host ""
    Write-Host "ERRO: Não foi possível enviar a chave para o Debian." -ForegroundColor Red
    exit 1
}
 
Write-Host ""
Write-Host "Chave pública enviada para $RemoteTmp" -ForegroundColor Green
 
# ------------------------------------------
# INSTALAR NO AUTHORIZED_KEYS
# ------------------------------------------
 
Write-Host ""
Write-Host "A instalar a chave para o utilizador '$SFTPUser'..." -ForegroundColor Yellow
Write-Host "(se pedido, introduza a password do utilizador '$DebianAdmin' para o sudo)"
Write-Host ""
 
$RemoteLines = @(
    "set -e",
    "sudo install -d -m 700 -o $SFTPUser -g $SFTPUser $SFTPHome/.ssh",
    "sudo touch $SFTPHome/.ssh/authorized_keys",
    "sudo grep -qxF -f $RemoteTmp $SFTPHome/.ssh/authorized_keys || sudo tee -a $SFTPHome/.ssh/authorized_keys < $RemoteTmp > /dev/null",
    "sudo chown -R ${SFTPUser}:${SFTPUser} $SFTPHome/.ssh",
    "sudo chmod 700 $SFTPHome/.ssh",
    "sudo chmod 600 $SFTPHome/.ssh/authorized_keys",
    "rm -f $RemoteTmp"
)
 
# Uma só linha, separada por ';' -> sem problemas de CRLF
$RemoteCommand = $RemoteLines -join "; "
 
# -t: permite ao sudo pedir password
ssh -t @SshOpts "${DebianAdmin}@${DebianIP}" $RemoteCommand
 
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
Write-Host "$SFTPHome/.ssh/authorized_keys"
 
Write-Host ""
Write-Host "IMPORTANTE:" -ForegroundColor Red
Write-Host "A chave privada sqlbackup.pri NÃO foi enviada para o Debian."
Write-Host "Mantenha-a neste computador."
Write-Host ""
