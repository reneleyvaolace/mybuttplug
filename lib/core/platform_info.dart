// ═══════════════════════════════════════════════════════════════
// Velvet Sync · lib/core/platform_info.dart
// Información y Detección de Plataforma
// 
// Proporciona utilidades para detectar la plataforma de ejecución
// y ajustar el comportamiento de la aplicación accordingly.
// ═══════════════════════════════════════════════════════════════

import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb;

// ═══════════════════════════════════════════════════════════════
// Platform Detection
// ═══════════════════════════════════════════════════════════════

/// Utilidades para detectar la plataforma de ejecución
class PlatformInfo {
  const PlatformInfo._();

  /// ¿Se está ejecutando en la web?
  static bool get isWeb => kIsWeb;

  /// ¿Se está ejecutando en Android?
  static bool get isAndroid => !kIsWeb && Platform.isAndroid;

  /// ¿Se está ejecutando en iOS?
  static bool get isIOS => !kIsWeb && Platform.isIOS;

  /// ¿Se está ejecutando en Windows?
  static bool get isWindows => !kIsWeb && Platform.isWindows;

  /// ¿Se está ejecutando en macOS?
  static bool get isMacOS => !kIsWeb && Platform.isMacOS;

  /// ¿Se está ejecutando en Linux?
  static bool get isLinux => !kIsWeb && Platform.isLinux;

  /// ¿Se está ejecutando en un dispositivo móvil?
  static bool get isMobile => isAndroid || isIOS;

  /// ¿Se está ejecutando en un dispositivo de escritorio?
  static bool get isDesktop => isWindows || isMacOS || isLinux;

  /// ¿La plataforma soporta BLE nativo?
  /// 
  /// BLE nativo está disponible en:
  /// - Android ✅
  /// - iOS ✅
  /// - Windows 🟡 (limitado)
  /// - macOS 🟡 (limitado)
  /// - Linux 🟡 (limitado)
  /// - Web ❌ (no disponible)
  static bool get hasNativeBleSupport => isMobile || isDesktop;

  /// ¿La plataforma requiere backend para BLE?
  /// 
  /// Web requiere un backend para controlar dispositivos BLE.
  static bool get requiresBleBackend => isWeb;

  /// ¿La plataforma soporta Buttplug vía WebSocket?
  /// 
  /// Buttplug WebSocket está disponible en TODAS las plataformas.
  static bool get hasButtplugSupport => true;

  /// Nombre de la plataforma (para logging/UI)
  static String get platformName {
    if (isWeb) return 'Web';
    if (isAndroid) return 'Android';
    if (isIOS) return 'iOS';
    if (isWindows) return 'Windows';
    if (isMacOS) return 'macOS';
    if (isLinux) return 'Linux';
    return 'Unknown';
  }

  /// Descripción de la plataforma
  static String get platformDescription {
    if (isWeb) return 'Flutter Web (requiere backend BLE)';
    if (isMobile) return 'Flutter Mobile (BLE nativo disponible)';
    if (isDesktop) return 'Flutter Desktop (BLE limitado, recomendado Buttplug)';
    return 'Plataforma desconocida';
  }

  /// Configuración recomendada para la plataforma
  static PlatformConfig get recommendedConfig {
    if (isWeb) {
      return const PlatformConfig(
        useNativeBle: false,
        useButtplugWebSocket: true,
        bleBackendUrl: 'ws://localhost:8000/ble',
        buttplugUrl: 'ws://localhost:12345',
      );
    }
    
    if (isMobile) {
      return const PlatformConfig(
        useNativeBle: true,
        useButtplugWebSocket: true,
        bleBackendUrl: null,
        buttplugUrl: 'ws://localhost:12345',
      );
    }
    
    if (isDesktop) {
      return const PlatformConfig(
        useNativeBle: false, // Desktop BLE es limitado
        useButtplugWebSocket: true,
        bleBackendUrl: null,
        buttplugUrl: 'ws://localhost:12345',
      );
    }

    // Default
    return const PlatformConfig(
      useNativeBle: false,
      useButtplugWebSocket: true,
      bleBackendUrl: null,
      buttplugUrl: 'ws://localhost:12345',
    );
  }
}

// ═══════════════════════════════════════════════════════════════
// Platform Configuration
// ═══════════════════════════════════════════════════════════════

/// Configuración de plataforma
class PlatformConfig {
  /// ¿Usar BLE nativo (flutter_blue_plus)?
  final bool useNativeBle;

  /// ¿Usar Buttplug vía WebSocket?
  final bool useButtplugWebSocket;

  /// URL del backend BLE (para Web)
  final String? bleBackendUrl;

  /// URL de Buttplug/Intiface Engine
  final String? buttplugUrl;

  const PlatformConfig({
    required this.useNativeBle,
    required this.useButtplugWebSocket,
    this.bleBackendUrl,
    this.buttplugUrl,
  });

  /// Verifica si la configuración es válida
  bool get isValid {
    if (useNativeBle && useButtplugWebSocket) return true;
    if (!useNativeBle && useButtplugWebSocket && buttplugUrl != null) return true;
    if (!useNativeBle && !useButtplugWebSocket && bleBackendUrl != null) return true;
    return false;
  }

  /// Obtiene el modo de conexión
  String get connectionMode {
    if (useNativeBle) return 'Native BLE';
    if (useButtplugWebSocket) return 'Buttplug WebSocket';
    if (bleBackendUrl != null) return 'BLE Backend';
    return 'Unknown';
  }

  @override
  String toString() {
    return 'PlatformConfig(mode: $connectionMode, buttplug: $buttplugUrl, backend: $bleBackendUrl)';
  }
}

// ═══════════════════════════════════════════════════════════════
// Platform-Specific Features
// ═══════════════════════════════════════════════════════════════

/// Características disponibles por plataforma
enum PlatformFeature {
  /// BLE nativo (flutter_blue_plus)
  nativeBle,

  /// Buttplug WebSocket
  buttplugWebSocket,

  /// Backend BLE (para Web)
  bleBackend,

  /// Foreground service (solo Android)
  foregroundService,

  /// Background BLE (solo mobile)
  backgroundBle,

  /// System tray (solo desktop)
  systemTray,

  /// Deep linking (mobile + desktop)
  deepLinking,

  /// File system access
  fileSystem,

  /// Notifications
  notifications,
}

/// Extensión para verificar características de plataforma
extension PlatformFeatureExtension on PlatformFeature {
  /// ¿La característica está disponible en esta plataforma?
  bool get isAvailable {
    switch (this) {
      case PlatformFeature.nativeBle:
        return PlatformInfo.hasNativeBleSupport;
      case PlatformFeature.buttplugWebSocket:
        return PlatformInfo.hasButtplugSupport;
      case PlatformFeature.bleBackend:
        return true; // Todas las plataformas pueden usar backend
      case PlatformFeature.foregroundService:
        return PlatformInfo.isAndroid;
      case PlatformFeature.backgroundBle:
        return PlatformInfo.isMobile;
      case PlatformFeature.systemTray:
        return PlatformInfo.isDesktop;
      case PlatformFeature.deepLinking:
        return PlatformInfo.isMobile || PlatformInfo.isDesktop;
      case PlatformFeature.fileSystem:
        return !PlatformInfo.isWeb;
      case PlatformFeature.notifications:
        return PlatformInfo.isMobile || PlatformInfo.isDesktop;
    }
  }

  /// Descripción de la característica
  String get description {
    switch (this) {
      case PlatformFeature.nativeBle:
        return 'BLE Nativo (flutter_blue_plus)';
      case PlatformFeature.buttplugWebSocket:
        return 'Buttplug WebSocket (100+ dispositivos)';
      case PlatformFeature.bleBackend:
        return 'Backend BLE (para Web)';
      case PlatformFeature.foregroundService:
        return 'Foreground Service (Android)';
      case PlatformFeature.backgroundBle:
        return 'Background BLE (Mobile)';
      case PlatformFeature.systemTray:
        return 'System Tray (Desktop)';
      case PlatformFeature.deepLinking:
        return 'Deep Linking';
      case PlatformFeature.fileSystem:
        return 'File System Access';
      case PlatformFeature.notifications:
        return 'Notificaciones';
    }
  }

  /// Estado de la característica
  String get statusText {
    if (isAvailable) return '✅ Disponible';
    return '❌ No disponible';
  }
}

// ═══════════════════════════════════════════════════════════════
// Debug/Info Widget
// ═══════════════════════════════════════════════════════════════

/// Información de plataforma para debugging
class PlatformDebugInfo {
  /// Obtiene información detallada de la plataforma
  static Map<String, String> get info {
    return {
      'Platform': PlatformInfo.platformName,
      'Description': PlatformInfo.platformDescription,
      'Is Web': PlatformInfo.isWeb.toString(),
      'Is Mobile': PlatformInfo.isMobile.toString(),
      'Is Desktop': PlatformInfo.isDesktop.toString(),
      'Has Native BLE': PlatformInfo.hasNativeBleSupport.toString(),
      'Requires BLE Backend': PlatformInfo.requiresBleBackend.toString(),
      'Has Buttplug': PlatformInfo.hasButtplugSupport.toString(),
      'Config': PlatformInfo.recommendedConfig.toString(),
    };
  }

  /// Imprime información de plataforma en consola
  static void printDebug() {
    debugPrint('════════════════════════════════════════');
    debugPrint('📱 PLATFORM INFO');
    debugPrint('════════════════════════════════════════');
    info.forEach((key, value) {
      debugPrint('$key: $value');
    });
    debugPrint('════════════════════════════════════════');
  }

  /// Obtiene lista de características disponibles
  static List<String> get availableFeatures {
    return PlatformFeature.values
        .where((f) => f.isAvailable)
        .map((f) => f.description)
        .toList();
  }

  /// Obtiene lista de características NO disponibles
  static List<String> get unavailableFeatures {
    return PlatformFeature.values
        .where((f) => !f.isAvailable)
        .map((f) => f.description)
        .toList();
  }
}
