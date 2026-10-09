import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../push/application/push_service.dart';
import '../data/message_repository.dart';

/// Threads in a mess with a message I haven't read (the More badge).
/// Refreshes when a push arrives while the app is open.
final unreadMessagesCountProvider = FutureProvider.family<int, String>((
  ref,
  messId,
) {
  ref.watch(pushArrivalProvider);
  return ref.watch(messageRepositoryProvider).unreadCount(messId);
});
