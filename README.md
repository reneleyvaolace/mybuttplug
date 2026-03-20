# 🏗️ Velvet Sync Platform

> **Base Tecnológica Unificada para Dispositivos Hápticos**
> **Versión:** 1.0.0 | **Estado:** ✅ Base Completada
> **Soporte:** **2600+ dispositivos** (Love Spouse + Buttplug)

---

## 📋 ¿Qué es Velvet Sync Platform?

Una base tecnológica unificada que integra lo mejor de:

- ✅ **VelvetSyncApp** - Control nativo LVS (wbMSE/8154) con **~600 dispositivos**
- ✅ **Buttplug Ecosystem** - Soporte universal (**2000+ dispositivos**)
- ✅ **btleplug** - BLE cross-platform

**Propósito:** Proporcionar cimientos sólidos para crear múltiples productos (Mobile, Desktop, CLI, API, SDK) sin reimplementar la lógica base.

---

## 🔌 Soporte de Dispositivos

### 📊 Resumen Global de Soporte

| Fuente | Cantidad | Tipo | Estado |
|--------|----------|------|--------|
| **Love Spouse (wbMSE)** | ~600 dispositivos | Nativo | ✅ Sin dependencias |
| **Buttplug Ecosystem** | 2000+ dispositivos | Universal | ✅ Vía Intiface Engine |
| **TOTAL GLOBAL** | **2600+** | **Híbrido** | ✅ **Integrado** |

---

### 🏷️ Dispositivos Nativos - Love Spouse / ZLMicro (~600 dispositivos)

**Protocolo:** wbMSE (Love Spouse) - **Sin dependencias adicionales**

| Protocolo | Dispositivos | Transporte | Catálogo |
|-----------|--------------|------------|----------|
| **LVS (wbMSE)** | Knight No. 3 (8154), 7043, +284 modelos ZLMicro | BLE Advertising + 2.4G | ✅ ~600 productos |

**Catálogo Love Spouse Completo:**
- **438 productos** en `catalog_dump.txt`
- **284 productos** en `devices-categories-updated.csv` (18 columnas)
- **~500+ productos** en archivos SQL (`insert_catalog_massive_v2.sql`, `insert_models_final.sql`)
- **Funciones:** classic, music, shake, interactive, finger, video, game, explore, heating, voice, kegel
- **Conexión:** BLE (prefijo: `77 62 4d 53 45`) + 2.4G

**Prefijos de Modelo Soportados:**
`AA*` (AATD, AAGS, AAHT, AAZD, AASJ, AAYJ, AAFJ), `HA*`, `HE*`, `ZA*`, `ZB*`, `YE*`, `MN*`, `EA*`, `RA*`, `LA*`, `CA*`, `DA*`, `BA*`, `JA*`, `MA*`, `NA*`, `GA*`, `WA*`, `YA*`, `CD*`, `FJ*`, `LC*`, `SC*`, `TD*`, `XB*`, `RB*`, `PB*`, `CB*`, `DB*`, `EB*`, `FB*`, `GB*`, `HB*`, `IB*`, `KB*`, `LB*`, `MB*`, `NB*`, `QB*`, `SB*`, `VB*`, `YB*`

> 📖 **Ver catálogo completo:** [documentacion/resumenes/CATALOGO_LOVE_SPOUSE.md](documentacion/resumenes/CATALOGO_LOVE_SPOUSE.md)
>
> 📖 **Ver resumen global:** [documentacion/resumenes/RESUMEN_DISPOSITIVOS_GLOBAL.md](documentacion/resumenes/RESUMEN_DISPOSITIVOS_GLOBAL.md)

---

### 🌐 Dispositivos Universales - 2000+ Modelos (Requiere Intiface Engine)

**40+ Fabricantes Soportados:**

| Fabricante | Modelos Populares | Cantidad |
|------------|-------------------|----------|
| **Lovense** | Nora, Max, Lush, Calor, Dom, Edge, Ambi, Ferri, Osci, Hasmo | 50+ |
| **WeVibe** | Pivot, Chorus, Moxie, Nova, Sync, Verge, Melt, Rey, Gala, Ditto | 30+ |
| **Kiiroo** | Keon, Pearl, Onyx, Titan, Cliona, OhMiBod 4.0, Fuse | 20+ |
| **Satisfyer** | Pro 2, Connect, Men's Pleasure, Dual Delight, Secrets | 25+ |
| **Magic Motion** | Capa, Bora, Draco, Eidolon, Flamingo, Krush, Sword | 20+ |
| **Lelo** | Hugo, F1s, Ida, Enigma, Soraya, Smart Wand, Tiani | 15+ |
| **Tenga** | Flip, iro+, Cospa, Gear, Moon | 10+ |
| **Vorze** | Cyclone SA, Piston, UFO, Bach | 10+ |
| **Youcups/You2Toys** | VX001, Youcups | 15+ |
| **Motorbunny** | Bunny, Link, Buck | 8+ |
| **Mysteryvibe** | Crescendo, Tenuto, Massimo | 6+ |
| **Libo** | PiPiJing, MonsterPub, XiaoLu | 20+ |
| **Svakom** | Alex, Don, Vito, Ella | 15+ |
| **Picobong** | 6 Functions, Surfer, Diver, Ring | 12+ |
| **Prettylove** | Aegu BLE | 10+ |
| **Vibratissimo** | Panty Vibrator | 5+ |
| **Lovehoney** | Desire, Prostate | 8+ |
| **Aneros** | MGX, Helix, Trident | 10+ |
| **Womanizer** | Womanizer | 15+ |
| **Fun Factory** | Fun Factory | 12+ |
| **OhMiBod** | OhMiBod 4.0, Esca 2 | 8+ |
| **Fleshlight** | Fleshlight Launch | 5+ |
| **Twerking Butt** | Twerking Butt | 3+ |
| **SayberX** | SayberX | 5+ |
| **Zalo** | Queen | 3+ |
| **Muse** | Muse S | 3+ |
| **Realov** | Realov Vibe | 5+ |
| **Le Wand** | Le Wand | 8+ |
| **L'Amourose** | L'Amourose | 6+ |
| **Petra** | Petra | 5+ |
| **Sculpted** | Sculpted | 4+ |
| **Geeky Vibes** | Geeky Vibes | 6+ |
| **Blush** | Blush | 8+ |
| **Aogu** | Aogu BLE | 10+ |
| **Patoo** | Patoo | 3+ |
| **Cueme** | FUNCODE | 5+ |
| **Cupido** | Cupido | 5+ |
| **Jolted** | Jolted | 4+ |
| **Desire** | Desire | 5+ |
| **Youou** | VX001 | 4+ |
| **Realtouch** | Realtouch | 2+ |
| **Erostek** | ET312 | 2+ |
| **Rez** | Trancevibrator | 2+ |
| **Y 1800+ modelos más** | ... | 1800+ |

**Para usar dispositivos Buttplug:**

1. **Instalar Intiface Engine** (gratis):
   ```bash
   # Windows
   winget install Intiface.IntifaceEngine
   
   # macOS
   brew install intiface-engine
   
   # Linux
   cargo install intiface_engine
   ```

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
