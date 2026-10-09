import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:meal_bazar/core/l10n/gen/app_localizations.dart';
import 'package:meal_bazar/core/theme/app_theme.dart';
import 'package:meal_bazar/features/audit/data/audit_repository.dart';
import 'package:meal_bazar/features/audit/domain/audit.dart';
import 'package:meal_bazar/features/audit/presentation/audit_screen.dart';
import 'package:meal_bazar/features/mess/application/mess_providers.dart';
import 'package:mocktail/mocktail.dart';

class MockAuditRepository extends Mock implements AuditRepository {}

class FixedMess extends CurrentMessId {
  @override
  String? build() => 'mess1';
}

final bn = lookupAppLocalizations(const Locale('bn'));
final en = lookupAppLocalizations(const Locale('en'));
const names = {'u-rahim': 'রহিম', 'm-karim': 'করিম', 'm-rahim': 'রহিম'};

AuditEntry entry(
  String entity,
  String action, {
  Map<String, dynamic>? oldRow,
  Map<String, dynamic>? newRow,
  String? actor = 'u-rahim',
  String? entityId,
  String source = 'app',
  String? reason,
}) => AuditEntry(
  id: 1,
  action: action,
  entity: entity,
  at: DateTime.utc(2026, 10, 8, 6),
  actorId: actor,
  entityId: entityId,
  oldRow: oldRow,
  newRow: newRow,
  source: source,
  reason: reason,
);

void main() {
  group('describeAudit', () {
    test('bazar insert with Bangla amount', () {
      expect(
        describeAudit(
          bn,
          entry('bazars', 'insert', newRow: {'amount': 1000}),
          names,
        ),
        'রহিম বাজার যোগ করেছেন ৳১,০০০',
      );
      expect(
        describeAudit(
          en,
          entry('bazars', 'insert', newRow: {'amount': 1000}),
          names,
        ),
        'রহিম added a bazar ৳1,000',
      );
    });

    test('soft delete reads as deleted', () {
      final e = entry(
        'expenses',
        'update',
        oldRow: {'amount': '250.50', 'deleted_at': null},
        newRow: {'amount': '250.50', 'deleted_at': '2026-10-08T06:00:00Z'},
      );
      expect(describeAudit(bn, e, names), 'রহিম খরচ মুছেছেন ৳২৫০.৫০');
    });

    test('deposit and meal name the member', () {
      expect(
        describeAudit(
          bn,
          entry(
            'deposits',
            'insert',
            newRow: {'member_id': 'm-karim', 'amount': 500},
          ),
          names,
        ),
        'রহিম করিম-এর জমা যোগ করেছেন ৳৫০০',
      );
      expect(
        describeAudit(
          bn,
          entry(
            'meal_entries',
            'update',
            newRow: {'member_id': 'm-karim', 'date': '2026-10-08'},
          ),
          names,
        ),
        'রহিম করিম-এর মিল বদলেছেন ৮ অক্টোবর ২০২৬',
      );
    });

    test('deposit verification and meal changes say what changed', () {
      expect(
        describeAudit(
          bn,
          entry(
            'deposits',
            'update',
            oldRow: {
              'member_id': 'm-karim',
              'amount': 500,
              'status': 'pending',
            },
            newRow: {
              'member_id': 'm-karim',
              'amount': 500,
              'status': 'verified',
            },
          ),
          names,
        ),
        'রহিম করিম-এর জমা যাচাই করেছেন ৳৫০০',
      );
      expect(
        describeAudit(
          bn,
          entry(
            'deposits',
            'update',
            oldRow: {
              'member_id': 'm-karim',
              'amount': 500,
              'status': 'pending',
            },
            newRow: {
              'member_id': 'm-karim',
              'amount': 500,
              'status': 'rejected',
            },
          ),
          names,
        ),
        'রহিম করিম-এর জমা বাতিল করেছেন ৳৫০০',
      );
      Map<String, dynamic> meal(num count, {bool off = false, int g = 0}) => {
        'member_id': 'm-karim',
        'date': '2026-10-08',
        'count': count,
        'is_off': off,
        'guest_count': g,
      };
      expect(
        describeAudit(
          bn,
          entry('meal_entries', 'update', oldRow: meal(1), newRow: meal(0.5)),
          names,
        ),
        'রহিম করিম-এর মিল বদলেছেন ৮ অক্টোবর ২০২৬ · ১ → ½',
      );
      expect(
        describeAudit(
          bn,
          entry('meal_entries', 'insert', newRow: meal(0, off: true, g: 2)),
          names,
        ),
        'রহিম করিম-এর মিল যোগ করেছেন ৮ অক্টোবর ২০২৬ · অফ +২',
      );
    });

    test('members, meal types, messes', () {
      expect(
        describeAudit(
          bn,
          entry('mess_members', 'insert', newRow: {'display_name': 'করিম'}),
          names,
        ),
        'রহিম সদস্য করিম যোগ করেছেন',
      );
      expect(
        describeAudit(
          bn,
          entry('meal_types', 'delete', oldRow: {'name': 'সকাল'}),
          names,
        ),
        'রহিম মিলের ধরন সকাল মুছেছেন',
      );
      expect(
        describeAudit(bn, entry('messes', 'update', newRow: {}), names),
        'রহিম মেসের সেটিংস বদলেছেন',
      );
    });

    test('duties, notices, monthly bills', () {
      expect(
        describeAudit(
          bn,
          entry(
            'bazar_duties',
            'insert',
            newRow: {'member_id': 'm-karim', 'date': '2026-10-12'},
          ),
          names,
        ),
        'রহিম করিম-এর বাজার ডিউটি যোগ করেছেন ১২ অক্টোবর ২০২৬',
      );
      expect(
        describeAudit(
          en,
          entry('announcements', 'insert', newRow: {'title': 'Rent'}),
          names,
        ),
        contains('notice Rent'),
      );
      expect(
        describeAudit(
          bn,
          entry('recurring_expenses', 'delete', oldRow: {'amount': 500}),
          names,
        ),
        'রহিম মাসিক বিল মুছেছেন ৳৫০০',
      );
    });

    test('months, account deletion, unknown actor, system, fallback', () {
      expect(
        describeAudit(
          bn,
          entry('months', 'close_month', newRow: {'start_date': '2026-09-01'}),
          names,
        ),
        'রহিম মাস বন্ধ করেছেন ১ সেপ্টেম্বর ২০২৬',
      );
      expect(
        describeAudit(
          bn,
          entry('months', 'reopen_month', newRow: {'start_date': '2026-09-01'}),
          names,
        ),
        'রহিম মাস আবার খুলেছেন ১ সেপ্টেম্বর ২০২৬',
      );
      expect(
        describeAudit(
          bn,
          entry('mess_members', 'delete_account', entityId: 'm-rahim'),
          names,
        ),
        'রহিম অ্যাকাউন্ট মুছে ফেলেছেন',
      );
      expect(
        describeAudit(
          bn,
          entry('bazars', 'insert', actor: 'gone', newRow: {'amount': 5}),
          names,
        ),
        'কেউ বাজার যোগ করেছেন ৳৫',
      );
      expect(
        describeAudit(
          bn,
          entry('expense_categories', 'insert', actor: null, newRow: {}),
          names,
        ),
        'সিস্টেম expense_categories যোগ করেছেন',
      );
    });
  });

  testWidgets('audit screen renders entries with AI chip and reason', (
    tester,
  ) async {
    final repo = MockAuditRepository();
    when(
      () => repo.page(
        'mess1',
        entities: any(named: 'entities'),
        offset: any(named: 'offset'),
        limit: any(named: 'limit'),
      ),
    ).thenAnswer(
      (_) async => [
        entry('bazars', 'insert', newRow: {'amount': 1000}, source: 'ai'),
        entry(
          'months',
          'reopen_month',
          newRow: {'start_date': '2026-09-01'},
          reason: 'ভুল বাজার ঠিক করতে',
        ),
      ],
    );
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          auditRepositoryProvider.overrideWithValue(repo),
          currentMessIdProvider.overrideWith(FixedMess.new),
          membersProvider('mess1').overrideWith((ref) async => []),
        ],
        child: MaterialApp(
          theme: AppTheme.light(),
          locale: const Locale('bn'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: const AuditScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('কেউ বাজার যোগ করেছেন ৳১,০০০'), findsOneWidget);
    expect(find.text('এআই'), findsOneWidget);
    expect(find.text('কারণ: ভুল বাজার ঠিক করতে'), findsOneWidget);
    expect(find.text('আরও দেখুন'), findsNothing); // fewer than one page

    await tester.tap(find.text('টাকা'));
    await tester.pumpAndSettle();
    verify(
      () => repo.page(
        'mess1',
        entities: ['bazars', 'expenses', 'deposits', 'months'],
        offset: 0,
        limit: 50,
      ),
    ).called(1);
  });
}
