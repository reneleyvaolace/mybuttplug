// ═══════════════════════════════════════════════════════════════
// Velvet Sync Platform · lib/core/protocols/lvs_protocol.dart
// Protocolo para dispositivos Love Spouse (wbMSE/8154)
// ═══════════════════════════════════════════════════════════════

import 'dart:typed_data';
import '../types/command_types.dart';
import '../types/device_types.dart';
import '../types/result_types.dart';
import 'protocol_base.dart';

/// Protocolo para dispositivos Love Spouse (wbMSE/8154)
/// 
/// Implementa el protocolo propietario de los dispositivos LVS:
/// - Company ID: 0xFFF0
/// - Service UUID: 0000fff0-0000-1000-8000-00805f9b34fb
/// - Advertising: Peripheral Mode (Manufacturer Data)
/// - Prefijo: wbMSE (77 62 4D 53 45)
/// 
/// Modos de paquete:
/// - Modo 11B: [PREFIX 8B] + [CMD 3B]
/// - Modo 18B: [FF FF 00] + [PREFIX 8B] + [CMD 3B] + [03 03 8F AE]
class LvsProtocol extends ProtocolBase {
  @override
  String get name => 'LVS';
  
  @override
  String get description => 'Protocolo para dispositivos Love Spouse (wbMSE/8154)';
  
  @override
  String get version => '1.0.0';
  
  @override
  List<ConnectionType> get supportedTransports => [ConnectionType.ble];
  
  @override
  List<DeviceFeature> get supportedFeatures => [
    DeviceFeature.vibrate,
    DeviceFeature.oscillate,
  ];
  
  @override
  ControlPrecision get precision => ControlPrecision.precise;
  
  /// Modo de paquete actual
  PacketMode packetMode = PacketMode.b11;
  
  /// Prefijo del protocolo (8 bytes)
  static const List<int> prefix = [
    0x6D, 0xB6, 0x43, 0xCE, 0x97, 0xFE, 0x42, 0x7C
  ];
  
  /// Header para modo 18B
  static const List<int> header18B = [0xFF, 0xFF, 0x00];
  
  /// Appendix para modo 18B
  static const List<int> appendix18B = [0x03, 0x03, 0x8F, 0xAE];
  
  /// Company ID
  static const int companyId = 0xFFF0;
  
  /// Service UUID
  static const String serviceUuid = '0000fff0-0000-1000-8000-00805f9b34fb';
  
  // ═══════════════════════════════════════════════════════════
  // COMANDOS BÁSICOS
  // ═══════════════════════════════════════════════════════════
  
  /// Comandos de velocidad (Classic)
  static const List<int> cmdStop = [0xE5, 0x15, 0x7D];
  static const List<int> cmdLow = [0xE4, 0x9C, 0x6C];
  static const List<int> cmdMed = [0xE7, 0x07, 0x5E];
  static const List<int> cmdHigh = [0xE6, 0x8E, 0x4F];
  
  /// Canal 1
  static const List<int> ch1Stop = [0xD5, 0x96, 0x4C];
  static const List<int> ch1Low = [0xD4, 0x1F, 0x5D];
  static const List<int> ch1Med = [0xD7, 0x84, 0x6F];
  static const List<int> ch1High = [0xD6, 0x0D, 0x7E];
  
  /// Canal 2
  static const List<int> ch2Stop = [0xE5, 0x15, 0x7D];
  static const List<int> ch2Low = [0xE4, 0x9C, 0x6C];
  static const List<int> ch2Med = [0xE7, 0x07, 0x5E];
  static const List<int> ch2High = [0xE6, 0x8E, 0x4F];
  
  /// Patrones rítmicos
  static const List<int> pat1 = [0xE1, 0x31, 0x3B];
  static const List<int> pat2 = [0xE0, 0xB8, 0x2A];
  static const List<int> pat3 = [0xE3, 0x23, 0x18];
  static const List<int> pat4 = [0xE2, 0xAA, 0x09];
  static const List<int> pat5 = [0xED, 0x5D, 0xF1];
  static const List<int> pat6 = [0xEC, 0xD4, 0xE0];
  
  // ═══════════════════════════════════════════════════════════
  // TRADUCCIÓN DE COMANDOS
  // ═══════════════════════════════════════════════════════════
  
  @override
  Result<SpecificCommand, ProtocolError> translate(GenericCommand command) {
    try {
      List<int> cmdBytes;
      
      switch (command.type) {
        case CommandType.vibrate:
          cmdBytes = _translateVibrate(command.intensity, command.channel);
          break;
          
        case CommandType.stop:
          cmdBytes = _translateStop(command.channel);
          break;
          
        case CommandType.pattern:
          final patternId = command.parameters?['patternId'] as String?;
          if (patternId == null) {
            return Failure(ProtocolError.invalidPacketFormat);
          }
          cmdBytes = _translatePattern(patternId);
          break;
          
        case CommandType.custom:
          // Comando personalizado (bytes directos)
          final bytes = command.parameters?['bytes'] as List<int>?;
          if (bytes == null) {
            return Failure(ProtocolError.invalidPacketFormat);
          }
          cmdBytes = bytes;
          break;
          
        default:
          return Failure(ProtocolError.unrecognizedCommand);
      }
      
      // Construir paquete completo
      final packet = _buildPacket(cmdBytes);
      
      return Success(SpecificCommand.bytes(
        protocolName: name,
        bytes: packet,
        parameters: {
          'mode': packetMode.name,
          'channel': command.channel.name,
        },
      ));
      
    } catch (e) {
      return Failure(ProtocolError.invalidPacketFormat);
    }
  }
  
  /// Traducir comando de vibración
  List<int> _translateVibrate(double intensity, DeviceChannel channel) {
    // Convertir intensidad 0.0-1.0 a 0-255
    final intensityByte = (intensity * 255).clamp(0, 255).toInt();
    
    switch (channel) {
      case DeviceChannel.channel1:
        // Canal 1: Prefijo 0xD
        return [0xD6, 0x0D, intensityByte];
        
      case DeviceChannel.channel2:
        // Canal 2: Prefijo 0xE (o 0xA según modelo)
        return [0xE6, 0x8E, intensityByte];
        
      case DeviceChannel.both:
        // Dual motor sincronizado: Prefijo 0xF6
        return [0xF6, intensityByte, intensityByte];
        
      case DeviceChannel.single:
      default:
        // Canal único: Prefijo 0xE
        return [0xE6, 0x8E, intensityByte];
    }
  }
  
  /// Traducir comando de parada
  List<int> _translateStop(DeviceChannel channel) {
    switch (channel) {
      case DeviceChannel.channel1:
        return ch1Stop;
        
      case DeviceChannel.channel2:
        return ch2Stop;
        
      case DeviceChannel.both:
      case DeviceChannel.single:
      default:
        return cmdStop;
    }
  }
  
  /// Traducir comando de patrón
  List<int> _translatePattern(String patternId) {
    // Mapear patternId a comando
    switch (patternId.toLowerCase()) {
      case 'pat1':
      case 'pattern1':
        return pat1;
      case 'pat2':
      case 'pattern2':
        return pat2;
      case 'pat3':
      case 'pattern3':
        return pat3;
      case 'pat4':
      case 'pattern4':
        return pat4;
      case 'pat5':
      case 'pattern5':
        return pat5;
      case 'pat6':
      case 'pattern6':
        return pat6;
        
      case 'ch1_low':
        return ch1Low;
      case 'ch1_med':
        return ch1Med;
      case 'ch1_high':
        return ch1High;
        
      case 'ch2_low':
        return ch2Low;
      case 'ch2_med':
        return ch2Med;
      case 'ch2_high':
        return ch2High;
        
      default:
        // Patrón desconocido, usar stop
        return cmdStop;
    }
  }
  
  @override
  SpecificCommand translateVibrate(double intensity, {DeviceChannel channel = DeviceChannel.single}) {
    final cmdBytes = _translateVibrate(intensity, channel);
    final packet = _buildPacket(cmdBytes);
    
    return SpecificCommand.bytes(
      protocolName: name,
      bytes: packet,
      parameters: {'intensity': intensity, 'channel': channel.name},
    );
  }
  
  @override
  SpecificCommand translateRotate(double intensity) {
    // LVS no soporta rotación directamente, usar vibración
    return translateVibrate(intensity);
  }
  
  @override
  SpecificCommand translateStop({DeviceChannel channel = DeviceChannel.single}) {
    final cmdBytes = _translateStop(channel);
    final packet = _buildPacket(cmdBytes);
    
    return SpecificCommand.bytes(
      protocolName: name,
      bytes: packet,
      parameters: {'channel': channel.name},
    );
  }
  
  @override
  SpecificCommand translatePattern(String patternId) {
    final cmdBytes = _translatePattern(patternId);
    final packet = _buildPacket(cmdBytes);
    
    return SpecificCommand.bytes(
      protocolName: name,
      bytes: packet,
      parameters: {'patternId': patternId},
    );
  }
  
  // ═══════════════════════════════════════════════════════════
  // CONSTRUCCIÓN DE PAQUETES
  // ═══════════════════════════════════════════════════════════
  
  /// Construir paquete completo según el modo
  List<int> _buildPacket(List<int> cmdBytes) {
    if (packetMode == PacketMode.b11) {
      // Modo 11B: [PREFIX 8B] + [CMD 3B]
      return [...prefix, ...cmdBytes];
    } else {
      // Modo 18B: [FF FF 00] + [PREFIX 8B] + [CMD 3B] + [03 03 8F AE]
      return [...header18B, ...prefix, ...cmdBytes, ...appendix18B];
    }
  }
  
  /// Construir paquete de debug
  List<int> buildDebugPacket(int b0, int b1, int b2) {
    return _buildPacket([b0, b1, b2]);
  }
  
  /// Convertir bytes a hex string
  static String bytesToHex(List<int> bytes) {
    return bytes.map((b) => b.toRadixString(16).padLeft(2, '0').toUpperCase()).join(' ');
  }
  
  // ═══════════════════════════════════════════════════════════
  // ENVÍO DE COMANDOS
  // ═══════════════════════════════════════════════════════════
  
  @override
  Future<Result<void, DeviceError>> send(SpecificCommand command) async {
    // El envío real lo maneja el BLE Service
    // Este método es un placeholder que debe ser sobrescrito
    return Success(null);
  }
  
  // ═══════════════════════════════════════════════════════════
  // CONFIGURACIÓN
  // ═══════════════════════════════════════════════════════════
  
  @override
  Future<void> configure(Map<String, dynamic> config) async {
    if (config.containsKey('packetMode')) {
      final mode = config['packetMode'] as String;
      packetMode = mode == 'b18' ? PacketMode.b18 : PacketMode.b11;
    }
  }
  
  @override
  Map<String, dynamic> getConfiguration() {
    return {
      'packetMode': packetMode.name,
      'companyId': companyId,
      'serviceUuid': serviceUuid,
    };
  }
  
  // ═══════════════════════════════════════════════════════════
  // CLEANUP
  // ═══════════════════════════════════════════════════════════
  
  @override
  void dispose() {
    // No hay recursos que limpiar
  }
}

/// Modo de paquete
enum PacketMode {
  /// Paquete de 11 bytes
  b11,
  
  /// Paquete de 18 bytes
  b18,
}

/// Extensión para utilidades LVS
extension LvsProtocolUtils on LvsProtocol {
  /// Crear comando de intensidad proporcional (0-100)
  List<int> proportional(int intensityLevel) {
    final intensityByte = intensityLevel.clamp(0, 100);
    return [0xE6, 0x8E, intensityByte];
  }
  
  /// Crear comando para canal 1 proporcional
  List<int> proportionalChannel1(int intensityLevel) {
    final intensityByte = intensityLevel.clamp(0, 100);
    return [0xD6, 0x0D, intensityByte];
  }
  
  /// Crear comando para canal 2 proporcional
  List<int> proportionalChannel2(int intensityLevel) {
    final intensityByte = intensityLevel.clamp(0, 100);
    return [0xE6, 0x8E, intensityByte];
  }
  
  /// Crear comando dual motor sincronizado
  List<int> dualMotor(int m1, int m2) {
    return [0xF6, m1.clamp(0, 255), m2.clamp(0, 255)];
  }
  
  /// Obtener comando por nivel de velocidad
  List<int> commandForSpeed(String level) {
    switch (level.toLowerCase()) {
      case 'stop':
        return cmdStop;
      case 'low':
        return cmdLow;
      case 'medium':
        return cmdMed;
      case 'high':
        return cmdHigh;
      default:
        return cmdStop;
    }
  }
}
