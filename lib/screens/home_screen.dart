// ═══════════════════════════════════════════════════════════════
// Velvet Sync · lib/screens/home_screen.dart
// Pantalla Principal: Control Dashboard
// ═══════════════════════════════════════════════════════════════

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../ble/ble_service.dart';
import '../ble/lvs_commands.dart';
import '../theme.dart';
import '../widgets/preregister_widget.dart';
import '../widgets/compatible_devices_row.dart';
import '../widgets/quick_add_control.dart';
import '../widgets/lvs_modes.dart';
import '../services/catalog_service.dart';
import 'debug_screen.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  @override
  Widget build(BuildContext context) {
    final ble = ref.watch(bleProvider);

    return Scaffold(
      backgroundColor: LvsColors.bg,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text('VELVET SYNC', style: TextStyle(letterSpacing: 3, fontSize: 16)),
        actions: [
          IconButton(
            icon: const Icon(Icons.bug_report_rounded),
            onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const DebugScreen())),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async => ble.connectToDevice(catalog: ref.read(catalogProvider).asData?.value),
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Quick Add Control
              CardGlass(
                padding: const EdgeInsets.all(16),
                child: QuickAddControl(ref: ref),
              ),

              const SizedBox(height: 16),

              // Pre-register Panel
              PreregisterPanel(onAdded: () => ble.connectToDevice(catalog: ref.read(catalogProvider).asData?.value)),

              const SizedBox(height: 16),

              // Connection Status
              if (ble.isConnected || ble.isVirtualConnection) ...[
                CardGlass(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            ble.isVirtualConnection ? Icons.phone_android_rounded : Icons.bluetooth_connected_rounded,
                            color: ble.isVirtualConnection ? LvsColors.violet : LvsColors.teal,
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            ble.connectedDeviceName.isNotEmpty ? ble.connectedDeviceName : 'Dispositivo Conectado',
                            style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      // Control Canvas
                      LvsCanvas(ble: ble),

                      const SizedBox(height: 16),

                      // Pattern Selector
                      PatternSelectorRow(
                        activePattern: ble.activePattern != null ? ble.activePattern!.index + 1 : null,
                        color: LvsColors.pink,
                        onSelect: (p) {
                          if (p == 0) {
                            ble.selectSpeed(SpeedLevel.stop);
                          } else {
                            ble.selectPattern(LvsPattern.values[p - 1]);
                          }
                        },
                      ),

                      const SizedBox(height: 16),

                      // Speed Buttons
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          _SpeedButton(label: 'LOW', color: LvsColors.violet, onTap: () => ble.selectSpeed(SpeedLevel.low)),
                          _SpeedButton(label: 'MED', color: LvsColors.amber, onTap: () => ble.selectSpeed(SpeedLevel.medium)),
                          _SpeedButton(label: 'HIGH', color: LvsColors.pink, onTap: () => ble.selectSpeed(SpeedLevel.high)),
                          _SpeedButton(label: 'STOP', color: LvsColors.red, onTap: () => ble.emergencyStop()),
                        ],
                      ),

                      const SizedBox(height: 16),

                      // Disconnect Button
                      ElevatedButton.icon(
                        onPressed: () => ble.disconnect(),
                        icon: const Icon(Icons.bluetooth_disabled_rounded),
                        label: const Text('DESCONECTAR'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.transparent,
                          foregroundColor: LvsColors.text3,
                          side: const BorderSide(color: LvsColors.border),
                        ),
                      ),
                    ],
                  ),
                ),
              ] else ...[
                // Scan Button when not connected
                CardGlass(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    children: [
                      const Icon(Icons.bluetooth_searching_rounded, size: 64, color: LvsColors.teal),
                      const SizedBox(height: 16),
                      const Text(
                        'No hay dispositivo conectado',
                        style: TextStyle(color: LvsColors.text2, fontSize: 14),
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton.icon(
                        onPressed: ble.isScanning ? null : () => ble.connectToDevice(catalog: ref.read(catalogProvider).asData?.value),
                        icon: ble.isScanning ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2)) : const Icon(Icons.bluetooth_searching_rounded),
                        label: Text(ble.isScanning ? 'ESCANEANDO...' : 'BUSCAR DISPOSITIVO'),
                      ),
                    ],
                  ),
                ),
              ],

              const SizedBox(height: 16),

              // Compatible Devices Row
              const CompatibleDevicesRow(),
            ],
          ),
        ),
      ),
    );
  }
}

class _SpeedButton extends StatelessWidget {
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _SpeedButton({required this.label, required this.color, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: color.withOpacity(0.15),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withOpacity(0.4)),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: color,
            fontSize: 10,
            fontWeight: FontWeight.w900,
            letterSpacing: 1,
          ),
        ),
      ),
    );
  }
}
