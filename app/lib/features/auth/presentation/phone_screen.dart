import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/errors.dart';
import '../../../core/failure_text.dart';
import '../../../core/l10n/gen/app_localizations.dart';
import '../../../core/widgets/widgets.dart';
import '../application/auth_providers.dart';

/// Phone entry, then the 6-digit code, on one screen. The router leaves this
/// screen once the auth state turns signed in.
class PhoneScreen extends ConsumerStatefulWidget {
  const PhoneScreen({super.key});

  @override
  ConsumerState<PhoneScreen> createState() => _PhoneScreenState();
}

class _PhoneScreenState extends ConsumerState<PhoneScreen> {
  final _phone = TextEditingController();
  final _code = TextEditingController();

  @override
  void dispose() {
    _phone.dispose();
    _code.dispose();
    super.dispose();
  }

  OtpController get _ctrl => ref.read(otpControllerProvider.notifier);

  void _changePhone() {
    _code.clear();
    _ctrl.changePhone();
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final text = Theme.of(context).textTheme;
    final s = ref.watch(otpControllerProvider);
    final codeStep = s.step != OtpStep.enterPhone;
    final busy = s.sending || s.step == OtpStep.verifying;
    final failure = s.failure;
    final error = failure == null
        ? null
        : !codeStep && failure.kind == FailureKind.validation
        ? l.authPhoneInvalid
        : failureText(context, failure);

    final field = codeStep
        ? TextField(
            key: const Key('otp'),
            controller: _code,
            autofocus: true,
            enabled: s.step == OtpStep.codeSent,
            keyboardType: TextInputType.number,
            autofillHints: const [AutofillHints.oneTimeCode],
            inputFormatters: [
              FilteringTextInputFormatter.digitsOnly,
              LengthLimitingTextInputFormatter(6),
            ],
            style: text.titleMedium?.copyWith(
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
            decoration: InputDecoration(
              labelText: l.authCodeLabel,
              errorText: error,
            ),
            onChanged: (v) {
              if (v.length == 6) _ctrl.verify(v);
            },
          )
        : TextField(
            key: const Key('phone'),
            controller: _phone,
            autofocus: true,
            keyboardType: TextInputType.phone,
            autofillHints: const [AutofillHints.telephoneNumberNational],
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp('[0-9০-৯]')),
              LengthLimitingTextInputFormatter(11),
            ],
            style: text.titleMedium?.copyWith(
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
            decoration: InputDecoration(
              labelText: l.authPhoneLabel,
              prefixText: '+880 ',
              hintText: '1XXX-XXXXXX',
              errorText: error,
            ),
            onSubmitted: (v) => _ctrl.sendCode(v),
          );

    return Scaffold(
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(
                  AppSpace.gutter,
                  AppSpace.xxxl,
                  AppSpace.gutter,
                  AppSpace.gutter,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      codeStep ? l.authCodeTitle : l.authPhoneTitle,
                      style: text.headlineSmall,
                    ),
                    const SizedBox(height: AppSpace.sm),
                    Text(
                      codeStep
                          ? l.authCodeSentTo(s.phone ?? '')
                          : l.authPhoneHint,
                      style: text.bodyMedium,
                    ),
                    const SizedBox(height: AppSpace.xl),
                    field,
                    if (codeStep) ...[
                      const SizedBox(height: AppSpace.sm),
                      Wrap(
                        spacing: AppSpace.sm,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          if (s.resendIn > 0)
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                vertical: AppSpace.md,
                              ),
                              child: Text(
                                l.authResendIn(s.resendIn),
                                style: text.bodyMedium,
                              ),
                            )
                          else
                            TextButton(
                              onPressed: s.canResend ? _ctrl.resend : null,
                              child: Text(l.authResend),
                            ),
                          TextButton(
                            onPressed: busy ? null : _changePhone,
                            child: Text(l.authChangeNumber),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(AppSpace.gutter),
              child: AppButton(
                expand: true,
                loading: busy,
                label: codeStep ? l.authVerify : l.authSendCode,
                onPressed: codeStep
                    ? () => _ctrl.verify(_code.text)
                    : () => _ctrl.sendCode(_phone.text),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
