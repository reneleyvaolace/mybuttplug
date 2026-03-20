// ═══════════════════════════════════════════════════════════════
// Velvet Sync · lib/ble/ble_service_platform.dart
// Export Condicional de Servicio BLE por Plataforma
// 
// Este archivo exporta automáticamente el servicio BLE correcto
// según la plataforma de compilación.
// 
// Uso:
//   import 'package:velvet_sync/ble/ble_service_platform.dart';
//   
//   final ble = getBleService();
//   await ble.initialize();
// ═══════════════════════════════════════════════════════════════

// Export condicional basado en la plataforma
export 'ble_service_mobile.dart'
  if (dart.library.html) 'ble_service_web.dart'
  if (dart.library.io) 'ble_service_desktop.dart';

// ═══════════════════════════════════════════════════════════════
// Función factory unificada
// ═══════════════════════════════════════════════════════════════

import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb;

import 'ble_service_mobile.dart' as mobile;
import 'ble_service_desktop.dart' as desktop;
import 'ble_service_web.dart' as web;

/// Obtiene el servicio BLE apropiado para la plataforma actual.
/// 
/// Retorna:
/// - [mobile.BleServiceMobile] para Android/iOS
/// - [desktop.BleServiceDesktop] para Windows/macOS/Linux
/// - [web.BleServiceWeb] para Web
/// 
/// Ejemplo:
/// ```dart
/// final ble = getBleService();
/// await ble.initialize();
/// ```
dynamic getBleService() {
  if (kIsWeb) {
    return web.getBleService();
  }
  
  if (Platform.isAndroid || Platform.isIOS) {
    return mobile.getBleService();
  }
  
  if (Platform.isWindows || Platform.isMacOS || Platform.isLinux) {
    return desktop.getBleService();
  }
  
  throw UnsupportedError('Plataforma no soportada: ${Platform.operatingSystem}');
}

/// Obtiene información de la plataforma BLE
String getBlePlatformInfo() {
  if (kIsWeb) {
    return 'Web (requiere backend BLE)';
  }
  
  if (Platform.isAndroid || Platform.isIOS) {
    return 'Mobile (BLE nativo vía flutter_blue_plus)';
  }
  
  if (Platform.isWindows || Platform.isMacOS || Platform.isLinux) {
    return 'Desktop (Buttplug WebSocket)';
  }
  
  return 'Desconocido';
}

/// Verifica si el BLE está disponible en la plataforma actual
bool isBleAvailable() {
  // Web NO tiene BLE nativo, requiere backend
  if (kIsWeb) return true; // Pero requiere backend
  
  // Mobile tiene BLE nativo
  if (Platform.isAndroid || Platform.isIOS) return true;
  
  // Desktop tiene BLE limitado, usamos Buttplug
  if (Platform.isWindows || Platform.isMacOS || Platform.isLinux) return true;
  
  return false;
}

/// Verifica si se requiere backend para BLE
bool requiresBleBackend() {
  return kIsWeb;
}
