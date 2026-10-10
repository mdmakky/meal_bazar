import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import '../../../core/l10n/gen/app_localizations.dart';
import '../../../core/platform/platform_widgets.dart';
import '../../../core/widgets/widgets.dart';
import '../../auth/application/auth_providers.dart';
import '../application/mess_providers.dart';
import '../domain/invite_preview.dart';
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
      body: StaggeredList(
        child: ListView(
          padding: const EdgeInsets.all(AppSpace.gutter),
          children: StaggeredList.wrap([
            const Padding(
              padding: EdgeInsets.only(top: AppSpace.xl),
              child: Align(
                alignment: AlignmentDirectional.centerStart,
                child: BrandMark(size: 64),
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(top: AppSpace.xl),
              child: Text(l.messOnboardingTitle, style: text.displaySmall),
            ),
            Padding(
              padding: const EdgeInsets.only(top: AppSpace.md),
              child: Text(
                l.messOnboardingBody,
                style: text.bodyLarge?.copyWith(
                  color: context.palette.inkSecondary,
                ),
              ),
            ),
          ]),
        ),
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
            AppCard.raised(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
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

  /// The code from the deep link, previewed before joining; null when typed.
  late final String? _linkCode = extractInviteCode(widget.initialCode ?? '');

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
      final preview = _linkCode == null
          ? null
          : ref.read(invitePreviewProvider(_linkCode)).value;
      await ref
          .read(messControllerProvider)
          .joinMess(code: _code.text, displayName: _myName.text);
      if (!mounted) return;
      if (preview?.valid == true && preview!.autoApprove) {
        // Active at once: wait for the fresh memberships, then go home.
        final l = AppLocalizations.of(context);
        await ref.read(myMembershipsProvider.future);
        if (!mounted) return;
        showSnack(context, l.inviteJoined);
        context.go('/today');
      } else {
        // A link code typed by hand also activates; the router sends active
        // members on from /pending.
        context.go('/pending');
      }
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
    final linkCode = _linkCode;
    final preview = linkCode == null
        ? null
        : ref.watch(invitePreviewProvider(linkCode));
    final good = preview?.value?.valid == true ? preview!.value! : null;
    return Scaffold(
      appBar: AppBar(title: Text(l.messJoinTitle)),
      body: Form(
        key: _form,
        child: ListView(
          padding: const EdgeInsets.all(AppSpace.gutter),
          children: [
            if (preview != null) ...[
              preview.when(
                loading: () => const Padding(
                  padding: EdgeInsets.all(AppSpace.lg),
                  child: Center(child: CircularProgressIndicator()),
                ),
                // Offline or unreachable: fall back to the manual form.
                error: (_, _) => const SizedBox.shrink(),
                data: (p) => _InvitePreviewCard(p),
              ),
              const SizedBox(height: AppSpace.md),
            ],
            if (good == null)
              AppCard.raised(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
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
                      validator: (v) {
                        final n = (v ?? '').length;
                        return n >= 6 && n <= 12 ? null : l.messCodeInvalid;
                      },
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
                  ],
                ),
              ),
            if (good == null) const SizedBox(height: AppSpace.md),
            AppCard.raised(
              child: TextFormField(
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
            ),
          ],
        ),
      ),
      bottomNavigationBar: BottomAction(
        children: [
          AppButton(
            label: good?.autoApprove == true
                ? l.inviteJoinNow
                : l.messJoinSubmit,
            loading: _saving,
            onPressed: _submit,
          ),
        ],
      ),
    );
  }
}

/// Who invited me, or a calm reason the invite no longer works.
class _InvitePreviewCard extends StatelessWidget {
  const _InvitePreviewCard(this.preview);

  final InvitePreview preview;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final text = Theme.of(context).textTheme;
    final p = context.palette;
    final pv = preview;
    final String title;
    String? sub;
    if (pv.valid) {
      title = l.inviteCardTitle(pv.inviterName ?? '', pv.messName ?? '');
      if (pv.inviteeName != null) sub = l.inviteCardFor(pv.inviteeName!);
    } else {
      title = switch (pv.reason) {
        'used' => l.inviteReasonUsed,
        'expired' => l.inviteReasonExpired,
        'revoked' => l.inviteReasonRevoked,
        _ => l.inviteReasonUnknown,
      };
    }
    return AppCard.raised(
      key: const Key('invitePreview'),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        spacing: AppSpace.md,
        children: [
          Icon(
            pv.valid ? Icons.mark_email_read_outlined : Icons.link_off,
            color: p.inkSecondary,
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: text.titleMedium),
                if (sub != null)
                  Text(
                    sub,
                    style: text.bodyMedium?.copyWith(color: p.inkSecondary),
                  ),
              ],
            ),
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
        AppSnack.show(context, l.messPendingStill, icon: Icons.hourglass_top);
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
    final p = context.palette;
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
            Align(
              alignment: AlignmentDirectional.centerStart,
              child: CircleAvatar(
                radius: 28,
                backgroundColor: p.accentSoft,
                child: Icon(Icons.hourglass_top, color: p.ink),
              ),
            ),
            const SizedBox(height: AppSpace.xl),
            Text(l.messPendingTitle, style: text.displaySmall),
            const SizedBox(height: AppSpace.xl),
            // Calm "still waiting": the one breathing dot, nothing spinning.
            AppCard.raised(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                spacing: AppSpace.md,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(top: AppSpace.sm),
                    child: Transform.scale(
                      scale: 1.5,
                      child: AnimatedSyncDot(color: p.accent),
                    ),
                  ),
                  Expanded(
                    child: Text(
                      messName == null
                          ? l.messPendingBodyNoName
                          : l.messPendingBody(messName),
                      style: text.bodyLarge?.copyWith(color: p.inkSecondary),
                    ),
                  ),
                ],
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
