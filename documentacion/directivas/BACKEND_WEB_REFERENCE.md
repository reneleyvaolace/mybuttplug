# 🌐 Velvet Sync Backend - Referencia para Web

**Versión:** 1.0.0  
**Fecha:** 2026-03-19  
**Estado:** 🟡 Referencia para desarrollo futuro

---

## 📋 Visión General

Velvet Sync Backend es una **referencia de implementación** para crear un servidor que permita controlar dispositivos BLE desde aplicaciones Web.

**¿Por qué necesitamos backend para Web?**
- Los navegadores NO tienen acceso BLE directo (limitado a WebBLE API)
- WebBLE API solo funciona en Chrome/Edge y requiere HTTPS
- Backend permite controlar dispositivos desde cualquier navegador

**Tecnologías:**
- Python 3.9+ o Node.js 16+
- Buttplug-py o buttplug-js
- WebSocket para comunicación con Web app
- HTTP REST API opcional

---

## 🏗️ Arquitectura

```
┌─────────────────┐     WebSocket      ┌──────────────────┐
│   Web App       │ ◄────────────────► │  Velvet Sync     │
│   (Flutter Web) │    ws://server     │  Backend         │
│                 │                    │  (Python/Node)   │
└─────────────────┘                    └──────────────────┘
                                                │
                                          BLE/USB
                                                │
                                                ▼
                                       ┌──────────────────┐
                                       │  Dispositivos    │
                                       │  (100+ modelos)  │
                                       └──────────────────┘
```

---

## 🐍 Opción 1: Python Backend

### Instalación

```bash
# Crear entorno virtual
python -m venv venv
venv\Scripts\activate  # Windows
source venv/bin/activate  # Linux/macOS

# Instalar dependencias
pip install fastapi uvicorn buttplug websockets python-multipart
```

### `main.py` - Servidor Python

```python
#!/usr/bin/env python3
"""
Velvet Sync Backend - Python
Servidor WebSocket para controlar dispositivos BLE desde Web
"""

import asyncio
import json
import logging
from typing import Dict, List
from fastapi import FastAPI, WebSocket, WebSocketDisconnect
from fastapi.middleware.cors import CORSMiddleware
import buttplug

# Configuración
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

app = FastAPI(title="Velvet Sync Backend")

# CORS para permitir conexión desde Web
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],  # En producción, especificar dominios
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Cliente Buttplug
client: buttplug.Client = None
connected_devices: Dict[int, buttplug.Device] = {}

# ═══════════════════════════════════════════════════════════════
# Eventos de Startup/Shutdown
# ═══════════════════════════════════════════════════════════════

@app.on_event("startup")
async def startup_event():
    """Conectar a Intiface Engine al iniciar"""
    global client
    
    try:
        client = buttplug.Client("Velvet Sync Backend")
        await client.connect("ws://localhost:12345")
        logger.info("✅ Conectado a Intiface Engine")
    except Exception as e:
        logger.error(f"❌ Error conectando a Intiface: {e}")

@app.on_event("shutdown")
async def shutdown_event():
    """Desconectar al cerrar"""
    global client
    
    if client:
        await client.disconnect()
        logger.info("🔌 Desconectado de Intiface Engine")

# ═══════════════════════════════════════════════════════════════
# WebSocket Endpoint
# ═══════════════════════════════════════════════════════════════

@app.websocket("/ble")
async def websocket_endpoint(websocket: WebSocket):
    """Endpoint WebSocket para controlar dispositivos BLE"""
    await websocket.accept()
    logger.info("🔌 Cliente Web conectado")
    
    try:
        while True:
            # Recibir mensaje del cliente Web
            data = await websocket.receive_text()
            message = json.loads(data)
            
            # Procesar comando
            await process_command(websocket, message)
            
    except WebSocketDisconnect:
        logger.info("Cliente Web desconectado")
    except Exception as e:
        logger.error(f"Error: {e}")

async def process_command(websocket: WebSocket, message: dict):
    """Procesa comandos del cliente Web"""
    cmd_type = message.get('type')
    
    try:
        if cmd_type == 'start_scan':
            await start_scan(websocket, message)
        elif cmd_type == 'stop_scan':
            await stop_scan(websocket)
        elif cmd_type == 'connect':
            await connect_device(websocket, message)
        elif cmd_type == 'disconnect':
            await disconnect_device(websocket, message)
        elif cmd_type == 'vibrate':
            await vibrate_device(websocket, message)
        elif cmd_type == 'stop':
            await stop_device(websocket, message)
        else:
            await send_error(websocket, f"Comando desconocido: {cmd_type}")
    except Exception as e:
        await send_error(websocket, str(e))

# ═══════════════════════════════════════════════════════════════
# Comandos BLE
# ═══════════════════════════════════════════════════════════════

async def start_scan(websocket: WebSocket, message: dict):
    """Inicia escaneo de dispositivos"""
    timeout = message.get('timeout', 10)
    
    logger.info("Iniciando escaneo...")
    await websocket.send_json({
        'type': 'scan_starting',
        'timeout': timeout
    })
    
    # Iniciar escaneo
    await client.start_scanning()
    
    # Esperar timeout
    await asyncio.sleep(timeout)
    
    # Detener escaneo
    await client.stop_scanning()
    
    # Enviar dispositivos encontrados
    devices = []
    for idx, device in enumerate(client.devices.values()):
        device_info = {
            'index': idx,
            'name': device.name,
            'address': device.addr,
        }
        devices.append(device_info)
        connected_devices[idx] = device
    
    await websocket.send_json({
        'type': 'scan_complete',
        'devices': devices
    })
    
    logger.info(f"Escaneo completado: {len(devices)} dispositivos")

async def stop_scan(websocket: WebSocket):
    """Detiene escaneo"""
    await client.stop_scanning()
    await websocket.send_json({'type': 'scan_stopped'})

async def connect_device(websocket: WebSocket, message: dict):
    """Conecta a un dispositivo"""
    device_id = message.get('device_id')
    
    try:
        device = client.devices[device_id]
        await client.connect_device(device)
        
        await websocket.send_json({
            'type': 'device_connected',
            'device_id': device_id,
            'name': device.name
        })
        
        logger.info(f"✅ Conectado a {device.name}")
    except Exception as e:
        await send_error(websocket, f"Error conectando: {e}")

async def disconnect_device(websocket: WebSocket, message: dict):
    """Desconecta dispositivo"""
    device_id = message.get('device_id')
    
    try:
        device = client.devices[device_id]
        await device.disconnect()
        
        await websocket.send_json({
            'type': 'device_disconnected',
            'device_id': device_id
        })
        
        logger.info(f"Desconectado: {device.name}")
    except Exception as e:
        await send_error(websocket, f"Error desconectando: {e}")

async def vibrate_device(websocket: WebSocket, message: dict):
    """Controla vibración"""
    device_id = message.get('device_id')
    intensity = message.get('intensity', 0.5)
    
    try:
        device = client.devices[device_id]
        
        if device.has_output(buttplug.OutputType.VIBRATE):
            await device.run_output(
                buttplug.DeviceOutputCommand(
                    buttplug.OutputType.VIBRATE,
                    intensity
                )
            )
            
            await websocket.send_json({
                'type': 'vibrate_success',
                'device_id': device_id,
                'intensity': intensity
            })
            
            logger.info(f"Vibrate: {device.name} @ {intensity*100:.0f}%")
    except Exception as e:
        await send_error(websocket, f"Error vibrando: {e}")

async def stop_device(websocket: WebSocket, message: dict):
    """Detiene dispositivo"""
    device_id = message.get('device_id')
    
    try:
        device = client.devices[device_id]
        await device.stop_all()
        
        await websocket.send_json({
            'type': 'stop_success',
            'device_id': device_id
        })
        
        logger.info(f"Stop: {device.name}")
    except Exception as e:
        await send_error(websocket, f"Error deteniendo: {e}")

async def send_error(websocket: WebSocket, error_msg: str):
    """Envía error al cliente"""
    await websocket.send_json({
        'type': 'error',
        'message': error_msg
    })
    logger.error(f"❌ {error_msg}")

# ═══════════════════════════════════════════════════════════════
# HTTP REST API (Opcional)
# ═══════════════════════════════════════════════════════════════

@app.get("/")
async def root():
    """Información del servidor"""
    return {
        "name": "Velvet Sync Backend",
        "version": "1.0.0",
        "websocket": "/ble"
    }

@app.get("/devices")
async def get_devices():
    """Obtener dispositivos conectados"""
    devices = []
    for idx, device in client.devices.items():
        devices.append({
            'index': idx,
            'name': device.name,
            'address': device.addr
        })
    return {"devices": devices}

@app.post("/vibrate")
async def api_vibrate(device_id: int, intensity: float):
    """API REST para vibrar"""
    try:
        device = client.devices[device_id]
        await device.run_output(
            buttplug.DeviceOutputCommand(
                buttplug.OutputType.VIBRATE,
                intensity
            )
        )
        return {"status": "ok", "intensity": intensity}
    except Exception as e:
        return {"status": "error", "message": str(e)}

@app.post("/stop")
async def api_stop(device_id: int):
    """API REST para detener"""
    try:
        device = client.devices[device_id]
        await device.stop_all()
        return {"status": "ok"}
    except Exception as e:
        return {"status": "error", "message": str(e)}

# ═══════════════════════════════════════════════════════════════
# Ejecución
# ═══════════════════════════════════════════════════════════════

if __name__ == "__main__":
    import uvicorn
    uvicorn.run(app, host="0.0.0.0", port=8000)
```

### Ejecutar Servidor Python

```bash
# Iniciar servidor
python main.py

# O con uvicorn directo
uvicorn main:app --reload --host 0.0.0.0 --port 8000
```

---

## 🟨 Opción 2: Node.js Backend

### Instalación

```bash
# Inicializar proyecto
npm init -y
npm install buttplug ws express cors

# O con yarn
yarn add buttplug ws express cors
```

### `server.js` - Servidor Node.js

```javascript
#!/usr/bin/env node
/**
 * Velvet Sync Backend - Node.js
 * Servidor WebSocket para controlar dispositivos BLE desde Web
 */

const express = require('express');
const WebSocket = require('ws');
const cors = require('cors');
const buttplug = require('buttplug');

const app = express();
const PORT = 8000;
const BUTTPLUG_URL = 'ws://localhost:12345';

// CORS
app.use(cors());

// Cliente Buttplug
let client = null;
const connectedDevices = new Map();

// ═══════════════════════════════════════════════════════════════
// Inicialización
// ═══════════════════════════════════════════════════════════════

async function initialize() {
    try {
        client = new buttplug.Client('Velvet Sync Backend');
        await client.connect(BUTTPLUG_URL);
        console.log('✅ Conectado a Intiface Engine');
    } catch (e) {
        console.error('❌ Error conectando a Intiface:', e);
    }
}

// ═══════════════════════════════════════════════════════════════
// WebSocket Server
// ═══════════════════════════════════════════════════════════════

const wss = new WebSocket.Server({ port: 8001 });

wss.on('connection', (ws) => {
    console.log('🔌 Cliente Web conectado');
    
    ws.on('message', async (message) => {
        try {
            const data = JSON.parse(message);
            await processCommand(ws, data);
        } catch (e) {
            sendError(ws, e.message);
        }
    });
    
    ws.on('close', () => {
        console.log('Cliente Web desconectado');
    });
});

async function processCommand(ws, message) {
    const cmdType = message.type;
    
    switch (cmdType) {
        case 'start_scan':
            await startScan(ws, message);
            break;
        case 'connect':
            await connectDevice(ws, message);
            break;
        case 'vibrate':
            await vibrateDevice(ws, message);
            break;
        case 'stop':
            await stopDevice(ws, message);
            break;
        default:
            sendError(ws, `Comando desconocido: ${cmdType}`);
    }
}

async function startScan(ws, message) {
    const timeout = message.timeout || 10000;
    
    console.log('Iniciando escaneo...');
    ws.send(JSON.stringify({ type: 'scan_starting', timeout }));
    
    await client.startScanning();
    
    setTimeout(async () => {
        await client.stopScanning();
        
        const devices = [];
        client.devices.forEach((device, index) => {
            devices.push({
                index,
                name: device.name,
                address: device.addr
            });
            connectedDevices.set(index, device);
        });
        
        ws.send(JSON.stringify({
            type: 'scan_complete',
            devices
        }));
        
        console.log(`Escaneo completado: ${devices.length} dispositivos`);
    }, timeout);
}

async function connectDevice(ws, message) {
    const deviceId = message.device_id;
    const device = client.devices.get(deviceId);
    
    if (!device) {
        sendError(ws, 'Dispositivo no encontrado');
        return;
    }
    
    await client.connectDevice(device);
    
    ws.send(JSON.stringify({
        type: 'device_connected',
        device_id: deviceId,
        name: device.name
    }));
    
    console.log(`✅ Conectado a ${device.name}`);
}

async function vibrateDevice(ws, message) {
    const deviceId = message.device_id;
    const intensity = message.intensity || 0.5;
    const device = client.devices.get(deviceId);
    
    if (!device) {
        sendError(ws, 'Dispositivo no encontrado');
        return;
    }
    
    if (device.hasOutput(buttplug.OutputType.Vibrate)) {
        await device.runOutput(
            new buttplug.DeviceOutputCommand(
                buttplug.OutputType.Vibrate,
                intensity
            )
        );
        
        ws.send(JSON.stringify({
            type: 'vibrate_success',
            device_id: deviceId,
            intensity: intensity
        }));
        
        console.log(`Vibrate: ${device.name} @ ${intensity*100:.0f}%`);
    }
}

async function stopDevice(ws, message) {
    const deviceId = message.device_id;
    const device = client.devices.get(deviceId);
    
    if (!device) {
        sendError(ws, 'Dispositivo no encontrado');
        return;
    }
    
    await device.stopAll();
    
    ws.send(JSON.stringify({
        type: 'stop_success',
        device_id: deviceId
    }));
    
    console.log(`Stop: ${device.name}`);
}

function sendError(ws, errorMsg) {
    ws.send(JSON.stringify({
        type: 'error',
        message: errorMsg
    }));
    console.error(`❌ ${errorMsg}`);
}

// ═══════════════════════════════════════════════════════════════
// HTTP Server (Opcional)
// ═══════════════════════════════════════════════════════════════

app.get('/', (req, res) => {
    res.json({
        name: 'Velvet Sync Backend',
        version: '1.0.0',
        websocket: `ws://localhost:${PORT}`
    });
});

app.get('/devices', (req, res) => {
    const devices = [];
    client.devices.forEach((device, index) => {
        devices.push({
            index,
            name: device.name,
            address: device.addr
        });
    });
    res.json({ devices });
});

app.post('/vibrate', express.json(), (req, res) => {
    const { device_id, intensity } = req.body;
    // ... implementación ...
    res.json({ status: 'ok' });
});

// ═══════════════════════════════════════════════════════════════
// Start
// ═══════════════════════════════════════════════════════════════

initialize().then(() => {
    app.listen(PORT, () => {
        console.log(`🚀 Velvet Sync Backend corriendo en http://localhost:${PORT}`);
        console.log(`📡 WebSocket: ws://localhost:8001`);
    });
});
```

---

## 📖 Uso desde Flutter Web

### Conexión WebSocket

```dart
// lib/ble/ble_service_web.dart (ya creado)
import 'dart:convert';
import 'package:web_socket_channel/web_socket_channel.dart';

class BleServiceWeb {
  WebSocketChannel? _channel;
  
  Future<void> connectToBackend() async {
    _channel = WebSocketChannel.connect(
      Uri.parse('ws://localhost:8000/ble'),
    );
    
    _channel!.stream.listen((message) {
      final data = jsonDecode(message);
      // ... procesar respuesta ...
    });
  }
  
  Future<void> vibrate(String deviceId, double intensity) async {
    _channel!.sink.add(jsonEncode({
      'type': 'vibrate',
      'device_id': deviceId,
      'intensity': intensity,
    }));
  }
}
```

---

## 🛡️ Seguridad

### 1. **NUNCA exponer a Internet sin autenticación**

```python
# Python - Agregar autenticación
from fastapi.security import APIKeyHeader

api_key_header = APIKeyHeader(name="X-API-Key")

@app.websocket("/ble")
async def websocket_endpoint(
    websocket: WebSocket,
    api_key: str = Depends(api_key_header)
):
    if api_key != os.getenv("API_KEY"):
        await websocket.close(code=4001, reason="No autorizado")
        return
    # ... resto del código ...
```

### 2. **Usar HTTPS/WSS en producción**

```python
# uvicorn con SSL
uvicorn main:app \
  --host 0.0.0.0 \
  --port 8000 \
  --ssl-keyfile=./key.pem \
  --ssl-certfile=./cert.pem
```

### 3. **Rate Limiting**

```python
from slowapi import Limiter
from slowapi.util import get_remote_address

limiter = Limiter(key_func=get_remote_address)

@app.websocket("/ble")
@limiter.limit("20/second")
async def websocket_endpoint(websocket: WebSocket, request: Request):
    # ... máximo 20 mensajes por segundo ...
```

---

## 📊 Comparación: Python vs Node.js

| Característica | Python | Node.js |
|----------------|--------|---------|
| **Facilidad** | ✅ Más fácil | 🟡 Moderado |
| **Performance** | 🟡 Bueno | ✅ Excelente |
| **buttplug-py** | ✅ Maduro | ✅ buttplug-js |
| **Comunidad** | ✅ Grande | ✅ Grande |
| **Recomendado** | ✅ **Sí** | 🟡 Alternativa |

---

## ✅ Conclusión

**Para Web, necesitas:**

1. ✅ **Backend Python/Node.js** corriendo en servidor
2. ✅ **Intiface Engine** instalado en mismo servidor
3. ✅ **WebSocket** entre Web app y backend
4. ✅ **Autenticación** si expones a Internet

**Recomendación:** Usar Python + FastAPI por simplicidad.

---

*Documento de referencia generado: 2026-03-19*  
*Velvet Sync Platform - Backend para Web v1.0.0*
