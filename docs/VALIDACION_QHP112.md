# QHP-112: conexión del frontend y organizador

Validación del 27 de octubre de 2026 (America/Bogota).

## Alcance y diseño

La rama `feature/QHP-112-conexion-railway` parte de `develop` `4e8df2f`.
Conecta el calendario y el formulario de creación existentes al gateway de
Railway. Mapa y Eventos conservan sus marcadores originales; no se añaden
pantallas de demo. Se restauraron las cinco opciones de navegación del
organizador, las tarjetas y la presentación original de planes.

Se cargan imágenes reales dentro de los espacios existentes. Se mantienen los
controles originales de negocio opcional, categoría, pago, audiencia, enlaces,
adjuntos y guardar borrador. El pago es un dato del evento, sin cobros.

Si el organizador no tiene negocios, se crea el negocio ficticio acordado por
el endpoint protegido y se reutiliza en consultas posteriores. El backend
obtiene el dueño del JWT y devuelve el ID; Flutter no inventa IDs ni dueños.
El NIT `DEMO-SIN-VALIDEZ-FISCAL` identifica ese registro de prueba.

## Arquitectura y seguridad

Revisado contra la Guía de Arquitectura y Estándares de Desarrollo del equipo:

- Presentation coordina la UI mediante controlador y casos de uso.
- Domain contiene contratos y valores tipados de eventos y borradores, sin
  Flutter, Dio, HTTP, JSON ni dependencias de Presentation.
- Data interpreta JSON, usa Dio y transforma errores técnicos en Failure.
- El modelo de sesión interpreta los claims; la entidad del dominio contiene
  datos ya interpretados. El rol solo orienta la navegación; autoriza el backend.
- Se reutilizan PKCE, almacenamiento seguro e interceptor centralizado, incluido
  el reintento multipart tras renovar la sesión.
- Tokens de pruebas solo en memoria del proceso; sin credenciales en Git o APK.

La UI conserva los archivos ya subidos si falla uno posterior y reintenta desde
el pendiente. La publicación conserva su identificador para consultar el mismo
resultado tras una respuesta perdida, evitando duplicar eventos.

## Verificaciones

- `flutter analyze`: sin incidencias.
- Suite Flutter: 529 pruebas aprobadas y dos pruebas remotas optativas omitidas
  en la corrida general. Después se añadieron dos casos del repositorio y sus
  doce pruebas aprobaron; CI ejecuta el conjunto completo actualizado.
- Ocho comparaciones píxel a píxel con el código de `origin/develop`: tres pasos
  del formulario, navegación de ambos roles y tarjetas de inicio, calendario y
  planes. Todas coincidieron con los mismos datos de prueba y render de Flutter.
  Son comparaciones de esos componentes, no de cada pantalla de la aplicación.
- Las dos pruebas optativas contra Railway se ejecutaron aparte y aprobaron:
  categorías/catálogo y recorrido de organizador con negocio, borrador, PNG,
  publicación idempotente, consulta de calendario, imagen pública, catálogo y
  feed del usuario. El evento técnico fue eliminado; se conserva el negocio
  ficticio por usuario que requiere el flujo acordado.
- APK debug compilado correctamente con gateway e issuer HTTPS explícitos.

Los archivos de comparación y logs locales están en `build/ui-review/` y archivos
`local-front-*.log`, fuera del código publicado. La aceptación manual en teléfono
queda a cargo del equipo; no se presenta como realizada.

## Probar la entrega

```powershell
flutter pub get
flutter analyze
flutter test --coverage
flutter build apk --debug --dart-define=API_BASE_URL=https://api-gateway-production-b74fe.up.railway.app --dart-define=KEYCLOAK_ISSUER_URL=https://keycloak-production-58e17.up.railway.app/realms/que-hay-pa-dev
```

`.env.example` contiene solo configuración pública de Railway. Los valores de
compilación tienen precedencia sobre `.env`. La variable de repositorio
`API_BASE_URL` para la publicación de APKs se corrigió del monolito al gateway.

En teléfono: iniciar como organizador, abrir Crear evento desde el calendario,
elegir negocio o Sin negocio, categoría y fecha futura, adjuntar una imagen y
guardar borrador. Reabrirlo, publicar y comprobar el evento en el calendario.
Con usuario regular, comprobar el evento y su imagen en el feed y catálogo.
