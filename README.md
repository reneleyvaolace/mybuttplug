# 🏗️ Velvet Sync Platform

> **Base Tecnológica Unificada para Dispositivos Hápticos**
> **Versión:** 1.0.0 | **Estado:** ✅ Base Completada

---

## 📋 ¿Qué es Velvet Sync Platform?

Una base tecnológica unificada que integra lo mejor de:

- ✅ **VelvetSyncApp** - Control nativo LVS (wbMSE/8154)
- ✅ **Buttplug Ecosystem** - Soporte universal (100+ dispositivos)
- ✅ **btleplug** - BLE cross-platform

**Propósito:** Proporcionar cimientos sólidos para crear múltiples productos (Mobile, Desktop, CLI, API, SDK) sin reimplementar la lógica base.

---

## 🔌 Soporte de Dispositivos

### Dispositivos Nativos (Sin dependencias adicionales)

| Protocolo | Dispositivos | Transporte |
|-----------|--------------|------------|
| **LVS (wbMSE)** | 8154, 7043, Knight No. 3 | BLE Advertising |

### Dispositivos Universales (Requiere Intiface Engine)

Para soportar **100+ dispositivos adicionales** (Lovense, WeVibe, Kiiroo, Satisfyer, etc.):

1. **Instalar Intiface Engine** (gratis):
   - Windows: `winget install Intiface.IntifaceEngine`
   - macOS: `brew install intiface-engine`
   - Linux: `cargo install intiface_engine`

2. **Iniciar el servicio**:
   ```bash
   intiface_engine --websocket-port 12345 --use-bluetooth-le
   ```

3. **Tu app se conectará automáticamente** vía WebSocket

> 📖 **Ver guía completa:** [documentacion/directivas/INTIFACE_ENGINE_SETUP.md](documentacion/directivas/INTIFACE_ENGINE_SETUP.md)

---

## 🚀 Inicio Rápido

### 📚 Ver Documentación Completa

Toda la documentación está en [`documentacion/`](documentacion/):

| Para | Comienza Aquí |
|------|---------------|
| **Nuevos** | [documentacion/resumenes/RESUMEN_BASE_CREADA.md](documentacion/resumenes/RESUMEN_BASE_CREADA.md) |
| **Desarrolladores** | [documentacion/arquitectura/ARQUITECTURA_BASE.md](documentacion/arquitectura/ARQUITECTURA_BASE.md) |
| **Arquitectos** | [documentacion/analisis/](documentacion/analisis/) |
| **Soporte** | [documentacion/TROUBLESHOOTING.md](documentacion/TROUBLESHOOTING.md) |

### 📁 Ver Código

El código está en [`lib/`](lib/):

```
lib/
├── core/           # Base tecnológica (types, HAL, protocols, config)
├── services/       # Servicios de negocio (9 archivos)
├── models/         # Modelos de datos
├── ble/            # Capa BLE nativa LVS
├── providers/      # State management (Riverpod)
├── widgets/        # Widgets reutilizables
├── utils/          # Utilidades
├── screens/        # Pantallas UI
├── main.dart       # Punto de entrada
└── theme.dart      # Tema Cyberpunk/Velvet
```

---

## 📊 Estado Actual

| Componente | Estado |
|------------|--------|
| **Core Types** | ✅ 100% |
| **HAL** | ✅ 100% |
| **Protocolos** | ✅ 80% |
| **Config** | ✅ 100% |
| **Logging** | ✅ 100% |
| **Servicios** | ✅ 100% |
| **UI** | ✅ Base completa |

---

## 🎯 Ejemplo de Uso

```dart
import 'package:velvet_sync/core/platform.dart';

// 1. Inicializar
final adapter = ProtocolAdapter();
final connectionManager = ConnectionManager();

// 2. Registrar protocolos
adapter.registerProtocol('LVS', LvsProtocol());
adapter.registerProtocol('Buttplug', ButtplugProtocol());

// 3. Escanear y conectar
final devices = await connectionManager.scan(
  deviceTypes: [DeviceType.vibrator],
  timeout: 10,
);

// 4. Controlar
if (devices.isNotEmpty) {
  final device = devices.first;
  await connectionManager.connect(device.id);
  await device.vibrate(0.75);
  await device.stop();
}
```

---

## 📁 Estructura de Archivos

```
mybuttplug/
├── 📄 README.md                       # Este archivo
├── 📁 lib/                            # Código fuente
│   ├── core/                          # Base tecnológica
│   ├── services/                      # Servicios
│   ├── models/                        # Modelos
│   ├── ble/                           # Capa BLE
│   ├── providers/                     # State management
│   ├── widgets/                       # Widgets
│   ├── utils/                         # Utilidades
│   ├── screens/                       # Pantallas
│   ├── main.dart                      # Entry point
│   └── theme.dart                     # Tema
│
├── 📁 documentacion/                  # 📚 DOCUMENTACIÓN COMPLETA
│   ├── README.md                      # Índice general
│   ├── arquitectura/                  # Arquitectura
│   ├── analisis/                      # Análisis
│   ├── directivas/                    # Directivas
│   ├── resumenes/                     # Resúmenes
│   ├── SECURITY.md                    # Seguridad
│   └── TROUBLESHOOTING.md             # Soporte
│
├── 📁 velvetsyncapp-local/            # Proyecto Flutter original (referencia)
│
└── 📄 .env.template                   # Template de configuración
```

---

## 🔗 Enlaces

### Documentación

- [Índice General](documentacion/README.md)
- [Arquitectura Base](documentacion/arquitectura/ARQUITECTURA_BASE.md)
- [Análisis de Proyecto](documentacion/analisis/ANALISIS_PROYECTO.md)
- [Análisis de Integración](documentacion/analisis/ANALISIS_INTEGRACION_BUTTPLUG.md)
- [Directivas](documentacion/directivas/)
- [Security Guide](documentacion/SECURITY.md)
- [Troubleshooting](documentacion/TROUBLESHOOTING.md)

### Externos

- [Buttplug Core](https://github.com/buttplugio/buttplug)
- [Buttplug Dart](https://pub.dev/packages/buttplug)
- [Documentación Buttplug](https://docs.buttplug.io)
- [VelvetSyncApp](https://github.com/reneleyvaolace/velvetsyncapp)

---

## 🛡️ Licencia

Esta base tecnológica integra componentes de múltiples fuentes:

- **Código original de VelvetSyncApp** - Propietario
- **Protocolo Buttplug** - BSD-3-Clause
- **btleplug** - BSD-3-Clause

---

**¡Base tecnológica lista para construir productos! 🚀**

---

*Última actualización: 2026-03-19*  
*Velvet Sync Platform v1.0.0*
