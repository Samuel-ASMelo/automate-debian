#!/bin/bash

# ==============================================================================
# SCRIPT DE AUTOMACAO DE INFRAESTRUTURA
# ==============================================================================
# Este script automatiza a criacao de usuarios, grupos, diretorios,
# permissoes e a instalacao e configuracao inicial de pacotes (Apache, UFW).
#
# As tarefas que requerem intervencao manual estao detalhadas em comentarios.
# ==============================================================================

echo "Iniciando a configuracao de infraestrutura..."

# ------------------------------------------------------------------------------
# 6.1.Criação de grupos e contas
# ------------------------------------------------------------------------------
# Criando os grupos 'desenvolvedores' e 'operacoes'.
echo "Criando grupos de usuarios..."
sudo groupadd desenvolvedores
sudo groupadd operacoes

# Criando usuarios e adicionando-os aos grupos.
echo "Criando usuarios e atribuindo-os aos grupos..."
sudo useradd -m -g desenvolvedores dev1
sudo useradd -m -g desenvolvedores dev2
sudo useradd -m -g operacoes ops1
sudo useradd -m -g operacoes ops2
sudo useradd -m -g desenvolvedores -G operacoes techlead

echo "Grupos e usuarios criados com sucesso."

# ------------------------------------------------------------------------------
# 6.3.Permissões sobre arquivos
# ------------------------------------------------------------------------------
# Criando o diretorio para a aplicacao e definindo as permissoes.
echo "Criando diretorio /srv/app e ajustando permissoes..."
sudo mkdir -p /srv/app

# Definindo 'desenvolvedores' como o grupo dono do diretorio.
sudo chown :desenvolvedores /srv/app

# Concedendo permissoes de leitura/escrita/execucao ao grupo dono
# e ativando o bit setgid (o '2' no inicio) para heranca de grupo.
sudo chmod 2770 /srv/app

# Usando ACL para conceder permissoes de leitura e execucao ao grupo 'operacoes'.
sudo setfacl -m g:operacoes:r-x /srv/app

echo "Diretorio /srv/app configurado com sucesso."

# ------------------------------------------------------------------------------
# 6.7. Manutenção de pacotes
# ------------------------------------------------------------------------------
# Atualizando a lista de pacotes e instalando Apache, UFW e Quota.
echo "Atualizando pacotes e instalando Apache, UFW, Quota..."
sudo apt-get update
sudo apt-get install -y apache2 ufw quota

# Criando uma pagina HTML de teste.
echo "Configurando Apache..."
sudo mkdir -p /srv/app
sudo cat << EOF > /srv/app/index.html
<!DOCTYPE html>
<html>
<head>
    <title>Servidor Apache</title>
</head>
<body>
    <h1>Bem-vindo ao meu servidor Apache!</h1>
    <p>Esta é a pagina inicial do diretório /srv/app/.</p>
</body>
</html>
EOF

# Alterando o DocumentRoot do Apache para o novo diretorio.
sudo sed -i 's|DocumentRoot /var/www/html|DocumentRoot /srv/app|g' /etc/apache2/sites-available/000-default.conf

# Adicionando um bloco de permissoes para o novo diretorio.
sudo sed -i '/<Directory \/var\/www\/>/i <Directory \/srv\/app\/>\n    Options Indexes FollowSymLinks\n    AllowOverride None\n    Require all granted\n</Directory>' /etc/apache2/sites-available/000-default.conf

# Reiniciando o servico do Apache para aplicar as mudancas.
sudo systemctl restart apache2

# ------------------------------------------------------------------------------
# 6.5. Configurações de rede
# ------------------------------------------------------------------------------
echo "Configurando o firewall UFW..."

# Definindo a politica padrao: nega entrada, permite saida.
sudo ufw default deny incoming
sudo ufw default allow outgoing

# Adicionando regras para as portas permitidas.
sudo ufw allow ssh
sudo ufw allow http

# Habilitando o firewall.
sudo ufw --force enable

echo "Firewall UFW configurado e ativado."

# ------------------------------------------------------------------------------
