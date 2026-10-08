import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:meal_bazar/core/errors.dart';
import 'package:meal_bazar/features/auth/application/auth_providers.dart';
import 'package:meal_bazar/features/auth/data/auth_repository.dart';
import 'package:mocktail/mocktail.dart';

class MockAuthRepository extends Mock implements AuthRepository {}

const phone = '+8801712345678';

void main() {
  late MockAuthRepository repo;
  late ProviderContainer container;
  late ProviderSubscription<OtpState> sub;

  OtpState read() => sub.read();
  OtpController ctrl() => container.read(otpControllerProvider.notifier);

  setUp(() {
    repo = MockAuthRepository();
    when(() => repo.sendOtp(any())).thenAnswer((_) async {});
    when(() => repo.verifyOtp(any(), any())).thenAnswer((_) async {});
    container = ProviderContainer(
      overrides: [authRepositoryProvider.overrideWithValue(repo)],
    );
    // Keep the auto-dispose provider alive for the whole test.
    sub = container.listen(otpControllerProvider, (_, _) {});
  });

  tearDown(() => container.dispose());

  test('invalid phone stays on enterPhone with validation failure', () async {
    await ctrl().sendCode('01212345678');
    expect(read().step, OtpStep.enterPhone);
    expect(read().failure?.kind, FailureKind.validation);
    verifyNever(() => repo.sendOtp(any()));
  });

  test('enterPhone → codeSent → verifying → done', () async {
    await ctrl().sendCode('01712-345678');
    verify(() => repo.sendOtp(phone)).called(1);
    expect(read().step, OtpStep.codeSent);
    expect(read().phone, phone);
    expect(read().resendIn, otpResendCooldown);

    final steps = <OtpStep>[];
    container.listen(otpControllerProvider, (_, s) => steps.add(s.step));
    await ctrl().verify('123456');
    verify(() => repo.verifyOtp(phone, '123456')).called(1);
    expect(steps, [OtpStep.verifying, OtpStep.done]);
  });

  test('wrong code returns to codeSent with invalidOtp', () async {
    when(
      () => repo.verifyOtp(any(), any()),
    ).thenThrow(const AppFailure(FailureKind.invalidOtp));
    await ctrl().sendCode(phone);
    await ctrl().verify('000000');
    expect(read().step, OtpStep.codeSent);
    expect(read().failure?.kind, FailureKind.invalidOtp);
  });

  test('malformed code is rejected without a network call', () async {
    await ctrl().sendCode(phone);
    await ctrl().verify('12ab');
    expect(read().failure?.kind, FailureKind.invalidOtp);
    verifyNever(() => repo.verifyOtp(any(), any()));
  });

  test('send failure stays on enterPhone', () async {
    when(
      () => repo.sendOtp(any()),
    ).thenThrow(const AppFailure(FailureKind.rateLimited));
    await ctrl().sendCode(phone);
    expect(read().step, OtpStep.enterPhone);
    expect(read().sending, isFalse);
    expect(read().failure?.kind, FailureKind.rateLimited);
  });

  test('resend is blocked during cooldown', () async {
    await ctrl().sendCode(phone);
    expect(read().canResend, isFalse);
    await ctrl().resend();
    verify(() => repo.sendOtp(phone)).called(1);
  });

  testWidgets('cooldown counts down to 0 and allows resend', (tester) async {
    await ctrl().sendCode(phone);
    await tester.pump(const Duration(seconds: 10));
    expect(read().resendIn, otpResendCooldown - 10);
    await tester.pump(const Duration(seconds: otpResendCooldown));
    expect(read().resendIn, 0);
    expect(read().canResend, isTrue);
    await ctrl().resend();
    verify(() => repo.sendOtp(phone)).called(2);
    container.dispose(); // cancel the new cooldown timer inside fake time
  });

  test('changePhone resets the flow', () async {
    await ctrl().sendCode(phone);
    ctrl().changePhone();
    expect(read().step, OtpStep.enterPhone);
    expect(read().phone, isNull);
  });
}
