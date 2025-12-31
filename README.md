# Asistencia App (Flutter) — Sistema de Asistencia Escolar

Aplicación móvil desarrollada en **Flutter** para el **registro y consulta de asistencias** en un entorno escolar.  
Este cliente se integra con un **backend REST en Express + MySQL**, con autenticación basada en **JWT** y control de acceso por **rol/grados (RBAC)**.

> Este repositorio corresponde al **cliente Flutter**. El backend (Express) se mantiene como proyecto separado.

---

## Contenido
- [Objetivo del proyecto](#objetivo-del-proyecto)
- [Alcance funcional](#alcance-funcional)
- [Stack tecnológico](#stack-tecnológico)
- [Arquitectura y decisiones de diseño](#arquitectura-y-decisiones-de-diseño)
- [Estructura del proyecto](#estructura-del-proyecto)
- [Integración con backend (API)](#integración-con-backend-api)
- [Reglas de negocio](#reglas-de-negocio)
- [Configuración y ejecución](#configuración-y-ejecución)
- [Calidad de código](#calidad-de-código)
- [Roadmap](#roadmap)
- [Licencia](#licencia)
- [Créditos](#creditos)

---

## Objetivo del proyecto

Digitalizar el proceso de asistencia escolar reduciendo el registro manual, estandarizando estados de asistencia y habilitando consultas por **grado, sección y fecha**, con trazabilidad hacia el backend institucional.

---

## Alcance funcional

Funcionalidades principales del cliente:

- **Autenticación (login)** y persistencia segura de sesión mediante token.
- **Selección de contexto**: grado, sección y fecha.
- **Listado de estudiantes** por grado/sección.
- **Registro y actualización** de asistencia (estados como `A`, `FI`, `FJ`, `TI` y `TJ`).
- **Consulta de asistencias** (listados/historial según endpoints disponibles).
- **Validación de calendario** para evitar registros en días **no laborables** (fin de semana y feriados).

---

## Stack tecnológico

**Framework / Lenguaje**
- Flutter (Dart) — `sdk: ">=3.7.0 <4.0.0"`

**Paquetes principales**
- `provider`: gestión de estado con `ChangeNotifier` (ViewModels).
- `dio`: cliente HTTP (headers, interceptores, timeouts, errores).
- `flutter_secure_storage`: almacenamiento seguro del token.
- `jwt_decoder`: lectura/validación de claims del JWT (rol, expiración).
- `intl`: formato de fechas y utilidades.
- `table_calendar`: selección/visualización de fechas.

---

## Arquitectura y decisiones de diseño

Enfoque práctico tipo **MVVM (ligero)**:

- **Views (UI)**: pantallas Flutter (widgets) responsables de render e interacción.
- **ViewModels (`ChangeNotifier`)**: contienen estado, orquestan flujos y coordinan llamadas a servicios.
- **Services**: encapsulan consumo de API y detalles HTTP; desacoplan la UI del backend.
- **Models**: mapeo de DTOs (`fromJson` / `toJson`).

### Decisiones clave

1. **Provider + ChangeNotifier** (simplicidad y legibilidad)  
   Se priorizó un patrón directo y de baja complejidad para un proyecto académico con alcance definido.

2. **Dio como cliente HTTP**  
   Facilita interceptores (JWT), estandarización de headers y manejo consistente de errores.

3. **Token en Secure Storage**  
   Persistencia de sesión sin exponer credenciales en almacenamiento inseguro.

4. **Reglas de calendario centralizadas**  
   La lógica de feriados/fines de semana se ubica en `utils/` para reutilización y consistencia.

---

## Estructura del proyecto

Estructura típica observada en `lib/`:

```text
lib/
  core/
    api_config.dart
  models/
    ...
  services/
    asistencia_service.dart
    auth_service.dart
    estudiante_service.dart
    navigation_service.dart
    parametros_service.dart
  theme/
    app_colors.dart
    app_theme.dart
  utils/
    calendar_rules.dart
  viewmodels/
    asistencia_viewmodel.dart
    auth_viewmodel.dart
    estudiante_viewmodel.dart
    grados_viewmodel.dart
    registro_asistencia_viewmodel.dart
    seccion_viewmodel.dart
  views/
    auxiliar/
      home_screen.dart
      grados_screen.dart
      seccion_screen.dart
      estudiantes_screen.dart
      asistencia_screen.dart
      asistencia_list_screen.dart
      seleccionar_grado_seccion_screen.dart
      seleccionar_grado_seccion_fecha_screen.dart
    login/
      login_screen.dart
    splash/
      splash_screen.dart
  main.dart
```

**Descripción por capa**
- `core/`: configuración transversal (baseUrl/cliente Dio).
- `models/`: modelos y mapeo JSON.
- `services/`: consumo de endpoints y reglas de integración.
- `viewmodels/`: estado y lógica de presentación.
- `views/`: pantallas organizadas por módulo.
- `theme/`: tema/colores.
- `utils/`: utilitarios (calendario, validaciones comunes).

---

## Integración con backend (API)

El cliente está diseñado para operar con un backend REST (Express + MySQL). Endpoints típicos:

### Auth
- `POST /auth/login`
- `GET /auth/me`

### Catálogos / Parámetros
- `GET /grados`
- `GET /secciones`  
*(En el cliente puede aparecer como `/parametros/grados` y `/parametros/secciones` según tu routing/gateway.)*

### Asistencias
- `GET /asistencias`
- `POST /asistencias`
- `PUT /asistencias/:id_asistencia`
- `DELETE /asistencias/:id_asistencia`
- `GET /asistencias/historial`
- `GET /asistencias/:grado/:seccion`
- `GET /asistencias/:grado/:seccion/:fecha`
- `GET /asistencias-mes?mes=&anio=`

### Alumnos
- `GET /alumnos/:grado/:seccion`

### Autorización (RBAC)

El backend aplica control por rol y grados, por ejemplo:
- `administrador`: sin restricción de grados.
- `auxiliar_mañana`: grados 4º–5º.
- `auxiliar_tarde`: grados 1º–3º.

El cliente:
- almacena el token en **Secure Storage**,
- decodifica claims (rol/exp) para validaciones básicas,
- envía el token por header (p.ej. `Authorization: Bearer <token>`).

---

## Reglas de negocio

- **Días no laborables**: fin de semana y feriados (en `utils/calendar_rules.dart`).  
  Se evita/advierte el registro de asistencias en fechas no válidas.
- **Contexto obligatorio**: el registro se realiza sobre **grado + sección + fecha**.
- **Estados de asistencia**: soporta estados definidos por negocio (ej. `A`, `FI`, `FJ`, `TI`).  
  Recomendación: mantener el catálogo como fuente de verdad en backend y reflejarlo en UI.

---

## Configuración y ejecución

### Requisitos
- Flutter SDK compatible con `>=3.7.0 <4.0.0`
- Android Studio (emulador) o dispositivo físico
- Backend Express accesible desde el dispositivo/emulador

### 1) Instalar dependencias
```bash
flutter pub get
```

### 2) Configurar `baseUrl`
Editar `lib/core/api_config.dart` y ajustar el `baseUrl`.

Ejemplos:
- Emulador Android: `http://10.0.2.2:PUERTO`
- Dispositivo físico (misma red): `http://IP_DE_TU_PC:PUERTO`

### 3) Ejecutar
```bash
flutter run
```

### 4) Build APK (release)
```bash
flutter build apk --release
```

---

## Calidad de código

- Linting: `flutter_lints`.
- Nota: si existen `print()` en ViewModels, se recomienda migrar a logging estructurado (ej. paquete `logger`) y estandarizar niveles (info/warn/error).

---

## Roadmap

Mejoras sugeridas:

- Interceptores Dio: manejo uniforme de `401/403`, expiración y reintentos.
- Manejo de errores: tipificar fallos (network/timeout/forbidden) y mensajes consistentes en UI.
- Tests: unit tests para ViewModels y Services (mock de Dio).
- Modularización por feature: agrupar `views/viewmodels/services` por dominio (asistencia, auth, alumnos).
- Soporte offline (opcional): caché local (SQLite/Drift) para contingencias sin red.
- Observabilidad: logging estructurado y métricas básicas (tiempo de respuesta, fallos por endpoint).

---

## Licencia

Este proyecto se distribuye bajo la licencia **MIT**.  
Consulta el archivo [`LICENSE`](LICENSE) para más detalles.

---

## Créditos
Proyecto desarrollado como parte del trabajo de grado/bachiller, orientado a un flujo realista de control
de asistencias escolar con separación cliente–servidor e implementación de control de acceso por rol.
