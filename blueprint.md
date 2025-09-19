
## Visão Geral

Este aplicativo Flutter foi projetado para capturar notificações de aplicativos selecionados, armazená-las localmente e, em seguida, enviar os dados da transação para um webhook. Ele fornece uma interface de usuário para gerenciar permissões, visualizar transações capturadas e selecionar de quais aplicativos as notificações devem ser ouvidas.

## Funcionalidades

- **Verificação de Permissão na Inicialização**: Verifica se a permissão de acesso às notificações é concedida quando o aplicativo é iniciado.
- **Tela de Permissão**: Uma tela dedicada que solicita aos usuários que concedam a permissão necessária para que o aplicativo leia as notificações.
- **Tela de Configurações**: Permite que os usuários selecionem de uma lista de aplicativos instalados de quais eles desejam capturar notificações.
- **Tela Principal**: Exibe uma lista de transações capturadas com seus status (pendente, sincronizado, falhou).
- **Sincronização com Webhook**: Envia as transações pendentes para um serviço de webhook predefinido.
- **Persistência de Dados**: Usa um banco de dados local (SQLite) para armazenar transações e `shared_preferences` para salvar as configurações do usuário.

## Estrutura do Projeto

- `lib/main.dart`: O ponto de entrada principal do aplicativo, que lida com a lógica de inicialização e roteamento.
- `lib/permission_screen.dart`: A tela para solicitar a permissão de acesso às notificações.
- `lib/screens/settings_screen.dart`: A tela onde os usuários podem selecionar os aplicativos para monitorar.
- `lib/helpers/database_helper.dart`: Contém a lógica para gerenciar o banco de dados SQLite.
- `lib/services/webhook_service.dart`: Lida com o envio de dados de transação para o webhook.
- `android/`: Contém os arquivos de configuração e código nativo específicos do Android.
- `.github/workflows/`: Workflows do GitHub Actions para CI/CD e deploy automatizado.
  - `deploy-apk.yml`: Workflow básico para build e deploy de APKs
  - `advanced-deploy.yml`: Workflow avançado com builds otimizados e releases
  - `ci.yml`: Integração contínua para desenvolvimento
- `.github/README.md`: Documentação completa dos workflows e configurações de deploy.

## Fluxo de Trabalho

1. **Inicialização**: O aplicativo verifica se a permissão de acesso às notificações foi concedida.
2. **Concessão de Permissão**: Se a permissão não for concedida, o usuário é direcionado para a `PermissionScreen` para concedê-la.
3. **Seleção de Aplicativos**: Na `SettingsScreen`, o usuário pode selecionar os aplicativos dos quais deseja capturar notificações.
4. **Captura de Notificações**: O aplicativo ouve as notificações dos aplicativos selecionados em segundo plano.
5. **Armazenamento de Transações**: As notificações capturadas são salvas no banco de dados local com o status "pendente".
6. **Visualização e Sincronização**: A `HomeScreen` exibe as transações. O usuário pode acionar manualmente uma sincronização para enviar as transações pendentes para o webhook.
7. **Atualização de Status**: O status de cada transação é atualizado com base no sucesso ou falha da sincronização do webhook.

## Alterações Atuais

### GitHub Actions para Deploy de APK
- **Workflows de CI/CD**: Implementados três workflows para automatização completa:
  - `deploy-apk.yml`: Workflow básico para deploy de APKs
  - `advanced-deploy.yml`: Workflow avançado com builds otimizados e assinatura
  - `ci.yml`: Integração contínua para desenvolvimento
- **Build Automatizado**: APKs são gerados automaticamente em push/pull requests
- **Assinatura de APK**: Suporte para assinatura de releases em produção
- **Artefatos**: Upload automático de APKs como artefatos do GitHub
- **Releases**: Criação automática de releases com APKs e notas detalhadas
- **Otimizações**: Builds separados por arquitetura (ARM64, ARMv7, x86_64)

### Melhorias na Configuração Android
- **Configuração de Assinatura**: Atualizado `build.gradle.kts` para suporte a assinatura segura
- **Gitignore**: Adicionadas entradas para arquivos sensíveis de assinatura
- **Build Types**: Configuração otimizada para builds release e debug

### Funcionalidades dos Workflows
- **Testes Automatizados**: Execução automática de testes e análise de código
- **Cobertura de Código**: Integração com Codecov para relatórios de cobertura
- **Comentários em PR**: Notificações automáticas com links para APKs de teste
- **Cache Inteligente**: Otimização de builds com cache de dependências

### Anteriores
- **Solicitação de Permissão de Notificação**: Adicionada a lógica para solicitar a permissão de notificação na `PermissionScreen`.
- **Permissão `POST_NOTIFICATIONS`**: Adicionada a permissão `POST_NOTIFICATIONS` ao `AndroidManifest.xml` para compatibilidade com o Android 13 e superior.
- **Correções e Melhorias**: Corrigidos vários problemas de análise estática e atualizadas as dependências desatualizadas.
- **Formatação de Código**: O código foi formatado para manter a consistência.
