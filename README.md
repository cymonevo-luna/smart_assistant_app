# flutter_template

A reusable Flutter base for building multiple apps that share one design system
but can each have a distinct **primary color / theme**. It ships with a complete
foundation: theming, reusable UI components, dependency injection, networking,
storage, state management, routing, localization, env config, typed models, and
error monitoring.

---

## Table of contents

- [Quick start](#quick-start)
- [Architecture overview](#architecture-overview)
- [Project structure](#project-structure)
- [Startup flow](#startup-flow)
- [Theming](#theming)
- [State management (Riverpod)](#state-management-riverpod)
- [Dependency injection (get_it)](#dependency-injection-get_it)
- [Storage](#storage)
- [Networking (ApiClient)](#networking-apiclient)
- [Models (freezed + json_serializable)](#models-freezed--json_serializable)
- [Routing (go_router)](#routing-go_router)
- [Localization (gen-l10n)](#localization-gen-l10n)
- [Environment config (flutter_dotenv)](#environment-config-flutter_dotenv)
- [Error monitoring (Sentry)](#error-monitoring-sentry)
- [UI components](#ui-components)
- [Code generation](#code-generation)
- [Creating a new app from this template](#creating-a-new-app-from-this-template)
- [Dependencies](#dependencies)

---

## Quick start

```bash
cp .env.example .env          # then edit values
flutter pub get
dart run build_runner build   # generate freezed/json model code
flutter gen-l10n              # generate localization classes
flutter run
```

The included `ShowcasePage` (`lib/features/showcase/`) demonstrates theming,
localization, routing and all components. Delete it once you start building real
screens.

---

## Architecture overview

| Concern | Tool | Where |
|---------|------|-------|
| Design system / theming | custom + `google_fonts` | `core/theme/` |
| App/UI state | `flutter_riverpod` | providers in `core/` + features |
| Service location (DI) | `get_it` | `core/di/locator.dart` |
| HTTP | `dio` (wrapped) | `core/network/` |
| Key/value storage | `shared_preferences` | `core/storage/` |
| Secure storage | `flutter_secure_storage` | `core/storage/` |
| Models / JSON | `freezed` + `json_serializable` | feature `models/` |
| Navigation | `go_router` | `core/router/` |
| Localization | Flutter `gen-l10n` | `lib/l10n/` |
| Env config | `flutter_dotenv` | `core/config/` + `.env` |
| Error monitoring | `sentry_flutter` | `main.dart` |

Rule of thumb: **services** (no UI, app-wide singletons) go in `get_it`; **state**
(reactive, UI-facing) goes in Riverpod providers.

---

## Project structure

```
lib/
├── main.dart                      # Startup: env, DI, Sentry, runApp
├── app.dart                       # MaterialApp.router + theme/locale wiring
├── core/
│   ├── config/app_config.dart     # .env-backed configuration
│   ├── di/locator.dart            # get_it service locator
│   ├── localization/locale_provider.dart
│   ├── network/
│   │   ├── api_client.dart        # Dio-based HTTP client
│   │   └── api_exception.dart     # Normalized error type
│   ├── router/app_router.dart     # go_router routes
│   ├── storage/
│   │   ├── preferences_service.dart   # shared_preferences wrapper
│   │   └── secure_storage_service.dart # secure token storage
│   └── theme/                     # Design system (+ theme_provider.dart)
├── l10n/                          # *.arb sources + generated localizations
├── shared/widgets/                # Reusable UI components (widgets.dart barrel)
└── features/
    ├── showcase/                  # Demo screen (reference; safe to delete)
    └── user/                      # Example feature: model + repository
```

---

## Startup flow

`main.dart` runs in order:

1. `AppConfig.load()` — read `.env`.
2. `setupLocator()` — register services in get_it (prefs, secure storage, API).
3. Wrap the app in a `ProviderScope` (Riverpod), overriding the default accent.
4. Initialize Sentry (only if a DSN is set), then `runApp`.

---

## Theming

Everything visual is generated from a single **seed color** per app.

Set the brand color (the default until the user changes it) in `main.dart`:

```dart
ProviderScope(
  overrides: [defaultAccentProvider.overrideWithValue(AppAccent.purple)],
  child: const App(),
);
```

Switch live from any widget (instant + persisted):

```dart
ref.read(themeProvider.notifier).setAccent(AppAccent.green);
ref.read(themeProvider.notifier).setThemeMode(ThemeMode.dark);
ref.read(themeProvider.notifier).toggleBrightness();

final accent = ref.watch(themeProvider).accent; // observe
```

Use tokens instead of hardcoding:

```dart
context.colors.primary         // accent-driven ColorScheme
context.tokens.success         // semantic colors (success/warning/danger/info)
context.tokens.textSecondary   // muted text
context.textStyles.titleLarge  // TextTheme
AppSpacing.md / AppRadius.brLg // spacing + radius scales
```

Accents available in `AppAccent`: blue, red, orange, green, purple, teal. Add an
enum entry with a seed color to introduce a new one.

---

## State management (Riverpod)

The app is wrapped in `ProviderScope`. Theme and locale are Riverpod
`Notifier`s (`themeProvider`, `localeProvider`). Build new state the same way:

```dart
class CounterNotifier extends Notifier<int> {
  @override
  int build() => 0;
  void increment() => state++;
}
final counterProvider = NotifierProvider<CounterNotifier, int>(CounterNotifier.new);
```

In widgets, extend `ConsumerWidget` and use `ref.watch` / `ref.read`.

---

## Dependency injection (get_it)

Services are registered once in `core/di/locator.dart` and resolved anywhere:

```dart
final api = locator<ApiClient>();
final prefs = locator<PreferencesService>();
final secure = locator<SecureStorageService>();
```

Register your own services/repositories in `setupLocator()`.

---

## Storage

**Non-sensitive** key/value (`PreferencesService`), keys centralized in `PrefKeys`:

```dart
final prefs = locator<PreferencesService>();
await prefs.setBool(PrefKeys.onboardingDone, true);
final done = prefs.getBool(PrefKeys.onboardingDone);
```

**Sensitive** values (`SecureStorageService`) — tokens/secrets, encrypted:

```dart
final secure = locator<SecureStorageService>();
await secure.writeToken(token);
final token = await secure.readToken();
await secure.deleteToken();
```

The saved auth token is automatically restored onto `ApiClient` at startup.

---

## Networking (ApiClient)

Dio-based client; all failures are normalized to `ApiException` (auth-token
injection, 401 handling, and debug logging built in).

```dart
final client = locator<ApiClient>();

final json = await client.get<Map<String, dynamic>>('/me');           // raw
final user = await client.get<User>('/me', decoder: User.fromJson);   // typed
await client.post<void>('/tasks', body: {'title': 'New task'});
await client.get('/tasks', query: {'page': 1});

client.setAuthToken(token); // pass null to clear on logout
```

Uniform error handling:

```dart
try {
  await locator<ApiClient>().get<User>('/me', decoder: User.fromJson);
} on ApiException catch (e) {
  switch (e.type) {
    case ApiErrorType.unauthorized: /* ... */
    case ApiErrorType.network: /* ... */
    default: showError(e.message);
  }
}
```

Advanced cases (uploads, custom options): `locator<ApiClient>().raw` (the `Dio`).

---

## Models (freezed + json_serializable)

Immutable models with `copyWith`, equality, and JSON. See
`features/user/models/user.dart`:

```dart
@freezed
abstract class User with _$User {
  const factory User({
    required String id,
    required String name,
    required String email,
    String? avatarUrl,
  }) = _User;

  factory User.fromJson(Map<String, dynamic> json) => _$UserFromJson(json);
}
```

Repositories pair models with the client (see
`features/user/data/user_repository.dart`):

```dart
final repo = UserRepository(locator<ApiClient>());
final user = await repo.fetchCurrentUser();
```

Re-run codegen after editing a model (see [Code generation](#code-generation)).

---

## Routing (go_router)

Routes live in `core/router/app_router.dart`, names in the `AppRoute` enum:

```dart
context.goNamed(AppRoute.home.name);     // replace
context.pushNamed(AppRoute.details.name); // push
```

Add a `GoRoute` to the `routes` list and a corresponding `AppRoute` entry.

---

## Localization (gen-l10n)

Translations are ARB files in `lib/l10n/` (`app_en.arb`, `app_id.arb`).

```dart
final l10n = AppLocalizations.of(context);
Text(l10n.overview);
Text(l10n.greeting('Alex')); // placeholders supported
```

Change language at runtime (persisted):

```dart
ref.read(localeProvider.notifier).setLocale(const Locale('id'));
ref.read(localeProvider.notifier).setLocale(null); // follow system
```

To add a language: add `lib/l10n/app_<code>.arb`, add the `Locale` to
`kSupportedLocales`, then run `flutter gen-l10n`.

---

## Environment config (flutter_dotenv)

Config comes from `.env` (git-ignored; `.env.example` is the committed template),
exposed through `AppConfig`:

```dart
AppConfig.apiBaseUrl;     // String
AppConfig.environment;    // AppEnv.dev | staging | prod
AppConfig.sentryDsn;      // String
AppConfig.sentryEnabled;  // bool
```

`.env` is declared as an asset in `pubspec.yaml`. Keep secrets out of source
control; for CI you can also inject values via `--dart-define`.

---

## Error monitoring (Sentry)

Enabled automatically when `SENTRY_DSN` is set in `.env`; otherwise skipped. The
app is wrapped in `SentryWidget` and runs under `SentryFlutter.init`. Capture
manually:

```dart
await Sentry.captureException(error, stackTrace: stack);
```

---

## UI components

Import via one barrel:

```dart
import 'package:flutter_template/shared/widgets/widgets.dart';
```

| Component | Purpose |
|-----------|---------|
| `AppText` | Theme-aware text with variants (`AppText.title(...)`) |
| `AppButton` / `AppSocialButton` | Primary/secondary/text + social sign-in |
| `AppCard` | Rounded, soft-shadow surface (optional tap) |
| `AppTextField` | Labeled rounded input (+ password toggle) |
| `AppStatCard` | Metric tile with icon badge + trend |
| `AppListTile` | Row with icon, title, trailing value/chevron |
| `AppIconBadge` | Tinted circular/rounded icon chip |
| `AppSectionHeader` | Section title + optional action |

See `ShowcasePage` for a full assembled example.

---

## Code generation

Run after changing any `@freezed` model or `*.arb` file:

```bash
dart run build_runner build      # freezed + json_serializable
# or watch: dart run build_runner watch
flutter gen-l10n                 # localizations
```

`scripts/build-apk.sh` (used by the Jenkins deploy host) runs codegen before
`flutter build apk`. It removes a stale `build_runner` lock when the holding
process is dead. Because `build_runner` intermittently deadlocks in the analyzer
(hangs mid-run until killed), codegen runs under a short per-attempt timeout
(`BUILD_RUNNER_TIMEOUT`, default 600s) and is retried up to `BUILD_RUNNER_ATTEMPTS`
(default 3) times — a fresh run almost always clears the hang. Each retry hard-kills
the deadlocked run and its lock; a genuine (non-timeout) codegen error fails fast.
See `scripts/build-apk.test.sh` for the regression test.

Generated files (`*.freezed.dart`, `*.g.dart`, `lib/l10n/app_localizations*.dart`)
are committed so the project builds without a codegen step.

---

## Creating a new app from this template

1. Copy the repo (or use it as a starter).
2. Rename the package: `name:` in `pubspec.yaml` + update
   `package:flutter_template/...` imports.
3. `cp .env.example .env` and set `API_BASE_URL`, `SENTRY_DSN`, `APP_ENV`.
4. Set the brand color via `defaultAccentProvider.overrideWithValue(...)` in
   `main.dart`.
5. Run codegen (`dart run build_runner build`, `flutter gen-l10n`).
6. Delete `lib/features/showcase/`, register your services/repositories in
   `setupLocator()`, and build screens under `features/` using the shared
   widgets.

---

## Dependencies

| Package | Use |
|---------|-----|
| `google_fonts` | Typography (Inter by default) |
| `flutter_riverpod` | State management |
| `get_it` | Dependency injection / service locator |
| `dio` | HTTP client (`ApiClient`) |
| `shared_preferences` | Non-sensitive key/value storage |
| `flutter_secure_storage` | Encrypted storage for tokens/secrets |
| `go_router` | Navigation/routing |
| `flutter_localizations` + gen-l10n | Localization |
| `flutter_dotenv` | Environment config |
| `sentry_flutter` | Crash/error monitoring |
| `freezed` + `json_serializable` | Immutable models + JSON (dev: codegen) |
| `build_runner` | Code generation runner (dev) |
