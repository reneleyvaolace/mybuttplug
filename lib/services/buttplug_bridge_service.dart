// ═══════════════════════════════════════════════════════════════
// Velvet Sync · lib/services/buttplug_bridge_service.dart
// Puente Buttplug - Conexión WebSocket a Intiface Engine
// ═══════════════════════════════════════════════════════════════
//
// 📖 RECURSOS:
// - Buttplug-dart: https://pub.dev/packages/buttplug
// - Intiface Engine: https://github.com/intiface/intiface-engine
// - Buttplug.io: https://buttplug.io
// - Documentación: https://docs.buttplug.io
//
// 🔌 INSTALACIÓN DE INTIFACE ENGINE:
// Ver: documentacion/directivas/INTIFACE_ENGINE_SETUP.md
//
// ═══════════════════════════════════════════════════════════════

import 'dart:async';
import 'dart:io' show Platform;
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:buttplug/buttplug.dart';
import '../models/toy_model.dart';
import '../utils/logger.dart';

// ═══════════════════════════════════════════════════════════════
// Providers de Riverpod
// ═══════════════════════════════════════════════════════════════

/// Provider que expone el ButtplugBridgeService como singleton
final buttplugBridgeProvider = ChangeNotifierProvider((ref) {
  return ButtplugBridgeService();
});

/// Provider que expone el estado de conexión
final buttplugConnectionStateProvider = Provider<ButtplugConnectionState>((ref) {
  final service = ref.watch(buttplugBridgeProvider);
  return service.connectionState;
});

/// Provider que expone la lista de dispositivos descubiertos
final buttplugDevicesProvider = Provider<List<ButtplugDevice>>((ref) {
  final service = ref.watch(buttplugBridgeProvider);
  return service.discoveredDevices;
});

// ═══════════════════════════════════════════════════════════════
// Estados de Conexión
// ═══════════════════════════════════════════════════════════════

enum ButtplugConnectionState {
  /// Desconectado del servidor Buttplug
  disconnected,

  /// Conectando al servidor
  connecting,

  /// Conectado y listo para usar
  connected,

  /// Escaneando dispositivos
  scanning,

  /// Error de conexión
  error,
}

// ═══════════════════════════════════════════════════════════════
// Dispositivo Buttplug
// ═══════════════════════════════════════════════════════════════

/// Wrapper para dispositivos Buttplug con información extendida
class ButtplugDevice {
  /// ID único del dispositivo
  final String id;

  /// Nombre amigable del dispositivo
  final String name;

  /// Índice del dispositivo en el cliente
  final int deviceIndex;

  /// Si el dispositivo tiene vibración
  final bool hasVibrate;

  /// Si el dispositivo tiene rotación
  final bool hasRotate;

  /// Si el dispositivo tiene succión
  final bool hasSuction;

  /// Si el dispositivo tiene empuje
  final bool hasThrust;

  /// Número de actuadores de vibración
  final int vibrateCount;

  /// Battery level (0-100, null si no soporta)
  final int? batteryLevel;

  /// RSSI de la señal (null si no disponible)
  final int? rssi;

  const ButtplugDevice({
    required this.id,
    required this.name,
    required this.deviceIndex,
    this.hasVibrate = false,
    this.hasRotate = false,
    this.hasSuction = false,
    this.hasThrust = false,
    this.vibrateCount = 0,
    this.batteryLevel,
    this.rssi,
  });

  /// Crea un ButtplugDevice desde un Device de buttplug-dart
  factory ButtplugDevice.fromButtplugDevice(Device device) {
    return ButtplugDevice(
      id: device.addr,
      name: device.name,
      deviceIndex: device.deviceIndex,
      hasVibrate: device.hasOutput(OutputType.VIBRATE),
      hasRotate: device.hasOutput(OutputType.ROTATE),
      hasSuction: device.hasOutput(OutputType.SUCTION),
      hasThrust: device.hasOutput(OutputType.THRUST),
      vibrateCount: device.vibrateCount,
      batteryLevel: device.battery,
      rssi: device.rssi,
    );
  }

  /// Convierte a ToyModel para compatibilidad con el sistema existente
  ToyModel toToyModel() {
    String motorLogic = 'Single Channel';
    if (vibrateCount > 1) motorLogic = 'Dual Channel';
    if (hasThrust) motorLogic = 'Dual Channel (Thrust + Vibrate)';

    return ToyModel(
      id: id,
      name: name,
      usageType: 'Universal',
      targetAnatomy: 'Universal',
      stimulationType: _getStimulationType(),
      motorLogic: motorLogic,
      imageUrl: '',
      qrCodeUrl: '',
      supportedFuncs: _getSupportedFuncs(),
      isPrecise: true,
      broadcastPrefix: 'BUTTPLUG',
    );
  }

  String _getStimulationType() {
    final types = <String>[];
    if (hasVibrate) types.add('Vibración');
    if (hasRotate) types.add('Rotación');
    if (hasSuction) types.add('Succión');
    if (hasThrust) types.add('Empuje');
    return types.isEmpty ? 'Desconocido' : types.join(' + ');
  }

  String _getSupportedFuncs() {
    final funcs = <String>[];
    if (hasVibrate) funcs.add('vibrate');
    if (hasRotate) funcs.add('rotate');
    if (hasSuction) funcs.add('suction');
    if (hasThrust) funcs.add('thrust');
    return funcs.join(',');
  }

  @override
  String toString() {
    return 'ButtplugDevice(name: $name, id: $id, index: $deviceIndex)';
  }
}

// ═══════════════════════════════════════════════════════════════
// Buttplug Bridge Service
// ═══════════════════════════════════════════════════════════════

/// Servicio puente para conectar con Intiface Engine vía WebSocket
///
/// Permite controlar 100+ dispositivos soportados por Buttplug:
/// - Lovense (Nora, Max, Lush, etc.)
/// - WeVibe (Pivot, Chorus, etc.)
/// - Kiiroo (Keon, Pearl, etc.)
/// - Satisfyer (Pro 2, Connect, etc.)
/// - Magic Motion, Lelo, etc.
class ButtplugBridgeService extends ChangeNotifier {
  static final ButtplugBridgeService _instance =
      ButtplugBridgeService._internal();
  factory ButtplugBridgeService() => _instance;
  ButtplugBridgeService._internal();

  ButtplugClient? _client;
  ButtplugConnectionState _connectionState = ButtplugConnectionState.disconnected;
  final List<ButtplugDevice> _discoveredDevices = [];
  
  Timer? _reconnectTimer;
  Timer? _scanTimer;
  
  String _serverUrl = 'ws://localhost:12345';
  String _clientName = 'VelvetSync';
  
  bool _isScanning = false;
  int _scanTimeoutSeconds = 10;

  // ═══════════════════════════════════════════════════════════════
  // Getters de Estado
  // ═══════════════════════════════════════════════════════════════

  /// Estado actual de conexión
  ButtplugConnectionState get connectionState => _connectionState;

  /// Lista de dispositivos descubiertos
  List<ButtplugDevice> get discoveredDevices => List.unmodifiable(_discoveredDevices);

  /// Si está conectado al servidor
  bool get isConnected => _connectionState == ButtplugConnectionState.connected;

  /// Si está escaneando
  bool get isScanning => _isScanning;

  /// Si está desconectado
  bool get isDisconnected => _connectionState == ButtplugConnectionState.disconnected;

  /// URL del servidor
  String get serverUrl => _serverUrl;

  /// Número de dispositivos descubiertos
  int get deviceCount => _discoveredDevices.length;

  // ═══════════════════════════════════════════════════════════════
  // Configuración
  // ═══════════════════════════════════════════════════════════════

  /// Configura la URL del servidor Buttplug/Intiface
  ///
  /// [url] - URL WebSocket (ej: 'ws://localhost:12345')
  /// [clientName] - Nombre del cliente (ej: 'VelvetSync')
  void configure({
    String url = 'ws://localhost:12345',
    String clientName = 'VelvetSync',
  }) {
    _serverUrl = url;
    _clientName = clientName;
    lvsLog('Buttplug configurado: $url como $clientName', tag: 'BUTTPLUG');
  }

  /// Configura el timeout de escaneo
  void setScanTimeout(int seconds) {
    _scanTimeoutSeconds = seconds.clamp(5, 60);
    lvsLog('Scan timeout configurado: ${_scanTimeoutSeconds}s', tag: 'BUTTPLUG');
  }

  // ═══════════════════════════════════════════════════════════════
  // Conexión
  // ═══════════════════════════════════════════════════════════════

  /// Conecta al servidor Buttplug/Intiface Engine
  ///
  /// Retorna `true` si la conexión fue exitosa
  Future<bool> connect() async {
    if (_connectionState == ButtplugConnectionState.connecting) {
      lvsLog('Ya hay conexión en progreso', tag: 'BUTTPLUG');
      return false;
    }

    if (_connectionState == ButtplugConnectionState.connected) {
      lvsLog('Ya está conectado', tag: 'BUTTPLUG');
      return true;
    }

    lvsLog('Conectando a $_serverUrl...', tag: 'BUTTPLUG');
    _setState(ButtplugConnectionState.connecting);

    try {
      _client = ButtplugClient(_clientName);
      
      // Escuchar eventos de desconexión
      _client!.onDisconnect.listen((_) {
        lvsLog('Desconectado del servidor Buttplug', tag: 'BUTTPLUG');
        _handleDisconnect();
      });

      // Conectar al servidor
      await _client!.connect(_serverUrl);
      
      lvsLog('✅ Conectado a Buttplug Server', tag: 'BUTTPLUG');
      _setState(ButtplugConnectionState.connected);
      
      return true;
    } catch (e) {
      lvsLog('❌ Error conectando a Buttplug: $e', tag: 'BUTTPLUG');
      _setState(ButtplugConnectionState.error);
      _client = null;
      return false;
    }
  }

  /// Desconecta del servidor
  Future<void> disconnect() async {
    lvsLog('Desconectando de Buttplug...', tag: 'BUTTPLUG');
    
    _stopScan();
    _reconnectTimer?.cancel();
    
    try {
      await _client?.disconnect();
    } catch (e) {
      lvsLog('Error al desconectar: $e', tag: 'BUTTPLUG');
    }
    
    _handleDisconnect();
  }

  /// Maneja la desconexión
  void _handleDisconnect() {
    _client = null;
    _discoveredDevices.clear();
    _setState(ButtplugConnectionState.disconnected);
    notifyListeners();
  }

  /// Intenta reconectar automáticamente
  void setAutoReconnect({bool enabled = true, int intervalSeconds = 30}) {
    _reconnectTimer?.cancel();
    
    if (enabled) {
      _reconnectTimer = Timer.periodic(Duration(seconds: intervalSeconds), (_) async {
        if (_connectionState == ButtplugConnectionState.disconnected ||
            _connectionState == ButtplugConnectionState.error) {
          lvsLog('Intentando reconectar automáticamente...', tag: 'BUTTPLUG');
          await connect();
        }
      });
      lvsLog('Auto-reconexión activada (cada ${intervalSeconds}s)', tag: 'BUTTPLUG');
    }
  }

  // ═══════════════════════════════════════════════════════════════
  // Escaneo de Dispositivos
  // ═══════════════════════════════════════════════════════════════

  /// Inicia escaneo de dispositivos Buttplug
  ///
  /// [timeout] - Tiempo de escaneo en segundos (default: 10)
  Future<void> startScan({int? timeout}) async {
    if (_client == null || !isConnected) {
      lvsLog('No hay conexión para escanear', tag: 'BUTTPLUG');
      return;
    }

    if (_isScanning) {
      lvsLog('Ya hay escaneo en progreso', tag: 'BUTTPLUG');
      return;
    }

    lvsLog('Iniciando escaneo de dispositivos...', tag: 'BUTTPLUG');
    _isScanning = true;
    _setState(ButtplugConnectionState.scanning);
    _discoveredDevices.clear();
    notifyListeners();

    try {
      // Iniciar escaneo
      await _client!.startScanning();
      
      // Escanear por timeout segundos
      await Future.delayed(Duration(seconds: timeout ?? _scanTimeoutSeconds));
      
      // Detener escaneo
      await _client!.stopScanning();
      
      // Obtener dispositivos descubiertos
      await _updateDiscoveredDevices();
      
      _isScanning = false;
      lvsLog('✅ Escaneo completado: ${_discoveredDevices.length} dispositivos', tag: 'BUTTPLUG');
      notifyListeners();
    } catch (e) {
      lvsLog('❌ Error en escaneo: $e', tag: 'BUTTPLUG');
      _isScanning = false;
      _setState(ButtplugConnectionState.error);
      notifyListeners();
    }
  }

  /// Detiene el escaneo actual
  Future<void> stopScan() async {
    if (!_isScanning) return;
    
    try {
      await _client!.stopScanning();
      await _updateDiscoveredDevices();
    } catch (e) {
      lvsLog('Error al detener escaneo: $e', tag: 'BUTTPLUG');
    }
    
    _isScanning = false;
    notifyListeners();
  }

  /// Internamente detiene el escaneo
  void _stopScan() {
    _isScanning = false;
  }

  /// Actualiza la lista de dispositivos descubiertos
  Future<void> _updateDiscoveredDevices() async {
    _discoveredDevices.clear();
    
    for (final device in _client!.devices.values) {
      try {
        final buttplugDevice = ButtplugDevice.fromButtplugDevice(device);
        _discoveredDevices.add(buttplugDevice);
      } catch (e) {
        lvsLog('Error procesando dispositivo ${device.name}: $e', tag: 'BUTTPLUG');
      }
    }
  }

  // ═══════════════════════════════════════════════════════════════
  // Control de Dispositivos
  // ═══════════════════════════════════════════════════════════════

  /// Controla la vibración de un dispositivo
  ///
  /// [deviceIndex] - Índice del dispositivo (0-based)
  /// [intensity] - Intensidad (0.0 - 1.0)
  /// [speed] - Velocidad de oscilación (0.0 - 1.0, opcional)
  Future<void> vibrate({
    required int deviceIndex,
    required double intensity,
    double? speed,
  }) async {
    if (_client == null || !isConnected) {
      lvsLog('No hay conexión para vibrar', tag: 'BUTTPLUG');
      return;
    }

    final device = _getDeviceByIndex(deviceIndex);
    if (device == null) {
      lvsLog('Dispositivo $deviceIndex no encontrado', tag: 'BUTTPLUG');
      return;
    }

    try {
      if (device.hasVibrate) {
        await device.runOutput(
          DeviceOutputCommand(OutputType.VIBRATE, intensity.clamp(0.0, 1.0)),
        );
        lvsLog('Vibración: ${device.name} = ${(intensity * 100).round()}%', tag: 'BUTTPLUG');
      }
    } catch (e) {
      lvsLog('Error vibrando ${device.name}: $e', tag: 'BUTTPLUG');
    }
  }

  /// Controla la rotación de un dispositivo
  ///
  /// [deviceIndex] - Índice del dispositivo
  /// [intensity] - Intensidad (0.0 - 1.0)
  Future<void> rotate({
    required int deviceIndex,
    required double intensity,
  }) async {
    if (_client == null || !isConnected) return;

    final device = _getDeviceByIndex(deviceIndex);
    if (device == null || !device.hasRotate) return;

    try {
      await device.runOutput(
        DeviceOutputCommand(OutputType.ROTATE, intensity.clamp(0.0, 1.0)),
      );
      lvsLog('Rotación: ${device.name} = ${(intensity * 100).round()}%', tag: 'BUTTPLUG');
    } catch (e) {
      lvsLog('Error rotando ${device.name}: $e', tag: 'BUTTPLUG');
    }
  }

  /// Controla la succión de un dispositivo
  ///
  /// [deviceIndex] - Índice del dispositivo
  /// [intensity] - Intensidad (0.0 - 1.0)
  Future<void> suction({
    required int deviceIndex,
    required double intensity,
  }) async {
    if (_client == null || !isConnected) return;

    final device = _getDeviceByIndex(deviceIndex);
    if (device == null || !device.hasSuction) return;

    try {
      await device.runOutput(
        DeviceOutputCommand(OutputType.SUCTION, intensity.clamp(0.0, 1.0)),
      );
      lvsLog('Succión: ${device.name} = ${(intensity * 100).round()}%', tag: 'BUTTPLUG');
    } catch (e) {
      lvsLog('Error succionando ${device.name}: $e', tag: 'BUTTPLUG');
    }
  }

  /// Controla el empuje de un dispositivo
  ///
  /// [deviceIndex] - Índice del dispositivo
  /// [intensity] - Intensidad (0.0 - 1.0)
  Future<void> thrust({
    required int deviceIndex,
    required double intensity,
  }) async {
    if (_client == null || !isConnected) return;

    final device = _getDeviceByIndex(deviceIndex);
    if (device == null || !device.hasThrust) return;

    try {
      await device.runOutput(
        DeviceOutputCommand(OutputType.THRUST, intensity.clamp(0.0, 1.0)),
      );
      lvsLog('Empuje: ${device.name} = ${(intensity * 100).round()}%', tag: 'BUTTPLUG');
    } catch (e) {
      lvsLog('Error empujando ${device.name}: $e', tag: 'BUTTPLUG');
    }
  }

  /// Detiene todos los actuadores de un dispositivo
  ///
  /// [deviceIndex] - Índice del dispositivo
  Future<void> stop({required int deviceIndex}) async {
    if (_client == null || !isConnected) return;

    final device = _getDeviceByIndex(deviceIndex);
    if (device == null) return;

    try {
      await device.stopAll();
      lvsLog('Stop: ${device.name}', tag: 'BUTTPLUG');
    } catch (e) {
      lvsLog('Error deteniendo ${device.name}: $e', tag: 'BUTTPLUG');
    }
  }

  /// Detiene TODOS los dispositivos conectados
  Future<void> stopAll() async {
    if (_client == null || !isConnected) return;

    lvsLog('🛑 STOP ALL - Deteniendo todos los dispositivos', tag: 'BUTTPLUG');
    
    for (final device in _client!.devices.values) {
      try {
        await device.stopAll();
      } catch (e) {
        lvsLog('Error deteniendo ${device.name}: $e', tag: 'BUTTPLUG');
      }
    }
  }

  /// Obtiene dispositivo por índice
  Device? _getDeviceByIndex(int index) {
    try {
      return _client!.devices.values.elementAt(index);
    } catch (e) {
      return null;
    }
  }

  // ═══════════════════════════════════════════════════════════════
  // Información del Dispositivo
  // ═══════════════════════════════════════════════════════════════

  /// Obtiene el nivel de batería de un dispositivo
  ///
  /// [deviceIndex] - Índice del dispositivo
  /// Retorna nivel de batería (0-100) o null si no soporta
  Future<int?> getBatteryLevel(int deviceIndex) async {
    if (_client == null || !isConnected) return null;

    final device = _getDeviceByIndex(deviceIndex);
    if (device == null) return null;

    try {
      return device.battery;
    } catch (e) {
      return null;
    }
  }

  /// Obtiene el RSSI de un dispositivo
  ///
  /// [deviceIndex] - Índice del dispositivo
  /// Retorna RSSI o null si no disponible
  Future<int?> getRssi(int deviceIndex) async {
    if (_client == null || !isConnected) return null;

    final device = _getDeviceByIndex(deviceIndex);
    if (device == null) return null;

    try {
      return device.rssi;
    } catch (e) {
      return null;
    }
  }

  // ═══════════════════════════════════════════════════════════════
  // Métodos Internos
  // ═══════════════════════════════════════════════════════════════

  /// Establece el estado de conexión
  void _setState(ButtplugConnectionState state) {
    _connectionState = state;
    lvsLog('Estado Buttplug: ${state.name}', tag: 'BUTTPLUG');
    notifyListeners();
  }

  // ═══════════════════════════════════════════════════════════════
  // Utilidades de Detección
  // ═══════════════════════════════════════════════════════════════

  /// Verifica si Intiface Engine está instalado y disponible
  ///
  /// Retorna `true` si el comando `intiface_engine` está disponible en PATH
  static Future<bool> isIntifaceEngineInstalled() async {
    try {
      final result = await Process.run(
        Platform.isWindows ? 'where' : 'which',
        ['intiface_engine'],
      );
      return result.exitCode == 0 && result.stdout.toString().isNotEmpty;
    } catch (e) {
      lvsLog('Error verificando Intiface Engine: $e', tag: 'BUTTPLUG');
      return false;
    }
  }

  /// Obtiene instrucciones de instalación según la plataforma
  static String getInstallationInstructions() {
    if (Platform.isWindows) {
      return 'Windows: winget install Intiface.IntifaceEngine';
    } else if (Platform.isMacOS) {
      return 'macOS: brew install intiface-engine';
    } else if (Platform.isLinux) {
      return 'Linux: cargo install intiface_engine';
    }
    return 'Ver: https://github.com/intiface/intiface-engine';
  }

  /// Verifica si el puerto WebSocket está accesible
  ///
  /// [host] - Host del servidor (default: localhost)
  /// [port] - Puerto WebSocket (default: 12345)
  static Future<bool> isWebSocketPortAccessible({
    String host = 'localhost',
    int port = 12345,
  }) async {
    try {
      final socket = await Socket.connect(host, port, timeout: const Duration(seconds: 2));
      await socket.close();
      return true;
    } catch (e) {
      return false;
    }
  }

  // ═══════════════════════════════════════════════════════════════
  // Cleanup
  // ═══════════════════════════════════════════════════════════════

  @override
  void dispose() {
    lvsLog('Cerrando Buttplug Bridge...', tag: 'BUTTPLUG');
    _reconnectTimer?.cancel();
    _scanTimer?.cancel();
    disconnect();
    super.dispose();
  }
}

// ═══════════════════════════════════════════════════════════════
// Extensiones de Utilidad
// ═══════════════════════════════════════════════════════════════

/// Extensión para controlar dispositivos fácilmente
extension ButtplugDeviceControl on ButtplugBridgeService {
  /// Controla vibración en todos los dispositivos
  Future<void> vibrateAll(double intensity) async {
    final count = discoveredDevices.length;
    for (int i = 0; i < count; i++) {
      await vibrate(deviceIndex: i, intensity: intensity);
    }
  }

  /// Detiene todos los dispositivos (alias)
  Future<void> emergencyStop() async => stopAll();
}
