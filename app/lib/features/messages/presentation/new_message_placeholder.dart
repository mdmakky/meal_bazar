import 'package:flutter/material.dart';

import '../../../core/l10n/gen/app_localizations.dart';
import '../../../core/widgets/widgets.dart';
import '../domain/message_draft.dart';

/// `/more/messages/new` until the messages feature lands.
class NewMessagePlaceholder extends StatelessWidget {
  const NewMessagePlaceholder({super.key, this.draft});

  final MessageDraft? draft;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(l.reportProblem)),
      body: EmptyView(
        icon: Icons.forum_outlined,
        message: [?draft?.refLabel, l.messagesComingSoon].join('\n\n'),
      ),
    );
  }
}
