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
# Bloco de Tarefas Manuais (Comentarios)
# ------------------------------------------------------------------------------
# As tarefas a seguir nao podem ser totalmente automatizadas por
# questoes de seguranca ou dependencia de informacoes especificas
# do ambiente.

# ------------------------------------------------------------------------------
# TAREFA MANUAL 1: Configuracao de Cotas de Disco
# ------------------------------------------------------------------------------
# Para ativar as cotas, e necessario editar o arquivo /etc/fstab.
# A automacao é arriscada porque o nome da particao varia (ex: /dev/sda1).
#
# PASSO A PASSO MANUAL:
# 1. Edite o arquivo '/etc/fstab' e adicione 'usrquota,grpquota' nas opcoes
#    de montagem da particao do sistema de arquivos raiz (/).
#    Exemplo: 'UUID=... / ext4 defaults,usrquota,grpquota 0 1'
#
# 2. Salve o arquivo e, entao, execute os seguintes comandos para ativar as cotas:
#    sudo mount -o remount /
#    sudo quotacheck -cug /
#    sudo quotaon -vug /
#
# 3. Apos a ativacao, voce pode usar os seguintes comandos para definir as cotas:
#    sudo setquota -u dev1 204800 256000 0 0 /
#    sudo setquota -u dev2 204800 256000 0 0 /
#    sudo setquota -u ops1 204800 256000 0 0 /
#    sudo setquota -u ops2 204800 256000 0 0 /
#    sudo setquota -u techlead 204800 256000 0 0 /

# ------------------------------------------------------------------------------
# TAREFA MANUAL 2: Configuracao de Endereco IP Estatico
# ------------------------------------------------------------------------------
# O gateway e os servidores DNS sao especificos da sua rede.
#
# PASSO A PASSO MANUAL:
# 1. Edite o arquivo '/etc/network/interfaces'.
#
# 2. Adicione as seguintes linhas, substituindo os valores pelos da sua rede:
#
#    auto enp0s3
#    iface enp0s3 inet static
#        address 10.0.2.100
#        netmask 255.255.255.0
#        gateway [SEU_GATEWAY_CORRETO]
#        dns-nameservers [SEU_DNS1] [SEU_DNS2]
#
# 3. Apos a edicao, reinicie o servico de rede:
#    sudo systemctl restart networking
# ------------------------------------------------------------------------------