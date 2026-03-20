# 🔧 Troubleshooting - Velvet Sync

## 📱 Problemas Comunes y Soluciones

---

## 🖥️ **Pantalla en Blanco en Emuladores (BlueStacks, Nox, etc.)**

### Síntomas
- La app se queda en pantalla blanca/negra después de iniciar
- Splash screen se muestra pero no navega a la pantalla principal
- No hay respuesta al tocar la pantalla

### Causas Probables

#### 1. **BlueStacks no detectado por ADB** ❌

**Problema:** Flutter no puede conectar al emulador.

**Solución:**
```powershell
# Conectar ADB a BlueStacks
adb connect 127.0.0.1:5555

# Verificar dispositivos conectados
adb devices

# Si el puerto 5555 no funciona, intentar alternativas:
adb connect 127.0.0.1:5556
adb connect 127.0.0.1:5557
adb connect 127.0.0.1:5558
```

**Verificación:**
```powershell
flutter devices
# Debería mostrar el emulador en la lista
```

---

#### 2. **Servicios de Google Play desactualizados** ❌

**Problema:** Supabase/Firebase requieren Google Play Services actualizados.

**Solución:**
1. En BlueStacks, abre **Configuración**
2. Ve a **Apps → Google Play Services**
3. Si hay actualización disponible, instálala
4. Reinicia BlueStacks

---

#### 3. **Hardware BLE no disponible en emulador** ⚠️ **CRÍTICO**

**Problema:** La app usa `flutter_blue_plus` que requiere **hardware Bluetooth real**.

**Los emuladores NO tienen Bluetooth físico**, lo que causa:
- Crash silencioso al inicializar BLE
- Foreground service falla
- La app se queda colgada en la inicialización

**Solución recomendada:**
> ✅ **Usa un dispositivo físico Android** para testing de funcionalidades BLE.
>
> Los emuladores solo son útiles para testing de UI básica.

**Workaround para debugging:**
Si necesitas testear sin BLE, comenta temporalmente la inicialización del AI Bridge en `main.dart`:

```dart
// Comentar temporalmente para testing en emulador
// final aiBridge = AIHardwareBridge();
// await aiBridge.init();
```

---

#### 4. **Error de inicialización silencioso** ❌

**Problema:** Los servicios fallan al iniciar pero no se muestra el error.

**Solución:** El `main.dart` actual ya incluye manejo de errores con logs.

**Ver logs en tiempo real:**
```powershell
# Conectar a dispositivo/emulador
flutter devices

# Ver logs
flutter logs

# O filtrar por tag
adb logcat | grep -i "INIT\|SUPABASE\|AI_BRIDGE"
```

---

### **Pasos de Diagnóstico**

1. **Verificar conexión ADB:**
   ```powershell
   adb devices
   ```

2. **Verificar Flutter:**
   ```powershell
   flutter doctor -v
   ```

3. **Limpiar proyecto:**
   ```powershell
   flutter clean
   flutter pub get
   ```

4. **Reiniciar emulador/ADB:**
   ```powershell
   adb kill-server
   adb start-server
   ```

---

## 🔴 **Errores de Conexión BLE**

### "No se encontró dispositivo compatible"

**Causas:**
- Dispositivo fuera de rango (>10m)
- Dispositivo ya conectado a otro teléfono
- Dispositivo en modo sueño (apagado)

**Soluciones:**
1. Acercar el dispositivo al teléfono (<3m)
2. Desconectar de otros dispositivos
3. Reiniciar el dispositivo (apagar/encender)
4. Verificar que el LED esté parpadeando (modo pairing)

---

### "Handshake fallido: hardware no responde"

**Causa:** El dispositivo está visible pero no responde a comandos.

**Solución:**
1. Verificar batería del dispositivo
2. Reiniciar Bluetooth del teléfono
3. Reinstalar app (limpiar caché BLE)

---

## 🔴 **Errores de Supabase**

### "Failed host lookup"

**Causa:** Sin conexión a internet o DNS bloqueado.

**Solución:**
1. Verificar conexión WiFi/Datos
2. Probar con otro DNS (8.8.8.8)
3. Reiniciar router

---

### "Invalid API key"

**Causa:** Credenciales de Supabase incorrectas en `.env`.

**Solución:**
1. Verificar `.env` existe en raíz del proyecto
2. Ejecutar `flutter clean` y rebuild
3. Regenerar API keys en Supabase Dashboard

---

## 📋 **Comandos Útiles de Diagnóstico**

```powershell
# Ver logs de la app
flutter logs

# Ver dispositivos conectados
adb devices

# Reiniciar ADB
adb kill-server && adb start-server

# Limpiar proyecto
flutter clean

# Reinstalar dependencias
flutter pub get

# Ver estado de Flutter
flutter doctor -v

# Conectar BlueStacks
adb connect 127.0.0.1:5555
```

---

*Última actualización: Marzo 2026*
*Versión: 1.2.0*
