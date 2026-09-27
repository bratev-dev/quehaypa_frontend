# Qué Hay Pa'? — Frontend

[![Flutter CI](https://github.com/bratev-dev/quehaypa_frontend/actions/workflows/flutter-ci.yml/badge.svg?branch=develop)](https://github.com/bratev-dev/quehaypa_frontend/actions/workflows/flutter-ci.yml)
![Flutter](https://img.shields.io/badge/Flutter-3.47.3-02569B?logo=flutter&logoColor=white)
![Dart](https://img.shields.io/badge/Dart-3.13-0175C2?logo=dart&logoColor=white)
![Platform](https://img.shields.io/badge/platform-Android-3DDC84?logo=android&logoColor=white)

Aplicación móvil de **Qué Hay Pa'?**, construida en Flutter. Consume la [API del backend](https://github.com/bratev-dev/quehaypa-backend) por REST y delega la autenticación en Keycloak (OAuth2 / OpenID Connect con PKCE).

Este repositorio contiene solo el cliente móvil. El backend (Spring Boot) y Keycloak viven en el [repositorio del backend](https://github.com/bratev-dev/quehaypa-backend) y se despliegan en Railway.

**APK de pruebas más reciente:** [pre-release `develop-latest`](https://github.com/bratev-dev/quehaypa_frontend/releases/tag/develop-latest). Se regenera con cada cambio en `develop`.

---

## Tabla de contenidos

- [Arquitectura](#arquitectura)
- [Stack tecnológico](#stack-tecnológico)
- [Estructura del proyecto](#estructura-del-proyecto)
- [Requisitos previos](#requisitos-previos)
- [Configuración de entornos](#configuración-de-entornos)
- [Puesta en marcha](#puesta-en-marcha)
- [Pruebas, calidad y cobertura](#pruebas-calidad-y-cobertura)
- [Integración y entrega continua](#integración-y-entrega-continua)
- [Flujo de ramas, commits y Pull Requests](#flujo-de-ramas-commits-y-pull-requests)
- [Dependencias y Dependabot](#dependencias-y-dependabot)
- [Versiones](#versiones)

---

## Arquitectura

Cada feature sigue **Clean Architecture**, y su capa de presentación se organiza con **Atomic Design**:

```
feature/
├── data/            # Datasources (Dio), modelos JSON y repositorios concretos
├── domain/          # Entidades, contratos de repositorio y casos de uso (Dart puro)
└── presentation/
    ├── atoms/       # Componentes UI mínimos (botones, campos, chips)
    ├── molecules/   # Composición de átomos (formularios, tarjetas)
    ├── organisms/   # Secciones completas de una pantalla
    ├── templates/   # Layout de una pantalla, sin estado
    ├── pages/       # Pantallas conectadas a los controladores
    └── controllers/ # Estado de la feature (Riverpod) y providers
```

- Las dependencias fluyen en una sola dirección: `presentation → domain → data`. `domain` no importa Flutter, Dio ni JSON.
- Los datasources traducen los errores HTTP a excepciones (`core/errors/exceptions.dart`), y los repositorios los convierten en *failures* del dominio (`core/errors/failtures.dart`), que la UI muestra.
- Toda feature usa el `Dio` central (`dioProvider`). Su `AuthInterceptor` agrega el `Bearer` y, ante un 401, renueva el token una sola vez y reintenta. Si la renovación falla, cierra la sesión.

## Stack tecnológico

| Categoría | Tecnología |
| --- | --- |
| Framework | [Flutter](https://flutter.dev) 3.47.3 (Dart 3.13) |
| Gestión de estado | [Riverpod](https://riverpod.dev) 3.x |
| Navegación | [go_router](https://pub.dev/packages/go_router) |
| Autenticación | [flutter_appauth](https://pub.dev/packages/flutter_appauth) (Authorization Code + PKCE contra Keycloak) |
| Cliente HTTP | [Dio](https://pub.dev/packages/dio) |
| Almacenamiento seguro de tokens | [flutter_secure_storage](https://pub.dev/packages/flutter_secure_storage) |
| Configuración | [flutter_dotenv](https://pub.dev/packages/flutter_dotenv) (archivo `.env`) |
| Pruebas | `flutter_test`, [mocktail](https://pub.dev/packages/mocktail) |
| Calidad | `flutter analyze`, SonarCloud |
| CI/CD | GitHub Actions + GitHub Releases |

> **Plataformas:** `flutter_appauth` no tiene implementación web, así que el inicio de sesión solo funciona en Android e iOS. El objetivo del proyecto es Android.

## Estructura del proyecto

```
frontend/
├── android/ ios/ ...          # Proyectos nativos
├── assets/                    # Imágenes (SVG) y videos
├── lib/
│   ├── app/                   # AppConfig (.env), router, tema y providers transversales
│   ├── core/
│   │   ├── errors/            # Excepciones, failures y mensajes amigables
│   │   ├── network/           # Cliente Dio y AuthInterceptor
│   │   └── security/          # TokenManager, almacenamiento seguro y eventos de sesión
│   ├── features/
│   │   ├── authentication/    # Login, registro por pasos y sincronización del perfil
│   │   ├── preferences/       # Catálogo de intereses, preferencias y feed de eventos
│   │   ├── plans/             # CRUD de planes contra el backend (datos y controlador)
│   │   ├── my_plans/          # Pantalla "Mis planes" y modal de creación
│   │   ├── dashboard/         # Inicio con categorías y eventos
│   │   ├── saved_to_plans/    # Guardar un evento en un plan
│   │   ├── navigation/        # Barra de navegación inferior
│   │   ├── home/ splash/      # Bienvenida y arranque
│   └── main.dart              # Carga .env y arranca la app
├── test/                      # Pruebas unitarias y de widgets (misma estructura que lib/)
├── tool/                      # Scripts de medición de cobertura
├── docs/                      # Documento de arquitectura del frontend
└── .github/                   # Workflows, Dependabot y plantilla de PR
```

## Requisitos previos

- [Flutter SDK](https://docs.flutter.dev/get-started/install) `3.47.3` (con `fvm` o `asdf` puedes fijar la versión exacta)
- Android SDK / [Android Studio](https://developer.android.com/studio) y un emulador o un teléfono con depuración USB
- JDK 17 (lo usa Gradle)
- Backend y Keycloak accesibles desde el dispositivo, sea en tu PC o en Railway. Ver [Configuración de entornos](#configuración-de-entornos)

```bash
flutter doctor -v
```

## Configuración de entornos

La app lee su configuración de un archivo **`.env`** en la raíz del proyecto, que `main.dart` carga al arrancar. Ese archivo está en `.gitignore` y nunca se sube al repositorio. Para crearlo, parte de la plantilla:

```bash
cp .env.example .env
```

| Variable | Descripción |
| --- | --- |
| `API_BASE_URL` | URL base del backend, sin `/api/v1`. Ej.: `http://192.168.1.19:5001` |
| `KEYCLOAK_ISSUER_URL` | Emisor del realm: `http(s)://<host>/realms/que-hay-pa-dev` |

Otros valores fijos del cliente OIDC, que viven en `lib/app/config/app_config.dart`:

- client id: `que-hay-pa-mobile`
- redirect URI: `com.quehaypa.app://oauth/callback`

**Reglas importantes:**

- **`KEYCLOAK_ISSUER_URL` debe ser idéntico a `JWT_ISSUER_URI` del backend.** El claim `iss` del token toma la URL por la que la app llegó a Keycloak. Si no coincide con la que valida el backend, todas las peticiones responden 401.
- En un **teléfono físico**, `localhost` es el propio teléfono. Usa la IP LAN de tu PC en ambas variables y en el backend.
- Para usar los servicios de Railway, pide las URLs vigentes a quien administra los despliegues. En el CI se inyectan desde las *Variables* del repositorio (`API_BASE_URL` y `KEYCLOAK_ISSUER_URL`), no desde el código.

## Puesta en marcha

```bash
git clone https://github.com/bratev-dev/quehaypa_frontend.git
cd quehaypa_frontend
cp .env.example .env        # y completa las URLs
flutter pub get
flutter run                 # emulador o dispositivo conectado
```

Para instalar la versión de pruebas sin compilar, descarga `que-hay-pa-develop.apk` de la pre-release [`develop-latest`](https://github.com/bratev-dev/quehaypa_frontend/releases/tag/develop-latest). Ese APK apunta a los servicios de Railway.

## Pruebas, calidad y cobertura

Antes de abrir un Pull Request, corre localmente lo mismo que valida el CI:

```bash
dart format --output=none --set-exit-if-changed .   # formato
flutter analyze                                      # análisis estático
flutter test                                         # pruebas unitarias y de widgets
```

### Cobertura medida sin trampas

`flutter test --coverage` solo reporta los archivos que alguna prueba importa. Un archivo sin pruebas desaparece del reporte e infla el porcentaje. Para medir como el CI, genera primero una prueba que importe todo `lib/`:

```bash
bash tool/coverage_all_files.sh      # genera test/coverage_all_files_test.dart (no se versiona)
flutter test --coverage
python tool/coverage_summary.py      # muestra el porcentaje con el alcance de SonarCloud y el total
```

En Windows también puedes generar el mismo archivo desde PowerShell:

```powershell
.\tool\coverage_all_files.ps1
flutter test --coverage
```

**Alcance de la métrica.** Se excluyen del porcentaje solo los widgets de presentación **sin reglas de negocio**: dibujo, animaciones, tema y composición de pantallas. La lista está en `sonar.coverage.exclusions` de [`sonar-project.properties`](sonar-project.properties) y es la única fuente: el resumen del CI la lee de ahí. Los widgets que contienen validaciones se miden y tienen pruebas de widget. Hoy son:

- acceso a Keycloak y continuación del registro (cancelación, rol y navegación)
- datos personales (fecha de nacimiento, CC)
- selección de intereses (mínimo 4)
- modal de creación de planes

Si agregas un widget con reglas de negocio, no lo pongas en la lista de exclusión: escríbele pruebas.

**Convenciones de pruebas:**

- Los datasources se prueban con `test/helpers/fake_http_adapter.dart`, un adaptador HTTP falso para Dio que no usa red.
- Los repositorios y controladores se prueban con `mocktail` y `ProviderContainer`.
- Los widgets usan `test/helpers/widget_finders.dart`.

## Integración y entrega continua

El workflow [`flutter-ci.yml`](.github/workflows/flutter-ci.yml) corre en cada push y Pull Request hacia `develop` y `main`:

| Job | Qué hace |
| --- | --- |
| **Analizar y probar** | `dart format`, `flutter analyze`, generación de la prueba que importa todo `lib/`, `flutter test --coverage`, resumen de cobertura en la página del run y análisis de **SonarCloud** con el `lcov` (calidad, seguridad y cobertura) |
| **Build Android (debug)** | Compila un APK de debug para verificar que el build completo (Gradle y JDK) sigue funcionando |
| **Publicar APK de pruebas** | Solo en push a `develop`. Compila el APK de release con el `.env` armado desde las *Variables* del repositorio y lo publica en la pre-release `develop-latest` |

Otros workflows:

| Workflow | Función |
| --- | --- |
| [`branch-naming.yml`](.github/workflows/branch-naming.yml) | Rechaza ramas que no sigan la convención (las ramas `dependabot/*` están exentas) |
| [`pr-title.yml`](.github/workflows/pr-title.yml) | Exige un título de PR con formato Conventional Commits y clave de Jira |
| [`dependabot-automerge.yml`](.github/workflows/dependabot-automerge.yml) | Aprueba y fusiona solas las actualizaciones *patch* y *minor* cuando el CI pasa |

**SonarCloud** (proyecto `bratev-dev_QueHayPa_Alta`) comenta cada PR y su Quality Gate (*Sonar way*: al menos 80 % de cobertura y sin incidencias nuevas en el código nuevo) es un check obligatorio. El análisis automático de SonarCloud está desactivado: solo analiza el CI, que es el que aporta la cobertura.

**Protección de ramas.** Para fusionar en `develop` y en `main` deben pasar `Analizar y probar`, `Build Android (debug)`, `check-branch-name`, `check-pr-title` y `SonarCloud Code Analysis`. Además, `main` exige 1 aprobación y las reglas también aplican a los administradores.

## Flujo de ramas, commits y Pull Requests

El repositorio está conectado a Jira (proyecto **QHP**) con la app **GitHub for Jira**. Una rama, un commit o un PR que incluya `QHP-<número>` aparece en el panel de desarrollo del issue.

| Rama | Propósito | Se crea desde | Se fusiona en |
| --- | --- | --- | --- |
| `main` | Versión estable y liberada (tags `vX.Y.Z-…`) | — | — |
| `develop` | Integración continua del sprint | — | — |
| `feature/QHP-<n>-<descripción>` | Historia de usuario | `develop` | `develop` (squash) |
| `fix/QHP-<n>-<descripción>` | Corrección de un error | `develop` | `develop` (squash) |
| `chore/QHP-<n>-<descripción>` | Mantenimiento, CI, pruebas, documentación | `develop` | `develop` (squash) |
| `hotfix/QHP-<n>-<descripción>` | Parche urgente sobre lo liberado | `main` | `main` y luego `develop` |

La descripción va en español y en kebab-case. Ejemplo: `feature/QHP-123-login-con-google`. `QHP-<n>` es la clave real del issue en Jira. Una rama corresponde a un solo issue.

**Título del Pull Request.** Se valida con Conventional Commits y la clave de Jira:

```
<tipo>(QHP-<n>): <descripción en español>
```

Los tipos válidos son `feat`, `fix`, `chore`, `docs`, `style`, `refactor`, `perf`, `test`, `build`, `ci` y `revert`. Para un cambio que rompe compatibilidad se agrega `!`, como en `feat(QHP-90)!: ...`. Ejemplos: `feat(QHP-78): crear planes desde la app`, `test(QHP-85): cobertura real del frontend`.

**Métodos de fusión.**

- Hacia `develop`, solo **squash**: cada PR queda como un único commit cuyo mensaje es el título del PR, y así el historial de `develop` sigue Conventional Commits.
- Hacia `main`, solo **merge commit**, usado para las releases `develop → main`. Así `main` conserva exactamente los commits de `develop` y no divergen.
- Las ramas se borran solas al fusionar.

**Release.** Se abre un PR `develop → main` con título `chore(QHP-<n>): release …`, se fusiona con merge commit tras la aprobación y se etiqueta `main` con la versión, por ejemplo `v0.1.0-sprint1`.

**Uso de IA generativa.** Si un PR incluye código generado o asistido por IA, se marca la casilla de la [plantilla de PR](.github/pull_request_template.md) y se antepone **`[IA-ASISTIDO]`** a la primera línea de la descripción. También se indica la herramienta usada y cómo se validó el código.

Los commits, los PR y las revisiones se redactan en español.

## Dependencias y Dependabot

[`dependabot.yml`](.github/dependabot.yml) revisa cada lunes las dependencias de `pub`, `gradle` y `github-actions`, y abre los PR contra `develop`:

- Las actualizaciones *minor* y *patch* se agrupan en un solo PR por ecosistema. `dependabot-automerge.yml` las aprueba y las fusiona cuando el CI pasa.
- Las actualizaciones *major* quedan abiertas para revisión manual.

## Versiones

| Versión | Fecha | Contenido |
| --- | --- | --- |
| `v0.1.0-sprint1` | 25-sep-2026 | Sprint 1: registro e inicio de sesión con Keycloak, intereses y feed de eventos, CRUD de planes, CI con SonarCloud y APK de pruebas |

### Registro pendiente en el backend (QHP-92 / QHP-94)

El frontend requiere el backend QHP-93 con la migración V7. Tras login, registro
o restauración consulta POST /api/v1/registrations/me: PENDING abre selección de
rol y COMPLETED habilita dashboard. Nombre y apellidos se precargan desde
given_name y family_name de los tokens OIDC.

Después del perfil e intereses se confirma POST /api/v1/registrations/me/complete
antes de habilitar dashboard. Atrás desde selección de rol llama DELETE
/api/v1/registrations/me antes de cerrar sesión. Si falla, conserva formulario y
sesión para reintentar. Cancelar dentro de Keycloak antes de obtener tokens sigue
volviendo al vídeo sin errores. Cerrar el proceso no ejecuta una cancelación
garantizada; el siguiente login recupera el estado pendiente del backend.

Verificar ambos roles y la reutilización del correo tras cancelar con
Keycloak/API reales. No activar esta versión del cliente contra el backend
anterior que carece de estas rutas.

Después de editar nombre/apellidos, el backend sincroniza Keycloak y Flutter
renueva los tokens y recarga el perfil. Si falla la renovación tras un guardado
confirmado, la app informa que los datos se guardaron y pide volver a iniciar
sesión para actualizar los claims. No confundirlo con un fallo de persistencia.
