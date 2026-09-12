import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'aura_engine.dart';

/// Provider for the AuraEngine singleton.
///
/// Usage:
/// ```dart
/// final engine = ref.read(auraEngineProvider);
/// final total = engine.calculateTotal(userId);
/// engine.award(userId, AuraAction.createPost);
/// ```
final auraEngineProvider = Provider<AuraEngine>((ref) {
  return AuraEngine();
});
