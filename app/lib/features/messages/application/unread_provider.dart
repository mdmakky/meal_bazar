import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Unread member messages / open disputes for a mess. 0 until the messages
/// feature lands.
final unreadMessagesCountProvider = FutureProvider.family<int, String>(
  (ref, messId) async => 0,
);
