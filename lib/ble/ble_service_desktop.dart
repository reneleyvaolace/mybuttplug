// ═══════════════════════════════════════════════════════════════
// Velvet Sync · lib/ble/ble_service_desktop.dart
// Servicio BLE para Desktop (Windows/macOS/Linux)
// 
// Usa Buttplug WebSocket para comunicación BLE en desktop.
// flutter_blue_plus tiene soporte limitado en desktop.
// ═══════════════════════════════════════════════════════════════

import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import '../utils/logger.dart';

/// Servicio BLE específico para desktop (Windows/macOS/Linux)
/// 
/// En desktop, usamos Buttplug WebSocket en lugar de BLE nativo
/// porque flutter_blue_plus tiene soporte limitado.
class BleServiceDesktop {
  static final BleServiceDesktop _instance = BleServiceDesktop._internal();
  factory BleServiceDesktop() => _instance;
  BleServiceDesktop._internal();

  bool _isConnected = false;
  bool _isScanning = false;
  String? _buttplugUrl;

  /// ¿Está conectado a Buttplug?
  bool get isConnected => _isConnected;
  
  /// ¿Está escaneando?
  bool get isScanning => _isScanning;

  /// Verifica si el BLE está disponible en esta plataforma
  static bool get isSupported => !kIsWeb && 
      (Platform.isWindows || Platform.isMacOS || Platform.isLinux);

  /// Inicializa el servicio BLE desktop
  Future<void> initialize({String buttplugUrl = 'ws://localhost:12345'}) async {
    if (!isSupported) {
      lvsLog('BLE Desktop no soportado en esta plataforma', tag: 'BLE_DESKTOP');
      throw UnsupportedError('BLE Desktop solo está disponible en Windows/macOS/Linux');
    }

    _buttplugUrl = buttplugUrl;
    lvsLog('BLE Desktop inicializado (usará Buttplug WebSocket)', tag: 'BLE_DESKTOP');
  }

  /// Verifica si Intiface Engine está disponible
  Future<bool> isIntifaceEngineAvailable() async {
    try {
      final socket = await Socket.connect(
        'localhost',
        12345,
        timeout: const Duration(seconds: 2),
      );
      await socket.close();
      return true;
    } catch (e) {
      return false;
    }
  }

  /// Escanea dispositivos vía Buttplug
  /// 
  /// Requiere Intiface Engine corriendo en localhost:12345
  Future<List<Map<String, dynamic>>> scan({
    Duration timeout = const Duration(seconds: 10),
  }) async {
    if (!isSupported) {
      throw UnsupportedError('BLE Desktop scan solo disponible en Windows/macOS/Linux');
    }

    lvsLog('Iniciando escaneo vía Buttplug...', tag: 'BLE_DESKTOP');
    _isScanning = true;

    try {
      // Conectar a Buttplug
      final channel = await _connectToButtplug();
      if (channel == null) {
        lvsLog('❌ No se pudo conectar a Buttplug', tag: 'BLE_DESKTOP');
        _isScanning = false;
        return [];
      }

      // Iniciar escaneo
      channel.sink.add(jsonEncode({
        'type': 'start_scan',
      }));

      // Esperar timeout
      await Future.delayed(timeout);

      // Detener escaneo
      channel.sink.add(jsonEncode({
        'type': 'stop_scan',
      }));

      // Obtener dispositivos
      channel.sink.add(jsonEncode({
        'type': 'get_devices',
      }));

      // Procesar respuesta (simplificado)
      _isScanning = false;
      lvsLog('Escaneo completado', tag: 'BLE_DESKTOP');
      return []; // TODO: Implementar parseo de dispositivos
    } catch (e) {
      lvsLog('Error en escaneo desktop: $e', tag: 'BLE_DESKTOP');
      _isScanning = false;
      return [];
    }
  }

  /// Conecta a un dispositivo vía Buttplug
  Future<void> connect(String deviceId) async {
    if (!isSupported) {
      throw UnsupportedError('BLE Desktop connect solo disponible en Windows/macOS/Linux');
    }

    final channel = await _connectToButtplug();
    if (channel == null) {
      throw Exception('No se pudo conectar a Buttplug');
    }

    channel.sink.add(jsonEncode({
      'type': 'connect_device',
      'device_id': deviceId,
    }));

    _isConnected = true;
    lvsLog('✅ Conectado a $deviceId', tag: 'BLE_DESKTOP');
  }

  /// Desconecta de un dispositivo
  Future<void> disconnect(String deviceId) async {
    if (!isSupported) {
      throw UnsupportedError('BLE Desktop disconnect solo disponible en Windows/macOS/Linux');
    }

    final channel = await _connectToButtplug();
    if (channel == null) return;

    channel.sink.add(jsonEncode({
      'type': 'disconnect_device',
      'device_id': deviceId,
    }));

    _isConnected = false;
    lvsLog('Desconectado', tag: 'BLE_DESKTOP');
  }

  /// Envía comando de vibración
  Future<void> vibrate(String deviceId, double intensity) async {
    if (!isSupported) {
      throw UnsupportedError('BLE Desktop vibrate solo disponible en Windows/macOS/Linux');
    }

    final channel = await _connectToButtplug();
    if (channel == null) return;

    channel.sink.add(jsonEncode({
      'type': 'vibrate',
      'device_id': deviceId,
      'intensity': intensity.clamp(0.0, 1.0),
    }));

    lvsLog('→ Vibrate: $deviceId @ ${(intensity * 100).round()}%', tag: 'BLE_DESKTOP');
  }

  /// Detiene todos los actuadores
  Future<void> stop(String deviceId) async {
    if (!isSupported) {
      throw UnsupportedError('BLE Desktop stop solo disponible en Windows/macOS/Linux');
    }

    final channel = await _connectToButtplug();
    if (channel == null) return;

    channel.sink.add(jsonEncode({
      'type': 'stop',
      'device_id': deviceId,
    }));

    lvsLog('→ Stop: $deviceId', tag: 'BLE_DESKTOP');
  }

  /// Conecta a Buttplug WebSocket
  Future<WebSocketChannel?> _connectToButtplug() async {
    try {
      final channel = WebSocketChannel.connect(
        Uri.parse(_buttplugUrl ?? 'ws://localhost:12345'),
      );
      
      // Esperar conexión
      await channel.ready.timeout(const Duration(seconds: 3));
      
      return channel;
    } catch (e) {
      lvsLog('Error conectando a Buttplug: $e', tag: 'BLE_DESKTOP');
      return null;
    }
  }

  /// Limpia recursos
  Future<void> dispose() async {
    lvsLog('Limpiando BLE Desktop...', tag: 'BLE_DESKTOP');
    _isConnected = false;
    _isScanning = false;
  }
}

// ═══════════════════════════════════════════════════════════════
// Factory para obtener el servicio BLE correcto
// ═══════════════════════════════════════════════════════════════

/// Obtiene el servicio BLE apropiado para la plataforma
dynamic getBleService() {
  if (kIsWeb) {
    throw UnsupportedError('Usa BleServiceWeb para plataforma web');
  }
  
  if (Platform.isWindows || Platform.isMacOS || Platform.isLinux) {
    return BleServiceDesktop();
  }
  
  throw UnsupportedError('Plataforma no soportada para BLE Desktop');
}
