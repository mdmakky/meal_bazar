/// The bazar item picker's fixed catalogue: name and default unit.
/// Plain data (Bangla names are what messes write on their ফর্দ), no table.
enum BazarGroup { staples, veg, protein, spice }

typedef CatalogueItem = ({String name, String unit});

const bazarCatalogue = <BazarGroup, List<CatalogueItem>>{
  BazarGroup.staples: [
    (name: 'চাল', unit: 'কেজি'),
    (name: 'ডাল', unit: 'কেজি'),
    (name: 'আটা', unit: 'কেজি'),
    (name: 'সয়াবিন তেল', unit: 'লিটার'),
    (name: 'চিনি', unit: 'কেজি'),
    (name: 'লবণ', unit: 'কেজি'),
  ],
  BazarGroup.veg: [
    (name: 'আলু', unit: 'কেজি'),
    (name: 'পেঁয়াজ', unit: 'কেজি'),
    (name: 'টমেটো', unit: 'কেজি'),
    (name: 'বেগুন', unit: 'কেজি'),
    (name: 'কাঁচা মরিচ', unit: 'গ্রাম'),
    (name: 'শাক', unit: 'আঁটি'),
  ],
  BazarGroup.protein: [
    (name: 'ডিম', unit: 'হালি'),
    (name: 'মুরগি', unit: 'কেজি'),
    (name: 'রুই মাছ', unit: 'কেজি'),
    (name: 'গরুর মাংস', unit: 'কেজি'),
  ],
  BazarGroup.spice: [
    (name: 'হলুদ', unit: 'গ্রাম'),
    (name: 'মরিচ গুঁড়া', unit: 'গ্রাম'),
    (name: 'আদা', unit: 'গ্রাম'),
    (name: 'রসুন', unit: 'গ্রাম'),
    (name: 'গ্যাস সিলিন্ডার', unit: 'টি'),
  ],
};

/// A catalogue group from the platform config (named by the admin).
typedef CatalogueGroup = ({String name, List<CatalogueItem> items});

/// The catalogue unit for [name], if it is a catalogue item. [groups] is the
/// platform config's catalogue; null means the built-in one.
String? catalogueUnit(String name, [List<CatalogueGroup>? groups]) {
  final unit =
      (groups?.expand((g) => g.items) ?? bazarCatalogue.values.expand((g) => g))
          .where((i) => i.name == name)
          .firstOrNull
          ?.unit;
  return unit == null || unit.isEmpty ? null : unit;
}

/// Units offered by the item row's unit chooser (plus the catalogue's own).
const bazarUnits = [
  'কেজি',
  'গ্রাম',
  'লিটার',
  'পিস',
  'হালি',
  'ডজন',
  'আঁটি',
  'প্যাকেট',
  'টি',
];

/// The [n] most bought item names, most frequent first (ties by name).
List<String> frequentItems(Iterable<String> names, {int n = 6}) {
  final counts = <String, int>{};
  for (final raw in names) {
    final name = raw.trim();
    if (name.isNotEmpty) counts[name] = (counts[name] ?? 0) + 1;
  }
  final sorted = counts.keys.toList()
    ..sort((a, b) {
      final c = counts[b]!.compareTo(counts[a]!);
      return c != 0 ? c : a.compareTo(b);
    });
  return sorted.take(n).toList();
}
