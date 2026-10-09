import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/failure_text.dart';
import '../../../core/ids.dart';
import '../../../core/l10n/gen/app_localizations.dart';
import '../../../core/widgets/widgets.dart';
import '../../mess/application/mess_providers.dart';
import '../../mess/domain/member.dart';
import '../../mess/presentation/common.dart';
import '../application/message_providers.dart';
import '../domain/message.dart';
import '../domain/message_draft.dart';
import 'messages_screens.dart';

/// Write to the managers (a member) or to a member (a manager). With a
/// [draft] it is a "report a problem" about that entry, prefilled. Sending
/// needs the network; on failure the text stays and the same ids are reused,
/// so a retry never makes a second thread.
class NewMessageScreen extends ConsumerStatefulWidget {
  const NewMessageScreen({super.key, this.draft});

  final MessageDraft? draft;

  @override
  ConsumerState<NewMessageScreen> createState() => _NewMessageState();
}

class _NewMessageState extends ConsumerState<NewMessageScreen> {
  final _form = GlobalKey<FormState>();
  late final TextEditingController _subject;
  late final TextEditingController _body;
  final _threadId = uuidV4();
  final _messageId = uuidV4();
  String? _member;
  var _sending = false;
  var _initialised = false;
  Object? _error;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_initialised) return;
    _initialised = true;
    final l = AppLocalizations.of(context);
    final label = widget.draft?.refLabel;
    _subject = TextEditingController(
      text: label == null ? '' : _clip(l.msgReportSubject(label)),
    );
    _body = TextEditingController(
      text: widget.draft == null ? '' : l.msgReportStarter,
    );
  }

  static String _clip(String s) => s.characters.length <= messageSubjectMax
      ? s
      : '${s.characters.take(messageSubjectMax - 1)}…';

  @override
  void dispose() {
    _subject.dispose();
    _body.dispose();
    super.dispose();
  }

  Future<void> _send(String messId, bool isManager) async {
    if (_sending || !_form.currentState!.validate()) return;
    setState(() {
      _sending = true;
      _error = null;
    });
    try {
      final id = await ref
          .read(messageControllerProvider)
          .start(
            threadId: _threadId,
            messageId: _messageId,
            messId: messId,
            subject: _subject.text,
            body: _body.text,
            memberId: isManager ? _member : null,
            draft: widget.draft,
          );
      if (!mounted) return;
      showSnack(context, AppLocalizations.of(context).msgSent);
      context.pushReplacement('/more/messages/$id');
    } catch (e) {
      if (mounted) {
        setState(() {
          _sending = false;
          _error = e;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final text = Theme.of(context).textTheme;
    final p = context.palette;
    final messId = ref.watch(currentMessIdProvider);
    final isManager = ref.watch(amIManagerProvider);
    final me = ref.watch(currentMembershipProvider)?.member.id;
    final draft = widget.draft;

    if (messId == null) {
      return Scaffold(
        appBar: AppBar(title: Text(l.msgNew)),
        body: EmptyView(message: l.emptyGeneric),
      );
    }
    final members = isManager
        ? ref.watch(membersProvider(messId))
        : const AsyncValue<List<Member>>.data([]);

    return Scaffold(
      appBar: AppBar(title: Text(draft == null ? l.msgNew : l.msgReport)),
      body: switch (members) {
        AsyncValue(:final error?) when !members.hasValue => ErrorView(
          message: failureText(context, error),
          onRetry: () => ref.invalidate(membersProvider(messId)),
        ),
        AsyncValue(:final value?) => Form(
          key: _form,
          child: ListView(
            padding: const EdgeInsets.all(AppSpace.gutter),
            children: [
              if (draft?.refLabel != null) ...[
                RefCard(type: draft!.refType, label: draft.refLabel!),
                const SizedBox(height: AppSpace.xl),
              ],
              if (isManager) ...[
                DropdownButtonFormField<String>(
                  key: const Key('msgMemberField'),
                  initialValue: _member,
                  isExpanded: true,
                  decoration: InputDecoration(labelText: l.msgTo),
                  items: [
                    for (final m in value)
                      if (m.id != me &&
                          m.hasAccount &&
                          (m.status == MemberStatus.active ||
                              m.status == MemberStatus.inactive))
                        DropdownMenuItem(
                          value: m.id,
                          child: Text(
                            m.displayName,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                  ],
                  validator: (v) => v == null ? l.msgMemberRequired : null,
                  onChanged: (id) => setState(() => _member = id),
                ),
                const SizedBox(height: AppSpace.lg),
              ] else ...[
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  spacing: AppSpace.md,
                  children: [
                    Icon(
                      Icons.info_outline,
                      size: AppSpace.xl,
                      color: p.inkSecondary,
                    ),
                    Expanded(
                      child: Text(
                        l.msgToManagers,
                        style: text.bodyMedium?.copyWith(color: p.inkSecondary),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpace.xl),
              ],
              TextFormField(
                key: const Key('msgSubjectField'),
                controller: _subject,
                maxLength: messageSubjectMax,
                textInputAction: TextInputAction.next,
                textCapitalization: TextCapitalization.sentences,
                decoration: InputDecoration(labelText: l.msgSubject),
                validator: (v) =>
                    (v ?? '').trim().isEmpty ? l.msgSubjectRequired : null,
              ),
              const SizedBox(height: AppSpace.md),
              TextFormField(
                key: const Key('msgBodyField'),
                controller: _body,
                maxLength: messageBodyMax,
                minLines: 4,
                maxLines: 10,
                textCapitalization: TextCapitalization.sentences,
                decoration: InputDecoration(
                  labelText: l.msgBody,
                  alignLabelWithHint: true,
                ),
                validator: (v) =>
                    (v ?? '').trim().isEmpty ? l.msgBodyRequired : null,
              ),
              if (_error != null) ...[
                const SizedBox(height: AppSpace.md),
                Text(
                  failureText(context, _error!),
                  key: const Key('msgSendError'),
                  style: text.bodyMedium?.copyWith(color: p.due),
                ),
              ],
            ],
          ),
        ),
        _ => const LoadingView(),
      },
      bottomNavigationBar: members.hasValue
          ? BottomAction(
              children: [
                AppButton(
                  key: const Key('msgSendButton'),
                  label: l.msgSend,
                  icon: Icons.send_rounded,
                  loading: _sending,
                  onPressed: () => _send(messId, isManager),
                ),
              ],
            )
          : null,
    );
  }
}
