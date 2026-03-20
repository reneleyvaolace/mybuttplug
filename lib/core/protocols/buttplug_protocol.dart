// ═══════════════════════════════════════════════════════════════
// Velvet Sync Platform · lib/core/protocols/buttplug_protocol.dart
// Protocolo Buttplug v4 para soporte universal de dispositivos
// ═══════════════════════════════════════════════════════════════

import '../types/command_types.dart';
import '../types/device_types.dart';
import '../types/result_types.dart';
import 'protocol_base.dart';

/// Protocolo Buttplug v4
/// 
/// Implementa el protocolo estándar de la industria para control
/// de dispositivos íntimos. Soporta 100+ dispositivos de múltiples
/// fabricantes.
/// 
/// Características:
/// - Protocolo estandarizado v4
/// - Soporte para 100+ dispositivos
/// - Comunicación vía WebSocket
/// - Auto-descubrimiento de dispositivos
/// - Configuración vía JSON
class ButtplugProtocol extends ProtocolBase {
  @override
  String get name => 'Buttplug';
  
  @override
  String get description => 'Protocolo estándar Buttplug v4 para soporte universal';
  
  @override
  String get version => '4.0.0';
  
  @override
  List<ConnectionType> get supportedTransports => [
    ConnectionType.ble,
    ConnectionType.usb,
    ConnectionType.serial,
    ConnectionType.wifi,
  ];
  
  @override
  List<DeviceFeature> get supportedFeatures => [
    DeviceFeature.vibrate,
    DeviceFeature.rotate,
    DeviceFeature.oscillate,
    DeviceFeature.thrust,
    DeviceFeature.suction,
    DeviceFeature.ems,
    DeviceFeature.battery,
  ];
  
  @override
  ControlPrecision get precision => ControlPrecision.proportional;
  
  /// URL del servidor Buttplug (Intiface Engine)
  String serverUrl = 'ws://localhost:12345';
  
  /// Nombre de la aplicación cliente
  String clientName = 'VelvetSync';
  
  /// Si está conectado al servidor
  bool _isConnected = false;
  
  /// Dispositivos descubiertos
  final Map<String, ButtplugDevice> _devices = {};
  
  /// Callback cuando se agrega un dispositivo
  void Function(ButtplugDevice)? onDeviceAdded;
  
  /// Callback cuando se remueve un dispositivo
  void Function(ButtplugDevice)? onDeviceRemoved;
  
  // ═══════════════════════════════════════════════════════════
  // TRADUCCIÓN DE COMANDOS
  // ═══════════════════════════════════════════════════════════
  
  @override
  Result<SpecificCommand, ProtocolError> translate(GenericCommand command) {
    try {
      Map<String, dynamic> cmdData;
      
      switch (command.type) {
        case CommandType.vibrate:
          cmdData = {
            'type': 'VibrateCmd',
            'speed': command.intensity,
            'index': _getVibrateIndex(command.channel),
          };
          break;
          
        case CommandType.rotate:
          cmdData = {
            'type': 'RotateCmd',
            'speed': command.intensity,
          };
          break;
          
        case CommandType.oscillate:
          cmdData = {
            'type': 'OscillateCmd',
            'speed': command.intensity,
          };
          break;
          
        case CommandType.stop:
          cmdData = {
            'type': 'StopDeviceCmd',
          };
          break;
          
        case CommandType.readBattery:
          cmdData = {
            'type': 'BatteryLevelCmd',
          };
          break;
          
        case CommandType.readRssi:
          cmdData = {
            'type': 'RSSILevelCmd',
          };
          break;
          
        default:
          return Failure(ProtocolError.unrecognizedCommand);
      }
      
      // Agregar metadata
      cmdData['deviceId'] = command.deviceId;
      cmdData['commandId'] = command.commandId;
      
      return Success(SpecificCommand(
        protocolName: name,
        parameters: cmdData,
        metadata: {
          'channel': command.channel.name,
          'duration': command.durationMs,
        },
      ));
      
    } catch (e) {
      return Failure(ProtocolError.invalidPacketFormat);
    }
  }
  
  /// Obtener índice de vibrador según canal
  int _getVibrateIndex(DeviceChannel channel) {
    switch (channel) {
      case DeviceChannel.channel1:
        return 0;
      case DeviceChannel.channel2:
        return 1;
      default:
        return 0;
    }
  }
  
  @override
  SpecificCommand translateVibrate(double intensity, {DeviceChannel channel = DeviceChannel.single}) {
    final cmd = GenericCommand.vibrate(
      deviceId: 'unknown',
      intensity: intensity,
      channel: channel,
    );
    return translate(cmd).getOrElse(() => throw StateError('Failed to translate'));
  }
  
  @override
  SpecificCommand translateRotate(double intensity) {
    final cmd = GenericCommand.rotate(
      deviceId: 'unknown',
      intensity: intensity,
    );
    return translate(cmd).getOrElse(() => throw StateError('Failed to translate'));
  }
  
  @override
  SpecificCommand translateStop({DeviceChannel channel = DeviceChannel.single}) {
    final cmd = GenericCommand.stop(
      deviceId: 'unknown',
      channel: channel,
    );
    return translate(cmd).getOrElse(() => throw StateError('Failed to translate'));
  }
  
  @override
  SpecificCommand translatePattern(String patternId) {
    // Buttplug no soporta patrones nativamente, se implementan como secuencias
    return SpecificCommand(
      protocolName: name,
      parameters: {
        'type': 'PatternCmd',
        'patternId': patternId,
      },
    );
  }
  
  // ═══════════════════════════════════════════════════════════
  // ENVÍO DE COMANDOS
  // ═══════════════════════════════════════════════════════════
  
  @override
  Future<Result<void, DeviceError>> send(SpecificCommand command) async {
    if (!_isConnected) {
      return Failure(DeviceError.notConnected);
    }
    
    try {
      // El envío real se hace vía WebSocket al servidor Buttplug
      // Esta es una implementación simplificada
      final params = command.parameters;
      
      if (params == null) {
        return Failure(DeviceError.invalidCommand);
      }
      
      // Construir mensaje Buttplug
      final message = {
        'type': params['type'],
        'timestamp': DateTime.now().millisecondsSinceEpoch,
        ...params,
      };
      
      // Enviar vía WebSocket (implementación real requerida)
      await _sendMessage(message);
      
      return Success(null);
    } catch (e) {
      return Failure(DeviceError.connectionError);
    }
  }
  
  /// Enviar mensaje al servidor Buttplug
  Future<void> _sendMessage(Map<String, dynamic> message) async {
    // Implementación real requiere WebSocket
    // Esto es un placeholder
    await Future.delayed(Duration.zero);
  }
  
  // ═══════════════════════════════════════════════════════════
  // GESTIÓN DE DISPOSITIVOS
  // ═══════════════════════════════════════════════════════════
  
  /// Conectar al servidor Buttplug
  Future<Result<void, DeviceError>> connect() async {
    try {
      // Conexión WebSocket al servidor
      await _connectToServer();
      _isConnected = true;
      return Success(null);
    } catch (e) {
      return Failure(DeviceError.connectionError);
    }
  }
  
  /// Desconectar del servidor Buttplug
  Future<Result<void, DeviceError>> disconnect() async {
    try {
      await _disconnectFromServer();
      _isConnected = false;
      _devices.clear();
      return Success(null);
    } catch (e) {
      return Failure(DeviceError.connectionError);
    }
  }
  
  /// Escanear dispositivos
  Future<Result<List<ButtplugDevice>, DeviceError>> scan({
    Duration timeout = const Duration(seconds: 10),
  }) async {
    if (!_isConnected) {
      return Failure(DeviceError.notConnected);
    }
    
    try {
      // Iniciar escaneo
      await _startScanning();
      
      // Esperar timeout
      await Future.delayed(timeout);
      
      // Detener escaneo
      await _stopScanning();
      
      return Success(_devices.values.toList());
    } catch (e) {
      return Failure(DeviceError.bluetoothUnavailable);
    }
  }
  
  /// Agregar dispositivo descubierto
  void _addDevice(ButtplugDevice device) {
    _devices[device.id] = device;
    onDeviceAdded?.call(device);
  }
  
  /// Remover dispositivo
  void _removeDevice(String deviceId) {
    final device = _devices.remove(deviceId);
    if (device != null) {
      onDeviceRemoved?.call(device);
    }
  }
  
  /// Métodos placeholder para implementación real
  Future<void> _connectToServer() async => await Future.delayed(Duration.zero);
  Future<void> _disconnectFromServer() async => await Future.delayed(Duration.zero);
  Future<void> _startScanning() async => await Future.delayed(Duration.zero);
  Future<void> _stopScanning() async => await Future.delayed(Duration.zero);
  
  // ═══════════════════════════════════════════════════════════
  // CONFIGURACIÓN
  // ═══════════════════════════════════════════════════════════
  
  @override
  Future<void> configure(Map<String, dynamic> config) async {
    if (config.containsKey('serverUrl')) {
      serverUrl = config['serverUrl'] as String;
    }
    if (config.containsKey('clientName')) {
      clientName = config['clientName'] as String;
    }
  }
  
  @override
  Map<String, dynamic> getConfiguration() {
    return {
      'serverUrl': serverUrl,
      'clientName': clientName,
      'isConnected': _isConnected,
      'deviceCount': _devices.length,
    };
  }
  
  // ═══════════════════════════════════════════════════════════
  // CLEANUP
  // ═══════════════════════════════════════════════════════════
  
  @override
  void dispose() {
    _devices.clear();
    _isConnected = false;
  }
}

/// Dispositivo Buttplug
class ButtplugDevice {
  /// ID único del dispositivo
  final String id;
  
  /// Nombre del dispositivo
  final String name;
  
  /// Tipo de dispositivo
  final DeviceType deviceType;
  
  /// Features soportadas
  final List<DeviceFeature> features;
  
  /// Si tiene batería
  final bool hasBattery;
  
  /// Si tiene RSSI
  final bool hasRssi;
  
  /// Número de vibradores
  final int vibratorCount;
  
  /// Número de motores de rotación
  final int rotateCount;
  
  ButtplugDevice({
    required this.id,
    required this.name,
    required this.deviceType,
    required this.features,
    this.hasBattery = false,
    this.hasRssi = false,
    this.vibratorCount = 0,
    this.rotateCount = 0,
  });
  
  /// Verificar si soporta vibración
  bool get hasVibrate => features.contains(DeviceFeature.vibrate);
  
  /// Verificar si soporta rotación
  bool get hasRotate => features.contains(DeviceFeature.rotate);
  
  /// Crear desde mensaje del servidor
  factory ButtplugDevice.fromJson(Map<String, dynamic> json) {
    final features = <DeviceFeature>[];
    
    // Parsear features
    final deviceFeatures = json['features'] as List? ?? [];
    for (final feature in deviceFeatures) {
      final featureName = feature['name'] as String?;
      if (featureName != null) {
        features.add(_parseFeature(featureName));
      }
    }
    
    return ButtplugDevice(
      id: json['id'] as String,
      name: json['name'] as String,
      deviceType: _parseDeviceType(json['name'] as String),
      features: features,
      hasBattery: json['has_battery'] as bool? ?? false,
      hasRssi: json['has_rssi'] as bool? ?? false,
      vibratorCount: json['vibrator_count'] as int? ?? 0,
      rotateCount: json['rotate_count'] as int? ?? 0,
    );
  }
  
  static DeviceFeature _parseFeature(String name) {
    switch (name.toLowerCase()) {
      case 'vibrate':
        return DeviceFeature.vibrate;
      case 'rotate':
        return DeviceFeature.rotate;
      case 'oscillate':
        return DeviceFeature.oscillate;
      case 'thrust':
        return DeviceFeature.thrust;
      case 'suction':
        return DeviceFeature.suction;
      case 'ems':
        return DeviceFeature.ems;
      case 'battery':
        return DeviceFeature.battery;
      default:
        return DeviceFeature.vibrate;
    }
  }
  
  static DeviceType _parseDeviceType(String name) {
    final nameLower = name.toLowerCase();
    
    if (nameLower.contains('vibrat')) return DeviceType.vibrator;
    if (nameLower.contains('egg')) return DeviceType.egg;
    if (nameLower.contains('bullet')) return DeviceType.bullet;
    if (nameLower.contains('ring')) return DeviceType.ring;
    if (nameLower.contains('clitor')) return DeviceType.clitoral;
    if (nameLower.contains('prostat')) return DeviceType.prostate;
    if (nameLower.contains('anal')) return DeviceType.anal;
    if (nameLower.contains('penis')) return DeviceType.penis;
    if (nameLower.contains('suction')) return DeviceType.suction;
    
    return DeviceType.unknown;
  }
}
