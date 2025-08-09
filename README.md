# automate-debian-server

## Descrição do Projeto

Este projeto consiste em um script em Shell (`setup_infra.sh`) que automatiza a configuração inicial de um servidor Debian. Ele foi desenvolvido para otimizar o processo de criação de usuários, grupos, permissões de diretórios, e a instalação e configuração de pacotes essenciais como Apache, UFW e ferramentas de cota de disco.

O objetivo é fornecer uma base de infraestrutura segura e funcional de forma rápida, com instruções claras para as poucas tarefas que exigem intervenção manual, documentadas neste arquivo.

## Funcionalidades do Script

O script `setup_infra.sh` executa as seguintes tarefas automaticamente:
- **Criação de Grupos e Usuários:** Cria os grupos `desenvolvedores` e `operacoes`, além dos usuários `dev1`, `dev2`, `ops1`, `ops2` e `techlead`, com a atribuição correta de grupos.
- **Configuração de Diretórios e Permissões:** Cria o diretório `/srv/app` e define as permissões apropriadas usando `chown`, `chmod` e `setfacl`.
- **Instalação de Pacotes:** Instala o Apache, UFW e as ferramentas de cota de disco.
- **Configuração do Apache:** Altera o `DocumentRoot` para o diretório `/srv/app` e cria um arquivo `index.html` de teste.
- **Configuração do UFW (Firewall):** Define políticas padrão e adiciona regras para permitir o tráfego nas portas SSH (22) e HTTP (80).

## Pré-requisitos

- Sistema operacional baseado em Debian (como Debian, Ubuntu, etc.).
- Acesso de superusuário (root) ou permissões `sudo`.

## Como Usar

1.  **Salve o script:** Copie o conteúdo do script `setup_infra.sh` para um arquivo no seu servidor.

2.  **Dê permissões de execução:** Antes de executar o script, torne-o executável.
    ```bash
    chmod +x setup_infra.sh
    ```

3.  **Execute o script:**
    ```bash
    sudo ./setup_infra.sh
    ```

## Tarefas que Requerem Intervenção Manual

Após a execução do script, as seguintes tarefas não puderam ser automatizadas e precisam ser concluídas manualmente.

### 1. Configuração de Cotas de Disco

Para ativar as cotas, é necessário editar o arquivo `/etc/fstab`, pois o nome da partição pode variar.

**Passo a passo manual:**
1.  **Edite o arquivo `/etc/fstab`** e adicione as opções `usrquota,grpquota` nas opções de montagem da partição do sistema de arquivos raiz (`/`).
    Exemplo: `UUID=... / ext4 defaults,usrquota,grpquota 0 1`
2.  **Monte novamente a partição** para ativar as cotas.
    ```bash
    sudo mount -o remount /
    ```
3.  **Crie os arquivos de cota** para cada partição.
    ```bash
    sudo quotacheck -cug /
    ```
4.  **Ative as cotas.**
    ```bash
    sudo quotaon -vug /
    ```
5.  **Defina as cotas para os usuários** (200MB soft / 250MB hard).
    ```bash
    sudo setquota -u dev1 204800 256000 0 0 /
    sudo setquota -u dev2 204800 256000 0 0 /
    sudo setquota -u ops1 204800 256000 0 0 /
    sudo setquota -u ops2 204800 256000 0 0 /
    sudo setquota -u techlead 204800 256000 0 0 /
    ```
### 2. Configuração de Endereço IP Estático

O script não pode determinar o `gateway` e os `dns-nameservers` da sua rede.

**Passo a passo manual:**
1.  **Edite o arquivo `/etc/network/interfaces`**.
2.  **Adicione as seguintes linhas**, substituindo os valores pelos da sua rede:
    ```
    auto enp0s3
    iface enp0s3 inet static
        address 10.0.2.100
        netmask 255.255.255.0
        gateway [SEU_GATEWAY_CORRETO]
        dns-nameservers [SEU_DNS1] [SEU_DNS2]
    ```
3.  **Reinicie o serviço de rede** para aplicar as mudanças.
    ```bash
    sudo systemctl restart networking
    ```
4.   *(Opcional, mas recomendado)* **Reinicie o servidor** para garantir que todas as configurações de rede sejam aplicadas sem conflitos.
    ```bash
    sudo reboot
    ```

## Autores

- André Fellipe;
- Efraim Fonseca;
- Lucas Emanuel;
- Marcos Eduardo;
- Samuel Ademar;
