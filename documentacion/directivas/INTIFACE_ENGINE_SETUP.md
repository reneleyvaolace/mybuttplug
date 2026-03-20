# 🔌 Guía de Instalación de Intiface Engine

**Versión:** 1.0.0  
**Fecha:** 2026-03-19  
**Estado:** ✅ Recomendado para soporte universal

---

## 📋 ¿Qué es Intiface Engine?

**Intiface Engine** es el motor de Buttplug que permite controlar **100+ dispositivos** de diferentes fabricantes:

- Lovense (Nora, Max, Lush, Calor, etc.)
- WeVibe (Pivot, Chorus, Moxie, etc.)
- Kiiroo (Keon, Pearl, Onyx, etc.)
- Satisfyer (Pro 2, Connect, etc.)
- Magic Motion, Lelo, Tenga, Patoo, y más

**No es obligatorio** para dispositivos LVS (wbMSE/8154), pero **sí es necesario** para soporte universal.

---

## 🎯 ¿Cuándo Necesitas Intiface Engine?

| Escenario | ¿Necesario? |
|-----------|-------------|
| Solo dispositivos LVS (8154, 7043) | ❌ NO |
| Dispositivos Lovense, WeVibe, etc. | ✅ SÍ |
| Soporte universal (100+ dispositivos) | ✅ SÍ |
| Desarrollo de productos multi-dispositivo | ✅ SÍ |

---

## 📦 Instalación por Plataforma

### Windows

#### Opción 1: Winget (Recomendada)

```powershell
winget install Intiface.IntifaceEngine
```

#### Opción 2: Descarga directa

1. Ir a https://github.com/intiface/intiface-engine/releases
2. Descargar el `.msi` más reciente
3. Ejecutar instalador
4. Aceptar firewall si pregunta

#### Opción 3: Cargo (desde source)

```powershell
cargo install intiface_engine
```

---

### macOS

#### Opción 1: Homebrew (Recomendada)

```bash
brew install intiface-engine
```

#### Opción 2: Descarga directa

1. Ir a https://github.com/intiface/intiface-engine/releases
2. Descargar el `.dmg` más reciente
3. Arrastrar a Applications
4. Ejecutar desde Terminal

#### Opción 3: Cargo (desde source)

```bash
cargo install intiface_engine
```

---

### Linux

#### Opción 1: Cargo (Recomendada)

```bash
# Instalar Rust si no lo tienes
curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh

# Instalar Intiface Engine
cargo install intiface_engine
```

#### Opción 2: AUR (Arch Linux)

```bash
yay -S intiface-central
```

#### Opción 3: Binario precompilado

1. Ir a https://github.com/intiface/intiface-engine/releases
2. Descargar el `.tar.gz` para Linux
3. Extraer: `tar -xzf intiface-engine-*.tar.gz`
4. Mover a PATH: `sudo mv intiface-engine /usr/local/bin/`

---

### Android / iOS

**Intiface Engine NO está disponible para móviles.**

Para soporte de dispositivos universales en móvil:

1. **Opción A:** Usar Intiface Central (app GUI)
   - Android: https://play.google.com/store/apps/details?id=com.intiface.central
   - iOS: https://apps.apple.com/app/intiface-central

2. **Opción B:** Conectar a Intiface Engine en PC
   - PC ejecuta Intiface Engine
   - Móvil se conecta vía WebSocket (misma red)

---

## 🚀 Uso Básico

### 1. Iniciar Intiface Engine

```bash
# Comando básico
intiface_engine

# Con opciones específicas
intiface_engine \
  --websocket-port 12345 \
  --use-bluetooth-le \
  --server-name "VelvetSync"
```

### 2. Verificar que está corriendo

```bash
# Ver procesos
ps aux | grep intiface  # Linux/macOS
tasklist | findstr intiface  # Windows

# O abrir http://localhost:12345 en navegador
```

### 3. Conectar desde Velvet Sync

```dart
import 'package:velvet_sync/services/buttplug_bridge_service.dart';

// En tu código
final bridge = ref.read(buttplugBridgeProvider);
bridge.configure(url: 'ws://localhost:12345');
await bridge.connect();

// Escanear dispositivos
await bridge.startScan(timeout: 10);

// Controlar
await bridge.vibrate(deviceIndex: 0, intensity: 0.75);
```

---

## ⚙️ Configuración Avanzada

### Opciones de Línea de Comandos

| Opción | Descripción | Default |
|--------|-------------|---------|
| `--websocket-port` | Puerto WebSocket | 12345 |
| `--use-bluetooth-le` | Habilitar BLE | true |
| `--server-name` | Nombre del servidor | "Intiface Engine" |
| `--log-level` | Nivel de logging | info |
| `--use-xinput` | Usar XInput (gamepads) | false |

### Ejemplo de Configuración Completa

```bash
intiface_engine \
  --websocket-port 12345 \
  --use-bluetooth-le \
  --server-name "VelvetSync Server" \
  --log-level debug \
  --use-xinput
```

---

## 🔒 Seguridad

### 1. **NUNCA exponer a Internet**

```bash
# ❌ MALO: Exponer a todas las interfaces
intiface_engine --websocket-port 12345 --server-name 0.0.0.0

# ✅ BUENO: Solo localhost
intiface_engine --websocket-port 12345 --server-name 127.0.0.1
```

### 2. **Usar firewall**

```bash
# Windows: Firewall bloquea por defecto (aceptar solo redes privadas)
# macOS: Firewall pregunta al iniciar (aceptar)
# Linux: Configurar ufw
sudo ufw allow from 127.0.0.1 to any port 12345
```

### 3. **Autenticación (si expones en red local)**

```dart
// En tu app, verificar conexión segura
if (!serverUrl.startsWith('ws://localhost') && 
    !serverUrl.startsWith('ws://127.0.0.1')) {
  lvsLog('⚠️ Servidor no es localhost, verificar seguridad', tag: 'BUTTPLUG');
}
```

---

## 🔧 Solución de Problemas

### Problema: "No se puede conectar al puerto 12345"

**Causa:** Puerto ya está en uso

**Solución:**
```bash
# Windows
netstat -ano | findstr :12345
taskkill /PID <PID> /F

# Linux/macOS
lsof -i :12345
kill -9 <PID>
```

### Problema: "Bluetooth no disponible"

**Causa:** Bluetooth apagado o no disponible

**Solución:**
```bash
# Verificar Bluetooth
# Windows: Configuración → Dispositivos → Bluetooth
# macOS: Preferencias → Bluetooth
# Linux: bluetoothctl show

# Reiniciar servicio Bluetooth
sudo systemctl restart bluetooth  # Linux
```

### Problema: "Dispositivo no aparece en escaneo"

**Causas posibles:**
1. Dispositivo ya conectado a otra app
2. Dispositivo fuera de rango
3. Dispositivo apagado

**Solución:**
1. Cerrar otras apps (Lovense Connect, etc.)
2. Acercar dispositivo (< 3m)
3. Reiniciar dispositivo (apagar/encender)

---

## 📊 Dispositivos Soportados

### Fabricantes Principales

| Fabricante | Modelos | Protocolo |
|------------|---------|-----------|
| **Lovense** | Nora, Max, Lush, Calor, Edge, etc. | Lovense |
| **WeVibe** | Pivot, Chorus, Moxie, Verge, etc. | WeVibe |
| **Kiiroo** | Keon, Pearl, Onyx, Moon, etc. | Kiiroo |
| **Satisfyer** | Pro 2, Connect, Couples, etc. | Satisfyer |
| **Magic Motion** | Capa, Bora, Crystal, etc. | Magic Motion |
| **Lelo** | Hugo, F1s, Tiani, etc. | Lelo |
| **Tenga** | Flip, iroha, etc. | Tenga |
| **Patoo** | Varios | Patoo |

**Total:** 100+ dispositivos de 20+ fabricantes

---

## 🎯 Integración con Velvet Sync

### Configuración Automática

Velvet Sync detecta automáticamente si Intiface Engine está disponible:

```dart
class VelvetSyncApp {
  Future<void> initialize() async {
    // 1. Intentar conectar a Buttplug (Intiface Engine)
    final bridge = ref.read(buttplugBridgeProvider);
    final connected = await bridge.connect();
    
    if (connected) {
      lvsLog('✅ Intiface Engine disponible - 100+ dispositivos', tag: 'INIT');
    } else {
      lvsLog('⚠️ Intiface Engine no disponible - solo LVS', tag: 'INIT');
      lvsLog('💡 Instalar: https://github.com/intiface/intiface-engine', tag: 'INIT');
    }
  }
}
```

### Modo Fallback

Si Intiface Engine no está disponible, la app usa BLE nativo para LVS:

```
┌─────────────────────────────────────────────────────────┐
│              Velvet Sync App                            │
│                                                         │
│  ┌───────────────────┐     ┌─────────────────────┐    │
│  │  BLE Nativo       │     │  Buttplug Bridge    │    │
│  │  (LVS 8154/7043)  │     │  (100+ dispositivos)│    │
│  │                   │     │                     │    │
│  │  ✅ Siempre       │     │  ⚠️ Si disponible   │    │
│  └───────────────────┘     └─────────────────────┘    │
└─────────────────────────────────────────────────────────┘
```

---

## 📝 Referencias

### Enlaces Oficiales

- **Intiface Engine:** https://github.com/intiface/intiface-engine
- **Buttplug.io:** https://buttplug.io
- **Documentación:** https://docs.buttplug.io
- **Intiface Central (GUI):** https://www.intiface.com/central/

### Licencia

- **Intiface Engine:** BSD-3-Clause ✅ Uso comercial permitido
- **Buttplug:** BSD-3-Clause ✅ Uso comercial permitido

---

## ✅ Checklist de Instalación

### Windows
- [ ] Instalar con `winget install Intiface.IntifaceEngine`
- [ ] Aceptar firewall cuando pregunte
- [ ] Ejecutar `intiface_engine` en terminal
- [ ] Verificar en http://localhost:12345

### macOS
- [ ] Instalar con `brew install intiface-engine`
- [ ] Aceptar permisos de Bluetooth
- [ ] Ejecutar `intiface-engine` en terminal
- [ ] Verificar conexión

### Linux
- [ ] Instalar Rust con `curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh`
- [ ] Instalar con `cargo install intiface_engine`
- [ ] Configurar firewall: `sudo ufw allow from 127.0.0.1 to any port 12345`
- [ ] Ejecutar `intiface_engine`
- [ ] Verificar conexión

---

*Guía generada: 2026-03-19*  
*Velvet Sync Platform - Intiface Engine Setup v1.0.0*
