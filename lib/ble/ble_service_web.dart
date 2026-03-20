// ═══════════════════════════════════════════════════════════════
// Velvet Sync · lib/ble/ble_service_web.dart
// Servicio BLE para Web
// 
// Web NO tiene acceso BLE directo. Requiere backend que controle
// los dispositivos BLE y exponga API WebSocket/HTTP.
// ═══════════════════════════════════════════════════════════════

import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import '../utils/logger.dart';

/// Servicio BLE específico para Web
/// 
/// Web NO tiene acceso BLE nativo. Este servicio se conecta a un
/// backend (Python/Node.js) que controla los dispositivos BLE.
class BleServiceWeb {
  static final BleServiceWeb _instance = BleServiceWeb._internal();
  factory BleServiceWeb() => _instance;
  BleServiceWeb._internal();

  WebSocketChannel? _channel;
  bool _isConnected = false;
  bool _isScanning = false;
  String? _backendUrl;
  final List<Map<String, dynamic>> _discoveredDevices = [];

  /// ¿Está conectado al backend?
  bool get isConnected => _isConnected;
  
  /// ¿Está escaneando?
  bool get isScanning => _isScanning;

  /// Dispositivos descubiertos
  List<Map<String, dynamic>> get discoveredDevices => List.unmodifiable(_discoveredDevices);

  /// Verifica si el BLE está disponible en esta plataforma
  static bool get isSupported => kIsWeb;

  /// Inicializa el servicio BLE web
  Future<void> initialize({String backendUrl = 'ws://localhost:8000/ble'}) async {
    if (!isSupported) {
      lvsLog('BLE Web no soportado en esta plataforma', tag: 'BLE_WEB');
      throw UnsupportedError('BLE Web solo está disponible en navegadores');
    }

    _backendUrl = backendUrl;
    lvsLog('BLE Web inicializado (requiere backend: $backendUrl)', tag: 'BLE_WEB');
  }

  /// Conecta al backend BLE
  Future<bool> connectToBackend() async {
    if (_backendUrl == null) {
      lvsLog('❌ Backend URL no configurada', tag: 'BLE_WEB');
      return false;
    }

    try {
      lvsLog('Conectando al backend BLE...', tag: 'BLE_WEB');
      _channel = WebSocketChannel.connect(Uri.parse(_backendUrl!));
      
      // Esperar conexión
      await _channel!.ready.timeout(const Duration(seconds: 3));
      
      // Escuchar mensajes del backend
      _channel!.stream.listen(
        (message) => _handleMessage(message),
        onError: (error) => _handleError(error),
        onDone: () => _handleDisconnect(),
      );

      _isConnected = true;
      lvsLog('✅ Conectado al backend BLE', tag: 'BLE_WEB');
      return true;
    } catch (e) {
      lvsLog('❌ Error conectando al backend: $e', tag: 'BLE_WEB');
      _isConnected = false;
      return false;
    }
  }

  /// Maneja mensajes del backend
  void _handleMessage(dynamic message) {
    try {
      final data = jsonDecode(message as String);
      final type = data['type'] as String;

      switch (type) {
        case 'scan_result':
          _discoveredDevices.add(data['device'] as Map<String, dynamic>);
          lvsLog('Dispositivo encontrado: ${data['device']['name']}', tag: 'BLE_WEB');
          break;
        
        case 'scan_complete':
          _isScanning = false;
          lvsLog('Escaneo completado: ${_discoveredDevices.length} dispositivos', tag: 'BLE_WEB');
          break;
        
        case 'device_connected':
          lvsLog('✅ Dispositivo conectado: ${data['device_id']}', tag: 'BLE_WEB');
          break;
        
        case 'device_disconnected':
          lvsLog('Dispositivo desconectado: ${data['device_id']}', tag: 'BLE_WEB');
          break;
        
        case 'error':
          lvsLog('❌ Error del backend: ${data['message']}', tag: 'BLE_WEB');
          break;
      }
    } catch (e) {
      lvsLog('Error procesando mensaje: $e', tag: 'BLE_WEB');
    }
  }

  /// Maneja errores del backend
  void _handleError(dynamic error) {
    lvsLog('Error del backend: $error', tag: 'BLE_WEB');
    _handleDisconnect();
  }

  /// Maneja desconexión
  void _handleDisconnect() {
    _isConnected = false;
    _channel = null;
    lvsLog('Desconectado del backend', tag: 'BLE_WEB');
  }

  /// Escanea dispositivos vía backend
  Future<List<Map<String, dynamic>>> scan({
    Duration timeout = const Duration(seconds: 10),
  }) async {
    if (!isSupported) {
      throw UnsupportedError('BLE Web scan solo disponible en Web');
    }

    if (!_isConnected) {
      lvsLog('❌ No hay conexión al backend', tag: 'BLE_WEB');
      return [];
    }

    lvsLog('Iniciando escaneo...', tag: 'BLE_WEB');
    _isScanning = true;
    _discoveredDevices.clear();

    _channel!.sink.add(jsonEncode({
      'type': 'start_scan',
      'timeout': timeout.inSeconds,
    }));

    // Esperar a que complete el escaneo
    while (_isScanning) {
      await Future.delayed(const Duration(milliseconds: 100));
    }

    return _discoveredDevices;
  }

  /// Conecta a un dispositivo vía backend
  Future<bool> connect(String deviceId) async {
    if (!isSupported) {
      throw UnsupportedError('BLE Web connect solo disponible en Web');
    }

    if (!_isConnected) {
      lvsLog('❌ No hay conexión al backend', tag: 'BLE_WEB');
      return false;
    }

    lvsLog('Conectando a $deviceId...', tag: 'BLE_WEB');
    
    _channel!.sink.add(jsonEncode({
      'type': 'connect',
      'device_id': deviceId,
    }));

    // Esperar confirmación (timeout 5s)
    final connected = await _waitForDeviceStatus(deviceId, 'connected');
    return connected;
  }

  /// Desconecta de un dispositivo
  Future<void> disconnect(String deviceId) async {
    if (!isSupported) {
      throw UnsupportedError('BLE Web disconnect solo disponible en Web');
    }

    if (!_isConnected) return;

    lvsLog('Desconectando $deviceId...', tag: 'BLE_WEB');
    
    _channel!.sink.add(jsonEncode({
      'type': 'disconnect',
      'device_id': deviceId,
    }));
  }

  /// Envía comando de vibración
  Future<void> vibrate(String deviceId, double intensity) async {
    if (!isSupported) {
      throw UnsupportedError('BLE Web vibrate solo disponible en Web');
    }

    if (!_isConnected) {
      lvsLog('❌ No hay conexión al backend', tag: 'BLE_WEB');
      return;
    }

    _channel!.sink.add(jsonEncode({
      'type': 'vibrate',
      'device_id': deviceId,
      'intensity': intensity.clamp(0.0, 1.0),
    }));

    lvsLog('→ Vibrate: $deviceId @ ${(intensity * 100).round()}%', tag: 'BLE_WEB');
  }

  /// Detiene todos los actuadores
  Future<void> stop(String deviceId) async {
    if (!isSupported) {
      throw UnsupportedError('BLE Web stop solo disponible en Web');
    }

    if (!_isConnected) return;

    _channel!.sink.add(jsonEncode({
      'type': 'stop',
      'device_id': deviceId,
    }));

    lvsLog('→ Stop: $deviceId', tag: 'BLE_WEB');
  }

  /// Espera el estado de un dispositivo
  Future<bool> _waitForDeviceStatus(String deviceId, String status, {int timeout = 5}) async {
    final endTime = DateTime.now().add(Duration(seconds: timeout));
    
    while (DateTime.now().isBefore(endTime)) {
      // TODO: Implementar verificación de estado
      await Future.delayed(const Duration(milliseconds: 100));
    }
    
    return false;
  }

  /// Limpia recursos
  Future<void> dispose() async {
    lvsLog('Limpiando BLE Web...', tag: 'BLE_WEB');
    _channel?.sink.close();
    _isConnected = false;
    _isScanning = false;
    _discoveredDevices.clear();
  }
}

// ═══════════════════════════════════════════════════════════════
// Factory para obtener el servicio BLE correcto
// ═══════════════════════════════════════════════════════════════

/// Obtiene el servicio BLE apropiado para la plataforma
dynamic getBleService() {
  if (kIsWeb) {
    return BleServiceWeb();
  }
  
  throw UnsupportedError('Usa getBleService() desde ble_service_platform.dart');
}
