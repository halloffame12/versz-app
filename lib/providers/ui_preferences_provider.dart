import 'package:flutter_riverpod/flutter_riverpod.dart';

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
  UiPreferencesNotifier() : super(const UiPreferencesState());

  Future<void> setSubtleChatFeedback(bool value) async {
    state = state.copyWith(subtleChatFeedback: value);
  }

  Future<void> setFastRetryAnimations(bool value) async {
    state = state.copyWith(fastRetryAnimations: value);
  }

  Future<void> resetToDefaults() async {
    state = const UiPreferencesState();
  }
}
