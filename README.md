# Lightning Scanner

O Lightning Scanner é uma ferramenta para detectar e analisar processos específicos em execução no seu sistema, enviando resultados para um webhook do Discord. O script usa um scanner externo (`strings2.exe`) para verificar os processos e registrar os resultados.

## Funcionalidades

- **Autenticação**: Protege o acesso ao scanner com um sistema de login simples.
- **Detecção de Processos**: Escaneia processos específicos como `explorer`, `javaw`, `dps`, e `pca`.
- **Configuração de Strings**: Lê strings de busca de arquivos de configuração específicos para cada processo.
- **Relatórios e Webhooks**: Envia resultados para um webhook do Discord com formatação adequada.

## Pré-requisitos

- **PowerShell**: Certifique-se de que o PowerShell esteja instalado em seu sistema.
- **strings2.exe**: O executável `strings2.exe` deve ser baixado e colocado no diretório do projeto.
- **Permissões**: O script deve ser executado com permissões suficientes para acessar processos e enviar solicitações de rede.

## Estrutura do Projeto

- `index.ps1`: O script principal que realiza a varredura de processos e manipula a configuração.
- `./strings/`: Diretório para armazenar arquivos de saída do scanner.
- `./config/`: Diretório para arquivos de configuração com strings de busca para cada processo.

## Configuração

1. **Configuração de Processos**:
   - Crie arquivos de configuração no diretório `./config/` com o formato `<processo>.txt`.
   - Cada linha deve conter uma string de busca e o nome do processo no formato `string:processo`.

   Exemplo para `explorer.txt`:
