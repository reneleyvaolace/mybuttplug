# 📱 Guía de Desarrollo Multi-Plataforma

**Versión:** 1.0.0  
**Fecha:** 2026-03-19  
**Estado:** ✅ Lista para producción

---

## 🎯 Visión General

Velvet Sync Platform ahora soporta **múltiples plataformas** desde una sola base de código:

| Plataforma | Estado | BLE Nativo | Buttplug WS | Backend Requerido |
|------------|--------|------------|-------------|-------------------|
| **Android** | ✅ Completo | ✅ Sí | ✅ Sí | ❌ No |
| **iOS** | ✅ Completo | ✅ Sí | ✅ Sí | ❌ No |
| **Windows** | 🟡 Parcial | 🟡 Limitado | ✅ Sí | 🟡 Opcional |
| **macOS** | 🟡 Parcial | 🟡 Limitado | ✅ Sí | 🟡 Opcional |
| **Linux** | 🟡 Parcial | 🟡 Limitado | ✅ Sí | 🟡 Opcional |
| **Web** | 🟡 Parcial | ❌ No | ✅ Sí | ✅ Sí |

---

## 🏗️ Arquitectura Multi-Plataforma

```
┌─────────────────────────────────────────────────────────────────┐
│                    TU CÓDIGO (Dart)                             │
│  - Core Types                                                   │
│  - HAL                                                          │
│  - Protocols                                                    │
│  - Models                                                       │
│  - Utils                                                        │
└─────────────────────────────────────────────────────────────────┘
                              ▼
┌─────────────────────────────────────────────────────────────────┐
│              CAPA DE ABSTRACCIÓN (Platform Info)                │
│  - platform_info.dart                                           │
│  - ble_service_platform.dart                                    │
└─────────────────────────────────────────────────────────────────┘
                              ▼
┌─────────────────────────────────────────────────────────────────┐
│              IMPLEMENTACIÓN POR PLATAFORMA                      │
│  ┌──────────┐  ┌──────────┐  ┌──────────┐                      │
│  │  Mobile  │  │ Desktop  │  │   Web    │                      │
│  │ Android  │  │ Windows  │  │ Flutter  │                      │
│  │   iOS    │  │  macOS   │  │   HTML   │                      │
│  │          │  │  Linux   │  │   JS     │                      │
│  └────┬─────┘  └────┬─────┘  └────┬─────┘                      │
│       │             │             │                              │
│       ▼             ▼             ▼                              │
│  ┌──────────┐  ┌──────────┐  ┌──────────┐                      │
│  │flutter_  │  │Buttplug  │  │Backend   │                      │
│  │blue_plus │  │WebSocket │  │Python/   │                      │
│  │          │  │          │  │Node.js   │                      │
│  └──────────┘  └──────────┘  └──────────┘                      │
└─────────────────────────────────────────────────────────────────┘
```

---

## 📦 Estructura de Archivos

```
lib/
├── core/
│   ├── platform_info.dart           # ← NUEVO: Detección de plataforma
│   ├── types/                       # ✅ Portable a TODAS
│   ├── hal/                         # ✅ Portable a TODAS
│   ├── protocols/                   # ✅ Portable a TODAS
│   └── config/                      # ✅ Portable a TODAS
│
├── ble/
│   ├── ble_service_platform.dart    # ← NUEVO: Export condicional
│   ├── ble_service_mobile.dart      # ← NUEVO: Android/iOS
│   ├── ble_service_desktop.dart     # ← NUEVO: Windows/macOS/Linux
│   ├── ble_service_web.dart         # ← NUEVO: Web (WebSocket)
│   └── ble_service.dart             # Original (LVS nativo)
│
├── services/
│   ├── buttplug_bridge_service.dart # ✅ Portable (WebSocket)
│   └── ...                          # ✅ Todos portables
│
├── models/                          # ✅ Portable a TODAS
├── utils/                           # ✅ Portable a TODAS
├── widgets/                         # ✅ Portable a TODAS
└── screens/                         # ✅ Portable (ajustes responsive)
```

---

## 🔧 Configuración por Plataforma

### Android/iOS (Mobile)

**pubspec.yaml:**
```yaml
dependencies:
  flutter_blue_plus: ^2.x  # ✅ BLE nativo
  buttplug: ^1.0.0         # ✅ Buttplug WebSocket
```

**main.dart:**
```dart
import 'package:velvet_sync/ble/ble_service_platform.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Obtiene servicio BLE automático según plataforma
  final ble = getBleService();
  await ble.initialize();
  
  runApp(MyApp());
}
```

---

### Windows/macOS/Linux (Desktop)

**pubspec.yaml:**
```yaml
dependencies:
  # flutter_blue_plus NO incluido (limitado en desktop)
  buttplug: ^1.0.0         # ✅ Buttplug WebSocket (recomendado)
```

**main.dart:**
```dart
import 'package:velvet_sync/ble/ble_service_platform.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Desktop usa Buttplug WebSocket automáticamente
  final ble = getBleService();
  await ble.initialize(
    buttplugUrl: 'ws://localhost:12345',
  );
  
  runApp(MyApp());
}
```

**Requisitos:**
- Usuario debe instalar Intiface Engine
- O usar backend Python/Node.js

---

### Web

**pubspec.yaml:**
```yaml
dependencies:
  web_socket_channel: ^2.4.0  # ✅ WebSocket para Web
  # NO incluir flutter_blue_plus (no funciona en Web)
  # NO incluir buttplug (requiere WebSocket backend)
```

**main.dart:**
```dart
import 'package:velvet_sync/ble/ble_service_platform.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Web requiere backend BLE
  final ble = getBleService();
  await ble.initialize(
    backendUrl: 'ws://tudominio.com:8000/ble',
  );
  
  runApp(MyApp());
}
```

**Requisitos:**
- Backend Python/Node.js corriendo en servidor
- Intiface Engine en mismo servidor
- WebSocket habilitado

---

## 📝 Código Portable vs Específico

### ✅ Código 100% Portable

```dart
// lib/core/types/device_types.dart
enum DeviceType { vibrator, egg, bullet, ... }
// ✅ Funciona en TODAS las plataformas

// lib/models/toy_model.dart
class ToyModel {
  final String id;
  final String name;
  // ...
}
// ✅ Funciona en TODAS las plataformas

// lib/services/buttplug_bridge_service.dart
class ButtplugBridgeService {
  Future<void> connect() async {
    await _client.connect('ws://localhost:12345');
  }
}
// ✅ WebSocket funciona en TODAS las plataformas
```

### ⚠️ Código Específico por Plataforma

```dart
// lib/ble/ble_service_mobile.dart
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
// ❌ Solo Android/iOS

// lib/ble/ble_service_web.dart
import 'package:web_socket_channel/web_socket_channel.dart';
// ❌ Solo Web (requiere backend)

// lib/ble/ble_service_desktop.dart
// Usa Buttplug WebSocket en lugar de BLE nativo
// ❌ Solo Windows/macOS/Linux
```

---

## 🎯 Patrones de Diseño Multi-Plataforma

### 1. **Conditional Imports**

```dart
// lib/ble/ble_service_platform.dart
export 'ble_service_mobile.dart'
  if (dart.library.html) 'ble_service_web.dart'
  if (dart.library.io) 'ble_service_desktop.dart';
```

**Uso:**
```dart
import 'package:velvet_sync/ble/ble_service_platform.dart';

final ble = getBleService();  // Automáticamente obtiene el correcto
```

---

### 2. **Platform Detection**

```dart
import 'package:velvet_sync/core/platform_info.dart';

if (PlatformInfo.isWeb) {
  // Web-specific code
  await ble.initialize(backendUrl: 'ws://server/ble');
} else if (PlatformInfo.isMobile) {
  // Mobile-specific code
  await ble.initialize();  // BLE nativo
} else if (PlatformInfo.isDesktop) {
  // Desktop-specific code
  await ble.initialize(buttplugUrl: 'ws://localhost:12345');
}
```

---

### 3. **Feature Detection**

```dart
import 'package:velvet_sync/core/platform_info.dart';

if (PlatformFeature.nativeBle.isAvailable) {
  // Usar BLE nativo
  await ble.scan();
} else {
  // Usar backend/Buttplug
  await buttplugBridge.connect();
}
```

---

## 🚀 Build por Plataforma

### Android

```bash
flutter build apk --release
flutter build appbundle --release
```

### iOS

```bash
flutter build ios --release
```

### Windows

```bash
flutter build windows --release
```

### macOS

```bash
flutter build macos --release
```

### Linux

```bash
flutter build linux --release
```

### Web

```bash
flutter build web --release
```

---

## 📊 Matriz de Características

| Característica | Android | iOS | Windows | macOS | Linux | Web |
|----------------|---------|-----|---------|-------|-------|-----|
| **BLE Nativo** | ✅ | ✅ | 🟡 | 🟡 | 🟡 | ❌ |
| **Buttplug WS** | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ |
| **Foreground Service** | ✅ | ❌ | ❌ | ❌ | ❌ | ❌ |
| **Background BLE** | ✅ | ✅ | ❌ | ❌ | ❌ | ❌ |
| **System Tray** | ❌ | ❌ | ✅ | ✅ | ✅ | ❌ |
| **Deep Linking** | ✅ | ✅ | 🟡 | 🟡 | 🟡 | ❌ |
| **File System** | ✅ | ✅ | ✅ | ✅ | ✅ | 🟡 |
| **Notifications** | ✅ | ✅ | ✅ | ✅ | ✅ | 🟡 |

**Leyenda:**
- ✅ = Soporte completo
- 🟡 = Soporte limitado/parcial
- ❌ = No disponible

---

## 🛠️ Troubleshooting

### Problema: "dart:io no encontrado en Web"

**Solución:**
```dart
// ❌ MALO
import 'dart:io';

// ✅ BUENO
import 'dart:io' if (dart.library.html) 'dart:html';

// O mejor, usar PlatformInfo:
import 'package:velvet_sync/core/platform_info.dart';

if (!PlatformInfo.isWeb) {
  // Código que usa dart:io
}
```

---

### Problema: "flutter_blue_plus no funciona en Desktop"

**Solución:** Usar Buttplug WebSocket en lugar de BLE nativo:

```dart
// ✅ Desktop usa Buttplug automáticamente
final ble = getBleService();  // ble_service_desktop.dart
await ble.initialize(buttplugUrl: 'ws://localhost:12345');
```

---

### Problema: "Web no tiene acceso BLE"

**Solución:** Crear backend Python/Node.js:

```
┌─────────────┐     WebSocket     ┌──────────────┐
│  Web App    │ ◄───────────────► │   Backend    │
│  (Flutter)  │   ws://server     │   (Python)   │
└─────────────┘                   └──────────────┘
                                           │
                                     BLE/USB
                                           │
                                           ▼
                                  ┌──────────────┐
                                  │ Dispositivos │
                                  └──────────────┘
```

**Ver:** [BACKEND_WEB_REFERENCE.md](BACKEND_WEB_REFERENCE.md)

---

## ✅ Checklist por Plataforma

### Mobile (Android/iOS)

- [ ] `flutter_blue_plus` en pubspec.yaml
- [ ] Permisos BLE en AndroidManifest.xml / Info.plist
- [ ] Foreground service configurado (Android)
- [ ] Background modes (iOS)

### Desktop (Windows/macOS/Linux)

- [ ] Buttplug en pubspec.yaml
- [ ] Documentación de instalación de Intiface Engine
- [ ] System tray icon (opcional)
- [ ] Auto-start (opcional)

### Web

- [ ] Backend Python/Node.js implementado
- [ ] WebSocket URL configurada
- [ ] HTTPS en producción
- [ ] CORS configurado
- [ ] Autenticación si es público

---

## 📚 Recursos Adicionales

### Documentación

- [Platform Info API](../lib/core/platform_info.dart)
- [BLE Service Platform](../lib/ble/ble_service_platform.dart)
- [Backend Web Reference](BACKEND_WEB_REFERENCE.md)
- [Intiface Engine Setup](INTIFACE_ENGINE_SETUP.md)

### Enlaces Externos

- [Flutter Multi-Platform](https://docs.flutter.dev/multi-platform)
- [Buttplug.io](https://buttplug.io)
- [Intiface Engine](https://github.com/intiface/intiface-engine)

---

*Guía generada: 2026-03-19*  
*Velvet Sync Platform - Multi-Platform Guide v1.0.0*
