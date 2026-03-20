// ═══════════════════════════════════════════════════════════════
// Velvet Sync Platform · lib/core/platform.dart
// Export unificado de toda la plataforma core
// ═══════════════════════════════════════════════════════════════

// Types
export 'types/device_types.dart';
export 'types/command_types.dart';
export 'types/event_types.dart';
export 'types/result_types.dart';

// HAL - Hardware Abstraction Layer
export 'hal/device_interface.dart';
export 'hal/connection_manager.dart';
export 'hal/command_queue.dart';
export 'hal/protocol_adapter.dart';

// Protocols
export 'protocols/protocol_base.dart';
export 'protocols/lvs_protocol.dart';
export 'protocols/buttplug_protocol.dart';

// Config
export 'config/device_config.dart';
export 'config/device_config_loader.dart';
