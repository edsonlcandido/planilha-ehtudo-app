# GitHub Actions para Deploy de APK

Este repositório contém workflows do GitHub Actions para automatizar o build e deploy de APKs do aplicativo Planilha É Htudo.

## 📋 Workflows Disponíveis

### 1. `deploy-apk.yml` - Deploy Básico
**Trigger:** Push para main/master, Pull Requests, Manual

Workflow simples que:
- Executa testes e análise de código
- Gera APKs debug e release
- Faz upload como artefatos
- Cria releases automáticos na branch principal

### 2. `advanced-deploy.yml` - Deploy Avançado
**Trigger:** Push para main/master/develop, Tags v*, Manual com opções

Workflow completo que:
- Executa testes com cobertura de código
- Gera APKs otimizados por arquitetura (ARM64, ARMv7, x86_64)
- Suporte para assinatura de APK em produção
- Releases com notas detalhadas
- Upload para Codecov

### 3. `ci.yml` - Integração Contínua
**Trigger:** Push para branches de desenvolvimento, Pull Requests

Workflow rápido para desenvolvimento:
- Validação de código e testes
- APK debug para testes
- Comentários automáticos em PRs

## 🔐 Configuração de Assinatura de APK (Opcional)

Para builds de produção assinados, configure os seguintes secrets no GitHub:

### Secrets Necessários:
```
ANDROID_KEYSTORE_BASE64    # Keystore em Base64
ANDROID_KEYSTORE_PASSWORD  # Senha do keystore
ANDROID_KEY_ALIAS         # Alias da chave
ANDROID_KEY_PASSWORD      # Senha da chave
```

### Como gerar o keystore:

1. **Criar keystore:**
```bash
keytool -genkey -v -keystore release.keystore -alias planilha-ehtudo -keyalg RSA -keysize 2048 -validity 10000
```

2. **Converter para Base64:**
```bash
base64 -i release.keystore | tr -d '\n' > keystore.base64
```

3. **Configurar no GitHub:**
- Vá para Settings > Secrets and variables > Actions
- Adicione os secrets listados acima

### Configuração no Android (automática):

O workflow criará automaticamente:
- `android/key.properties`
- `android/app/keystore/release.keystore`

## 📦 Artefatos Gerados

### Debug APKs:
- **Retenção:** 7-30 dias
- **Uso:** Testes internos
- **Tamanho:** ~50-70MB

### Release APKs:
- **Universal:** Funciona em todos os dispositivos (~70-90MB)
- **ARM64:** Dispositivos modernos (~25-35MB)
- **ARMv7:** Dispositivos mais antigos (~25-35MB)
- **x86_64:** Emuladores e tablets Intel (~25-35MB)

## 🚀 Como Usar

### Para Desenvolvedores:

1. **Pull Request:**
   - Crie um PR → CI automático executa
   - APK debug fica disponível nos artefatos
   - Comentário automático no PR com instruções

2. **Branch de Desenvolvimento:**
   - Push para `develop`, `feature/*`, `fix/*` → CI executa
   - APK debug para testes rápidos

3. **Release:**
   - Push para `main`/`master` → Deploy completo
   - APKs release + debug
   - Release automático no GitHub

### Para Usuários Finais:

1. Vá para [Releases](../../releases)
2. Baixe o APK apropriado:
   - **ARM64**: Recomendado para celulares modernos
   - **Universal**: Se não souber qual escolher
3. Instale o APK no dispositivo

## 🔧 Configurações Avançadas

### Modificar Versão do Flutter:
Edite a variável `FLUTTER_VERSION` nos workflows.

### Alterar Retenção de Artefatos:
Modifique `retention-days` nos steps de upload.

### Personalizar Releases:
Edite as seções de geração de release notes.

## 📊 Monitoramento

### Codecov:
Relatórios de cobertura de código são enviados automaticamente para o Codecov.

### Logs dos Workflows:
Acesse a aba "Actions" para ver logs detalhados de cada execução.

## ⚠️ Troubleshooting

### Falhas Comuns:

1. **Erro de dependências:**
   ```
   flutter pub get
   flutter clean
   ```

2. **Erro de assinatura:**
   - Verifique se os secrets estão configurados
   - Confirme se o keystore é válido

3. **Erro de build:**
   - Verifique se o código passa nos testes localmente
   - Confirme compatibilidade com a versão do Flutter

### Logs Úteis:
```bash
# Executar localmente para debug
flutter doctor -v
flutter analyze
flutter test
flutter build apk --debug
```

## 📝 Contribuindo

1. Teste mudanças nos workflows em um fork primeiro
2. Use branches de feature para modificações
3. Mantenha os workflows simples e bem documentados

## 🔗 Links Úteis

- [Documentação Flutter CI/CD](https://docs.flutter.dev/deployment/cd)
- [GitHub Actions Documentation](https://docs.github.com/en/actions)
- [Android App Signing](https://developer.android.com/studio/publish/app-signing)