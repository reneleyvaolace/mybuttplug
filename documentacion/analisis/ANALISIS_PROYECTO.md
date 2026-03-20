# 📋 Análisis del Proyecto VelvetSyncApp

## Resumen Ejecutivo

**Repositorio:** https://github.com/reneleyvaolace/velvetsyncapp
**Versión Actual:** 1.4.0+1
**Estado:** ✅ Funcional con hardware real probado
**Tecnología:** Flutter (Dart) + BLE Peripheral Mode

---

## 🏗️ Arquitectura Actual

### Stack Tecnológico

| Componente | Tecnología | Versión |
|------------|-----------|---------|
| **Framework** | Flutter | 3.x (Dart 3.3+) |
| **BLE Library** | flutter_blue_plus | ^2.2.1 |
| **BLE Peripheral** | flutter_ble_peripheral | ^2.1.0 |
| **State Management** | Riverpod + Provider | ^2.6.1 / ^6.1.5 |
| **Background Service** | flutter_foreground_task | ^9.2.1 |
| **Database** | Supabase | ^2.12.0 |

### Protocolo Implementado

**Dispositivos Soportados:**
- Love Spouse 8154 (wbMSE)
- Protocolo Broadlink Fastcon (brMesh)

**Especificaciones BLE:**
```
Company ID:     0xFFF0
Service UUID:   0000fff0-0000-1000-8000-00805f9b34fb
Advertising:    Peripheral Mode (no GATT persistent)
Prefijo:        wbMSE (77 62 4D 53 45)
```

**Modos de Paquete:**
```dart
// Modo 11B: [PREFIX 8B] + [CMD 3B]
[0x6D, 0xB6, 0x43, 0xCE, 0x97, 0xFE, 0x42, 0x7C] + [CMD]

// Modo 18B: [FF FF 00] + [PREFIX] + [CMD] + [03 03 8F AE]
[0xFF, 0xFF, 0x00] + [PREFIX 8B] + [CMD 3B] + [0x03, 0x03, 0x8F, 0xAE]
```

**Comandos Implementados:**
- ✅ Velocidad (Stop/Low/Med/High)
- ✅ Patrones rítmicos (6 modos)
- ✅ Dual Channel (8154)
- ✅ Control preciso 0-255
- ✅ Comando multimedia sincronizado (0xF6)

---

## 📁 Estructura del Proyecto

```
velvetsyncapp/
├── lib/
│   ├── main.dart                 # Entry point + ForegroundTask
│   ├── theme.dart                # Design system
│   │
│   ├── ble/                      # ← NÚCLEO BLE
│   │   ├── ble_service.dart      # Escaneo, conexión, burst mode
│   │   └── lvs_commands.dart     # Protocolo, comandos, paquetes
│   │
│   ├── models/                   # Modelos de datos
│   │   ├── toy_model.dart        # Catálogo de dispositivos
│   │   └── device_sync_model.dart
│   │
│   ├── services/                 # Servicios
│   │   ├── ai_hardware_bridge_service.dart  # ← IA → Hardware
│   │   ├── sync_service.dart     # Sincronización P2P
│   │   ├── supabase_service.dart # Backend
│   │   └── ai_service.dart       # IA
│   │
│   ├── screens/                  # UI
│   │   ├── home_screen.dart      # Control principal
│   │   ├── catalog_screen.dart   # Catálogo
│   │   ├── debug_screen.dart     # Debug mode
│   │   └── ...
│   │
│   └── utils/
│       ├── logger.dart           # Logging unificado
│       └── protocol_translator.dart
│
├── android/                      # Android nativo
├── ios/                          # iOS nativo
├── documentacion/tecnica/        # Docs técnicas
└── test/                         # Tests
```

---

## 🎯 Características Principales

### 1. BLE High Performance
- **Advertising Mode:** Envío de comandos vía Manufacturer Data (no GATT)
- **Burst Mode:** Envío continuo de comandos
- **Background Service:** Foreground service en Android para mantener BLE activo
- **Permisos completos:** Android 12+ (BLUETOOTH_SCAN/CONNECT/ADVERTISE)

### 2. Control de Dispositivos
- **Single Channel:** Dispositivos de 1 motor
- **Dual Channel:** Dispositivos de 2 motores (8154)
- **Precise Control:** Intensidad 0-255 (no solo 3 niveles)
- **Patrones Rítmicos:** 6 modos predefinidos

### 3. Sincronización
- **P2P Sync:** Sincronización entre dispositivos
- **AI Integration:** Puente IA → Hardware
- **Multimedia Sync:** Sincronización con audio

### 4. Catálogo
- **Supabase Backend:** Catálogo en la nube
- **CSV Import:** Carga masiva de dispositivos
- **QR Scanner:** Escaneo de códigos QR

---

## 🔍 Puntos Clave del Código

### ble_service.dart - Conexión BLE

```dart
// Handshake de verificación de hardware
static const List<int> verificationCmd = [0x01, 0x01, 0x01];
static const int expectedAck = 0x06;

Future<bool> verifyHardwareConnection() async {
  final bool ok = await writeCommand(verificationCmd, label: 'VERIFY_HW');
  return ok;
}

// Escritura de comandos con cola de rendimiento
Future<bool> writeCommand(List<int> cmdBytes, {...}) async {
  _commandQueue.add(_QueuedCommand(...));
  _processCommandQueue();
}
```

### lvs_commands.dart - Protocolo

```dart
// Comando Dual Sincronizado (0xF6)
static List<int> dualMotor(int m1, int m2) {
  return [0xF6, m1.clamp(0, 255), m2.clamp(0, 255)];
}

// Control preciso 0-255
static List<int> preciseChannel1(int intensity) {
  return [0xD6, 0x0D, intensity.clamp(0, 255)];
}
```

### ai_hardware_bridge_service.dart - IA → Hardware

```dart
class AIHardwareBridge {
  // Escucha eventos APPLY_AI_PROFILE del SyncService
  // Traduce a comandos BLE usando ProtocolTranslator
  Future<void> handleAIProfile(DeviceSyncEvent event) async {
    // Traduce evento de IA → comando BLE
    final cmd = ProtocolTranslator.translate(event);
    await _bleService?.writeCommand(cmd);
  }
}
```

---

## 🚀 Estado de las Plataformas

| Plataforma | Estado | Notas |
|------------|--------|-------|
| **Android** | ✅ Completo | API 21-34, BLE + Background |
| **iOS** | ✅ Completo | Requiere macOS/Xcode |
| **Web** | 🟡 Parcial | Limitado BLE |
| **Windows** | 🟡 Parcial | Carpetas presentes |
| **Linux/macOS** | 🟡 Parcial | Carpetas presentes |

---

## 📊 Métricas del Proyecto

- **Commits:** 65+
- **Archivos:** 3295+
- **Lenguajes:**
  - PLpgSQL: 78.8% (DB scripts)
  - Dart: 16.6% (App Flutter)
  - Python: 2.4% (Scripts utilidad)

---

## 🔧 Próximos Pasos Sugeridos

### 1. Integración con Buttplug Ecosystem
- [ ] Evaluar integración con `buttplug-rs` (Intiface Engine)
- [ ] Crear bridge Buttplug ↔ Velvet Sync
- [ ] Soporte para más dispositivos (Lovense, WeVibe, etc.)

### 2. Mejoras de Rendimiento
- [ ] Optimizar cola de comandos BLE
- [ ] Implementar caching de catálogos
- [ ] Reducir latencia de envío de comandos

### 3. Testing
- [ ] Tests unitarios para `lvs_commands.dart`
- [ ] Tests de integración BLE
- [ ] CI/CD pipeline

### 4. Documentación
- [ ] API docs con `dartdoc`
- [ ] Guía de desarrollo para contribuidores
- [ ] Manual de usuario final

---

## 📞 Contacto y Recursos

- **Repo Principal:** https://github.com/reneleyvaolace/velvetsyncapp
- **Buttplug Core:** https://github.com/buttplugio/buttplug
- **Documentación Buttplug:** https://docs.buttplug.io
- **Protocolo Lovense:** https://buttplug.io/stpihkal/protocols/lovense/

---

## 🎯 Conclusión

El proyecto **VelvetSyncApp** tiene una base sólida y funcional con:
- ✅ Implementación BLE completa y probada
- ✅ Protocolo personalizado documentado
- ✅ Arquitectura limpia (Riverpod, servicios separados)
- ✅ Soporte multiplataforma (Android/iOS)
- ✅ Integración con IA y sincronización P2P

**Recomendación:** Continuar el desarrollo sobre esta base en lugar de empezar desde cero. La integración con Buttplug puede ser un siguiente paso natural para expandir compatibilidad.

---

*Documento generado: 2026-03-19*
*Análisis basado en el repositorio velvetsyncapp-local (clone del 2026-03-19)*
