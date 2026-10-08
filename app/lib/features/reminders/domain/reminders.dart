import 'package:timezone/timezone.dart' as tz;

/// Mess times (cutoff, reminders) are Bangladesh wall-clock time.
tz.Location get dhaka => tz.getLocation('Asia/Dhaka');

enum ReminderKind {
  cutoff(1, '/today'),
  nudge(2, '/meals'),
  duty(0, '/today');

  const ReminderKind(this.id, this.route);

  /// Notification id for the daily kinds; duty ids come from [dutyId].
  final int id;

  /// Opened when the notification is tapped.
  final String route;
}

/// Which reminders the user wants; all on by default.
class ReminderSettings {
  const ReminderSettings({
    this.cutoff = true,
    this.nudge = true,
    this.duty = true,
  });

  final bool cutoff;
  final bool nudge;
  final bool duty;

  bool of(ReminderKind k) => switch (k) {
    ReminderKind.cutoff => cutoff,
    ReminderKind.nudge => nudge,
    ReminderKind.duty => duty,
  };

  ReminderSettings toggled(ReminderKind k, bool on) => ReminderSettings(
    cutoff: k == ReminderKind.cutoff ? on : cutoff,
    nudge: k == ReminderKind.nudge ? on : nudge,
    duty: k == ReminderKind.duty ? on : duty,
  );
}

/// One daily notification to schedule.
class DailyReminder {
  const DailyReminder(this.kind, this.at);

  final ReminderKind kind;

  /// First fire time; it then repeats at the same time every day.
  final tz.TZDateTime at;
}

const cutoffLead = Duration(minutes: 30);
const nudgeHour = 21;
const dutyHour = 20;

/// The next [hour]:[minute] in Dhaka strictly after [now].
tz.TZDateTime nextDaily(DateTime now, int hour, int minute) {
  final n = tz.TZDateTime.from(now, dhaka);
  var at = tz.TZDateTime(dhaka, n.year, n.month, n.day, hour, minute);
  if (!at.isAfter(n)) at = at.add(const Duration(days: 1));
  return at;
}

/// Postgres `time` like '22:00:00' → minutes since midnight. Falls back to
/// the 22:00 default on garbage.
int cutoffMinutes(String cutoff) {
  final p = cutoff.split(':');
  final h = p.isNotEmpty ? int.tryParse(p[0]) : null;
  final m = p.length > 1 ? int.tryParse(p[1]) : 0;
  if (h == null || m == null || h < 0 || h > 23 || m < 0 || m > 59) {
    return 22 * 60;
  }
  return h * 60 + m;
}

/// [cutoffLead] before the mess's daily meal-off cutoff.
tz.TZDateTime nextCutoffReminder(DateTime now, String cutoff) {
  final mins = (cutoffMinutes(cutoff) - cutoffLead.inMinutes) % (24 * 60);
  return nextDaily(now, mins ~/ 60, mins % 60);
}

/// Daily reminders for an active member; managers also get the nudge.
List<DailyReminder> planDaily({
  required DateTime now,
  required String cutoff,
  required bool isManager,
  required ReminderSettings settings,
}) => [
  if (settings.cutoff)
    DailyReminder(ReminderKind.cutoff, nextCutoffReminder(now, cutoff)),
  if (isManager && settings.nudge)
    DailyReminder(ReminderKind.nudge, nextDaily(now, nudgeHour, 0)),
];

/// [dutyHour] on the evening before [date] (a calendar day), Dhaka time.
tz.TZDateTime dutyReminderAt(DateTime date) =>
    tz.TZDateTime(dhaka, date.year, date.month, date.day - 1, dutyHour);

/// Stable per-day id (yyyymmdd) so rescheduling a duty replaces it.
int dutyId(DateTime date) => date.year * 10000 + date.month * 100 + date.day;

bool isDutyId(int id) => id > 10000000;
