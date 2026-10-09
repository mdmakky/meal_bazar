import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:meal_bazar/admin/data/admin_repository.dart';
import 'package:meal_bazar/admin/domain/admin_models.dart';
import 'package:meal_bazar/admin/presentation/ai_page.dart';
import 'package:mocktail/mocktail.dart';

import 'harness.dart';

const _models = [
  ModelInfo(
    provider: 'gemini',
    id: 'gemini-flash',
    free: true,
    vision: true,
    contextLength: 1000000,
  ),
  ModelInfo(
    provider: 'openrouter',
    id: 'or-free',
    free: true,
    contextLength: 32000,
    inputPrice: 0,
    outputPrice: 0,
  ),
  ModelInfo(
    provider: 'openrouter',
    id: 'or-paid',
    vision: true,
    contextLength: 200000,
    inputPrice: 3,
    outputPrice: 15,
  ),
];

const _saved = {
  'enabled': true,
  'text_chain': [
    {'provider': 'gemini', 'model': 'gemini-flash'},
    {'provider': 'openrouter', 'model': 'or-free'},
  ],
  'vision_chain': [
    {'provider': 'gemini', 'model': 'gemini-flash'},
  ],
  'quota_meal_draft': 30,
  'quota_bazar_draft': 10,
  'timeout_ms': 20000,
  'temperature': 0.2,
  'allow_paid': false,
};

void main() {
  late MockAdminRepository repo;

  setUpAll(registerAdminFallbacks);
  setUp(() {
    repo = MockAdminRepository();
    when(() => repo.models('all')).thenAnswer((_) async => _models);
    when(() => repo.setConfig(any(), any())).thenAnswer((_) async {});
  });

  Future<void> pump(WidgetTester t) =>
      pumpAdmin(t, const AiSettingsEditor(saved: _saved), repo: repo);

  Finder addToText() => find.text('Add to text chain');
  Finder rowsOf(String id) =>
      find.descendant(of: find.byType(DataTable), matching: find.text(id));

  testWidgets('catalogue filters: provider, vision, free', (t) async {
    await pump(t);
    expect(addToText(), findsNWidgets(3));

    await t.tap(find.text('OpenRouter'));
    await t.pumpAndSettle();
    expect(addToText(), findsNWidgets(2));
    expect(rowsOf('gemini-flash'), findsNothing);

    await t.tap(find.text('All'));
    await t.tap(find.widgetWithText(FilterChip, 'Vision'));
    await t.pumpAndSettle();
    expect(rowsOf('or-free'), findsNothing);
    expect(rowsOf('or-paid'), findsWidgets);

    await t.tap(find.widgetWithText(FilterChip, 'Free'));
    await t.pumpAndSettle();
    expect(rowsOf('gemini-flash'), findsWidgets);
    expect(rowsOf('or-paid'), findsNothing);

    await t.enterText(
      find.widgetWithText(TextField, 'Search models'),
      'nothing',
    );
    await t.pumpAndSettle();
    expect(find.text('No results'), findsOneWidget);
  });

  testWidgets('add to text chain, saved in the v3 shape', (t) async {
    await pump(t);
    // Rows sort by name: gemini-flash, or-free, or-paid.
    await tapVisible(t, addToText().at(1));
    expect(find.text('3/5'), findsOneWidget);
    final v = await saveAndCapture(t, repo, 'ai') as Map;
    expect(v['text_chain'], [
      {'provider': 'gemini', 'model': 'gemini-flash'},
      {'provider': 'openrouter', 'model': 'or-free'},
      {'provider': 'openrouter', 'model': 'or-free'},
    ]);
    expect(v['vision_chain'], _saved['vision_chain']);
    expect(
      v.keys,
      containsAll([
        'enabled',
        'quota_meal_draft',
        'timeout_ms',
        'temperature',
        'allow_paid',
      ]),
    );
    expect(v.containsKey('primary_model'), isFalse);
  });

  testWidgets('drag reorders the chain in the payload', (t) async {
    await pump(t);
    final handle = find.byIcon(Icons.drag_handle).first;
    final g = await t.startGesture(t.getCenter(handle));
    for (var i = 0; i < 10; i++) {
      await g.moveBy(const Offset(0, 20));
      await t.pump(const Duration(milliseconds: 16));
    }
    await g.up();
    await t.pumpAndSettle();
    final v = await saveAndCapture(t, repo, 'ai') as Map;
    expect(v['text_chain'], [
      {'provider': 'openrouter', 'model': 'or-free'},
      {'provider': 'gemini', 'model': 'gemini-flash'},
    ]);
  });

  testWidgets('remove empties a chain; an empty chain cannot be saved', (
    t,
  ) async {
    await pump(t);
    // Close buttons: text chain ×2, then vision chain ×1.
    await t.tap(find.byTooltip('Delete').at(2));
    await t.pumpAndSettle();
    await t.tap(find.text('Save'));
    await t.pumpAndSettle();
    expect(find.text('Each chain needs 1 to 5 models'), findsOneWidget);
    verifyNever(() => repo.setConfig(any(), any()));
  });

  testWidgets('paid model while allow_paid is off asks first', (t) async {
    await pump(t);
    await tapVisible(t, find.text('Add to vision chain').last); // or-paid

    await t.tap(find.text('Save'));
    await t.pumpAndSettle();
    expect(find.text('Save paid models?'), findsOneWidget);
    expect(find.textContaining('openrouter/or-paid'), findsOneWidget);
    await t.tap(find.text('Cancel'));
    await t.pumpAndSettle();
    verifyNever(() => repo.setConfig(any(), any()));

    await t.tap(find.text('Save'));
    await t.pumpAndSettle();
    await t.tap(find.text('Save anyway'));
    await t.pumpAndSettle();
    final v =
        verify(() => repo.setConfig('ai', captureAny())).captured.single as Map;
    expect((v['vision_chain'] as List).last, {
      'provider': 'openrouter',
      'model': 'or-paid',
    });
  });

  testWidgets('no warning once paid models are allowed', (t) async {
    await pump(t);
    await tapVisible(t, find.text('Add to vision chain').last);
    await t.tap(find.widgetWithText(SwitchListTile, 'Allow paid models'));
    await t.pumpAndSettle();
    final v = await saveAndCapture(t, repo, 'ai') as Map;
    expect(v['allow_paid'], true);
    expect(find.text('Save paid models?'), findsNothing);
  });

  testWidgets('test button shows latency and sample', (t) async {
    when(() => repo.testModel(any(), any(), any())).thenAnswer(
      (_) async =>
          const ModelTestResult(ok: true, latencyMs: 640, sample: 'pong'),
    );
    await pump(t);
    await tapVisible(t, find.text('Test').first);
    expect(find.text('OK · 640 ms · pong'), findsOneWidget);
  });

  testWidgets('missing gateway URL explains the fix', (t) async {
    when(
      () => repo.models('all'),
    ).thenAnswer((_) async => throw const GatewayNotConfigured());
    await pump(t);
    expect(find.textContaining('AI_GATEWAY_URL'), findsOneWidget);
    // Chains stay editable by hand.
    expect(find.text('Add model manually'), findsNWidgets(2));
  });
}
