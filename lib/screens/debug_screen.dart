// ═══════════════════════════════════════════════════════════════
// Velvet Sync · lib/screens/debug_screen.dart
// Pantalla de Debug para testing BLE y Buttplug
// 
// 📖 RECURSOS:
// - Buttplug Playground (referencia): https://github.com/intiface/buttplug-playground
// - Buttplug-dart: https://pub.dev/packages/buttplug
// ═══════════════════════════════════════════════════════════════

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../ble/ble_service.dart';
import '../ble/lvs_commands.dart';
import '../services/buttplug_bridge_service.dart';
import '../theme.dart';

// ═══════════════════════════════════════════════════════════════
// Providers
// ═══════════════════════════════════════════════════════════════

final debugIntensityProvider = StateProvider<double>((ref) => 0.5);
final debugSelectedDeviceProvider = StateProvider<int>((ref) => 0);
final debugLogProvider = StateProvider<List<String>>((ref) => []);

// ═══════════════════════════════════════════════════════════════
// Debug Screen
// ═══════════════════════════════════════════════════════════════

class DebugScreen extends ConsumerStatefulWidget {
  const DebugScreen({super.key});

  @override
  ConsumerState<DebugScreen> createState() => _DebugScreenState();
}

class _DebugScreenState extends ConsumerState<DebugScreen> {
  final TextEditingController _intensityCtrl = TextEditingController(text: '50');
  final TextEditingController _patternCtrl = TextEditingController();
  bool _showButtplugSection = false;
  bool _showAdvancedControls = false;

  @override
  void dispose() {
    _intensityCtrl.dispose();
    _patternCtrl.dispose();
    super.dispose();
  }

  void _addLog(String message) {
    final logList = ref.read(debugLogProvider.notifier);
    final timestamp = DateTime.now().toString().substring(11, 19);
    logList.state = ['[$timestamp] $message', ...logList.state].take(100).toList();
  }

  @override
  Widget build(BuildContext context) {
    final ble = ref.watch(bleProvider);
    final buttplugBridge = ref.watch(buttplugBridgeProvider);
    final buttplugDevices = ref.watch(buttplugDevicesProvider);
    final intensity = ref.watch(debugIntensityProvider);
    final selectedDevice = ref.watch(debugSelectedDeviceProvider);
    final logs = ref.watch(debugLogProvider);

    return Scaffold(
      backgroundColor: LvsColors.bg,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text('🔧 DEBUG / TESTING', style: TextStyle(letterSpacing: 2, fontSize: 14)),
        actions: [
          IconButton(
            icon: const Icon(Icons.bug_report, size: 20),
            onPressed: () => _showOptionsDialog(context),
            tooltip: 'Opciones',
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline, size: 20),
            onPressed: () => ref.read(debugLogProvider.notifier).state = [],
            tooltip: 'Limpiar logs',
          ),
        ],
      ),
      body: Column(
        children: [
          // Connection Status Cards
          _buildConnectionStatusCards(ble, buttplugBridge),

          // Main Content
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // LVS BLE Section
                  _buildLvsSection(ble, intensity),

                  const SizedBox(height: 24),

                  // Buttplug Section (optional)
                  if (_showButtplugSection)
                    _buildButtplugSection(buttplugBridge, buttplugDevices, selectedDevice),

                  const SizedBox(height: 24),

                  // Advanced Testing Controls
                  if (_showAdvancedControls)
                    _buildAdvancedTestingControls(ble),

                  const SizedBox(height: 24),

                  // Log Console
                  _buildLogConsole(logs),
                ],
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        mini: true,
        backgroundColor: _showAdvancedControls ? LvsColors.teal : LvsColors.text3,
        child: const Icon(Icons.tune, size: 20),
        onPressed: () => setState(() => _showAdvancedControls = !_showAdvancedControls),
        tooltip: 'Controles Avanzados',
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════
  // Connection Status Cards
  // ═══════════════════════════════════════════════════════════════

  Widget _buildConnectionStatusCards(BleService ble, ButtplugBridgeService buttplugBridge) {
    return Container(
      padding: const EdgeInsets.all(16),
      color: LvsColors.bgCard,
      child: Row(
        children: [
          // LVS Status
          Expanded(
            child: _buildStatusCard(
              title: 'LVS BLE',
              connected: ble.isConnected,
              scanning: ble.isScanning,
              deviceName: ble.connectedDeviceName.isNotEmpty ? ble.connectedDeviceName : 'N/A',
              color: LvsColors.teal,
            ),
          ),

          const SizedBox(width: 12),

          // Buttplug Status
          Expanded(
            child: _buildStatusCard(
              title: 'BUTTPLUG',
              connected: buttplugBridge.isConnected,
              scanning: buttplugBridge.isScanning,
              deviceName: buttplugBridge.deviceCount > 0 
                  ? '${buttplugBridge.deviceCount} devices' 
                  : 'N/A',
              color: LvsColors.pink,
              onTap: () => setState(() => _showButtplugSection = !_showButtplugSection),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusCard({
    required String title,
    required bool connected,
    required bool scanning,
    required String deviceName,
    required Color color,
    VoidCallback? onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: connected ? color : (scanning ? Colors.orange : Colors.grey),
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 6),
                Text(title, style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 10)),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              connected ? 'CONECTADO' : (scanning ? 'ESCANEANDO...' : 'DESCONECTADO'),
              style: TextStyle(color: connected ? color : LvsColors.text3, fontSize: 9, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            Text(deviceName, style: const TextStyle(color: LvsColors.text2, fontSize: 8), maxLines: 2, overflow: TextOverflow.ellipsis),
          ],
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════
  // LVS BLE Section
  // ═══════════════════════════════════════════════════════════════

  Widget _buildLvsSection(BleService ble, double intensity) {
    return CardGlass(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.bluetooth_connected, color: LvsColors.teal, size: 18),
              const SizedBox(width: 8),
              const Text('LVS BLE TESTING', style: TextStyle(color: LvsColors.teal, fontWeight: FontWeight.bold, fontSize: 12)),
            ],
          ),
          const SizedBox(height: 16),

          // Scan Button
          ElevatedButton.icon(
            onPressed: ble.isScanning ? null : () {
              _addLog('Iniciando escaneo LVS...');
              ble.connectToDevice();
            },
            icon: ble.isScanning 
                ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: LvsColors.teal)) 
                : const Icon(Icons.bluetooth_searching, color: LvsColors.teal),
            label: Text(ble.isScanning ? 'ESCANEANDO...' : 'ESCANEAR DISPOSITIVO'),
            style: ElevatedButton.styleFrom(
              backgroundColor: LvsColors.teal.withOpacity(0.2),
              minimumSize: const Size(double.infinity, 48),
            ),
          ),

          const SizedBox(height: 16),

          // Test Commands (only if connected)
          if (ble.isConnected) ...[
            const Text('COMANDOS RÁPIDOS', style: TextStyle(color: LvsColors.text3, fontSize: 10, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _CommandButton(label: 'LOW', color: Colors.blue, onPressed: () {
                  ble.selectSpeed(SpeedLevel.low);
                  _addLog('LVS: LOW speed');
                }),
                _CommandButton(label: 'MED', color: Colors.orange, onPressed: () {
                  ble.selectSpeed(SpeedLevel.medium);
                  _addLog('LVS: MED speed');
                }),
                _CommandButton(label: 'HIGH', color: Colors.red, onPressed: () {
                  ble.selectSpeed(SpeedLevel.high);
                  _addLog('LVS: HIGH speed');
                }),
                _CommandButton(label: 'STOP', color: LvsColors.red, onPressed: () {
                  ble.emergencyStop();
                  _addLog('LVS: EMERGENCY STOP');
                }),
              ],
            ),

            const SizedBox(height: 16),

            // Intensity Slider
            const Text('INTENSIDAD MANUAL', style: TextStyle(color: LvsColors.text3, fontSize: 10, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: Slider(
                    value: intensity,
                    onChanged: (v) {
                      ref.read(debugIntensityProvider.notifier).state = v;
                      _intensityCtrl.text = '${(v * 100).round()}';
                    },
                    min: 0,
                    max: 1,
                    divisions: 100,
                    label: '${(intensity * 100).round()}%',
                    activeColor: LvsColors.teal,
                  ),
                ),
                SizedBox(
                  width: 60,
                  child: TextField(
                    controller: _intensityCtrl,
                    keyboardType: TextInputType.number,
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: Colors.white, fontSize: 12),
                    decoration: const InputDecoration(
                      suffixText: '%',
                      border: OutlineInputBorder(),
                      contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 0),
                    ),
                    onSubmitted: (v) {
                      final val = (int.tryParse(v) ?? 50) / 100;
                      ref.read(debugIntensityProvider.notifier).state = val;
                    },
                  ),
                ),
              ],
            ),

            // Apply Intensity Button
            ElevatedButton.icon(
              onPressed: () {
                ble.setProportionalIntensity((intensity * 100).round());
                _addLog('LVS: Intensidad ${(intensity * 100).round()}%');
              },
              icon: const Icon(Icons.bolt, size: 16),
              label: const Text('APLICAR INTENSIDAD'),
              style: ElevatedButton.styleFrom(
                backgroundColor: LvsColors.teal.withOpacity(0.2),
                minimumSize: const Size(double.infinity, 40),
              ),
            ),
          ],

          // Disconnect Button
          if (ble.isConnected) ...[
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: () {
                ble.disconnect();
                _addLog('LVS: Desconectado');
              },
              icon: const Icon(Icons.bluetooth_disabled, size: 16),
              label: const Text('DESCONECTAR LVS'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.transparent,
                foregroundColor: LvsColors.text3,
                side: const BorderSide(color: LvsColors.border),
                minimumSize: const Size(double.infinity, 40),
              ),
            ),
          ],
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════
  // Buttplug Section
  // ═══════════════════════════════════════════════════════════════

  Widget _buildButtplugSection(ButtplugBridgeService bridge, List<ButtplugDevice> devices, int selectedDevice) {
    return CardGlass(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.usb, color: LvsColors.pink, size: 18),
              const SizedBox(width: 8),
              const Text('BUTTPLUG TESTING', style: TextStyle(color: LvsColors.pink, fontWeight: FontWeight.bold, fontSize: 12)),
              const Spacer(),
              IconButton(
                icon: const Icon(Icons.info_outline, size: 16),
                onPressed: () => _showButtplugInfoDialog(),
                tooltip: 'Info',
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Connect Button
          ElevatedButton.icon(
            onPressed: bridge.isDisconnected ? () async {
              _addLog('Buttplug: Conectando...');
              final connected = await bridge.connect();
              _addLog(connected ? 'Buttplug: ✅ Conectado' : 'Buttplug: ❌ Error');
            } : null,
            icon: bridge.isConnected ? const Icon(Icons.check, color: LvsColors.pink) : const Icon(Icons.link, color: LvsColors.pink),
            label: Text(bridge.isConnected ? 'CONECTADO' : 'CONECTAR'),
            style: ElevatedButton.styleFrom(
              backgroundColor: LvsColors.pink.withOpacity(0.2),
              minimumSize: const Size(double.infinity, 48),
            ),
          ),

          const SizedBox(height: 16),

          // Scan Button (only if connected)
          if (bridge.isConnected) ...[
            ElevatedButton.icon(
              onPressed: bridge.isScanning ? null : () async {
                _addLog('Buttplug: Iniciando escaneo...');
                await bridge.startScan(timeout: 10);
                _addLog('Buttplug: ${bridge.deviceCount} dispositivos encontrados');
              },
              icon: bridge.isScanning 
                  ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: LvsColors.pink)) 
                  : const Icon(Icons.search, color: LvsColors.pink),
              label: Text(bridge.isScanning ? 'ESCANEANDO...' : 'ESCANEAR DISPOSITIVOS'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.transparent,
                foregroundColor: LvsColors.pink,
                side: BorderSide(color: LvsColors.pink.withOpacity(0.3)),
                minimumSize: const Size(double.infinity, 40),
              ),
            ),

            const SizedBox(height: 16),

            // Device List
            if (devices.isNotEmpty) ...[
              const Text('DISPOSITIVOS ENCONTRADOS', style: TextStyle(color: LvsColors.text3, fontSize: 10, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Container(
                constraints: const BoxConstraints(maxHeight: 150),
                child: ListView.separated(
                  shrinkWrap: true,
                  itemCount: devices.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 4),
                  itemBuilder: (context, index) {
                    final device = devices[index];
                    final isSelected = index == selectedDevice;
                    return GestureDetector(
                      onTap: () => ref.read(debugSelectedDeviceProvider.notifier).state = index,
                      child: Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: isSelected ? LvsColors.pink.withOpacity(0.2) : Colors.transparent,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: isSelected ? LvsColors.pink : LvsColors.border),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              isSelected ? Icons.radio_button_checked : Icons.radio_button_unchecked,
                              color: isSelected ? LvsColors.pink : LvsColors.text3,
                              size: 16,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(device.name, style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
                                  Text(
                                    device.toToyModel().stimulationType,
                                    style: const TextStyle(color: LvsColors.text2, fontSize: 9),
                                  ),
                                ],
                              ),
                            ),
                            if (device.batteryLevel != null)
                              Text('${device.batteryLevel}%', style: const TextStyle(color: LvsColors.text3, fontSize: 9)),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),

              const SizedBox(height: 16),

              // Device Controls
              const Text('CONTROLES DEL DISPOSITIVO', style: TextStyle(color: LvsColors.text3, fontSize: 10, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),

              // Vibrate Slider
              Row(
                children: [
                  const Text('VIBRATE', style: TextStyle(color: LvsColors.text3, fontSize: 9)),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Slider(
                      value: intensity,
                      onChanged: (v) => ref.read(debugIntensityProvider.notifier).state = v,
                      min: 0,
                      max: 1,
                      divisions: 100,
                      label: '${(intensity * 100).round()}%',
                      activeColor: LvsColors.pink,
                    ),
                  ),
                  SizedBox(
                    width: 50,
                    child: Text('${(intensity * 100).round()}%', style: const TextStyle(color: LvsColors.text2, fontSize: 9)),
                  ),
                ],
              ),

              // Control Buttons
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _CommandButton(
                    label: 'VIBRATE',
                    color: LvsColors.pink,
                    onPressed: () {
                      bridge.vibrate(deviceIndex: selectedDevice, intensity: intensity);
                      _addLog('Buttplug: Vibrate ${devices[selectedDevice].name} @ ${(intensity * 100).round()}%');
                    },
                  ),
                  _CommandButton(
                    label: 'STOP',
                    color: Colors.red,
                    onPressed: () {
                      bridge.stop(deviceIndex: selectedDevice);
                      _addLog('Buttplug: Stop ${devices[selectedDevice].name}');
                    },
                  ),
                ],
              ),
            ],

            // No devices message
            if (devices.isEmpty && !bridge.isScanning) ...[
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.transparent,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: LvsColors.border),
                ),
                child: const Center(
                  child: Text('No hay dispositivos.\nPresiona ESCANEAR para buscar.', 
                    textAlign: TextAlign.center,
                    style: TextStyle(color: LvsColors.text3, fontSize: 10)),
                ),
              ),
            ],

            const SizedBox(height: 16),

            // Disconnect Button
            ElevatedButton.icon(
              onPressed: () {
                bridge.disconnect();
                _addLog('Buttplug: Desconectado');
              },
              icon: const Icon(Icons.link_off, size: 16),
              label: const Text('DESCONECTAR BUTTPLUG'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.transparent,
                foregroundColor: LvsColors.text3,
                side: const BorderSide(color: LvsColors.border),
                minimumSize: const Size(double.infinity, 40),
              ),
            ),
          ],
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════
  // Advanced Testing Controls
  // ═══════════════════════════════════════════════════════════════

  Widget _buildAdvancedTestingControls(BleService ble) {
    return CardGlass(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.science, color: LvsColors.amber, size: 18),
              const SizedBox(width: 8),
              const Text('CONTROLES AVANZADOS', style: TextStyle(color: LvsColors.amber, fontWeight: FontWeight.bold, fontSize: 12)),
            ],
          ),
          const SizedBox(height: 16),

          // Pattern Testing
          const Text('PATRONES (1-9)', style: TextStyle(color: LvsColors.text3, fontSize: 10, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          TextField(
            controller: _patternCtrl,
            keyboardType: TextInputType.number,
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.white, fontSize: 14),
            decoration: const InputDecoration(
              hintText: 'Patrón (1-9)',
              border: OutlineInputBorder(),
              contentPadding: EdgeInsets.symmetric(vertical: 8),
            ),
            onSubmitted: (v) {
              final pattern = int.tryParse(v);
              if (pattern != null && pattern >= 1 && pattern <= 9) {
                ble.setPatternChannel1(pattern);
                _addLog('LVS: Patrón CH1 #$pattern');
              }
            },
          ),

          const SizedBox(height: 16),

          // Dual Channel Testing
          const Text('DUAL CHANNEL', style: TextStyle(color: LvsColors.text3, fontSize: 10, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: ElevatedButton(
                  onPressed: ble.isConnected ? () {
                    ble.setProportionalChannel1(50);
                    _addLog('LVS: CH1 @ 50%');
                  } : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue.withOpacity(0.2),
                    minimumSize: const Size(0, 40),
                  ),
                  child: const Text('CH1 50%', style: TextStyle(fontSize: 10)),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: ElevatedButton(
                  onPressed: ble.isConnected ? () {
                    ble.setProportionalChannel2(50);
                    _addLog('LVS: CH2 @ 50%');
                  } : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.purple.withOpacity(0.2),
                    minimumSize: const Size(0, 40),
                  ),
                  child: const Text('CH2 50%', style: TextStyle(fontSize: 10)),
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Copy Logs Button
          ElevatedButton.icon(
            onPressed: () {
              final logs = ref.read(debugLogProvider);
              Clipboard.setData(ClipboardData(text: logs.join('\n')));
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('✅ Logs copiados al portapapeles'), duration: Duration(seconds: 2)),
              );
              _addLog('Logs copiados al portapapeles');
            },
            icon: const Icon(Icons.content_copy, size: 16),
            label: const Text('COPIAR LOGS'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.transparent,
              foregroundColor: LvsColors.text2,
              side: const BorderSide(color: LvsColors.border),
              minimumSize: const Size(double.infinity, 40),
            ),
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════
  // Log Console
  // ═══════════════════════════════════════════════════════════════

  Widget _buildLogConsole(List<String> logs) {
    return Expanded(
      child: Container(
        constraints: const BoxConstraints(minHeight: 200),
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.3),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: LvsColors.border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: LvsColors.bgCard,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.terminal, color: LvsColors.text3, size: 16),
                  const SizedBox(width: 8),
                  const Text('LOG CONSOLE', style: TextStyle(color: LvsColors.text3, fontSize: 10, fontWeight: FontWeight.bold)),
                  const Spacer(),
                  Text('${logs.length} entries', style: const TextStyle(color: LvsColors.text3, fontSize: 9)),
                ],
              ),
            ),
            Expanded(
              child: ListView.separated(
                padding: const EdgeInsets.all(12),
                reverse: true,
                itemCount: logs.length,
                separatorBuilder: (_, __) => const SizedBox(height: 4),
                itemBuilder: (context, index) {
                  final log = logs[logs.length - 1 - index];
                  return SelectableText(
                    log,
                    style: const TextStyle(color: LvsColors.text2, fontSize: 9, fontFamily: 'monospace'),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════
  // Dialogs
  // ═══════════════════════════════════════════════════════════════

  void _showOptionsDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: LvsColors.bg,
        title: const Text('OPCIONES DEBUG', style: TextStyle(color: Colors.white, fontSize: 14)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SwitchListTile(
              title: const Text('Mostrar Buttplug', style: TextStyle(color: Colors.white, fontSize: 12)),
              value: _showButtplugSection,
              onChanged: (v) {
                setState(() => _showButtplugSection = v);
                Navigator.pop(context);
              },
            ),
            SwitchListTile(
              title: const Text('Controles Avanzados', style: TextStyle(color: Colors.white, fontSize: 12)),
              value: _showAdvancedControls,
              onChanged: (v) {
                setState(() => _showAdvancedControls = v);
                Navigator.pop(context);
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showButtplugInfoDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: LvsColors.bg,
        title: const Text('BUTTPLUG', style: TextStyle(color: LvsColors.pink, fontSize: 14)),
        content: const Text(
          'Buttplug permite controlar 100+ dispositivos (Lovense, WeVibe, Kiiroo, etc.)\n\n'
          'Requiere Intiface Engine instalado:\n'
          '• Windows: winget install Intiface.IntifaceEngine\n'
          '• macOS: brew install intiface-engine\n'
          '• Linux: cargo install intiface_engine\n\n'
          'Luego inicia: intiface_engine --websocket-port 12345',
          style: TextStyle(color: LvsColors.text2, fontSize: 11),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('CERRAR'),
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
// Command Button Widget
// ═══════════════════════════════════════════════════════════════

class _CommandButton extends StatelessWidget {
  final String label;
  final Color color;
  final VoidCallback onPressed;

  const _CommandButton({required this.label, required this.color, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: color.withOpacity(0.2),
        foregroundColor: color,
        minimumSize: const Size(70, 36),
        padding: const EdgeInsets.symmetric(horizontal: 12),
      ),
      child: Text(label, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
    );
  }
}
