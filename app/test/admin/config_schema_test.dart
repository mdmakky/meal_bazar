import 'package:flutter/painting.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:meal_bazar/admin/domain/admin_models.dart';
import 'package:meal_bazar/admin/domain/config_schema.dart';

ModelInfo model(
  String id, {
  String provider = 'openrouter',
  bool free = false,
  bool vision = false,
  bool text = true,
  int ctx = 0,
  double? inPrice,
  double? outPrice,
}) => ModelInfo(
  provider: provider,
  id: id,
  name: id,
  free: free,
  vision: vision,
  text: text,
  contextLength: ctx,
  inputPrice: inPrice,
  outputPrice: outPrice,
);

void main() {
  test('feature list has all 30 flags (v2 + push + messages), each once', () {
    expect(allFlags.length, 30);
    expect(allFlags.toSet().length, 30);
    for (final f in [
      'ai',
      'push',
      'messages',
      'invite_qr',
      'offline_mode',
      'cook_share',
      'email_login',
    ]) {
      expect(allFlags, contains(f));
    }
  });

  test('features: missing flags default to true, unknown keys kept', () {
    final f = withDefaults('features', {'ai': false, 'legacy': 1}) as Map;
    expect(f['ai'], false);
    expect(f['notices'], true);
    expect(f['legacy'], 1);
  });

  test('payment methods: fixed keys in order, labels kept', () {
    final p =
        withDefaults('payment_methods', [
              {
                'key': 'bkash',
                'label_bn': 'বিকাশ',
                'label_en': 'bKash',
                'enabled': false,
              },
              {
                'key': 'bogus',
                'label_bn': 'x',
                'label_en': 'x',
                'enabled': true,
              },
            ])
            as List;
    expect(p.map((e) => e['key']), paymentMethodKeys);
    expect(p[1], {
      'key': 'bkash',
      'label_bn': 'বিকাশ',
      'label_en': 'bKash',
      'enabled': false,
    });
  });

  test('ai: v1 flat models become chains; v3 fields default', () {
    final ai =
        withDefaults('ai', {
              'enabled': false,
              'primary_model': 'gemini-2.5-flash',
              'fallback_model': 'openrouter/free',
              'quota_meal_draft': 5,
            })
            as Map;
    expect(ai['text_chain'], [
      {'provider': 'gemini', 'model': 'gemini-2.5-flash'},
      {'provider': 'openrouter', 'model': 'openrouter/free'},
    ]);
    expect(ai['vision_chain'], ai['text_chain']);
    expect(ai.containsKey('primary_model'), isFalse);
    expect(ai['enabled'], false);
    expect(ai['quota_meal_draft'], 5);
    expect(ai['timeout_ms'], 20000);
    expect(ai['allow_paid'], false);
  });

  test('app: nested banner merges over defaults', () {
    final app =
        withDefaults('app', {
              'banner': {'active': true},
            })
            as Map;
    expect(app['banner'], {
      'active': true,
      'text_bn': '',
      'text_en': '',
      'level': 'info',
    });
    expect(app['min_version'], '1.0.0');
  });

  test('validators', () {
    expect(version('1.2.3'), isNull);
    expect(version('1.2'), Invalid.version);
    expect(time('22:00'), isNull);
    expect(time('24:00'), Invalid.time);
    expect(intInRange('29', 1, 28), Invalid.range);
    expect(intInRange('x', 1, 28), Invalid.number);
    expect(optionalEmail(''), isNull);
    expect(optionalEmail('a@b'), Invalid.email);
    expect(optionalUrl('https://x.co/p'), isNull);
    expect(optionalUrl('x.co'), Invalid.url);
    expect(hexColor('#C98A0B'), isNull);
    expect(hexColor('C98A0B'), Invalid.hex);
    expect(positiveNumber('0'), Invalid.range);
  });

  test('contrast ratio matches WCAG', () {
    expect(
      contrastRatio(const Color(0xFF000000), const Color(0xFFFFFFFF)),
      closeTo(21, 0.01),
    );
    expect(
      contrastRatio(parseHex('#C98A0B')!, const Color(0xFFFFFFFF)),
      greaterThan(minAccentContrast - 0.5),
    );
    expect(parseHex('#zzzzzz'), isNull);
  });

  group('model filters', () {
    final all = [
      model('free-text', free: true, ctx: 8000),
      model('paid-vision', vision: true, ctx: 200000, inPrice: 3, outPrice: 15),
      model('cheap', ctx: 32000, inPrice: 0.1, outPrice: 0.4),
      model(
        'gemini-flash',
        provider: 'gemini',
        free: true,
        vision: true,
        ctx: 1000000,
      ),
    ];
    List<String> ids(ModelFilter f) =>
        filterModels(all, f).map((m) => m.id).toList();

    test('provider and search', () {
      expect(
        ids((
          provider: 'gemini',
          search: '',
          free: false,
          paid: false,
          vision: false,
          text: false,
          minContext: 0,
          maxPrice: null,
          sort: ModelSort.name,
          ascending: true,
        )),
        ['gemini-flash'],
      );
      expect(
        ids((
          provider: 'all',
          search: 'VISION',
          free: false,
          paid: false,
          vision: false,
          text: false,
          minContext: 0,
          maxPrice: null,
          sort: ModelSort.name,
          ascending: true,
        )),
        ['paid-vision'],
      );
    });

    test('free / paid / vision / context / price', () {
      ModelFilter f({
        bool free = false,
        bool paid = false,
        bool vision = false,
        int ctx = 0,
        double? max,
      }) => (
        provider: 'all',
        search: '',
        free: free,
        paid: paid,
        vision: vision,
        text: false,
        minContext: ctx,
        maxPrice: max,
        sort: ModelSort.name,
        ascending: true,
      );
      expect(ids(f(free: true)), ['free-text', 'gemini-flash']);
      expect(ids(f(paid: true)), ['cheap', 'paid-vision']);
      expect(ids(f(free: true, paid: true)).length, 4);
      expect(ids(f(vision: true)), ['gemini-flash', 'paid-vision']);
      expect(ids(f(ctx: 128000)), ['gemini-flash', 'paid-vision']);
      expect(ids(f(max: 1)), ['cheap', 'free-text', 'gemini-flash']);
    });

    test('sort by context descending', () {
      expect(
        ids((
          provider: 'all',
          search: '',
          free: false,
          paid: false,
          vision: false,
          text: false,
          minContext: 0,
          maxPrice: null,
          sort: ModelSort.context,
          ascending: false,
        )).first,
        'gemini-flash',
      );
    });
  });

  test('paidChainEntries finds paid models in either chain', () {
    final ai = {
      'text_chain': [
        {'provider': 'openrouter', 'model': 'paid-vision'},
        {'provider': 'gemini', 'model': 'gemini-flash'},
      ],
      'vision_chain': [
        {'provider': 'openrouter', 'model': 'paid-vision'},
      ],
    };
    final catalogue = [
      model('paid-vision', inPrice: 3, outPrice: 15),
      model('gemini-flash', provider: 'gemini', free: true),
    ];
    expect(paidChainEntries(ai, catalogue), ['openrouter/paid-vision']);
  });
}
