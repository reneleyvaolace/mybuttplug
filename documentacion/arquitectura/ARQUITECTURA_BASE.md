# 🏗️ Arquitectura de Base Tecnológica - Velvet Sync Platform

**Versión:** 1.0.0  
**Fecha:** 2026-03-19  
**Estado:** Fundación para todos los productos Velvet Sync

---

## 📋 Visión General

Esta base tecnológica unificada integra lo mejor de:
- ✅ **VelvetSyncApp** - Control nativo LVS (wbMSE/8154)
- ✅ **Buttplug Ecosystem** - Soporte universal (100+ dispositivos)
- ✅ **btleplug** - BLE cross-platform

**Objetivo:** Crear cimientos sólidos para:
- VelvetSync Mobile (Android/iOS)
- VelvetSync Desktop (Windows/macOS/Linux)
- VelvetSync API Server
- VelvetSync CLI
- VelvetSync SDK

---

## 🏛️ Arquitectura en Capas

```
┌─────────────────────────────────────────────────────────────────┐
│                    CAPA DE APLICACIÓN                            │
│  (Mobile, Desktop, Web, CLI, API, SDK)                          │
└─────────────────────────────────────────────────────────────────┘
                              ▼
┌─────────────────────────────────────────────────────────────────┐
│                    CAPA DE SERVICIOS                             │
│  - BLE Service          - AI Bridge Service                     │
│  - Buttplug Bridge      - Sync Service                          │
│  - Catalog Service      - Session Service                       │
└─────────────────────────────────────────────────────────────────┘
                              ▼
┌─────────────────────────────────────────────────────────────────┐
│              HARDWARE ABSTRACTION LAYER (HAL)                    │
│  - Device Interface      - Protocol Translator                   │
│  - Connection Manager    - Command Queue                         │
└─────────────────────────────────────────────────────────────────┘
                              ▼
┌─────────────────────────────────────────────────────────────────┐
│                    CAPA DE PROTOCOLO                             │
│  - LVS Protocol         - Buttplug Protocol                     │
│  - Lovense Protocol     - Dispositivos Personalizados           │
└─────────────────────────────────────────────────────────────────┘
                              ▼
┌─────────────────────────────────────────────────────────────────┐
│                    CAPA DE TRANSPORTE                            │
│  - BLE (flutter_blue_plus)  - WebSocket (Buttplug)              │
│  - USB                    - Serial                              │
└─────────────────────────────────────────────────────────────────┘
```

---

## 📦 Estructura de Directorios

```
lib/
├── core/                           # ← NÚCLEO DE LA PLATAFORMA
│   ├── platform.dart               # Export unificado
│   ├── types/                      # Tipos base
│   │   ├── device_types.dart       # Enums y tipos de dispositivos
│   │   ├── command_types.dart      # Tipos de comandos
│   │   ├── event_types.dart        # Eventos del sistema
│   │   └── result_types.dart       # Result/Either para errores
│   │
│   ├── hal/                        # Hardware Abstraction Layer
│   │   ├── device_interface.dart   # Interfaz común para dispositivos
│   │   ├── connection_manager.dart # Gestión de conexiones
│   │   ├── command_queue.dart      # Cola de comandos
│   │   └── protocol_adapter.dart   # Adaptador de protocolos
│   │
│   ├── protocols/                  # Implementación de protocolos
│   │   ├── protocol_base.dart      # Clase base para protocolos
│   │   ├── lvs_protocol.dart       # Protocolo LVS (wbMSE/8154)
│   │   ├── buttplug_protocol.dart  # Protocolo Buttplug v4
│   │   └── lovense_protocol.dart   # Protocolo Lovense
│   │
│   └── config/                     # Configuración
│       ├── device_config.dart      # Configuración de dispositivos
│       └── device_config_loader.dart # Carga desde JSON/CSV
│
├── services/                       # Servicios de la plataforma
│   ├── ble_service.dart            # BLE nativo (LVS)
│   ├── buttplug_bridge_service.dart # Puente Buttplug
│   ├── device_manager_service.dart # Gestor unificado
│   ├── ai_hardware_bridge_service.dart # IA → Hardware
│   ├── sync_service.dart           # Sincronización P2P
│   ├── catalog_service.dart        # Catálogo de dispositivos
│   └── session_service.dart        # Gestión de sesiones
│
├── models/                         # Modelos de datos
│   ├── device_model.dart           # Modelo unificado de dispositivo
│   ├── toy_model.dart              # Modelo específico LVS
│   └── device_sync_model.dart      # Modelo de sincronización
│
├── utils/                          # Utilidades
│   ├── logger.dart                 # Logging unificado
│   ├── protocol_translator.dart    # Traductor de protocolos
│   └── cache_manager.dart          # Gestión de caché
│
└── screens/                        # UI (solo para apps con UI)
```

---

## 🔧 Componentes Clave

### 1. Hardware Abstraction Layer (HAL)

**Propósito:** Abstraer diferencias entre protocolos y transportes

```dart
abstract class DeviceInterface {
  String get id;
  String get name;
  DeviceType get type;
  ConnectionStatus get status;

  // Control básico
  Future<void> connect();
  Future<void> disconnect();
  Future<void> stop();

  // Control de features
  Future<void> vibrate(double intensity);
  Future<void> rotate(double intensity);

  // Información
  Future<int> get batteryLevel();
  Future<double> get rssi();
}
```

### 2. Protocol Adapter

**Propósito:** Traducir comandos genéricos a protocolos específicos

```dart
final adapter = ProtocolAdapter();
adapter.registerProtocol('LVS', LvsProtocol());
adapter.registerProtocol('Buttplug', ButtplugProtocol());

// Traducir comando genérico a protocolo específico
final result = adapter.translate(
  GenericCommand.vibrate(deviceId: 'd1', intensity: 0.75),
  protocolName: 'LVS',
);
```

### 3. Connection Manager

**Propósito:** Gestionar conexiones de forma unificada

```dart
final manager = ConnectionManager();

// Escanear
final devices = await manager.scan(
  deviceTypes: [DeviceType.vibrator],
  timeout: 10,
);

// Conectar
await manager.connect('device-id');

// Desconectar
await manager.disconnect('device-id');
```

---

## 🎯 Principios de Diseño

### 1. Separación de Responsabilidades
- **Core:** Lógica de negocio independiente de UI
- **Services:** Integración con sistemas externos
- **HAL:** Abstracción de hardware
- **UI:** Presentación y experiencia de usuario

### 2. Inversión de Dependencias
- Las capas superiores dependen de abstracciones
- Las capas inferiores implementan concretas
- Fácil de testear y mockear

### 3. Manejo Funcional de Errores
```dart
// Result/Either para errores tipados
Future<Result<Device, DeviceError>> connect() async {
  try {
    final device = await _connect();
    return Success(device);
  } on ConnectionTimeoutException {
    return Failure(DeviceError.connectionTimeout);
  }
}
```

### 4. Inmutabilidad
- Todos los modelos son inmutables
- Copias con `copyWith()` para actualizaciones
- Thread-safe por diseño

---

## 📊 Estado de Implementación

| Componente | Estado | Archivos |
|------------|--------|----------|
| **Core Types** | ✅ 100% | 4 archivos |
| **HAL** | ✅ 100% | 4 archivos |
| **Protocolos** | ✅ 80% | 3 archivos |
| **Config** | ✅ 100% | 2 archivos |
| **Logging** | ✅ 100% | 1 archivo |
| **Servicios** | ⏳ Pendiente | Próxima fase |
| **UI** | ⏳ Pendiente | Usar existente |

---

## 🚀 Próximos Pasos

### Fase 2: Servicios Base
1. BLE Service (migrar desde VelvetSyncApp)
2. Buttplug Bridge Service
3. Device Manager Service
4. AI Bridge Service

### Fase 3: Migración de UI
1. Adaptar pantallas existentes
2. Crear nuevas pantallas
3. Testing end-to-end

### Fase 4: Productos Derivados
1. VelvetSync Desktop
2. VelvetSync CLI
3. VelvetSync API
4. VelvetSync SDK

---

*Documento generado: 2026-03-19*  
*Velvet Sync Platform - Arquitectura v1.0.0*
