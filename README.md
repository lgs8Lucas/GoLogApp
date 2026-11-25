# GoLog

App do motorista (Flutter) para rotas, entregas e ocorrências. Funciona
offline-first: rotas ficam em cache no SQLite, e ocorrências e telemetria
(GPS) são gravadas localmente e sincronizadas com a API a cada 3 minutos,
ao reabrir o app e no logout.

## Rodando

```bash
flutter pub get
flutter run \
  --dart-define=GOOGLE_MAPS_API_KEY=<chave com Maps + Navigation SDK> \
  --dart-define=API_URL=http://147.15.18.21:8081   # opcional (este é o padrão)
```

| dart-define           | Obrigatório | Uso                                                         |
|-----------------------|-------------|-------------------------------------------------------------|
| `GOOGLE_MAPS_API_KEY` | sim         | Injetada no AndroidManifest e no AppDelegate (iOS).         |
| `API_URL`             | não         | URL base da API. Padrão: `http://147.15.18.21:8081`.        |

## Build de release (Android)

Crie `android/key.properties` (fica fora do git):

```properties
storeFile=/caminho/para/golog-release.jks
storePassword=...
keyAlias=golog
keyPassword=...
```

Sem esse arquivo o release é assinado com a chave de debug (o build avisa) e
não pode ser publicado.

## Android Auto

O GoLog aparece no Android Auto como **app de navegação** (Car App Library,
categoria `NAVIGATION`). O carro não roda a UI Flutter: ele abre o
`GoLogCarAppService` (`android/.../auto/`). A `GoLogCarScreen` desenha o mapa
do Navigation SDK e mostra as manobras e o ETA da **mesma sessão de navegação**
aberta no celular. Para isso usa o `AndroidAutoBaseScreen` do
`google_navigation_flutter`.

- A navegação começa no celular, ao abrir uma parada. O carro só espelha.
  Sem parada aberta, ele mostra "Nenhuma entrega em andamento".
- `lib/util/android_auto_bridge.dart` envia ao carro a parada atual e o aviso
  de chegada. Também avisa o app quando o motorista encerra a navegação pelo
  carro.
- Registrar a entrega ou a ocorrência continua sendo feito só no celular. O
  Android Auto não permite formulários nem assinatura.

### Testando

O Android Auto **esconde apps que não foram instalados pela Play Store**.
A partir da versão 17, **"Fontes desconhecidas" não vale para apps da Car App
Library** (template/navegação, como o GoLog). Só vale para apps de mídia.
Também não adianta `adb install -i com.android.vending`: o Android Auto
confere quem *iniciou* a instalação (`initiatingPackageName`), e pelo adb é
sempre `com.android.shell`. O log mostra
`CAR.VALIDATOR: Package DENIED; failed all other checks [br.com.golog.app]`.

Caminhos que funcionam no carro:

- **Play Console, teste interno** (recomendado): o app instalado pela Play
  Store passa na validação.
- **KingInstaller** (app de terceiros): pede ao instalador do sistema para
  instalar com a Play Store como instaladora. Confira o resultado com
  `adb shell dumpsys package br.com.golog.app | grep -E "installerPackageName|initiatingPackageName"`.
  O esperado é `com.android.vending` e `com.google.android.packageinstaller`.
  Toda atualização precisa ser instalada do mesmo jeito.

Sem carro: o **Desktop Head Unit** aceita apps instalados fora da loja
(`sdkmanager "extras;google;auto"`).
  No Android Auto, abra ⋮ → *Iniciar servidor da unidade principal*. Depois
  rode `adb forward tcp:5277 tcp:5277` e
  `$ANDROID_HOME/extras/google/auto/desktop-head-unit`.

Em builds release, só os hosts oficiais do Android Auto/Automotive são
aceitos (`HostValidator`). Para publicar na Play Store, apps de navegação
passam por uma revisão específica do Google para Android Auto.

## Estrutura

```
lib/
  data/
    datasource/local/   SQLite (sqflite) + CredentialStore (token/senha criptografados)
    datasource/remote/  ApiService: HTTP, token, renovação de sessão em 401
    model/              Models e DeliveryStatus
    repository/         Auth, Route (busca + cache + merge offline), Sync
  presentation/
    controller/         Controllers GetX (dependências injetadas no main.dart)
    screen/             *_screen.dart liga controller -> *_view.dart (layout puro, com @Preview)
    widgets/
  util/
```

- Dependências são montadas em `_registerDependencies()` no `main.dart`.
- O banco é versionado em `SqlService`: cada versão nova ganha um passo em
  `_migrations`. `occurrence` e `coordinate` guardam dados ainda não enviados
  e nunca devem ser apagadas numa migração.

## Testes

```bash
flutter test
```

## Pendências conhecidas

- **Rastreamento em segundo plano no Android**: o trajeto só é gravado com o
  app em primeiro plano. Para gravar com a tela bloqueada é preciso foreground
  service + `ACCESS_BACKGROUND_LOCATION`.
- **HTTPS**: a API ainda é acessada por HTTP; basta trocar `API_URL` quando o
  servidor tiver certificado.
- **Telemetria em lote**: cada coordenada é um POST; um endpoint de lote no
  backend reduziria muito o tráfego.
