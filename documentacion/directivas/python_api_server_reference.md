# 🐍 Velvet Sync API Server - Referencia Python

**Versión:** 1.0.0  
**Fecha:** 2026-03-19  
**Estado:** 🟡 Referencia para desarrollo futuro

---

## 📋 Visión General

Velvet Sync API Server es una **referencia de implementación** para crear un servidor HTTP que permita controlar dispositivos hápticos desde cualquier lenguaje o plataforma.

**Tecnologías:**
- Python 3.9+
- FastAPI (framework web)
- buttplug-py (cliente Buttplug)
- WebSocket (conexión a Intiface Engine)

---

## 🎯 Casos de Uso

### 1. **Integración con Terceros**
```bash
# Controlar dispositivos desde cualquier lenguaje
curl -X POST http://localhost:8000/vibrate \
  -H "Content-Type: application/json" \
  -d '{"device_index": 0, "intensity": 0.75}'
```

### 2. **Scripts de Automatización**
```python
# Python
import requests

requests.post('http://localhost:8000/vibrate', json={
    'device_index': 0,
    'intensity': 0.5
})
```

### 3. **Integración con Home Assistant**
```yaml
# configuration.yaml
rest_command:
  velvet_sync_vibrate:
    url: http://localhost:8000/vibrate
    method: post
    content_type: application/json
    payload: '{"device_index": 0, "intensity": 0.75}'
```

### 4. **Juegos y Aplicaciones**
- Control desde Unity/Unreal Engine
- Integración con juegos para adultos
- Sincronización con contenido multimedia

---

## 🏗️ Arquitectura

```
┌─────────────────┐     HTTP/REST      ┌──────────────────┐
│   Cualquier     │ ◄────────────────► │  Velvet Sync API │
│   Cliente       │    JSON            │  Server (Python) │
│   (App, Script) │                    │  FastAPI         │
└─────────────────┘                    └──────────────────┘
                                                │
                                          WebSocket
                                                │
                                                ▼
                                       ┌──────────────────┐
                                       │  Intiface Engine │
                                       │  (Buttplug Rust) │
                                       └──────────────────┘
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

## 📦 Instalación

### 1. **Requisitos Previos**

```bash
# Python 3.9+
python --version

# Instalar dependencias
pip install fastapi uvicorn buttplug websockets
```

### 2. **Requerimientos de Sistema**

- **Intiface Engine** instalado y corriendo
- Puerto WebSocket 12345 disponible
- Puertos HTTP 8000 disponibles

---

## 💻 Código de Referencia

### `main.py` - Servidor API

```python
#!/usr/bin/env python3
"""
Velvet Sync API Server
Servidor HTTP para control de dispositivos hápticos vía Buttplug
"""

from fastapi import FastAPI, HTTPException
from pydantic import BaseModel
import asyncio
import buttplug
from typing import List, Optional

# ── Inicialización ───────────────────────────────────────────────

app = FastAPI(
    title="Velvet Sync API",
    description="API para control de dispositivos hápticos",
    version="1.0.0"
)

# Cliente Buttplug
client: Optional[buttplug.Client] = None
connected_devices = []

# ── Modelos de Datos ─────────────────────────────────────────────

class VibrateRequest(BaseModel):
    device_index: int
    intensity: float  # 0.0 - 1.0
    speed: Optional[float] = None

class StopRequest(BaseModel):
    device_index: int

class DeviceInfo(BaseModel):
    index: int
    name: str
    has_vibrate: bool
    has_rotate: bool
    has_suction: bool
    has_thrust: bool
    battery: Optional[int] = None
    rssi: Optional[int] = None

# ── Eventos de Startup/Shutdown ─────────────────────────────────

@app.on_event("startup")
async def startup_event():
    """Conectar a Intiface Engine al iniciar"""
    global client
    
    try:
        client = buttplug.Client("Velvet Sync API")
        await client.connect("ws://localhost:12345")
        print("✅ Conectado a Intiface Engine")
    except Exception as e:
        print(f"❌ Error conectando a Intiface: {e}")

@app.on_event("shutdown")
async def shutdown_event():
    """Desconectar al cerrar"""
    global client
    
    if client:
        await client.disconnect()
        print("🔌 Desconectado de Intiface Engine")

# ── Endpoints ────────────────────────────────────────────────────

@app.get("/")
async def root():
    """Información de la API"""
    return {
        "name": "Velvet Sync API",
        "version": "1.0.0",
        "docs": "/docs"
    }

@app.get("/devices", response_model=List[DeviceInfo])
async def get_devices():
    """Obtener lista de dispositivos conectados"""
    if not client:
        raise HTTPException(status_code=503, detail="No conectado a Intiface")
    
    devices = []
    for idx, device in enumerate(client.devices.values()):
        devices.append(DeviceInfo(
            index=idx,
            name=device.name,
            has_vibrate=device.has_output(buttplug.OutputType.VIBRATE),
            has_rotate=device.has_output(buttplug.OutputType.ROTATE),
            has_suction=device.has_output(buttplug.OutputType.SUCTION),
            has_thrust=device.has_output(buttplug.OutputType.THRUST),
            battery=device.battery,
            rssi=device.rssi
        ))
    
    return devices

@app.post("/scan")
async def scan_devices(timeout: int = 10):
    """Escanear dispositivos"""
    if not client:
        raise HTTPException(status_code=503, detail="No conectado")
    
    try:
        await client.start_scanning()
        await asyncio.sleep(timeout)
        await client.stop_scanning()
        return {"message": "Escaneo completado", "devices": len(client.devices)}
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

@app.post("/vibrate")
async def vibrate(request: VibrateRequest):
    """Controlar vibración de dispositivo"""
    if not client:
        raise HTTPException(status_code=503, detail="No conectado")
    
    try:
        device = list(client.devices.values())[request.device_index]
        
        if device.has_output(buttplug.OutputType.VIBRATE):
            await device.run_output(
                buttplug.DeviceOutputCommand(
                    buttplug.OutputType.VIBRATE,
                    request.intensity
                )
            )
            return {"message": "Vibración establecida", "intensity": request.intensity}
        else:
            raise HTTPException(status_code=400, detail="Dispositivo no tiene vibración")
    except IndexError:
        raise HTTPException(status_code=404, detail="Dispositivo no encontrado")
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

@app.post("/stop")
async def stop(request: StopRequest):
    """Detener dispositivo"""
    if not client:
        raise HTTPException(status_code=503, detail="No conectado")
    
    try:
        device = list(client.devices.values())[request.device_index]
        await device.stop_all()
        return {"message": "Dispositivo detenido"}
    except IndexError:
        raise HTTPException(status_code=404, detail="Dispositivo no encontrado")
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

@app.post("/stop-all")
async def stop_all():
    """Detener TODOS los dispositivos"""
    if not client:
        raise HTTPException(status_code=503, detail="No conectado")
    
    try:
        for device in client.devices.values():
            await device.stop_all()
        return {"message": "Todos los dispositivos detenidos"}
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

@app.get("/battery/{device_index}")
async def get_battery(device_index: int):
    """Obtener nivel de batería"""
    if not client:
        raise HTTPException(status_code=503, detail="No conectado")
    
    try:
        device = list(client.devices.values())[device_index]
        return {"device_index": device_index, "battery": device.battery}
    except IndexError:
        raise HTTPException(status_code=404, detail="Dispositivo no encontrado")

# ── Ejecución ────────────────────────────────────────────────────

if __name__ == "__main__":
    import uvicorn
    uvicorn.run(app, host="0.0.0.0", port=8000)
```

---

## 📖 Uso de la API

### 1. **Iniciar Servidor**

```bash
python main.py

# O con uvicorn directo:
uvicorn main:app --reload --host 0.0.0.0 --port 8000
```

### 2. **Ver Documentación Interactiva**

```
http://localhost:8000/docs
```

### 3. **Ejemplos de Peticiones**

#### Obtener dispositivos:
```bash
curl http://localhost:8000/devices
```

#### Escanear dispositivos:
```bash
curl -X POST http://localhost:8000/scan?timeout=10
```

#### Controlar vibración:
```bash
curl -X POST http://localhost:8000/vibrate \
  -H "Content-Type: application/json" \
  -d '{"device_index": 0, "intensity": 0.75}'
```

#### Detener dispositivo:
```bash
curl -X POST http://localhost:8000/stop \
  -H "Content-Type: application/json" \
  -d '{"device_index": 0}'
```

#### Detener todos:
```bash
curl -X POST http://localhost:8000/stop-all
```

---

## 🔧 Configuración Avanzada

### Variables de Entorno

```bash
# .env
INTIFACE_URL=ws://localhost:12345
API_HOST=0.0.0.0
API_PORT=8000
```

### CORS (Cross-Origin)

```python
from fastapi.middleware.cors import CORSMiddleware

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],  # En producción, especificar dominios
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)
```

### Autenticación

```python
from fastapi.security import APIKeyHeader

api_key_header = APIKeyHeader(name="X-API-Key")

async def get_api_key(api_key: str = Depends(api_key_header)):
    if api_key != os.getenv("API_KEY"):
        raise HTTPException(status_code=401, detail="API Key inválida")
    return api_key

@app.post("/vibrate")
async def vibrate(
    request: VibrateRequest,
    api_key: str = Depends(get_api_key)
):
    # ... código de vibración ...
```

---

## 📊 Endpoints Disponibles

| Método | Endpoint | Descripción |
|--------|----------|-------------|
| `GET` | `/` | Información de API |
| `GET` | `/devices` | Lista de dispositivos |
| `POST` | `/scan` | Escanear dispositivos |
| `POST` | `/vibrate` | Controlar vibración |
| `POST` | `/rotate` | Controlar rotación |
| `POST` | `/suction` | Controlar succión |
| `POST` | `/thrust` | Controlar empuje |
| `POST` | `/stop` | Detener dispositivo |
| `POST` | `/stop-all` | Detener todos |
| `GET` | `/battery/{index}` | Nivel de batería |
| `GET` | `/rssi/{index}` | Señal RSSI |

---

## 🛡️ Consideraciones de Seguridad

### 1. **NUNCA exponer a Internet sin autenticación**

```python
# Siempre usar API Key o JWT
@app.post("/vibrate")
async def vibrate(request: VibrateRequest, user: User = Depends(get_current_user)):
    # ... solo usuarios autenticados ...
```

### 2. **Rate Limiting**

```python
from slowapi import Limiter
from slowapi.util import get_remote_address

limiter = Limiter(key_func=get_remote_address)

@app.post("/vibrate")
@limiter.limit("10/second")
async def vibrate(request: VibrateRequest):
    # ... máximo 10 peticiones por segundo ...
```

### 3. **Logging de Actividades**

```python
import logging

logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

@app.post("/vibrate")
async def vibrate(request: VibrateRequest):
    logger.info(f"Vibración: device={request.device_index}, intensity={request.intensity}")
    # ... código ...
```

---

## 🎯 Próximos Pasos

### Para Implementar

1. **Descargar buttplug-py:**
   ```bash
   pip install buttplug
   ```

2. **Instalar Intiface Engine:**
   ```bash
   # Windows
   winget install Intiface.IntifaceEngine
   
   # O desde source
   cargo install intiface_engine
   ```

3. **Probar conexión:**
   ```bash
   python main.py
   # Ir a http://localhost:8000/docs
   ```

### Para Producción

1. **Agregar autenticación**
2. **Configurar HTTPS**
3. **Implementar rate limiting**
4. **Agregar logging persistente**
5. **Configurar Docker**

---

## 📝 Notas

- **Esta es una referencia** - No está implementada en la base tecnológica actual
- **Útil para Q3 2026** - Cuando se desarrolle VelvetSync API Server
- **buttplug-py es BSD-3-Clause** - ✅ Uso comercial permitido

---

*Documento de referencia generado: 2026-03-19*  
*Velvet Sync Platform - Python API Server v1.0.0*
