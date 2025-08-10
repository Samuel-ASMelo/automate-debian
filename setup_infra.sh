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

# Definindo a senha inicial 'abc@123' para cada usuario.
# ATENCAO: Esta e uma senha padrao. O administrador deve exigir que os
# usuarios a alterem imediatamente apos o primeiro login para garantir a seguranca.
echo "Definindo senhas iniciais para os novos usuarios..."
echo "dev1:abc@123" | sudo chpasswd
echo "dev2:abc@123" | sudo chpasswd
echo "ops1:abc@123" | sudo chpasswd
echo "ops2:abc@123" | sudo chpasswd
echo "techlead:abc@123" | sudo chpasswd

echo "Grupos e usuarios criados e configurados com sucesso."

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

# Criando uma pagina HTML de teste com codificacao UTF-8 para evitar erros de caracteres.
echo "Configurando Apache..."
sudo mkdir -p /srv/app
sudo cat << EOF > /srv/app/index.html
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

# Alterando o DocumentRoot do Apache para o novo diretorio.
sudo sed -i 's|DocumentRoot /var/www/html|DocumentRoot /srv/app|g' /etc/apache2/sites-available/000-default.conf

# Adicionando um bloco de permissoes para o novo diretorio.
sudo sed -i '/<Directory \/var\/www\/>/i <Directory \/srv\/app\/>\n    Options Indexes FollowSymLinks\n    AllowOverride None\n    Require all granted\n</Directory>' /etc/apache2/sites-available/000-default.conf

# Reiniciando o servico do Apache para aplicar as mudancas.
sudo systemctl restart apache2

# ------------------------------------------------------------------------------
# 6.5. Configurações de rede e segurança de servicos
# ------------------------------------------------------------------------------
# Concedendo permissao de leitura e execucao para o usuario do Apache
# (www-data) no diretorio /srv/app, resolvendo o erro 403 Forbidden.
# Usamos setfacl para dar a permissao diretamente ao usuario, sem
# alterar as permissoes de outros.
echo "Configurando permissoes para o usuario do Apache..."
sudo setfacl -m u:www-data:r-x /srv/app

# Reiniciando o Apache para que a nova permissao seja reconhecida.
sudo systemctl restart apache2

# Configurando o firewall UFW...
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

echo Configuração Concluída.
