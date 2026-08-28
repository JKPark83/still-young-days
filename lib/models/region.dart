/// 시/도 with its 시군구 list. Codes are 법정동 codes (2 / 5 digits).
class Sido {
  const Sido({required this.code, required this.name, required this.sigungu});

  final String code;
  final String name;
  final List<Sigungu> sigungu;

  factory Sido.fromJson(Map<String, dynamic> json) => Sido(
    code: json['code'] as String,
    name: json['name'] as String,
    sigungu: (json['sigungu'] as List<dynamic>)
        .map((e) => Sigungu.fromJson(e as Map<String, dynamic>))
        .toList(growable: false),
  );
}

class Sigungu {
  const Sigungu({required this.code, required this.name});

  final String code;
  final String name;

  factory Sigungu.fromJson(Map<String, dynamic> json) =>
      Sigungu(code: json['code'] as String, name: json['name'] as String);
}
