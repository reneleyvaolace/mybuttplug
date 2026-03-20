# 🔍 Análisis de Repositorios para Integración con VelvetSyncApp

**Fecha:** 2026-03-19
**Objetivo:** Identificar componentes y funcionalidades para mejorar VelvetSyncApp y crear un ecosistema de productos para dispositivos ZLMICRO/Lovespouse

---

## 📊 Resumen Ejecutivo

### Ecosistema Buttplug Analizado

| Repositorio | Tecnología | Estado | Utilidad para VelvetSync |
|-------------|-----------|--------|-------------------------|
| **buttplug** | Rust | ✅ Activo (1.1k ⭐) | Protocolo unificado, device config |
| **buttplug-dart** | Dart | ✅ v1.0.0 | Cliente nativo para Flutter |
| **buttplug-py** | Python | ✅ Activo (70 ⭐) | Scripts, automation, testing |
| **btleplug** | Rust | ✅ 0.12.x (1.1k ⭐) | BLE backend (ya usado indirectamente) |
| **intiface-central** | Flutter+Rust | ✅ v3.0.3 | Referencia de arquitectura |
| **pylovespouse** | Python | 🟡 Early dev | Protocolo específico LVS |
| **LVS-Gateway** | ESP32 | 🟡 Desconocido | Hardware bridge alternativo |

---

## 🏗️ Arquitectura Recomendada para VelvetSyncApp 2.0

### Opción 1: Integración Ligera (Recomendada)

```
┌─────────────────────────┐     WebSocket      ┌──────────────────┐
│   VelvetSyncApp 2.0     │ ◄────────────────► │  Intiface Engine │
│   (Flutter + Riverpod)  │    ws://localhost  │  (Buttplug Rust) │
│   - UI mejorada         │                    │  - 100+ devices  │
│   - Catálogo Supabase   │                    │  - BLE/USB/Serial│
│   - IA Integration      │                    │  - Protocolos    │
│   - LVS nativo          │                    └──────────────────┘
└─────────────────────────┘
         │
         ├── BLE Nativo (flutter_blue_plus)
         │   └── Para dispositivos LVS (baja latencia)
         │
         └── Buttplug Client (buttplug-dart)
             └── Para otros dispositivos (Lovense, WeVibe, etc.)
```

**Ventajas:**
- ✅ No requiere reimplementar protocolos
- ✅ Soporte inmediato para 100+ dispositivos
- ✅ LVS mantiene control nativo de baja latencia
- ✅ Actualizaciones de protocolos automáticas

---

## 📦 Componentes a Integrar

### 1. **buttplug-dart** (Prioridad: ALTA)

**Repo:** https://pub.dev/packages/buttplug
**Versión:** 1.0.0
**Licencia:** BSD-3-Clause ✅

**Qué integrar:**
```yaml
# pubspec.yaml
dependencies:
  buttplug: ^1.0.0
  web_socket_channel: ^2.4.0
```

**Casos de uso:**
```dart
import 'package:buttplug/buttplug.dart';

// Conectar a Intiface Engine
final client = ButtplugClient('VelvetSync');
await client.connect('ws://localhost:12345');

// Escanear dispositivos
await client.startScanning();
await Future.delayed(Duration(seconds: 5));
await client.stopScanning();

// Controlar dispositivo
for (var device in client.devices.values()) {
  if (device.hasOutput(OutputType.VIBRATE)) {
    await device.runOutput(
      DeviceOutputCommand(OutputType.VIBRATE, 0.75)
    );
  }
}
```

**Beneficios:**
- Soporte para Lovense, WeVibe, Kiiroo, etc.
- Protocolo v4 completo
- Type-safe con Dart

---

### 2. **Device Configuration JSON** (Prioridad: ALTA)

**Repo:** https://github.com/buttplugio/buttplug/blob/master/buttplug-user-device-config-v4.json

**Estructura:**
```json
{
  "version": { "major": 4, "minor": 0 },
  "user_configs": {
    "protocols": {},
    "devices": [
      {
        "identifier": {
          "protocol": "lovense",
          "identifier": "EL",
          "address": "00:00:00:00:00:00"
        },
        "config": {
          "id": "uuid-unico",
          "base_id": "uuid-tipo",
          "features": [
            {
              "id": "feature-uuid",
              "base_id": "vibrate-base",
              "output": { "vibrate": { "disabled": false } }
            }
          ],
          "user_config": {
            "allow": true,
            "deny": false,
            "index": 0
          }
        }
      }
    ]
  }
}
```

**Cómo usar en VelvetSync:**
1. Descargar el JSON actualizado
2. Parsear con `dart:convert`
3. Agregar dispositivos LVS personalizados
4. Usar para auto-configurar dispositivos nuevos

---

### 3. **Intiface Engine** (Prioridad: MEDIA)

**Repo:** https://github.com/buttplugio/buttplug (crates/intiface_engine)

**Qué es:** CLI server que corre Buttplug Rust

**Instalación:**
```bash
# Windows
winget install Intiface.IntifaceEngine

# O compilar desde source
cargo install intiface_engine
```

**Uso en VelvetSync:**
```dart
// Iniciar Intiface Engine como proceso hijo
final engine = await Process.start('intiface_engine', [
  '--websocket-port', '12345',
  '--use-bluetooth-le',
]);

// Conectar cliente
final client = ButtplugClient('VelvetSync');
await client.connect('ws://localhost:12345');
```

**Beneficios:**
- 100+ protocolos soportados
- Actualizaciones automáticas
- Sin reimplementar protocolos

---

## 🎯 Plan de Integración por Fases

### Fase 1: Fundación (2-3 semanas)

**Objetivo:** Preparar VelvetSync para integración Buttplug

- [ ] **1.1** Agregar `buttplug-dart` a `pubspec.yaml`
- [ ] **1.2** Crear servicio `buttplug_bridge_service.dart`
- [ ] **1.3** Implementar conexión WebSocket a Intiface Engine
- [ ] **1.4** Agregar device config loader (JSON)
- [ ] **1.5** Tests de conexión básica

---

### Fase 2: Catálogo Unificado (2-3 semanas)

**Objetivo:** Soportar LVS + otros dispositivos en un solo catálogo

- [ ] **2.1** Extender `ToyModel` para soportar dispositivos Buttplug
- [ ] **2.2** Importar device config JSON de Buttplug
- [ ] **2.3** Crear UI unificada de selección de dispositivo
- [ ] **2.4** Agregar filtros por fabricante/protocolo
- [ ] **2.5** Soporte para QR scanning de dispositivos no-LVS

---

### Fase 3: Dual-Mode BLE (3-4 semanas)

**Objetivo:** Usar BLE nativo para LVS + Buttplug para otros

```dart
class BleService extends ChangeNotifier {
  // BLE nativo para LVS
  Future<void> connectLVS(ToyModel toy) async {
    // ... implementación actual ...
  }

  // Buttplug para otros
  Future<void> connectButtplug(ToyModel toy) async {
    final bridge = ref.read(buttplugBridgeProvider);
    await bridge.connect();
    await bridge.scan();
  }

  // Auto-detectar mejor método
  Future<void> connectSmart(ToyModel toy) async {
    if (toy.isLVS) {
      await connectLVS(toy); // Baja latencia
    } else if (toy.isButtplugDevice) {
      await connectButtplug(toy); // Soporte universal
    }
  }
}
```

---

## 📊 Matriz de Decisión

| Componente | Complejidad | Beneficio | Prioridad |
|------------|-------------|-----------|-----------|
| **buttplug-dart** | Baja | Alto | 🔴 ALTA |
| **Device Config JSON** | Baja | Alto | 🔴 ALTA |
| **Intiface Engine** | Media | Alto | 🟡 MEDIA |
| **flutter_rust_bridge** | Alta | Medio | 🟢 BAJA |
| **pylovespouse** | Baja | Bajo | 🟢 BAJA |
| **LVS-Gateway** | Media | Bajo | 🟢 BAJA |

---

## 🚀 Roadmap Recomendado

### Q2 2026 (Abril-Junio)

- [ ] Semana 1-2: Integrar `buttplug-dart`
- [ ] Semana 3-4: Device config loader
- [ ] Semana 5-6: Catálogo unificado
- [ ] Semana 7-8: Dual-mode BLE

### Q3 2026 (Julio-Septiembre)

- [ ] VelvetSync Desktop (Flutter Desktop)
- [ ] VelvetSync API Server (Python)
- [ ] VelvetSync CLI (Dart)

---

## 📝 Consideraciones Legales

### Licencias

| Componente | Licencia | Uso Comercial |
|------------|----------|---------------|
| **buttplug (Rust)** | BSD-3-Clause | ✅ Sí |
| **buttplug-dart** | BSD-3-Clause | ✅ Sí |
| **buttplug-py** | BSD-3-Clause | ✅ Sí |
| **intiface-central** | GPL-3.0 / Comercial | ⚠️ Requiere licencia comercial |
| **btleplug** | BSD-3-Clause | ✅ Sí |

**Recomendación:** Evitar copiar código de intiface-central (GPL). Usar solo como referencia.

---

## 🎯 Conclusión

### Lo que SÍ debes integrar:

1. ✅ **buttplug-dart** - Soporte universal de dispositivos
2. ✅ **Device Config JSON** - Auto-configuración
3. ✅ **Intiface Engine** (como dependencia externa) - Protocolos

### Lo que NO necesitas:

1. ❌ **Reimplementar protocolos** - Buttplug ya lo hace
2. ❌ **flutter_rust_bridge** - WebSocket es suficiente
3. ❌ **pylovespouse** - Tu implementación LVS es mejor

---

**Próximo paso:** ¿Quieres que empiece a implementar la **Fase 1** (integrar buttplug-dart)?

---

*Documento generado: 2026-03-19*
*Análisis basado en 7 repositorios del ecosistema Buttplug*
