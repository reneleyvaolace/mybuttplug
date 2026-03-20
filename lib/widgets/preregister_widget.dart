// ═══════════════════════════════════════════════════════════════
// Velvet Sync · lib/widgets/preregister_widget.dart · v1.0.0
// Widget de Pre-registro: agregar dispositivo por QR o clave
// ═══════════════════════════════════════════════════════════════

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import '../models/toy_model.dart';
import '../services/catalog_service.dart';
import '../theme.dart';

class PreregisterPanel extends ConsumerStatefulWidget {
  final VoidCallback? onAdded;
  const PreregisterPanel({super.key, this.onAdded});

  @override
  ConsumerState<PreregisterPanel> createState() => _PreregisterPanelState();
}

class _PreregisterPanelState extends ConsumerState<PreregisterPanel>
    with SingleTickerProviderStateMixin {
  bool _expanded = true;
  final TextEditingController _keyCtrl = TextEditingController();
  bool _loading = false;
  String? _feedback;
  bool _feedbackOk = false;
  late AnimationController _anim;
  late Animation<double> _fadeAnim;

  @override
  void initState() {
    super.initState();
    _anim = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 280));
    _fadeAnim = CurvedAnimation(parent: _anim, curve: Curves.easeOut);
    _anim.forward();
  }

  @override
  void dispose() {
    _anim.dispose();
    _keyCtrl.dispose();
    super.dispose();
  }

  void _toggle() {
    setState(() => _expanded = !_expanded);
    if (_expanded) {
      _anim.forward();
    } else {
      _anim.reverse();
      _feedback = null;
    }
  }

  Future<void> _addByKey(String key) async {
    if (key.trim().isEmpty) return;
    setState(() { _loading = true; _feedback = null; });

    final result = await ref.read(catalogProvider.notifier).addByKey(key.trim());
    if (!mounted) return;

    setState(() {
      _loading = false;
      if (result != null) {
        _feedbackOk = true;
        _feedback = '✅ ${result.name} registrado.';
        _keyCtrl.clear();
        if (widget.onAdded != null) widget.onAdded!();
      } else {
        _feedbackOk = false;
        _feedback = '❌ No se encontró dispositivo con clave "$key".';
      }
    });
  }

  Future<void> _openQr() async {
    final result = await Navigator.push<String>(
      context,
      MaterialPageRoute(builder: (_) => const _QrScanPage()),
    );
    if (result != null && result.isNotEmpty && mounted) {
      _keyCtrl.text = result;
      _addByKey(result);
    }
  }

  @override
  Widget build(BuildContext context) {
    final preregistered = ref.watch(catalogProvider).maybeWhen(
      data: (toys) => ref.read(catalogProvider.notifier).preregistered,
      orElse: () => <ToyModel>[],
    );

    final suggestedDevices = ref.watch(serverCatalogProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: _toggle,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: LvsColors.bgCardH.withOpacity(0.5),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: (_expanded ? LvsColors.teal : Colors.white12)),
            ),
            child: Row(
              children: [
                Icon(Icons.devices_other_rounded,
                    color: _expanded ? LvsColors.teal : LvsColors.text3,
                    size: 16),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    preregistered.isEmpty
                        ? 'Dispositivos Sugeridos'
                        : 'Pre-registrados: ${preregistered.length}',
                    style: TextStyle(
                      color: _expanded ? LvsColors.teal : LvsColors.text3,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                Icon(
                  _expanded ? Icons.expand_less : Icons.expand_more,
                  color: LvsColors.text3,
                  size: 18,
                ),
              ],
            ),
          ),
        ),

        SizeTransition(
          sizeFactor: _fadeAnim,
          child: FadeTransition(
            opacity: _fadeAnim,
            child: Container(
              margin: const EdgeInsets.only(top: 8),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: LvsColors.bgCard.withOpacity(0.8),
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: LvsColors.teal.withOpacity(0.2)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (preregistered.isNotEmpty) ...[
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: preregistered.map((toy) {
                        return GestureDetector(
                          onTap: () => _editDevice(toy),
                          child: Chip(
                            avatar: CircleAvatar(
                              backgroundColor: Colors.white10,
                              backgroundImage: toy.imageUrl.isNotEmpty ? NetworkImage(toy.imageUrl) : null,
                              child: toy.imageUrl.isEmpty ? const Icon(Icons.vibration, size: 10, color: LvsColors.teal) : null,
                            ),
                            label: Text(toy.name,
                                style: const TextStyle(
                                    color: Colors.white, fontSize: 10)),
                            deleteIcon: const Icon(Icons.close, size: 13),
                            onDeleted: () {
                              ref.read(catalogProvider.notifier).removeDevice(toy.id);
                            },
                            backgroundColor: LvsColors.teal.withOpacity(0.15),
                            side: BorderSide(color: LvsColors.teal.withOpacity(0.4)),
                          ),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 12),
                  ],

                  Row(
                    children: [
                      Expanded(
                        child: Container(
                          decoration: BoxDecoration(
                            color: Colors.black.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: LvsColors.pink.withOpacity(0.3)),
                          ),
                          child: TextField(
                            controller: _keyCtrl,
                            style: const TextStyle(color: Colors.white, fontSize: 14),
                            textCapitalization: TextCapitalization.characters,
                            decoration: InputDecoration(
                              hintText: 'ID del producto (ej: 8154)',
                              hintStyle: TextStyle(color: Colors.white.withOpacity(0.2), fontSize: 12),
                              prefixIcon: const Icon(Icons.vpn_key_rounded, color: LvsColors.pink, size: 16),
                              border: InputBorder.none,
                              contentPadding: const EdgeInsets.symmetric(vertical: 12, horizontal: 10),
                            ),
                            onSubmitted: _addByKey,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      _iconBtn(
                        icon: _loading
                            ? const SizedBox(
                                width: 18, height: 18,
                                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                            : const Icon(Icons.search_rounded, color: Colors.white, size: 20),
                        color: LvsColors.pink,
                        onTap: () => _addByKey(_keyCtrl.text),
                      ),
                      const SizedBox(width: 6),
                      _iconBtn(
                        icon: const Icon(Icons.qr_code_scanner_rounded, color: Colors.white, size: 20),
                        color: LvsColors.teal,
                        onTap: _openQr,
                      ),
                    ],
                  ),

                  if (_feedback != null) ...[
                    const SizedBox(height: 10),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: (_feedbackOk ? LvsColors.teal : LvsColors.red).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: (_feedbackOk ? LvsColors.teal : LvsColors.red).withOpacity(0.3),
                        ),
                      ),
                      child: Text(
                        _feedback!,
                        style: TextStyle(
                          color: _feedbackOk ? LvsColors.teal : LvsColors.red,
                          fontSize: 11,
                          height: 1.5,
                        ),
                      ),
                    ),
                  ],

                  const SizedBox(height: 16),
                  SizedBox(
                    height: 100,
                    child: suggestedDevices.isEmpty
                        ? const Center(child: Text('Cargando...'))
                        : ListView.separated(
                            scrollDirection: Axis.horizontal,
                            itemCount: suggestedDevices.length,
                            separatorBuilder: (_, __) => const SizedBox(width: 8),
                            itemBuilder: (ctx, i) {
                              final toy = suggestedDevices[i];
                              final isRegistered = preregistered.any((t) => t.id == toy.id);
                              return _SuggestionChip(
                                toy: toy,
                                isRegistered: isRegistered,
                                onAdd: () => _addByKey(toy.id),
                              );
                            },
                          ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  void _editDevice(ToyModel toy) {
    final controller = TextEditingController(text: toy.name);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: LvsColors.bg,
        title: const Text('EDITAR DISPOSITIVO'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (toy.imageUrl.isNotEmpty)
              Image.network(toy.imageUrl, height: 100),
            const SizedBox(height: 12),
            TextField(
              controller: controller,
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(
                labelText: 'Nombre',
                labelStyle: TextStyle(color: LvsColors.text3),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('CANCELAR')),
          ElevatedButton(
            onPressed: () {
              ref.read(catalogProvider.notifier).updateDevice(toy.id, controller.text, '');
              Navigator.pop(context);
            },
            child: const Text('GUARDAR'),
          ),
        ],
      ),
    );
  }

  Widget _iconBtn({required Widget icon, required Color color, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 44, height: 44,
        decoration: BoxDecoration(
          color: color.withOpacity(0.15),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withOpacity(0.4)),
        ),
        child: Center(child: icon),
      ),
    );
  }
}

class _SuggestionChip extends StatelessWidget {
  final ToyModel toy;
  final bool isRegistered;
  final VoidCallback onAdd;

  const _SuggestionChip({required this.toy, required this.isRegistered, required this.onAdd});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: isRegistered ? null : onAdd,
      child: Container(
        width: 85,
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: isRegistered ? LvsColors.teal.withOpacity(0.15) : LvsColors.violet.withOpacity(0.15),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isRegistered ? LvsColors.teal.withOpacity(0.4) : LvsColors.violet.withOpacity(0.4),
          ),
        ),
        child: Column(
          children: [
            toy.imageUrl.isNotEmpty
                ? ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.network(toy.imageUrl, width: 45, height: 45, fit: BoxFit.cover),
                  )
                : Icon(Icons.vibration_rounded, color: isRegistered ? LvsColors.teal : LvsColors.violet, size: 20),
            const SizedBox(height: 4),
            Text(
              toy.name.length > 12 ? '${toy.name.substring(0, 10)}..' : toy.name,
              maxLines: 2,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.white, fontSize: 7, fontWeight: FontWeight.w600),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 3, vertical: 1),
              decoration: BoxDecoration(
                color: isRegistered ? LvsColors.teal.withOpacity(0.3) : LvsColors.violet.withOpacity(0.3),
                borderRadius: BorderRadius.circular(3),
              ),
              child: Text(
                isRegistered ? '✓ AGREGADO' : '+ AGREGAR',
                style: TextStyle(
                  color: isRegistered ? LvsColors.teal : LvsColors.violet,
                  fontSize: 6,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _QrScanPage extends StatefulWidget {
  const _QrScanPage();
  @override
  State<_QrScanPage> createState() => _QrScanPageState();
}

class _QrScanPageState extends State<_QrScanPage> {
  final MobileScannerController _ctrl = MobileScannerController();
  bool _scanned = false;

  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }

  void _onDetect(BarcodeCapture cap) {
    if (_scanned) return;
    final val = cap.barcodes.firstOrNull?.rawValue;
    if (val == null || val.isEmpty) return;
    _scanned = true;
    _ctrl.stop();
    Navigator.pop(context, val);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: const Text('Escanear QR'),
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(icon: const Icon(Icons.flash_on_rounded), onPressed: () => _ctrl.toggleTorch()),
          IconButton(icon: const Icon(Icons.flip_camera_ios_rounded), onPressed: () => _ctrl.switchCamera()),
        ],
      ),
      body: Stack(
        children: [
          MobileScanner(controller: _ctrl, onDetect: _onDetect),
          Center(
            child: Container(
              width: 220, height: 220,
              decoration: BoxDecoration(
                border: Border.all(color: LvsColors.pink, width: 2),
                borderRadius: BorderRadius.circular(16),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
