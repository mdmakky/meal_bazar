import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/errors.dart';
import '../../../core/supabase.dart';
import '../data/auth_repository.dart';
import '../domain/phone.dart';
import '../domain/profile.dart';

final authRepositoryProvider = Provider<AuthRepository>(
  (ref) => AuthRepository(ref.watch(supabaseClientProvider)),
);

/// Signed-in user id, or null when signed out.
final authStateProvider = StreamProvider<String?>(
  (ref) => ref.watch(authRepositoryProvider).authStateChanges(),
);

/// True after a password-reset link opened the app, until the new password
/// is saved. The router holds the user on `/auth/reset-password` meanwhile.
final passwordRecoveryProvider = NotifierProvider<PasswordRecovery, bool>(
  PasswordRecovery.new,
);

class PasswordRecovery extends Notifier<bool> {
  @override
  bool build() {
    final sub = ref
        .watch(authRepositoryProvider)
        .passwordRecoveryEvents()
        .listen((_) => state = true);
    ref.onDispose(sub.cancel);
    return false;
  }

  void clear() => state = false;
}

/// My profile; null when signed out.
final myProfileProvider = AsyncNotifierProvider<MyProfileNotifier, Profile?>(
  MyProfileNotifier.new,
);

class MyProfileNotifier extends AsyncNotifier<Profile?> {
  @override
  Future<Profile?> build() async {
    final uid = await ref.watch(authStateProvider.future);
    if (uid == null) return null;
    return ref.watch(authRepositoryProvider).fetchMyProfile();
  }

  /// Throws [AppFailure]; on success the new profile becomes the state.
  Future<void> save({String? fullName, String? locale}) async {
    final profile = await ref
        .read(authRepositoryProvider)
        .updateProfile(fullName: fullName, locale: locale);
    state = AsyncData(profile);
  }
}

// ── OTP sign-in flow ─────────────────────────────────────────────────────

enum OtpStep { enterPhone, codeSent, verifying, done }

class OtpState {
  const OtpState({
    this.step = OtpStep.enterPhone,
    this.phone,
    this.sending = false,
    this.resendIn = 0,
    this.failure,
  });

  final OtpStep step;

  /// E.164 number the code was sent to.
  final String? phone;

  /// True while a code is being (re)sent.
  final bool sending;

  /// Seconds until "resend code" is allowed again.
  final int resendIn;

  /// Last error, cleared on the next action.
  final AppFailure? failure;

  bool get canResend => step == OtpStep.codeSent && !sending && resendIn == 0;

  OtpState copyWith({
    OtpStep? step,
    String? phone,
    bool? sending,
    int? resendIn,
    AppFailure? failure,
  }) => OtpState(
    step: step ?? this.step,
    phone: phone ?? this.phone,
    sending: sending ?? this.sending,
    resendIn: resendIn ?? this.resendIn,
    failure: failure,
  );
}

const otpResendCooldown = 30;

/// Keep one screen watching this for the whole flow (it is auto-disposed).
final otpControllerProvider =
    NotifierProvider.autoDispose<OtpController, OtpState>(OtpController.new);

class OtpController extends Notifier<OtpState> {
  Timer? _timer;

  @override
  OtpState build() {
    ref.onDispose(() => _timer?.cancel());
    return const OtpState();
  }

  /// Validates [rawPhone] and sends a code to it.
  Future<void> sendCode(String rawPhone) async {
    final phone = normalizeBdPhone(rawPhone);
    if (phone == null) {
      state = state.copyWith(
        failure: const AppFailure(FailureKind.validation, 'phone'),
      );
      return;
    }
    await _send(phone);
  }

  Future<void> resend() async {
    if (!state.canResend) return;
    await _send(state.phone!);
  }

  Future<void> verify(String code) async {
    final token = code.trim();
    final phone = state.phone;
    if (state.step != OtpStep.codeSent || phone == null) return;
    if (!RegExp(r'^\d{6}$').hasMatch(token)) {
      state = state.copyWith(
        failure: const AppFailure(FailureKind.invalidOtp, 'format'),
      );
      return;
    }
    state = state.copyWith(step: OtpStep.verifying);
    try {
      await ref.read(authRepositoryProvider).verifyOtp(phone, token);
      if (!ref.mounted) return;
      _timer?.cancel();
      state = state.copyWith(step: OtpStep.done, resendIn: 0);
    } on AppFailure catch (f) {
      if (!ref.mounted) return;
      state = state.copyWith(step: OtpStep.codeSent, failure: f);
    }
  }

  /// Back to the phone field (e.g. "wrong number?").
  void changePhone() {
    _timer?.cancel();
    state = const OtpState();
  }

  Future<void> _send(String phone) async {
    state = state.copyWith(sending: true);
    try {
      await ref.read(authRepositoryProvider).sendOtp(phone);
      if (!ref.mounted) return;
      state = OtpState(
        step: OtpStep.codeSent,
        phone: phone,
        resendIn: otpResendCooldown,
      );
      _startCooldown();
    } on AppFailure catch (f) {
      if (!ref.mounted) return;
      state = state.copyWith(sending: false, failure: f);
    }
  }

  void _startCooldown() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      final left = state.resendIn - 1;
      state = state.copyWith(resendIn: left, failure: state.failure);
      if (left <= 0) t.cancel();
    });
  }
}
