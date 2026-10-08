import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/failure_text.dart';
import '../../../core/l10n/gen/app_localizations.dart';
import '../../../core/widgets/widgets.dart';
import '../../mess/application/mess_providers.dart';
import '../../mess/presentation/common.dart';
import '../../money/application/money_providers.dart';
import '../../money/presentation/months_screen.dart' show rangeLabel;
import '../../month/application/month_providers.dart';
import '../../month/domain/month.dart';
import 'export_actions.dart';

/// `/more/export`: pick the current or a closed month, export it as CSV.
class ExportScreen extends ConsumerStatefulWidget {
  const ExportScreen({super.key});

  @override
  ConsumerState<ExportScreen> createState() => _ExportScreenState();
}

class _ExportScreenState extends ConsumerState<ExportScreen> {
  DateTime? _picked;
  var _busy = false;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final messId = ref.watch(currentMessIdProvider);
    return Scaffold(
      appBar: AppBar(title: Text(l.exportTitle)),
      body: messId == null
          ? EmptyView(message: l.moneyNoMess)
          : ref
                .watch(currentPeriodProvider(messId))
                .when(
                  loading: () => const LoadingView(),
                  error: (e, _) => ErrorView(
                    message: failureText(context, e),
                    onRetry: () =>
                        ref.invalidate(currentPeriodProvider(messId)),
                  ),
                  data: (current) => _body(context, messId, current),
                ),
    );
  }

  Widget _body(BuildContext context, String messId, MonthPeriod current) {
    final l = AppLocalizations.of(context);
    // Closed months are optional extras; if they fail, the current one stays.
    final months = ref.watch(monthsProvider(messId)).value ?? const [];
    final options = <(MonthPeriod, String)>[
      (current, l.exportCurrent),
      for (final m in months)
        if (m.start != current.start)
          (
            MonthPeriod(m.start, m.end),
            m.closed ? l.monthStatusClosed : l.monthStatusOpen,
          ),
    ];
    final picked = options
        .firstWhere((o) => o.$1.start == _picked, orElse: () => options.first)
        .$1;
    return ListView(
      children: [
        Padding(
          padding: const EdgeInsets.all(AppSpace.gutter),
          child: Text(l.exportHint),
        ),
        SectionTitle(l.exportPeriod),
        const Divider(),
        for (final (p, label) in options) ...[
          ListTile(
            minTileHeight: AppSize.touch + AppSpace.md,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: AppSpace.gutter,
            ),
            title: Text(rangeLabel(context, p.start, p.end)),
            subtitle: Text(label),
            selected: p == picked,
            trailing: p == picked ? const Icon(Icons.check) : null,
            onTap: () => setState(() => _picked = p.start),
          ),
          const Divider(),
        ],
        Padding(
          padding: const EdgeInsets.all(AppSpace.gutter),
          child: AppButton(
            label: l.exportButton,
            icon: Icons.file_download_outlined,
            expand: true,
            loading: _busy,
            onPressed: () async {
              setState(() => _busy = true);
              await exportMonthCsv(context, messId: messId, period: picked);
              if (mounted) setState(() => _busy = false);
            },
          ),
        ),
      ],
    );
  }
}
