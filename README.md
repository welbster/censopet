# CensoPet SJC 🐾

O **CensoPet SJC** é um aplicativo móvel *offline first* desenvolvido em Flutter, projetado para facilitar a coleta de dados populacionais de animais de estimação na cidade de São José dos Campos. O aplicativo é voltado para agentes de saúde e recenseadores, permitindo o registro ágil e seguro das informações em campo, mesmo em áreas sem conexão com a internet.

## 🌟 Principais Funcionalidades

- **Coleta Offline:** O principal foco do app. Todo e qualquer registro de endereço e contagem de animais é salvo localmente no dispositivo (utilizando `SharedPreferences`), garantindo que o trabalho de campo nunca seja interrompido por falta de sinal.
- **Autocompletar de Endereço (ViaCEP):** Em locais com internet, ao digitar o CEP o aplicativo preenche automaticamente o Logradouro e Bairro integrando com a API pública do ViaCEP.
- **Estatísticas Detalhadas:** Controle rigoroso da presença e agrupamento de animais em cada residência. Contabiliza totais, status de castração e vacinação nas categorias:
  - Cachorros 🐶
  - Gatos 🐱
  - Pitbulls ⚠️
  - Rottweilers ⚠️
- **Gestão de Agentes:** Registra a identidade e a matrícula do agente responsável para auditoria e padronização.
- **Exportação Fácil (.json):** Os dados coletados podem ser facilmente consolidados em um formato `.json` padronizado e compartilhado externamente (via WhatsApp, E-mail, Drive Compartilhado) de forma prática.
- **Limpeza e Importação:** O app possui recursos de Limpeza Total e um Importador de Backup (via arquivo `json`), muito útil em caso de troca de dispositivo ou envio massivo.

## 🛠️ Tecnologias e Dependências

- **Framework:** [Flutter](https://flutter.dev/) (SDK `>=3.0.0 <4.0.0`)
- **Linguagem:** Dart
- **Arquitetura/Estado:** Gerenciamento nativo simples e focado em performance (Stateful Widgets + SharedPreferences)
- **Integração de APIs:** `http` (Para uso na busca e validação ViaCEP)
- **Manipulação de Arquivos e Compartilhamento:** 
  - `path_provider` (Acesso a diretórios temporários do OS)
  - `file_picker` (Seleção de JSONs para importações locais)
  - `share_plus` (Envio e compartilhamento dos relatórios exportados)
- **Identificadores Únicos:** `uuid` v7 para IDs de registros de forma descentralizada.
- **UI e Design:** `lucide_icons` e Material Design 3.

## 📱 Estrutura do Projeto

A raiz do projeto abriga as devidas implementações nas pastas nativas e o código-fonte principal que se concentra em:
- `lib/main.dart`: Arquivo principal contendo os Modelos (`CensusRecord`, `AnimalStats`), a listagem dos bairros pre-determinados e toda a ramificação de telas (`DashboardScreen`, `FormScreen`).

## 🚀 Como Executar o Projeto Localmente

1. Certifique-se de ter o ambiente [Flutter](https://docs.flutter.dev/get-started/install) devidamente configurado em sua máquina.
2. Clone este repositório:
   ```bash
   git clone https://github.com/welbster/censopet.git
   ```
3. Baixe e atualize os pacotes do projeto:
   ```bash
   cd censopet_sjc
   flutter pub get
   ```
4. Conecte seu dispositivo (físico ou emulador Android/iOS) e instale o pacote de debug:
   ```bash
   flutter run
   ```

## 👨‍💻 Autor

- **Wélbster Florentino Labat Uchôas**
- 📧 Contato: welbsteruchoas@gmail.com
