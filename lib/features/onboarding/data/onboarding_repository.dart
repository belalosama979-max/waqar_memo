import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/firebase/firebase_providers.dart';

/// Whether the onboarding has been completed on this device.
class OnboardingController extends Notifier<bool> {
  static const _key = 'onboarding.completed.v1';

  @override
  bool build() => ref.read(sharedPreferencesProvider).getBool(_key) ?? false;

  Future<void> complete() async {
    await ref.read(sharedPreferencesProvider).setBool(_key, true);
    state = true;
  }
}

final onboardingDoneProvider = NotifierProvider<OnboardingController, bool>(OnboardingController.new);
