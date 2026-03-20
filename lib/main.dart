// ═══════════════════════════════════════════════════════════════
// Velvet Sync · lib/main.dart · v2.1.1
// Punto de entrada — inicialización de servicios y Splash Screen
// ═══════════════════════════════════════════════════════════════

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_foreground_task/flutter_foreground_task.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

import 'services/supabase_service.dart';
import 'services/link_service.dart';
import 'services/sync_service.dart';
import 'services/ai_hardware_bridge_service.dart';
import 'screens/splash_screen.dart';
import 'theme.dart';
import 'utils/logger.dart';

// ═══════════════════════════════════════════════════════════════
// MODO CAPTURA DE PANTALLA
// ═══════════════════════════════════════════════════════════════
const bool kScreenshotMode = false;

// ═══════════════════════════════════════════════════════════════
// MODO EMULADOR
// ═══════════════════════════════════════════════════════════════
const bool kEmulatorMode = false;

@pragma('vm:entry-point')
void startCallback() {
  FlutterForegroundTask.setTaskHandler(BleScanTaskHandler());
}

class BleScanTaskHandler extends TaskHandler {
  @override
  Future<void> onStart(DateTime timestamp, TaskStarter starter) async {
    lvsLog('Foreground task iniciado', tag: 'BG');
  }

  @override
  void onRepeatEvent(DateTime timestamp) {
    FlutterForegroundTask.updateService(
      notificationText: 'Velvet Sync activo',
    );
  }

  @override
  Future<void> onDestroy(DateTime timestamp, bool isTimeout) async {
    lvsLog('Foreground task destruido', tag: 'BG');
  }
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  lvsLog('════════════════════════════════════════', tag: 'INIT');
  lvsLog('🚀 Velvet Sync Iniciando...', tag: 'INIT');
  lvsLog('════════════════════════════════════════', tag: 'INIT');

  if (kEmulatorMode) {
    lvsLog('⚠️ MODO EMULADOR ACTIVO', tag: 'INIT');
  }

  try {
    lvsLog('Cargando .env...', tag: 'INIT');
    await dotenv.load(fileName: ".env");
    lvsLog('✅ .env cargado', tag: 'INIT');
  } catch (e) {
    lvsLog('❌ Error cargando .env: $e', tag: 'INIT');
    rethrow;
  }

  // Inicialización en paralelo de servicios
  lvsLog('Inicializando servicios...', tag: 'INIT');
  try {
    await Future.wait([
      () async {
        lvsLog('Inicializando Deep Linking...', tag: 'INIT');
        final linkService = LinkService();
        await linkService.init();
        lvsLog('✅ Deep Linking listo', tag: 'INIT');
      }(),

      () async {
        lvsLog('Inicializando Sync Service...', tag: 'INIT');
        final syncService = SyncService();
        await syncService.init();
        lvsLog('✅ Sync Service listo', tag: 'INIT');
      }(),
    ]);
  } catch (e) {
    lvsLog('❌ Error en inicialización: $e', tag: 'INIT');
    rethrow;
  }

  // Supabase se inicializa después del primer frame
  WidgetsBinding.instance.addPostFrameCallback((_) async {
    try {
      final supabase = SupabaseService();
      await supabase.initialize();
      lvsLog('✅ Supabase listo', tag: 'INIT');
    } catch (e) {
      lvsLog('⚠️ Supabase falló (app funciona offline): $e', tag: 'INIT');
    }
  });

  lvsLog('════════════════════════════════════════', tag: 'INIT');
  lvsLog('✅ Servicios listos', tag: 'INIT');
  lvsLog('════════════════════════════════════════', tag: 'INIT');

  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.light,
    systemNavigationBarColor: const Color(0xFF05050A),
    systemNavigationBarIconBrightness: Brightness.light,
  ));

  FlutterForegroundTask.initCommunicationPort();

  runApp(
    const ProviderScope(
      child: VelvetSyncApp(),
    ),
  );
}

class VelvetSyncApp extends StatelessWidget {
  const VelvetSyncApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Velvet Sync',
      debugShowCheckedModeBanner: kScreenshotMode,
      theme: LvsTheme.darkTheme,
      home: const SplashScreen(),
      routes: {
        '/splash': (context) => const SplashScreen(),
      },
    );
  }
}
