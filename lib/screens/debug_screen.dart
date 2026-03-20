// ═══════════════════════════════════════════════════════════════
// Velvet Sync · lib/screens/debug_screen.dart
// Pantalla de Debug para testing BLE
// ═══════════════════════════════════════════════════════════════

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../ble/ble_service.dart';
import '../ble/lvs_commands.dart';
import '../theme.dart';

class DebugScreen extends ConsumerWidget {
  const DebugScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ble = ref.watch(bleProvider);

    return Scaffold(
      backgroundColor: LvsColors.bg,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text('DEBUG', style: TextStyle(letterSpacing: 3, fontSize: 16)),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Connection Status
            CardGlass(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Estado: ${ble.state.name}', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  Text('Conectado: ${ble.isConnected}', style: const TextStyle(color: LvsColors.text2)),
                  Text('Escaneando: ${ble.isScanning}', style: const TextStyle(color: LvsColors.text2)),
                  Text('Hardware Confirmado: ${ble.isConnected}', style: const TextStyle(color: LvsColors.text2)),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // Scan Button
            ElevatedButton.icon(
              onPressed: ble.isScanning ? null : () => ble.connectToDevice(),
              icon: ble.isScanning ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2)) : const Icon(Icons.bluetooth_searching_rounded),
              label: Text(ble.isScanning ? 'ESCANEANDO...' : 'ESCANEAR'),
            ),

            const SizedBox(height: 16),

            // Test Commands
            if (ble.isConnected) ...[
              const Text('COMANDOS DE TEST', style: TextStyle(color: LvsColors.teal, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  ElevatedButton(onPressed: () => ble.selectSpeed(SpeedLevel.low), child: const Text('LOW')),
                  ElevatedButton(onPressed: () => ble.selectSpeed(SpeedLevel.medium), child: const Text('MED')),
                  ElevatedButton(onPressed: () => ble.selectSpeed(SpeedLevel.high), child: const Text('HIGH')),
                  ElevatedButton(onPressed: () => ble.emergencyStop(), child: const Text('STOP', style: TextStyle(color: LvsColors.red))),
                ],
              ),
            ],

            const Spacer(),

            // Disconnect
            ElevatedButton.icon(
              onPressed: ble.isConnected ? () => ble.disconnect() : null,
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
    );
  }
}
