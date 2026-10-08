import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import '../../../core/l10n/gen/app_localizations.dart';
import '../../../core/widgets/widgets.dart';
import '../../auth/application/auth_providers.dart';
import '../application/mess_providers.dart';
import '../domain/member.dart';
import 'common.dart';

/// First screen when the user has no mess yet.
class MessOnboardingScreen extends ConsumerWidget {
  const MessOnboardingScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final text = Theme.of(context).textTheme;
    return Scaffold(
      appBar: AppBar(
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: l.moreSignOut,
            onPressed: () => confirmSignOut(context, ref),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(AppSpace.gutter),
        children: [
          const SizedBox(height: AppSpace.xxl),
          Text(l.messOnboardingTitle, style: text.displaySmall),
          const SizedBox(height: AppSpace.md),
          Text(
            l.messOnboardingBody,
            style: text.bodyLarge?.copyWith(
              color: context.palette.inkSecondary,
            ),
          ),
        ],
      ),
      bottomNavigationBar: BottomAction(
        children: [
          AppButton(
            label: l.messCreateAction,
            icon: Icons.add,
            onPressed: () => context.push('/onboarding/create'),
          ),
          AppButton(
            label: l.messJoinAction,
            icon: Icons.qr_code,
            variant: AppButtonVariant.secondary,
            onPressed: () => context.push('/onboarding/join'),
          ),
        ],
      ),
    );
  }
}

/// Prefills [controller] with my profile name once it is known.
void _prefillMyName(WidgetRef ref, TextEditingController controller) {
  ref.listenManual(myProfileProvider, (_, next) {
    final name = next.value?.fullName ?? '';
    if (controller.text.isEmpty && name.isNotEmpty) controller.text = name;
  }, fireImmediately: true);
}

class CreateMessScreen extends ConsumerStatefulWidget {
  const CreateMessScreen({super.key});

  @override
  ConsumerState<CreateMessScreen> createState() => _CreateMessScreenState();
}

class _CreateMessScreenState extends ConsumerState<CreateMessScreen> {
  final _form = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _myName = TextEditingController();
  var _startDay = 1;
  var _saving = false;

  @override
  void initState() {
    super.initState();
    _prefillMyName(ref, _myName);
  }

  @override
  void dispose() {
    _name.dispose();
    _myName.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_saving || !_form.currentState!.validate()) return;
    setState(() => _saving = true);
    try {
      await ref
          .read(messControllerProvider)
          .createMess(
            name: _name.text,
            displayName: _myName.text,
            monthStartDay: _startDay,
          );
      if (mounted) context.go('/today');
    } catch (e) {
      if (!mounted) return;
      setState(() => _saving = false);
      showFailure(context, e);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    String? required(String? v) =>
        (v ?? '').trim().isEmpty ? l.messNameRequired : null;
    return Scaffold(
      appBar: AppBar(title: Text(l.messCreateTitle)),
      body: Form(
        key: _form,
        child: ListView(
          padding: const EdgeInsets.all(AppSpace.gutter),
          children: [
            TextFormField(
              controller: _name,
              autofocus: true,
              textInputAction: TextInputAction.next,
              decoration: InputDecoration(
                labelText: l.messNameLabel,
                hintText: l.messNameHint,
              ),
              validator: required,
            ),
            const SizedBox(height: AppSpace.lg),
            TextFormField(
              controller: _myName,
              textInputAction: TextInputAction.done,
              decoration: InputDecoration(
                labelText: l.messYourNameLabel,
                helperText: l.messYourNameHelp,
              ),
              validator: required,
              onFieldSubmitted: (_) => _submit(),
            ),
            const SizedBox(height: AppSpace.lg),
            MonthStartDayField(
              value: _startDay,
              onChanged: (d) => setState(() => _startDay = d),
            ),
          ],
        ),
      ),
      bottomNavigationBar: BottomAction(
        children: [
          AppButton(
            label: l.messCreateSubmit,
            loading: _saving,
            onPressed: _submit,
          ),
        ],
      ),
    );
  }
}

class JoinMessScreen extends ConsumerStatefulWidget {
  const JoinMessScreen({super.key, this.initialCode});

  /// From a deep link or `?code=`; ignored unless it holds a valid code.
  final String? initialCode;

  @override
  ConsumerState<JoinMessScreen> createState() => _JoinMessScreenState();
}

class _JoinMessScreenState extends ConsumerState<JoinMessScreen> {
  final _form = GlobalKey<FormState>();
  late final _code = TextEditingController(
    text: extractInviteCode(widget.initialCode ?? '') ?? '',
  );
  final _myName = TextEditingController();
  var _saving = false;

  @override
  void initState() {
    super.initState();
    _prefillMyName(ref, _myName);
  }

  @override
  void dispose() {
    _code.dispose();
    _myName.dispose();
    super.dispose();
  }

  Future<void> _scan() async {
    final l = AppLocalizations.of(context);
    final code = await AppSheet.show<String>(
      context,
      title: l.messScanTitle,
      child: const _ScannerBody(),
    );
    if (code != null && mounted) _code.text = code;
  }

  Future<void> _submit() async {
    if (_saving || !_form.currentState!.validate()) return;
    setState(() => _saving = true);
    try {
      await ref
          .read(messControllerProvider)
          .joinMess(code: _code.text, displayName: _myName.text);
      if (mounted) context.go('/pending');
    } catch (e) {
      if (!mounted) return;
      setState(() => _saving = false);
      showFailure(context, e);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final text = Theme.of(context).textTheme;
    return Scaffold(
      appBar: AppBar(title: Text(l.messJoinTitle)),
      body: Form(
        key: _form,
        child: ListView(
          padding: const EdgeInsets.all(AppSpace.gutter),
          children: [
            TextFormField(
              key: const Key('inviteCode'),
              controller: _code,
              autofocus: _code.text.isEmpty,
              textCapitalization: TextCapitalization.characters,
              autocorrect: false,
              enableSuggestions: false,
              inputFormatters: inviteCodeFormatters,
              textInputAction: TextInputAction.next,
              style: text.headlineSmall?.copyWith(
                letterSpacing: AppSpace.sm,
                fontFeatures: const [FontFeature.tabularFigures()],
              ),
              decoration: InputDecoration(
                labelText: l.messCodeLabel,
                helperText: l.messCodeHelp,
                hintText: 'ABC123',
              ),
              validator: (v) =>
                  (v ?? '').length == 6 ? null : l.messCodeInvalid,
            ),
            const SizedBox(height: AppSpace.md),
            Align(
              alignment: AlignmentDirectional.centerStart,
              child: AppButton(
                label: l.messScanQr,
                icon: Icons.qr_code_scanner,
                variant: AppButtonVariant.secondary,
                onPressed: _scan,
              ),
            ),
            const SizedBox(height: AppSpace.xl),
            TextFormField(
              controller: _myName,
              textInputAction: TextInputAction.done,
              decoration: InputDecoration(
                labelText: l.messYourNameLabel,
                helperText: l.messYourNameHelp,
              ),
              validator: (v) =>
                  (v ?? '').trim().isEmpty ? l.messNameRequired : null,
              onFieldSubmitted: (_) => _submit(),
            ),
          ],
        ),
      ),
      bottomNavigationBar: BottomAction(
        children: [
          AppButton(
            label: l.messJoinSubmit,
            loading: _saving,
            onPressed: _submit,
          ),
        ],
      ),
    );
  }
}

/// Camera preview; pops with the first valid invite code it sees.
class _ScannerBody extends StatefulWidget {
  const _ScannerBody();

  @override
  State<_ScannerBody> createState() => _ScannerBodyState();
}

class _ScannerBodyState extends State<_ScannerBody> {
  var _done = false;

  void _onDetect(BarcodeCapture capture) {
    if (_done) return;
    for (final b in capture.barcodes) {
      final code = extractInviteCode(b.rawValue ?? '');
      if (code != null) {
        _done = true;
        Navigator.pop(context, code);
        return;
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return Column(
      spacing: AppSpace.md,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(AppRadius.md),
          child: AspectRatio(
            aspectRatio: 1,
            child: MobileScanner(onDetect: _onDetect),
          ),
        ),
        Text(
          l.messScanHint,
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.bodyMedium,
        ),
      ],
    );
  }
}

class PendingApprovalScreen extends ConsumerStatefulWidget {
  const PendingApprovalScreen({super.key});

  @override
  ConsumerState<PendingApprovalScreen> createState() =>
      _PendingApprovalScreenState();
}

class _PendingApprovalScreenState extends ConsumerState<PendingApprovalScreen> {
  var _checking = false;

  Future<void> _refresh() async {
    final l = AppLocalizations.of(context);
    setState(() => _checking = true);
    try {
      final list = await ref.refresh(myMembershipsProvider.future);
      if (!mounted) return;
      final approved = list.any(
        (m) => m.mess != null && m.member.status == MemberStatus.active,
      );
      if (approved) {
        context.go('/today');
      } else {
        showSnack(context, l.messPendingStill);
      }
    } catch (e) {
      if (mounted) showFailure(context, e);
    } finally {
      if (mounted) setState(() => _checking = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final text = Theme.of(context).textTheme;
    final pending = (ref.watch(myMembershipsProvider).value ?? const []).where(
      (m) => m.member.status == MemberStatus.pending,
    );
    final messName =
        ref.watch(currentMembershipProvider)?.mess?.name ??
        pending.map((m) => m.mess?.name).nonNulls.firstOrNull;
    return Scaffold(
      appBar: AppBar(
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: l.moreSignOut,
            onPressed: () => confirmSignOut(context, ref),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _refresh,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(AppSpace.gutter),
          children: [
            const SizedBox(height: AppSpace.xxl),
            Icon(
              Icons.hourglass_empty,
              size: AppSize.emptyIcon,
              color: context.palette.inkTertiary,
            ),
            const SizedBox(height: AppSpace.lg),
            Text(l.messPendingTitle, style: text.headlineSmall),
            const SizedBox(height: AppSpace.md),
            Text(
              messName == null
                  ? l.messPendingBodyNoName
                  : l.messPendingBody(messName),
              style: text.bodyLarge?.copyWith(
                color: context.palette.inkSecondary,
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: BottomAction(
        children: [
          AppButton(
            label: l.messPendingRefresh,
            icon: Icons.refresh,
            loading: _checking,
            onPressed: _refresh,
          ),
          AppButton(
            label: l.messPendingJoinOther,
            variant: AppButtonVariant.text,
            onPressed: () => context.push('/onboarding/join'),
          ),
        ],
      ),
    );
  }
}
