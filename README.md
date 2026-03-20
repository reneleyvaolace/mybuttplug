# 🏗️ Velvet Sync Platform

> **Base Tecnológica Unificada para Dispositivos Hápticos**
> **Versión:** 1.0.0 | **Estado:** ✅ Base Completada
> **Soporte:** 2000+ dispositivos vía Buttplug + LVS nativo

---

## 📋 ¿Qué es Velvet Sync Platform?

Una base tecnológica unificada que integra lo mejor de:

- ✅ **VelvetSyncApp** - Control nativo LVS (wbMSE/8154)
- ✅ **Buttplug Ecosystem** - Soporte universal (**2000+ dispositivos**)
- ✅ **btleplug** - BLE cross-platform

**Propósito:** Proporcionar cimientos sólidos para crear múltiples productos (Mobile, Desktop, CLI, API, SDK) sin reimplementar la lógica base.

---

## 🔌 Soporte de Dispositivos

### 📊 Resumen de Soporte

| Fuente | Cantidad | Estado |
|--------|----------|--------|
| **LVS Nativo** | 7 dispositivos | ✅ Sin dependencias |
| **Buttplug** | 2000+ dispositivos | ✅ Vía Intiface Engine |
| **Total** | **2000+** | ✅ **Integrado** |

### Dispositivos Nativos - Love Spouse (Sin dependencias adicionales)

| Protocolo | Dispositivos | Transporte | Catálogo |
|-----------|--------------|------------|----------|
| **LVS (wbMSE)** | Knight No. 3 (8154), 7043, +284 modelos Love Spouse | BLE Advertising | ✅ 2000+ productos |

**Catálogo Love Spouse Completo:**
- **284 productos** en `devices-categories-updated.csv`
- **~1700+ productos** en archivos SQL (`insert_models_final.sql`, `insert_catalog_massive_v2.sql`)
- **Funciones:** classic, music, shake, interactive, finger, video, game, explore, heating, voice, kegel
- **Conexión:** 2.4G + BLE (prefijo: `77 62 4d 53 45`)

> 📖 **Ver catálogo completo:** [documentacion/resumenes/CATALOGO_LOVE_SPOUSE.md](documentacion/resumenes/CATALOGO_LOVE_SPOUSE.md)

### Dispositivos Universales - 2000+ Modelos (Requiere Intiface Engine)

**Fabricantes Soportados:** Lovense, WeVibe, Kiiroo, Satisfyer, Magic Motion, Lelo, Tenga, Vorze, Youcups, Motorbunny, Realov, Prettylove, Svakom, Mysteryvibe, Picobong, Libo, Vibratissimo, Twerking Butt, Lovehoney, Aneros, SayberX, Zalo, Muse, Cupido, Jolted, Blush, Aogu, Fun Factory, Womanizer, Petra, Le Wand, L'Amourose, Sculpted, Desire, Geeky Vibes, OhMiBod, Fleshlight, y más.

**Modelos Populares:**
- **Lovense:** Nora, Max, Lush, Calor, Dom, Edge, Ambi, Ferri, Osci
- **WeVibe:** Pivot, Chorus, Moxie, Nova, Sync, Verge, Melt, Rey, Gala
- **Kiiroo:** Keon, Pearl, Onyx, Titan, Cliona, OhMiBod 4.0
- **Satisfyer:** Pro 2, Connect, Men's Pleasure, Dual Delight
- **Magic Motion:** Capa, Bora, Draco, Eidolon, Flamingo, Krush
- **Lelo:** Hugo, F1s, Ida, Enigma, Soraya, Smart Wand
- **Tenga:** Flip, iro+, Cospa, Gear
- **Vorze:** Cyclone SA, Piston, UFO
- **Y 1900+ modelos más**

Para usar dispositivos Buttplug:

1. **Instalar Intiface Engine** (gratis):
   - Windows: `winget install Intiface.IntifaceEngine`
   - macOS: `brew install intiface-engine`
   - Linux: `cargo install intiface_engine`

2. **Iniciar el servicio**:
   ```bash
   intiface_engine --websocket-port 12345 --use-bluetooth-le
   ```

3. **Tu app escaneará automáticamente** hasta 2000+ dispositivos vía WebSocket

> 📖 **Ver guía completa:** [documentacion/directivas/INTIFACE_ENGINE_SETUP.md](documentacion/directivas/INTIFACE_ENGINE_SETUP.md)
> 
> 📖 **Ver lista completa:** [documentacion/resumenes/DISPOSITIVOS_2000_PLUS.md](documentacion/resumenes/DISPOSITIVOS_2000_PLUS.md)

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
