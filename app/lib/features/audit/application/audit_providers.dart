import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../mess/application/mess_providers.dart';
import '../data/audit_repository.dart';
import '../domain/audit.dart';

const auditPageSize = 50;

class AuditPage {
  const AuditPage(this.items, {required this.hasMore});

  final List<AuditEntry> items;
  final bool hasMore;
}

/// The audit feed for (messId, filter); [AuditFeed.loadMore] appends a page.
final auditFeedProvider = AsyncNotifierProvider.autoDispose
    .family<AuditFeed, AuditPage, (String, AuditFilter)>(AuditFeed.new);

class AuditFeed extends AsyncNotifier<AuditPage> {
  AuditFeed(this.arg);

  final (String, AuditFilter) arg;
  var _loadingMore = false;

  Future<List<AuditEntry>> _fetch(int offset) {
    final (messId, filter) = arg;
    return ref
        .read(auditRepositoryProvider)
        .page(
          messId,
          entities: filter.entities,
          offset: offset,
          limit: auditPageSize,
        );
  }

  @override
  Future<AuditPage> build() async {
    final items = await _fetch(0);
    return AuditPage(items, hasMore: items.length == auditPageSize);
  }

  Future<void> loadMore() async {
    final current = state.value;
    if (current == null || !current.hasMore || _loadingMore) return;
    _loadingMore = true;
    try {
      final next = await _fetch(current.items.length);
      if (!ref.mounted) return;
      state = AsyncData(
        AuditPage([
          ...current.items,
          ...next,
        ], hasMore: next.length == auditPageSize),
      );
    } finally {
      _loadingMore = false;
    }
  }
}

/// User ids and member ids → display name, for [describeAudit].
final auditNamesProvider = Provider.autoDispose
    .family<Map<String, String>, String>((ref, messId) {
      final members = ref.watch(membersProvider(messId)).value ?? const [];
      return {
        for (final m in members) ...{
          m.id: m.displayName,
          if (m.userId != null) m.userId!: m.displayName,
        },
      };
    });

/// Member "my activity": the latest entries others made about me, edit
/// bursts folded (Home shows the first few, the full list the rest).
final myActivityProvider = FutureProvider.family<List<AuditEntry>, String>(
  (ref, messId) async => collapseActivity(
    await ref.watch(auditRepositoryProvider).myActivity(messId, limit: 100),
  ),
);
