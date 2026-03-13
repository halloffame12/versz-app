import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/services/hive_service.dart';

class UiPreferencesState {
  final bool subtleChatFeedback;
  final bool fastRetryAnimations;

  const UiPreferencesState({
    this.subtleChatFeedback = true,
    this.fastRetryAnimations = false,
  });

  UiPreferencesState copyWith({
    bool? subtleChatFeedback,
    bool? fastRetryAnimations,
  }) {
    return UiPreferencesState(
      subtleChatFeedback: subtleChatFeedback ?? this.subtleChatFeedback,
      fastRetryAnimations: fastRetryAnimations ?? this.fastRetryAnimations,
    );
  }
}

final uiPreferencesProvider =
    StateNotifierProvider<UiPreferencesNotifier, UiPreferencesState>((ref) {
  return UiPreferencesNotifier();
});

class UiPreferencesNotifier extends StateNotifier<UiPreferencesState> {
  static const String _subtleChatFeedbackKey = 'subtle_chat_feedback';
  static const String _fastRetryAnimationsKey = 'fast_retry_animations';

  UiPreferencesNotifier() : super(const UiPreferencesState()) {
    _load();
  }

  void _load() {
    try {
      final subtle = HiveService().settingsBox.get(_subtleChatFeedbackKey);
      final fast = HiveService().settingsBox.get(_fastRetryAnimationsKey);
      state = state.copyWith(
        subtleChatFeedback: subtle is bool ? subtle : state.subtleChatFeedback,
        fastRetryAnimations: fast is bool ? fast : state.fastRetryAnimations,
      );
    } catch (_) {
      // Keep defaults if local settings are unavailable.
    }
  }

  Future<void> setSubtleChatFeedback(bool value) async {
    state = state.copyWith(subtleChatFeedback: value);
    try {
      await HiveService().settingsBox.put(_subtleChatFeedbackKey, value);
    } catch (_) {
      // Non-blocking preference persistence.
    }
  }

  Future<void> setFastRetryAnimations(bool value) async {
    state = state.copyWith(fastRetryAnimations: value);
    try {
      await HiveService().settingsBox.put(_fastRetryAnimationsKey, value);
    } catch (_) {
      // Non-blocking preference persistence.
    }
  }

  Future<void> resetToDefaults() async {
    state = const UiPreferencesState();
    try {
      await HiveService().settingsBox.put(_subtleChatFeedbackKey, state.subtleChatFeedback);
      await HiveService().settingsBox.put(_fastRetryAnimationsKey, state.fastRetryAnimations);
    } catch (_) {
      // Non-blocking preference persistence.
    }
  }
}
