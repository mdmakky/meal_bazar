import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:meal_bazar/admin/domain/config_schema.dart';
import 'package:meal_bazar/admin/presentation/settings_page.dart';
import 'package:mocktail/mocktail.dart';

import 'harness.dart';

void main() {
  late MockAdminRepository repo;

  setUpAll(registerAdminFallbacks);
  setUp(() {
    repo = MockAdminRepository();
    when(() => repo.setConfig(any(), any())).thenAnswer((_) async {});
  });

  testWidgets('features: grouped switches, payload has every flag', (t) async {
    await pumpAdmin(
      t,
      const FeaturesEditor(saved: {'ai': true, 'legacy': 1}),
      repo: repo,
    );
    expect(find.text('Meals'), findsOneWidget);
    expect(find.text('Account and login'), findsOneWidget);
    expect(find.byType(SwitchListTile), findsNWidgets(30));

    await t.tap(find.widgetWithText(SwitchListTile, 'Guest meals'));
    await t.tap(find.widgetWithText(SwitchListTile, 'All AI features'));
    final v = await saveAndCapture(t, repo, 'features') as Map;
    expect(v['guest_meals'], false);
    expect(v['ai'], false);
    expect(v['notices'], true);
    expect(v['legacy'], 1);
    for (final f in allFlags) {
      expect(v[f], isA<bool>(), reason: f);
    }
  });

  testWidgets('app: edits fields; invalid version blocks the save', (t) async {
    await pumpAdmin(
      t,
      const AppConfigEditor(saved: {'min_version': '1.0.0'}),
      repo: repo,
    );
    await t.enterText(field('Minimum version'), '1.2');
    await t.tap(find.text('Save'));
    await t.pumpAndSettle();
    expect(find.text('Use a version like 1.2.3'), findsOneWidget);
    verifyNever(() => repo.setConfig(any(), any()));

    await t.enterText(field('Minimum version'), '1.2.0');
    await t.tap(find.widgetWithText(SwitchListTile, 'Maintenance mode'));
    await t.enterText(field('Support email'), 'help@mealbazar.app');
    await t.tap(find.widgetWithText(SwitchListTile, 'Show the banner on Home'));
    await t.tap(find.text('info'));
    await t.pumpAndSettle();
    await t.tap(find.text('critical').last);
    await t.pumpAndSettle();
    final v = await saveAndCapture(t, repo, 'app') as Map;
    expect(v['min_version'], '1.2.0');
    expect(v['maintenance'], true);
    expect(v['support_email'], 'help@mealbazar.app');
    expect(v['banner'], {
      'active': true,
      'text_bn': '',
      'text_en': '',
      'level': 'critical',
    });
    expect(v['latest_version'], '1.0.0');
  });

  testWidgets('defaults: meal types and categories list editors', (t) async {
    await pumpAdmin(
      t,
      const DefaultsEditor(
        saved: {
          'month_start_day': 1,
          'meal_off_cutoff': '22:00',
          'meal_types': [
            {'name': 'দুপুর', 'weight': 1, 'enabled': true},
          ],
          'expense_categories': [
            {'name': 'গ্যাস', 'split': 'equal'},
          ],
        },
      ),
      repo: repo,
    );
    await t.enterText(field('Month start day (1–28)'), '5');
    await t.tap(find.text('Add').first);
    await t.pumpAndSettle();
    await t.enterText(field('Name').at(1), 'রাত');
    await t.enterText(field('Weight').at(1), '0.5');
    // Second category, split by meals.
    await t.tap(find.text('Add').last);
    await t.pumpAndSettle();
    await t.enterText(field('Name').last, 'বুয়া');
    await t.tap(find.text('Equal').last);
    await t.pumpAndSettle();
    await t.tap(find.text('By meals').last);
    await t.pumpAndSettle();
    final v = await saveAndCapture(t, repo, 'defaults') as Map;
    expect(v['month_start_day'], 5);
    expect(v['meal_off_cutoff'], '22:00');
    expect(v['meal_types'], [
      {'name': 'দুপুর', 'weight': 1, 'enabled': true},
      {'name': 'রাত', 'weight': 0.5, 'enabled': true},
    ]);
    expect(v['expense_categories'], [
      {'name': 'গ্যাস', 'split': 'equal'},
      {'name': 'বুয়া', 'split': 'meal'},
    ]);
  });

  testWidgets('catalogue: add group and item, reorder groups', (t) async {
    await pumpAdmin(
      t,
      const CatalogueEditor(
        saved: {
          'groups': [
            {
              'name': 'চাল-ডাল',
              'items': [
                {'name': 'চাল', 'unit': 'কেজি'},
              ],
            },
          ],
        },
      ),
      repo: repo,
    );
    await t.tap(find.text('Add group'));
    await t.pumpAndSettle();
    await t.enterText(field('Group name').last, 'সবজি');
    await t.tap(find.text('Add item').last);
    await t.pumpAndSettle();
    await t.enterText(field('Name').last, 'আলু');
    await t.enterText(field('Unit').last, 'কেজি');
    // Tree order of "Move up": item চাল, group 1, item আলু, group 2.
    await t.tap(find.byTooltip('Move up').at(3));
    await t.pumpAndSettle();
    final v = await saveAndCapture(t, repo, 'catalogue') as Map;
    expect(v['groups'], [
      {
        'name': 'সবজি',
        'items': [
          {'name': 'আলু', 'unit': 'কেজি'},
        ],
      },
      {
        'name': 'চাল-ডাল',
        'items': [
          {'name': 'চাল', 'unit': 'কেজি'},
        ],
      },
    ]);
  });

  testWidgets('payment methods: fixed keys, labels and visibility', (t) async {
    await pumpAdmin(
      t,
      const PaymentMethodsEditor(
        saved: [
          {
            'key': 'cash',
            'label_bn': 'নগদ',
            'label_en': 'Cash',
            'enabled': true,
          },
        ],
      ),
      repo: repo,
    );
    expect(find.text('bkash'), findsWidgets);
    await t.enterText(field('Label (English)').at(1), 'bKash');
    await t.tap(find.byType(Switch).at(2)); // nagad off
    final v = await saveAndCapture(t, repo, 'payment_methods') as List;
    expect(v.map((e) => e['key']), paymentMethodKeys);
    expect(v[0], {
      'key': 'cash',
      'label_bn': 'নগদ',
      'label_en': 'Cash',
      'enabled': true,
    });
    expect(v[1]['label_en'], 'bKash');
    expect(v[2]['enabled'], false);
  });

  testWidgets('server validation error is shown under the section', (t) async {
    when(
      () => repo.setConfig(any(), any()),
    ).thenThrow(Exception('INVALID_CONFIG: bad'));
    await pumpAdmin(t, const FeaturesEditor(saved: {}), repo: repo);
    await t.ensureVisible(find.text('Save'));
    await t.tap(find.text('Save'));
    await t.pumpAndSettle();
    expect(find.textContaining('INVALID_CONFIG'), findsOneWidget);
  });
}
