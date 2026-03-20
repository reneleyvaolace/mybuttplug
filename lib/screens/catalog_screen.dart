// ═══════════════════════════════════════════════════════════════
// Velvet Sync · lib/screens/catalog_screen.dart
// Catálogo de Dispositivos
// ═══════════════════════════════════════════════════════════════

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../theme.dart';
import '../models/toy_model.dart';
import '../services/catalog_service.dart';
import '../ble/ble_service.dart';

class CatalogScreen extends ConsumerWidget {
  const CatalogScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final catalogAsync = ref.watch(catalogProvider);

    return Scaffold(
      backgroundColor: LvsColors.bg,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text('CATÁLOGO', style: TextStyle(letterSpacing: 3, fontSize: 16)),
      ),
      body: catalogAsync.when(
        loading: () => const Center(child: CircularProgressIndicator(color: LvsColors.teal)),
        error: (error, stack) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline_rounded, size: 48, color: LvsColors.red),
              const SizedBox(height: 16),
              Text('Error cargando catálogo: $error', style: const TextStyle(color: LvsColors.text2)),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => ref.invalidate(catalogProvider),
                child: const Text('REINTENTAR'),
              ),
            ],
          ),
        ),
        data: (toys) => RefreshIndicator(
          onRefresh: () async => ref.invalidate(catalogProvider),
          child: GridView.builder(
            padding: const EdgeInsets.all(16),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 0.75,
            ),
            itemCount: toys.length,
            itemBuilder: (context, index) {
              final toy = toys[index];
              return _CatalogItem(toy: toy, ref: ref);
            },
          ),
        ),
      ),
    );
  }
}

class _CatalogItem extends StatelessWidget {
  final ToyModel toy;
  final WidgetRef ref;

  const _CatalogItem({required this.toy, required this.ref});

  @override
  Widget build(BuildContext context) {
    final isRegistered = ref.watch(preregisteredProvider).any((t) => t.id == toy.id);

    return GestureDetector(
      onTap: () => _showDetails(context),
      child: Container(
        decoration: BoxDecoration(
          color: LvsColors.bgCard,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isRegistered ? LvsColors.teal.withOpacity(0.4) : LvsColors.pink.withOpacity(0.2),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Image
            Expanded(
              child: ClipRRect(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                child: toy.imageUrl.isNotEmpty
                    ? CachedNetworkImage(
                        imageUrl: toy.imageUrl,
                        fit: BoxFit.cover,
                        width: double.infinity,
                        errorWidget: (_, __, ___) => _buildPlaceholder(),
                      )
                    : _buildPlaceholder(),
              ),
            ),

            // Info
            Padding(
              padding: const EdgeInsets.all(10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    toy.name,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    toy.id,
                    style: TextStyle(color: LvsColors.text3, fontSize: 9),
                  ),
                  const SizedBox(height: 8),
                  if (isRegistered)
                    const Chip(
                      label: Text('✓ REGISTRADO', style: TextStyle(fontSize: 8, color: Colors.white)),
                      backgroundColor: LvsColors.teal,
                      padding: EdgeInsets.zero,
                      visualDensity: VisualDensity.compact,
                    )
                  else
                    ElevatedButton(
                      onPressed: () => _addToy(),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: LvsColors.pink,
                        padding: const EdgeInsets.symmetric(vertical: 4),
                      ),
                      child: const Text('AGREGAR', style: TextStyle(fontSize: 9)),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPlaceholder() {
    return Container(
      color: LvsColors.bgCardH,
      child: const Icon(Icons.vibration_rounded, size: 48, color: LvsColors.text3),
    );
  }

  void _showDetails(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        decoration: const BoxDecoration(
          color: LvsColors.bg,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                if (toy.imageUrl.isNotEmpty)
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: CachedNetworkImage(imageUrl: toy.imageUrl, width: 80, height: 80, fit: BoxFit.cover),
                  ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(toy.name, style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 4),
                      Text('ID: ${toy.id}', style: TextStyle(color: LvsColors.text3, fontSize: 12)),
                      const SizedBox(height: 4),
                      Text('${toy.usageType} · ${toy.targetAnatomy}', style: const TextStyle(color: LvsColors.text2, fontSize: 11)),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _addToy,
              style: ElevatedButton.styleFrom(
                backgroundColor: LvsColors.pink,
                minimumSize: const Size(double.infinity, 48),
              ),
              child: const Text('AGREGAR DISPOSITIVO'),
            ),
          ],
        ),
      ),
    );
  }

  void _addToy() {
    ref.read(catalogProvider.notifier).addByKey(toy.id);
    ref.read(bleProvider).setActiveToy(toy);
  }
}
