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
