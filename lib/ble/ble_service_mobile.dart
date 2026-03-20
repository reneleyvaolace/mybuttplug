// ═══════════════════════════════════════════════════════════════
// Velvet Sync · lib/ble/ble_service_mobile.dart
// Servicio BLE para Mobile (Android/iOS)
// 
// Usa flutter_blue_plus para comunicación BLE nativa.
// Solo disponible en Android e iOS.
// ═══════════════════════════════════════════════════════════════

import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import '../utils/logger.dart';

// Re-export del servicio BLE original para mobile
export 'ble_service.dart';

/// Servicio BLE específico para mobile (Android/iOS)
class BleServiceMobile {
  static final BleServiceMobile _instance = BleServiceMobile._internal();
  factory BleServiceMobile() => _instance;
  BleServiceMobile._internal();

  BluetoothAdapterState _adapterState = BluetoothAdapterState.unknown;
  bool _isScanning = false;
  
  /// Estado del adaptador Bluetooth
  BluetoothAdapterState get adapterState => _adapterState;
  
  /// ¿Bluetooth está encendido?
  bool get isBluetoothOn => _adapterState == BluetoothAdapterState.on;
  
  /// ¿Está escaneando?
  bool get isScanning => _isScanning;

  /// Verifica si el BLE está disponible en esta plataforma
  static bool get isSupported => !kIsWeb && (Platform.isAndroid || Platform.isIOS);

  /// Inicializa el servicio BLE
  Future<void> initialize() async {
    if (!isSupported) {
      lvsLog('BLE no soportado en esta plataforma', tag: 'BLE_MOBILE');
      throw UnsupportedError('BLE solo está disponible en Android/iOS');
    }

    // Escuchar cambios de estado del adaptador
    FlutterBluePlus.adapterState.listen((state) {
      _adapterState = state;
      lvsLog('Estado Bluetooth: ${state.name}', tag: 'BLE_MOBILE');
    });

    // Verificar estado inicial
    _adapterState = await FlutterBluePlus.adapterState.first;
    
    // Encender Bluetooth si está apagado (Android)
    if (_adapterState != BluetoothAdapterState.on && Platform.isAndroid) {
      lvsLog('Encendiendo Bluetooth...', tag: 'BLE_MOBILE');
      await FlutterBluePlus.turnOn();
    }

    lvsLog('BLE Mobile inicializado', tag: 'BLE_MOBILE');
  }

  /// Escanea dispositivos LVS
  Future<List<BluetoothDevice>> scan({
    Duration timeout = const Duration(seconds: 10),
    List<String> deviceIds = const ['8154', '7043', 'LVS'],
  }) async {
    if (!isSupported) {
      throw UnsupportedError('BLE scan solo disponible en Android/iOS');
    }

    if (_isScanning) {
      lvsLog('Ya hay escaneo en progreso', tag: 'BLE_MOBILE');
      return [];
    }

    lvsLog('Iniciando escaneo BLE...', tag: 'BLE_MOBILE');
    _isScanning = true;

    try {
      await FlutterBluePlus.startScan(
        timeout: timeout,
        androidScanMode: AndroidScanMode.lowLatency,
        removeIfGone: const Duration(seconds: 5),
      );

      final devices = <BluetoothDevice>[];
      
      await FlutterBluePlus.onScanResults.listen((results) {
        for (final result in results) {
          final name = result.advertisementData.advName;
          final platformName = result.device.platformName;
          final displayName = name.isEmpty ? platformName : name;

          // Filtrar dispositivos LVS
          if (deviceIds.any((id) => displayName.contains(id)) ||
              displayName.startsWith('wbMSE')) {
            if (!devices.any((d) => d.remoteId == result.device.remoteId)) {
              devices.add(result.device);
              lvsLog('Dispositivo encontrado: $displayName', tag: 'BLE_MOBILE');
            }
          }
        }
      }).asFuture();

      await FlutterBluePlus.stopScan();
      _isScanning = false;
      
      lvsLog('Escaneo completado: ${devices.length} dispositivos', tag: 'BLE_MOBILE');
      return devices;
    } catch (e) {
      lvsLog('Error en escaneo BLE: $e', tag: 'BLE_MOBILE');
      _isScanning = false;
      return [];
    }
  }

  /// Conecta a un dispositivo
  Future<void> connect(BluetoothDevice device) async {
    if (!isSupported) {
      throw UnsupportedError('BLE connect solo disponible en Android/iOS');
    }

    lvsLog('Conectando a ${device.platformName}...', tag: 'BLE_MOBILE');
    await device.connect();
    lvsLog('✅ Conectado', tag: 'BLE_MOBILE');
  }

  /// Desconecta de un dispositivo
  Future<void> disconnect(BluetoothDevice device) async {
    if (!isSupported) {
      throw UnsupportedError('BLE disconnect solo disponible en Android/iOS');
    }

    lvsLog('Desconectando...', tag: 'BLE_MOBILE');
    await device.disconnect();
    lvsLog('Desconectado', tag: 'BLE_MOBILE');
  }

  /// Envía comando BLE
  Future<void> writeCommand(
    BluetoothDevice device,
    List<int> bytes, {
    String? serviceUuid,
    String? characteristicUuid,
  }) async {
    if (!isSupported) {
      throw UnsupportedError('BLE write solo disponible en Android/iOS');
    }

    try {
      final services = await device.discoverServices();
      
      for (final service in services) {
        if (serviceUuid == null || service.uuid.toString().contains(serviceUuid)) {
          for (final characteristic in service.characteristics) {
            if (characteristicUuid == null || 
                characteristic.uuid.toString().contains(characteristicUuid)) {
              if (characteristic.properties.write ||
                  characteristic.properties.writeWithoutResponse) {
                await characteristic.write(bytes, withoutResponse: true);
                lvsLog('→ Comando enviado: ${bytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join(' ')}', tag: 'BLE_MOBILE');
                return;
              }
            }
          }
        }
      }
      
      lvsLog('❌ No se encontró característica para escribir', tag: 'BLE_MOBILE');
    } catch (e) {
      lvsLog('Error escribiendo comando: $e', tag: 'BLE_MOBILE');
      rethrow;
    }
  }

  /// Limpia recursos
  Future<void> dispose() async {
    lvsLog('Limpiando BLE Mobile...', tag: 'BLE_MOBILE');
    await FlutterBluePlus.stopScan();
    // No cerrar FlutterBluePlus - es singleton global
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
  
  if (Platform.isAndroid || Platform.isIOS) {
    return BleServiceMobile();
  }
  
  throw UnsupportedError('Plataforma no soportada para BLE nativo');
}
