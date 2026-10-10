import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/failure_text.dart';
import '../../../core/l10n/gen/app_localizations.dart';
import '../../../core/widgets/widgets.dart';

const codeResendCooldown = 60;

/// Big centered field for the one-time code from an auth email.
class EmailCodeField extends StatelessWidget {
  const EmailCodeField({
    super.key,
    required this.controller,
    this.errorText,
    this.autofocus = false,
    this.onChanged,
  });

  final TextEditingController controller;
  final String? errorText;
  final bool autofocus;
  final ValueChanged<String>? onChanged;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      autofocus: autofocus,
      keyboardType: TextInputType.number,
      textAlign: TextAlign.center,
      maxLength: 10,
      autofillHints: const [AutofillHints.oneTimeCode],
      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
      style: Theme.of(
        context,
      ).textTheme.headlineMedium?.copyWith(letterSpacing: 6),
      onChanged: onChanged,
      decoration: InputDecoration(
        labelText: AppLocalizations.of(context).authCodeEmailLabel,
        errorText: errorText,
        counterText: '',
      ),
    );
  }
}

/// "Send the code again" with a countdown; the code was just sent, so it
/// starts disabled. [onResend] failures show as a snack.
class ResendCodeButton extends StatefulWidget {
  const ResendCodeButton({
    super.key,
    required this.onResend,
    this.enabled = true,
  });

  final Future<void> Function() onResend;
  final bool enabled;

  @override
  State<ResendCodeButton> createState() => _ResendCodeButtonState();
}

class _ResendCodeButtonState extends State<ResendCodeButton> {
  int _left = codeResendCooldown;
  bool _sending = false;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _startCooldown();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _startCooldown() {
    _timer?.cancel();
    setState(() => _left = codeResendCooldown);
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      setState(() => _left--);
      if (_left <= 0) t.cancel();
    });
  }

  Future<void> _resend() async {
    final l = AppLocalizations.of(context);
    setState(() => _sending = true);
    try {
      await widget.onResend();
      if (!mounted) return;
      AppSnack.show(context, l.authCodeResent);
      _startCooldown();
    } catch (e) {
      if (mounted) {
        AppSnack.show(
          context,
          failureText(context, e),
          icon: Icons.error_outline,
        );
      }
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return AppButton(
      key: const Key('resendCode'),
      variant: AppButtonVariant.text,
      loading: _sending,
      label: _left > 0 ? l.authCodeResendIn(_left) : l.authCodeResend,
      onPressed: _left > 0 || !widget.enabled ? null : _resend,
    );
  }
}
