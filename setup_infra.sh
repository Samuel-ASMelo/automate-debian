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
declare -A users=(
    ["dev1"]="desenvolvedores"
    ["dev2"]="desenvolvedores"
    ["ops1"]="operacoes"
    ["ops2"]="operacoes"
    ["techlead"]="desenvolvedores"
)
techlead_extra_group="operacoes"
password="abc@123"

for user in "${!users[@]}"; do
    if ! id "$user" &>/dev/null; then
        primary_group=${users[$user]}
        if [[ "$user" == "techlead" ]]; then
            sudo useradd -m -g "$primary_group" -G "$techlead_extra_group" "$user"
        else
            sudo useradd -m -g "$primary_group" "$user"
        fi
        echo "Usuário '$user' criado e atribuído ao grupo '$primary_group' com sucesso."
    else
        echo "Usuário '$user' já existe. Nenhuma ação necessária."
    fi
    # Definindo senhas
    if sudo passwd -S "$user" | grep -q "P"; then
        echo "Senha para o usuário '$user' já está configurada. Nenhuma ação necessária."
    else
        echo "$user:$password" | sudo chpasswd
        echo "Senha para o usuário '$user' definida com sucesso."
    fi
done

# ------------------------------------------------------------------------------
# 6.3. Permissões sobre arquivos
# ------------------------------------------------------------------------------
echo "--- Verificando e configurando diretórios e permissões ---"
dir="/srv/app"
group="desenvolvedores"

# Criando o diretorio
if [ ! -d "$dir" ]; then
    sudo mkdir -p "$dir"
    echo "Diretório '$dir' criado com sucesso."
else
    echo "Diretório '$dir' já existe. Nenhuma ação necessária."
fi

# Definindo o grupo dono
current_group=$(stat -c '%G' "$dir")
if [ "$current_group" != "$group" ]; then
    sudo chown :"$group" "$dir"
    echo "Grupo dono de '$dir' definido como '$group' com sucesso."
else
    echo "Grupo dono de '$dir' já é '$group'. Nenhuma ação necessária."
fi

# Concedendo permissoes e ativando o bit setgid
current_perms=$(stat -c '%a' "$dir")
if [ "$current_perms" != "2770" ]; then
    sudo chmod 2770 "$dir"
    echo "Permissões de '$dir' definidas como '2770' com sucesso."
else
    echo "Permissões de '$dir' já são '2770'. Nenhuma ação necessária."
fi

# Usando ACL para conceder permissoes ao grupo 'operacoes'
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

# Atualizando a lista de pacotes
if sudo apt-get update; then
    echo "Lista de pacotes atualizada com sucesso."
fi

# Instalando Apache
if ! dpkg -s apache2 &>/dev/null; then
    sudo apt-get install -y apache2
    echo "Apache instalado com sucesso."
else
    echo "Apache já está instalado. Nenhuma ação necessária."
fi

# Instalando UFW
if ! dpkg -s ufw &>/dev/null; then
    sudo apt-get install -y ufw
    echo "UFW instalado com sucesso."
else
    echo "UFW já está instalado. Nenhuma ação necessária."
fi

# Instalando Quota
if ! dpkg -s quota &>/dev/null; then
    sudo apt-get install -y quota
    echo "Quota instalado com sucesso."
else
    echo "Quota já está instalado. Nenhuma ação necessária."
fi

# Criando a pagina HTML de teste
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

# Corrigindo o grupo dono do arquivo para os desenvolvedores
file_group=$(stat -c '%G' "$html_file")
if [ "$file_group" != "$group" ]; then
    sudo chown :"$group" "$html_file"
    echo "Grupo dono de '$html_file' definido como '$group' com sucesso."
else
    echo "Grupo dono de '$html_file' já é '$group'. Nenhuma ação necessária."
fi

# Concedendo ACL para o grupo 'operacoes' no arquivo
if ! getfacl "$html_file" | grep -q "group:operacoes:r-x"; then
    sudo setfacl -m g:operacoes:r-x "$html_file"
    echo "ACL para o grupo 'operacoes' em '$html_file' aplicada com sucesso."
else
    echo "ACL para o grupo 'operacoes' em '$html_file' já existe. Nenhuma ação necessária."
fi

# Alterando o DocumentRoot do Apache
apache_conf="/etc/apache2/sites-available/000-default.conf"
if ! grep -q "DocumentRoot /srv/app" "$apache_conf"; then
    sudo sed -i 's|DocumentRoot /var/www/html|DocumentRoot /srv/app|g' "$apache_conf"
    echo "DocumentRoot do Apache alterado com sucesso."
else
    echo "DocumentRoot do Apache já está configurado. Nenhuma ação necessária."
fi

# Adicionando um bloco de permissoes para o novo diretorio
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

# Concedendo ACL para o usuario do Apache
if ! getfacl "$dir" | grep -q "user:www-data:r-x"; then
    sudo setfacl -m u:www-data:r-x "$dir"
    echo "ACL para o usuario 'www-data' em '$dir' aplicada com sucesso."
else
    echo "ACL para o usuario 'www-data' em '$dir' já existe. Nenhuma ação necessária."
fi

# Reiniciando o Apache para que a nova permissao seja reconhecida
if systemctl is-active --quiet apache2; then
    echo "Reiniciando o serviço Apache para aplicar as mudanças..."
    sudo systemctl restart apache2
    echo "Serviço Apache reiniciado com sucesso."
else
    echo "Serviço Apache não está ativo, ignorando reinício."
fi

# Configurando o firewall UFW
echo "Configurando o firewall UFW..."

# 1. Checa e define a política padrão de entrada (deny)
if ! sudo ufw status verbose | grep -q "Default: deny (incoming)"; then
    sudo ufw default deny incoming
    echo "Política de entrada do UFW definida para 'deny' com sucesso."
else
    echo "Política de entrada do UFW já está configurada para 'deny'. Nenhuma ação necessária."
fi

# 2. Checa e define a política padrão de saída (allow)
if ! sudo ufw status verbose | grep -q "Default: allow (outgoing)"; then
    sudo ufw default allow outgoing
    echo "Política de saída do UFW definida para 'allow' com sucesso."
else
    echo "Política de saída do UFW já está configurada para 'allow'. Nenhuma ação necessária."
fi

# 3. Checa e permite o tráfego SSH
if ! sudo ufw status | grep -q "OpenSSH"; then
    sudo ufw allow ssh
    echo "Regra para SSH adicionada com sucesso."
else
    echo "Regra para SSH já existe. Nenhuma ação necessária."
fi

# 4. Checa e permite o tráfego HTTP
if ! sudo ufw status | grep -q "WWW"; then
    sudo ufw allow http
    echo "Regra para HTTP adicionada com sucesso."
else
    echo "Regra para HTTP já existe. Nenhuma ação necessária."
fi

# 5. Habilita o firewall
if ! sudo ufw status | grep -q "Status: active"; then
    sudo ufw --force enable
    echo "Firewall UFW ativado com sucesso."
else
    echo "Firewall UFW já está ativo. Nenhuma ação necessária."
fi

echo "Configuração Concluída."
