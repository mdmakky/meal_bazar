import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/l10n/gen/app_localizations.dart';
import '../../core/widgets/widgets.dart';
import '../application/admin_providers.dart';
import 'common.dart';

/// Search box, a DataTable for one page, and prev/next. [load] maps the
/// query to a family provider; [columns]/[cells] render rows of type [T].
class PagedTable<T> extends ConsumerStatefulWidget {
  const PagedTable({
    super.key,
    required this.title,
    required this.searchHint,
    required this.load,
    required this.columns,
    required this.cells,
    required this.emptyMessage,
    this.actions = const [],
  });

  final String title;
  final String searchHint;
  final FutureProvider<List<T>> Function(PageQuery q) load;
  final List<String> columns;
  final List<Widget> Function(BuildContext context, T row) cells;
  final String emptyMessage;
  final List<Widget> actions;

  @override
  ConsumerState<PagedTable<T>> createState() => _PagedTableState<T>();
}

class _PagedTableState<T> extends ConsumerState<PagedTable<T>> {
  final _search = TextEditingController();
  PageQuery _q = (search: '', page: 0);

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final rows = ref.watch(widget.load(_q));
    final list = rows.value;
    return AdminPage(
      title: widget.title,
      actions: widget.actions,
      scroll: false,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: AppSpace.md,
        children: [
          TextField(
            controller: _search,
            decoration: InputDecoration(
              prefixIcon: const Icon(Icons.search),
              hintText: widget.searchHint,
            ),
            onSubmitted: (v) => setState(() => _q = (search: v, page: 0)),
          ),
          Expanded(
            child: rows.hasError && list == null
                ? ErrorView(
                    message: adminErrorText(context, rows.error!),
                    onRetry: () => ref.invalidate(widget.load(_q)),
                  )
                : list == null
                ? const LoadingView()
                : list.isEmpty
                ? EmptyView(
                    message: widget.emptyMessage,
                    icon: Icons.search_off,
                  )
                : SingleChildScrollView(
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: DataTable(
                        columns: [
                          for (final c in widget.columns)
                            DataColumn(label: Text(c)),
                        ],
                        rows: [
                          for (final r in list)
                            DataRow(
                              cells: [
                                for (final c in widget.cells(context, r))
                                  DataCell(c),
                              ],
                            ),
                        ],
                      ),
                    ),
                  ),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            spacing: AppSpace.sm,
            children: [
              Text(l.adminPage('${_q.page + 1}')),
              IconButton(
                tooltip: l.back,
                icon: const Icon(Icons.chevron_left),
                onPressed: _q.page == 0
                    ? null
                    : () => setState(
                        () => _q = (search: _q.search, page: _q.page - 1),
                      ),
              ),
              IconButton(
                tooltip: l.next,
                icon: const Icon(Icons.chevron_right),
                // A short page is the last one.
                onPressed: (list?.length ?? 0) < adminPageSize
                    ? null
                    : () => setState(
                        () => _q = (search: _q.search, page: _q.page + 1),
                      ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
