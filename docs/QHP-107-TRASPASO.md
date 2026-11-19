# Traspaso QHP-107 — filtro de radio del mapa

Fecha: 19 de noviembre de 2026 (Bogotá).

## Estado publicado

- Backend: [PR #18](https://github.com/bratev-dev/quehaypa-microservices/pull/18) fusionado a `develop` mediante squash (`cb783e4`). `GET /api/v1/events` acepta `latitude`, `longitude` y `radiusKm` juntos; valida radio de 1 a 20 km y filtra con PostGIS antes de paginar. CI y SonarCloud aprobaron; 98,1 % de cobertura en código nuevo. Suite local con PostgreSQL/PostGIS: 112 pruebas, 0 fallos, 0 omitidas.
- Frontend: rama [feature/QHP-107-radio-busqueda-mapa](https://github.com/bratev-dev/quehaypa_frontend/tree/feature/QHP-107-radio-busqueda-mapa), código en el commit `0b1159e`, subido al remoto. Parte de `origin/develop` (`36db12d`). No se abrió PR Flutter todavía.

## Lo implementado en Flutter

- El mapa ofrece un control de radio de 1 a 20 km, con 5 km iniciales. Al moverlo, consulta eventos y actualiza los pines sin salir de la pantalla.
- La referencia manual tiene prioridad sobre GPS. Si no existe ninguna de las dos, se consulta el catálogo general. La ubicación de respaldo o última conocida no se envía como ubicación actual.
- El cliente envía latitud, longitud y radio en cada página de `GET /api/v1/events`. El proveedor descarta una respuesta anterior cuando cambia la búsqueda.
- Se conserva la UI existente de carga, vacío, error y reintento. Se añadieron pruebas del contrato HTTP, prioridades, control de radio y respuesta obsoleta.

## Verificación local

- `dart analyze`: **No issues found**.
- `flutter test --no-pub --reporter compact`: **567 pruebas aprobadas, 4 omitidas** por requerir entorno real.
- `git diff --check`: sin problemas; rama sincronizada con `origin` al publicar.
- Se creó `.env` local desde `.env.example` para compilar las pruebas; está ignorado por Git y no contiene secretos.

## Siguiente trabajo

1. Revisar el diff del commit `0b1159e` y comparar la presentación del control de radio con Figma. El control actual abre una hoja con `Slider` y actualiza la búsqueda al moverlo.
2. Probar en dispositivo con backend real: radio 1, 5 y 20 km; punto manual, GPS tardío, retorno a ubicación actual, ausencia de permiso/GPS, estados vacío y error con reintento. Validar pines justo dentro y fuera del límite.
3. La compilación debug con `MAP_EVENTS_PREVIEW=true` sigue mostrando los tres eventos de muestra sin aplicar el radio. Usar el backend real para la validación de QHP-107; decidir si la vista de prueba también debe filtrar por distancia.
4. Abrir PR Flutter hacia `develop` con título `feat(QHP-107): filtrar eventos del mapa por radio`, iniciar la descripción con `[IA-ASISTIDO]`, marcar uso de IA y enlazar Jira QHP-107. Esperar CI, SonarCloud y revisión antes de fusionar.
5. Tras QHP-107, continuar con QHP-118 (guardar desde la tarjeta del mapa en un plan) según `Sprint-3-traspaso.md` del escritorio.

## Traer los cambios a otra PC

En una copia existente de `quehaypa_frontend`:

```bash
git fetch origin
git switch --track origin/feature/QHP-107-radio-busqueda-mapa
flutter pub get
```

Si la rama ya existe localmente, usar `git switch feature/QHP-107-radio-busqueda-mapa` y `git pull --ff-only`. El backend correspondiente está en `develop` de `bratev-dev/quehaypa-microservices` desde el commit `cb783e4`.
