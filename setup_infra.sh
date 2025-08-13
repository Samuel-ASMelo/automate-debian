#!/bin/bash

# ==============================================================================
# SCRIPT DE AUTOMACAO DE INFRAESTRUTURA
# ==============================================================================
# Este script automatiza a criacao de usuarios, grupos, diretorios,
# permissoes e a instalacao e configuracao inicial de pacotes (Apache, UFW).
#
# As tarefas que requerem intervencao manual estao detalhadas no arquivo README.md.
# ==============================================================================

echo "Iniciando a configuracao de infraestrutura..."

# ------------------------------------------------------------------------------
# 6.1. Criação de grupos e contas
# ------------------------------------------------------------------------------
echo "--- Verificando e criando grupos e usuários ---"

# Criando o grupo 'desenvolvedores'
if ! getent group desenvolvedores > /dev/null; then
    sudo groupadd desenvolvedores
    echo "Grupo 'desenvolvedores' criado com sucesso."
else
    echo "Grupo 'desenvolvedores' já existe. Nenhuma ação necessária."
fi

# Criando o grupo 'operacoes'
if ! getent group operacoes > /dev/null; then
    sudo groupadd operacoes
    echo "Grupo 'operacoes' criado com sucesso."
else
    echo "Grupo 'operacoes' já existe. Nenhuma ação necessária."
fi

# Criando usuários e atribuindo-os aos grupos
echo "Criando usuários..."
USERS=(
    "dev1:desenvolvedores"
    "dev2:desenvolvedores"
    "ops1:operacoes"
    "ops2:operacoes"
    "techlead:desenvolvedores:operacoes"
)
password="abc@123"

for user_info in "${USERS[@]}"; do
    IFS=':' read -r user_name primary_group extra_group <<< "$user_info"
    
    if ! id "$user_name" &>/dev/null; then
        if [ -n "$extra_group" ]; then
            sudo useradd -m -g "$primary_group" -G "$extra_group" "$user_name"
        else
            sudo useradd -m -g "$primary_group" "$user_name"
        fi
        echo "Usuário '$user_name' criado com sucesso."
    else
        echo "Usuário '$user_name' já existe. Nenhuma ação necessária."
    fi

    if ! sudo passwd -S "$user_name" | grep -q "P"; then
        echo "$user_name:$password" | sudo chpasswd
        echo "Senha para o usuário '$user_name' definida com sucesso."
    else
        echo "Senha para o usuário '$user_name' já está configurada. Nenhuma ação necessária."
    fi
done

# ------------------------------------------------------------------------------
# 6.3. Permissões sobre arquivos
# ------------------------------------------------------------------------------
echo "--- Verificando e configurando diretórios e permissões ---"
dir="/srv/app"
group="desenvolvedores"

if [ ! -d "$dir" ]; then
    sudo mkdir -p "$dir"
    echo "Diretório '$dir' criado com sucesso."
else
    echo "Diretório '$dir' já existe. Nenhuma ação necessária."
fi

current_group=$(stat -c '%G' "$dir")
if [ "$current_group" != "$group" ]; then
    sudo chown :"$group" "$dir"
    echo "Grupo dono de '$dir' definido como '$group' com sucesso."
else
    echo "Grupo dono de '$dir' já é '$group'. Nenhuma ação necessária."
fi

current_perms=$(stat -c '%a' "$dir")
if [ "$current_perms" != "2770" ]; then
    sudo chmod 2770 "$dir"
    echo "Permissões de '$dir' definidas como '2770' com sucesso."
else
    echo "Permissões de '$dir' já são '2770'. Nenhuma ação necessária."
fi

if ! getfacl "$dir" | grep -q "group:operacoes:r-x"; then
    sudo setfacl -m g:operacoes:r-x "$dir"
    echo "ACL para o grupo 'operacoes' em '$dir' aplicada com sucesso."
else
    echo "ACL para o grupo 'operacoes' em '$dir' já existe. Nenhuma ação necessária."
fi

echo "Diretório /srv/app configurado com sucesso."

# ------------------------------------------------------------------------------
# 6.7. Manutenção de pacotes
# ------------------------------------------------------------------------------
echo "--- Verificando e instalando pacotes e configurações ---"

if sudo apt-get update; then
    echo "Lista de pacotes atualizada com sucesso."
fi

if ! dpkg -s apache2 &>/dev/null; then
    sudo apt-get install -y apache2
    echo "Apache instalado com sucesso."
else
    echo "Apache já está instalado. Nenhuma ação necessária."
fi

if ! dpkg -s ufw &>/dev/null; then
    sudo apt-get install -y ufw
    echo "UFW instalado com sucesso."
else
    echo "UFW já está instalado. Nenhuma ação necessária."
fi

if ! dpkg -s quota &>/dev/null; then
    sudo apt-get install -y quota
    echo "Quota instalado com sucesso."
else
    echo "Quota já está instalado. Nenhuma ação necessária."
fi

html_file="/srv/app/index.html"
if [ ! -f "$html_file" ]; then
    sudo tee "$html_file" > /dev/null << EOF
<!DOCTYPE html>
<html>
<head>
    <meta charset="UTF-8">
    <title>Servidor Apache</title>
</head>
<body>
    <h1>Bem-vindo ao meu servidor Apache!</h1>
    <p>Esta é a pagina inicial do diretorio /srv/app/.</p>
</body>
</html>
EOF
    echo "Arquivo '$html_file' criado com sucesso."
else
    echo "Arquivo '$html_file' já existe. Nenhuma ação necessária."
fi

file_group=$(stat -c '%G' "$html_file")
if [ "$file_group" != "$group" ]; then
    sudo chown :"$group" "$html_file"
    echo "Grupo dono de '$html_file' definido como '$group' com sucesso."
else
    echo "Grupo dono de '$html_file' já é '$group'. Nenhuma ação necessária."
fi

if ! getfacl "$html_file" | grep -q "group:operacoes:r-x"; then
    sudo setfacl -m g:operacoes:r-x "$html_file"
    echo "ACL para o grupo 'operacoes' em '$html_file' aplicada com sucesso."
else
    echo "ACL para o grupo 'operacoes' em '$html_file' já existe. Nenhuma ação necessária."
fi

apache_conf="/etc/apache2/sites-available/000-default.conf"
if ! grep -q "DocumentRoot /srv/app" "$apache_conf"; then
    sudo sed -i 's|DocumentRoot /var/www/html|DocumentRoot /srv/app|g' "$apache_conf"
    echo "DocumentRoot do Apache alterado com sucesso."
else
    echo "DocumentRoot do Apache já está configurado. Nenhuma ação necessária."
fi

if ! grep -q "<Directory /srv/app/>" "$apache_conf"; then
    sudo sed -i '/<Directory \/var\/www\/>/i <Directory \/srv\/app\/>\n    Options Indexes FollowSymLinks\n    AllowOverride None\n    Require all granted\n</Directory>' "$apache_conf"
    echo "Bloco de permissões para /srv/app/ adicionado com sucesso."
else
    echo "Bloco de permissões para /srv/app/ já existe. Nenhuma ação necessária."
fi

# ------------------------------------------------------------------------------
# 6.5. Configurações de rede e segurança de servicos
# ------------------------------------------------------------------------------
echo "--- Configurando permissões de serviço e firewall ---"

if ! getfacl "$dir" | grep -q "user:www-data:r-x"; then
    sudo setfacl -m u:www-data:r-x "$dir"
    echo "ACL para o usuario 'www-data' em '$dir' aplicada com sucesso."
else
    echo "ACL para o usuario 'www-data' em '$dir' já existe. Nenhuma ação necessária."
fi

if systemctl is-active --quiet apache2; then
    echo "Reiniciando o serviço Apache para aplicar as mudanças..."
    sudo systemctl restart apache2
    echo "Serviço Apache reiniciado com sucesso."
else
    echo "Serviço Apache não está ativo, ignorando reinício."
fi

echo "Configurando o firewall UFW..."

if ! sudo ufw status verbose | grep -q "Default: deny (incoming)"; then
    sudo ufw default deny incoming
    echo "Política de entrada do UFW definida para 'deny' com sucesso."
else
    echo "Política de entrada do UFW já está configurada para 'deny'. Nenhuma ação necessária."
fi

if ! sudo ufw status verbose | grep -q "Default: allow (outgoing)"; then
    sudo ufw default allow outgoing
    echo "Política de saída do UFW definida para 'allow' com sucesso."
else
    echo "Política de saída do UFW já está configurada para 'allow'. Nenhuma ação necessária."
fi

if ! sudo ufw status | grep -q "OpenSSH"; then
    sudo ufw allow ssh
    echo "Regra para SSH adicionada com sucesso."
else
    echo "Regra para SSH já existe. Nenhuma ação necessária."
fi

if ! sudo ufw status | grep -q "WWW"; then
    sudo ufw allow http
    echo "Regra para HTTP adicionada com sucesso."
else
    echo "Regra para HTTP já existe. Nenhuma ação necessária."
fi

if ! sudo ufw status | grep -q "Status: active"; then
    sudo ufw --force enable
    echo "Firewall UFW ativado com sucesso."
else
    echo "Firewall UFW já está ativo. Nenhuma ação necessária."
fi

echo "Configuração Concluída."
