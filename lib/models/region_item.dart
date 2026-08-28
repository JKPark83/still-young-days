/// Item kind. Unknown values throw — schema violations must not pass silently.
enum ItemType {
  job,
  event;

  static ItemType parse(Object? raw) {
    return switch (raw) {
      'job' => ItemType.job,
      'event' => ItemType.event,
      _ => throw FormatException('Unknown item type: $raw'),
    };
  }
}

/// One region-scoped item (job now, welfare event in P4).
/// Mirrors the shared JSON schema (schemaVersion 1) exactly.
class RegionItem {
  const RegionItem({
    required this.type,
    required this.id,
    required this.title,
    required this.place,
    required this.address,
    required this.phone,
    required this.org,
    required this.description,
    required this.age,
    required this.applyStart,
    required this.applyEnd,
    required this.source,
    required this.sourceUrl,
  });

  final ItemType type;
  final String id;
  final String title;
  final String? place;
  final String? address;
  final String? phone;
  final String? org;
  final String? description;
  final String? age;
  final String? applyStart; // "YYYY-MM-DD"
  final String? applyEnd;
  final String source;
  final String? sourceUrl;

  bool get hasPhone => phone != null && phone!.trim().isNotEmpty;

  factory RegionItem.fromJson(Map<String, dynamic> json) {
    String? str(String key) {
      final v = json[key];
      if (v == null) return null;
      final s = v.toString().trim();
      return s.isEmpty ? null : s;
    }

    return RegionItem(
      type: ItemType.parse(json['type']),
      id: json['id'] as String,
      title: json['title'] as String,
      place: str('place'),
      address: str('address'),
      phone: str('phone'),
      org: str('org'),
      description: str('description'),
      age: str('age'),
      applyStart: str('applyStart'),
      applyEnd: str('applyEnd'),
      source: json['source'] as String,
      sourceUrl: str('sourceUrl'),
    );
  }
}

/// Top-level feed for one region.
class RegionFeed {
  const RegionFeed({
    required this.schemaVersion,
    required this.regionCode,
    required this.regionName,
    required this.generatedAt,
    required this.items,
    this.fromCache = false,
  });

  final int schemaVersion;
  final String regionCode;
  final String regionName;
  final DateTime generatedAt;
  final List<RegionItem> items;

  /// True when the network failed and this feed came from the local cache.
  /// Runtime-only; not part of the JSON schema.
  final bool fromCache;

  factory RegionFeed.fromJson(Map<String, dynamic> json) {
    final version = json['schemaVersion'] as int;
    if (version != 1) {
      throw FormatException('Unsupported schemaVersion: $version');
    }
    return RegionFeed(
      schemaVersion: version,
      regionCode: json['regionCode'] as String,
      regionName: json['regionName'] as String,
      generatedAt: DateTime.parse(json['generatedAt'] as String),
      items: (json['items'] as List<dynamic>)
          .map((e) => RegionItem.fromJson(e as Map<String, dynamic>))
          .toList(growable: false),
    );
  }

  RegionFeed copyWith({List<RegionItem>? items, bool? fromCache}) =>
      RegionFeed(
        schemaVersion: schemaVersion,
        regionCode: regionCode,
        regionName: regionName,
        generatedAt: generatedAt,
        items: items ?? this.items,
        fromCache: fromCache ?? this.fromCache,
      );
}
