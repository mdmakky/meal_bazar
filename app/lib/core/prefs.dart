import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Small per-mess device flags (setup checklist progress / dismissal).
/// Not synced: losing them only re-shows a hint.
final messFlagsProvider = FutureProvider.family<Set<String>, String>((
  ref,
  messId,
) async {
  final prefs = await SharedPreferences.getInstance();
  return {...?prefs.getStringList('flags:$messId')};
});

/// Sets [flag] for [messId]; a failure is ignored (it is only a hint).
Future<void> setMessFlag(WidgetRef ref, String messId, String flag) async {
  try {
    final prefs = await SharedPreferences.getInstance();
    final key = 'flags:$messId';
    final flags = {...?prefs.getStringList(key)};
    if (!flags.add(flag)) return;
    await prefs.setStringList(key, flags.toList());
    ref.invalidate(messFlagsProvider(messId));
  } catch (_) {}
}
