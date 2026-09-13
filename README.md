# Qué Hay Pa'? — Frontend

[![Flutter CI](https://github.com/bratev-dev/quehaypa_frontend/actions/workflows/flutter-ci.yml/badge.svg)](https://github.com/bratev-dev/quehaypa_frontend/actions/workflows/flutter-ci.yml)
![Flutter](https://img.shields.io/badge/Flutter-3.47.3-02569B?logo=flutter&logoColor=white)
![Dart](https://img.shields.io/badge/Dart-3.13-0175C2?logo=dart&logoColor=white)
![Platform](https://img.shields.io/badge/platform-Android-3DDC84?logo=android&logoColor=white)

Aplicación móvil cliente de **Qué Hay Pa'?**, construida en Flutter. Consume la [API de backend](https://github.com/bratev-dev/quehaypa_backend) mediante REST y delega la autenticación a un servidor de identidad OAuth2/OIDC (Keycloak).

Este repositorio contiene únicamente el frontend. El backend (Spring Boot) y la infraestructura de identidad viven en repositorios/servicios independientes.

---

## Tabla de contenidos

- [Arquitectura](#arquitectura)
- [Stack tecnológico](#stack-tecnológico)
- [Estructura del proyecto](#estructura-del-proyecto)
- [Requisitos previos](#requisitos-previos)
- [Configuración de entornos](#configuración-de-entornos)
- [Puesta en marcha](#puesta-en-marcha)
- [Pruebas y calidad de código](#pruebas-y-calidad-de-código)
- [Compilación para distribución](#compilación-para-distribución)
- [Integración continua](#integración-continua)
- [Flujo de ramas y contribución](#flujo-de-ramas-y-contribución)

---

## Arquitectura

El proyecto sigue **Clean Architecture** por feature, con la capa de presentación organizada bajo los principios de **Atomic Design**:

```
feature/
├── data/            # Fuentes de datos, modelos y repositorios concretos
├── domain/          # Entidades y casos de uso (reglas de negocio puras)
└── presentation/
    ├── atoms/       # Componentes UI mínimos y reutilizables (botones, campos)
    ├── molecules/   # Composición de átomos (formularios)
    ├── organisms/   # Secciones completas de una pantalla (headers, heroes)
    ├── templates/   # Layout de una pantalla, sin lógica de estado
    ├── pages/       # Widgets con estado, conectados a los controladores
    └── controllers/ # Estado de la feature (Riverpod)
```

La capa `domain` no depende de Flutter ni de ningún paquete externo, lo que permite testear las reglas de negocio de forma aislada. La comunicación entre capas fluye en una sola dirección: `presentation → domain → data`.

## Stack tecnológico

| Categoría          | Tecnología                                          |
| ------------------ | ---------------------------------------------------- |
| Framework           | [Flutter](https://flutter.dev) 3.47.3 (Dart 3.13)    |
| Gestión de estado   | [Riverpod](https://riverpod.dev) 3.x                 |
| Navegación          | [go_router](https://pub.dev/packages/go_router)      |
| Autenticación       | [flutter_appauth](https://pub.dev/packages/flutter_appauth) (OAuth2 / OIDC contra Keycloak) |
| Cliente HTTP        | [Dio](https://pub.dev/packages/dio)                  |
| Almacenamiento seguro | [flutter_secure_storage](https://pub.dev/packages/flutter_secure_storage) |
| CI/CD               | GitHub Actions                                       |

> **Nota sobre plataformas:** `flutter_appauth` no tiene implementación web. El flujo de login solo está soportado en Android e iOS; en web la navegación es funcional pero la autenticación no.

## Estructura del proyecto

```
frontend/
├── android/                  # Proyecto nativo Android
├── assets/
│   ├── images/                # SVGs e imágenes estáticas
│   └── videos/                 # Recursos multimedia
├── lib/
│   ├── app/
│   │   ├── config/              # AppConfig por entorno (development/production)
│   │   ├── providers/           # Providers transversales (red, sesión)
│   │   └── router/               # Configuración de GoRouter, rutas y nombres
│   ├── core/
│   │   ├── errors/                # Excepciones y failures compartidos
│   │   ├── network/                # Cliente Dio e interceptores
│   │   └── security/                # Gestión de tokens y sesión
│   ├── features/
│   │   ├── authentication/          # Login, registro, sesión
│   │   └── home/                     # Pantalla principal
│   └── main.dart
├── test/                      # Pruebas unitarias y de widgets
└── .github/workflows/          # Pipelines de CI
```

## Requisitos previos

- [Flutter SDK](https://docs.flutter.dev/get-started/install) `3.47.3` (usa `fvm` o `asdf` si necesitas fijar la versión exacta)
- Android SDK / [Android Studio](https://developer.android.com/studio) para compilar y depurar en Android
- Un backend y una instancia de Keycloak accesibles (locales o remotos) — ver [Configuración de entornos](#configuración-de-entornos)

Verifica tu entorno con:

```bash
flutter doctor -v
```

## Configuración de entornos

La app no hardcodea URLs de backend. El entorno activo se resuelve en `lib/app/config/app_config.dart` a partir de variables inyectadas en tiempo de compilación (`--dart-define`).

### Desarrollo local

Por defecto, `AppConfig.fromEnvironment()` usa el entorno `development`, que apunta a `localhost`. Si vas a probar desde un dispositivo físico (no un emulador), el celular no puede resolver `localhost` como tu máquina — pasa la IP LAN de tu PC:

```bash
flutter run --dart-define=BACKEND_HOST=192.168.1.19
```

### Producción / demo

Para apuntar a un backend desplegado, compila con `ENV=production` y las URLs correspondientes:

```bash
flutter build apk --release \
  --dart-define=ENV=production \
  --dart-define=API_BASE_URL=https://<tu-backend>.example.com \
  --dart-define=KEYCLOAK_ISSUER_URL=https://<tu-keycloak>.example.com/realms/<realm>
```

> Ninguna URL de infraestructura vive en el código fuente. Solicita las URLs vigentes a quien administre los despliegues del equipo.

## Puesta en marcha

```bash
# 1. Clonar el repositorio
git clone https://github.com/bratev-dev/quehaypa_frontend.git
cd quehaypa_frontend

# 2. Instalar dependencias
flutter pub get

# 3. Ejecutar en modo desarrollo (emulador o dispositivo conectado)
flutter run
```

## Pruebas y calidad de código

Antes de abrir un Pull Request, corre localmente lo mismo que valida el pipeline de CI:

```bash
# Formato de código
dart format --output=none --set-exit-if-changed .

# Análisis estático
flutter analyze

# Pruebas unitarias y de widgets
flutter test --coverage
```

## Compilación para distribución

```bash
# APK de debug (rápido, para pruebas internas)
flutter build apk --debug

# APK de release apuntando a producción
flutter build apk --release \
  --dart-define=ENV=production \
  --dart-define=API_BASE_URL=<url> \
  --dart-define=KEYCLOAK_ISSUER_URL=<url>
```

El APK generado queda en `build/app/outputs/flutter-apk/`.

## Integración continua

El workflow [`flutter-ci.yml`](.github/workflows/flutter-ci.yml) se ejecuta en cada push y Pull Request contra `main` y `develop`, y valida en orden:

1. **Formato** — `dart format --set-exit-if-changed`
2. **Análisis estático** — `flutter analyze`
3. **Pruebas** — `flutter test --coverage` (el reporte de cobertura se publica como artefacto)
4. **Build de verificación** — compila un APK de debug para confirmar que el proyecto completo (incluyendo el toolchain de Android/Gradle) sigue siendo compilable

Dependabot mantiene actualizadas las dependencias de Dart/Flutter, Gradle y las propias GitHub Actions (ver [`dependabot.yml`](.github/dependabot.yml)).

## Flujo de ramas y contribución

Este repositorio está conectado a Jira (proyecto **QHP**) mediante la app oficial **GitHub for Jira**. Cualquier rama, commit o Pull Request cuyo nombre incluya una clave `QHP-<número>` aparece automáticamente en el panel de desarrollo del issue correspondiente en Jira.

| Rama                             | Propósito                                                          |
| --------------------------------- | -------------------------------------------------------------------- |
| `main`                             | Código estable, listo para distribución/demo                        |
| `develop`                          | Integración de features antes de pasar a `main`                     |
| `feature/QHP-<n>-<descripción>`    | Desarrollo de una Historia de Usuario (issue tipo *Story* en Jira)   |
| `fix/QHP-<n>-<descripción>`        | Corrección de un error (issue tipo *Bug* en Jira)                    |
| `chore/QHP-<n>-<descripción>`      | Mantenimiento: config, dependencias, limpieza (issue tipo *Task*)    |
| `hotfix/QHP-<n>-<descripción>`     | Parche urgente sobre producción (issue tipo *Bug* urgente)            |

**Convención de nombres:**

```
<tipo>/QHP-<número>-<descripción-corta-en-kebab-case>
```

- `QHP-<número>` es la clave **real** del issue en Jira, tal cual aparece en él — nunca una numeración propia (ej. no usar `1.2` de Épica.Historia).
- La descripción va en español, en kebab-case, y es solo para que el equipo identifique la rama de un vistazo; Jira ignora esa parte.
- Ejemplos: `feature/QHP-123-login-con-google`, `fix/QHP-145-crash-al-abrir-perfil`, `chore/QHP-150-actualizar-dependencias`, `hotfix/QHP-160-token-expirado-en-produccion`.

**Reglas:**

- Toda rama `feature/*`, `fix/*` o `chore/*` se crea a partir de `develop` actualizada.
- Toda rama `hotfix/*` se crea a partir de `main` y, al mergear, se integra tanto a `main` como a `develop`.
- Un branch corresponde a un único issue de Jira (relación 1:1). Si el trabajo abarca más de una historia o bug, se abren ramas separadas.
- Nunca reutilices la clave de un issue en otra rama; si retomas el trabajo, continúa en la misma rama en lugar de crear una `-v2`.
- Los Pull Requests hacia `main` y `develop` están protegidos: requieren que el CI pase en verde.
- Después de mergear un PR a `main`, sincroniza `develop` (`main → develop`) para que ninguna rama nueva parta de una base desactualizada.
- Incluye la clave de Jira también en el título del Pull Request (ej: `[QHP-123] Login con Google`) — ver plantilla.
- Los commits y los Pull Requests se redactan en español.

Usa la [plantilla de Pull Request](.github/pull_request_template.md) del repositorio al abrir tu PR.
