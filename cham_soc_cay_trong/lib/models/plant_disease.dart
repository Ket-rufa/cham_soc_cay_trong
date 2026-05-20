import 'dart:convert';

class PlantDisease {
  final String id;
  final String name;
  final String englishName;
  final String shortDescription;
  final String symptoms;
  final String causes;
  final String prevention;
  final String treatment;
  final String mainImageUrl;
  final List<String> galleryImageUrls;
  final List<SusceptiblePlant> susceptiblePlants;
  final String type;

  const PlantDisease({
    required this.id,
    required this.name,
    required this.englishName,
    required this.shortDescription,
    required this.symptoms,
    required this.causes,
    required this.prevention,
    required this.treatment,
    required this.mainImageUrl,
    this.galleryImageUrls = const [],
    this.susceptiblePlants = const [],
    this.type = '',
  });

  factory PlantDisease.fromJson(Map<String, dynamic> json) {
    final rawName = _readString(json, const [
      'name',
      'disease_name',
      'diseaseName',
    ]);
    final nameParts = _DiseaseNameParts.from(rawName);
    final symptoms = _readString(json, const ['symptoms']);
    final causes = _readString(json, const ['causes']);
    final prevention = _readString(json, const ['prevention']);
    final treatment = _readString(json, const ['treatment']);
    final id = _readString(json, const ['id']);
    final englishName = _readString(json, const [
      'englishName',
      'english_name',
    ]).isNotEmpty
        ? _readString(json, const ['englishName', 'english_name'])
        : nameParts.englishName;
    final mainImageUrl = _readString(json, const [
      'mainImageUrl',
      'main_image_url',
      'imageUrl',
      'image_url',
    ]);
    final galleryImageUrls = _readStringList(_readValue(json, const [
      'galleryImageUrls',
      'gallery_image_urls',
      'galleryImages',
      'gallery_images',
      'gallery',
    ]));
    final localAssets = _DiseaseAssetSet.fromDiseaseName(
      name: nameParts.name,
      englishName: englishName,
      rawName: rawName,
    );

    return PlantDisease(
      id: id.isNotEmpty
          ? id
          : _slugify('${nameParts.name}-${nameParts.englishName}'),
      name: nameParts.name.isNotEmpty ? nameParts.name : 'Chưa cập nhật',
      englishName: englishName,
      shortDescription: _buildShortDescription(json, symptoms, causes),
      symptoms: symptoms,
      causes: causes,
      prevention: prevention,
      treatment: treatment,
      mainImageUrl:
          mainImageUrl.isNotEmpty ? mainImageUrl : localAssets.mainImageUrl,
      galleryImageUrls: galleryImageUrls.isNotEmpty
          ? galleryImageUrls
          : localAssets.galleryImageUrls,
      susceptiblePlants: _readSusceptiblePlants(json),
      type: _readString(json, const ['type']),
    );
  }

  bool get isDisease {
    final normalizedType = type.toLowerCase();
    final normalizedName = name.toLowerCase();
    return normalizedType.contains('bệnh') || normalizedName.startsWith('bệnh');
  }

  static String _buildShortDescription(
    Map<String, dynamic> json,
    String symptoms,
    String causes,
  ) {
    final configured = _readString(json, const [
      'shortDescription',
      'short_description',
      'description',
    ]);
    if (configured.isNotEmpty) {
      return configured;
    }
    if (symptoms.isNotEmpty) {
      return _limitSummary(symptoms);
    }
    if (causes.isNotEmpty) {
      return _limitSummary(causes);
    }
    return 'Chưa có mô tả tóm tắt.';
  }

  static String _limitSummary(String value) {
    final normalized = value.trim().replaceAll(RegExp(r'\s+'), ' ');
    const maxLength = 170;
    if (normalized.length <= maxLength) {
      return normalized;
    }

    final lastSpace = normalized.lastIndexOf(' ', maxLength - 3);
    final endIndex = lastSpace > 80 ? lastSpace : maxLength - 3;
    return '${normalized.substring(0, endIndex).trimRight()}...';
  }

  static List<SusceptiblePlant> _readSusceptiblePlants(
    Map<String, dynamic> json,
  ) {
    final structuredPlants = _readDynamicList(_readValue(json, const [
      'susceptiblePlants',
      'susceptible_plants',
      'topAffectedFlowers',
      'top_affected_flowers',
    ]));

    if (structuredPlants.isNotEmpty) {
      return List<SusceptiblePlant>.generate(
        structuredPlants.length,
        (index) {
          final item = structuredPlants[index];
          if (item is Map) {
            final data = Map<String, dynamic>.from(item);
            return SusceptiblePlant(
              name: _readString(data, const ['name']),
              description: _readString(data, const [
                'description',
                'reason',
              ]),
              rank:
                  int.tryParse(_readString(data, const ['rank'])) ?? index + 1,
            );
          }
          return SusceptiblePlant(
            name: item.toString(),
            description: '',
            rank: index + 1,
          );
        },
      ).where((plant) => plant.name.trim().isNotEmpty).take(3).toList();
    }

    final affectedPlants = _readString(json, const [
      'affectedPlants',
      'affected_plants',
    ]);

    if (affectedPlants.isEmpty) {
      return const [];
    }

    return affectedPlants
        .split(',')
        .map((name) => name.trim())
        .where((name) => name.isNotEmpty)
        .take(3)
        .toList()
        .asMap()
        .entries
        .map(
          (entry) => SusceptiblePlant(
            name: entry.value,
            description: '',
            rank: entry.key + 1,
          ),
        )
        .toList();
  }

  static dynamic _readValue(Map<String, dynamic> json, List<String> keys) {
    for (final key in keys) {
      if (json.containsKey(key)) {
        return json[key];
      }
    }
    return null;
  }

  static String _readString(Map<String, dynamic> json, List<String> keys) {
    final value = _readValue(json, keys);
    if (value == null) {
      return '';
    }
    if (value is String) {
      return value.trim();
    }
    return value.toString().trim();
  }

  static List<dynamic> _readDynamicList(dynamic value) {
    if (value == null) {
      return const [];
    }
    if (value is List) {
      return value;
    }
    if (value is String) {
      final trimmed = value.trim();
      if (trimmed.isEmpty) {
        return const [];
      }
      try {
        final decoded = jsonDecode(trimmed);
        if (decoded is List) {
          return decoded;
        }
      } catch (_) {
        return const [];
      }
    }
    return const [];
  }

  static List<String> _readStringList(dynamic value) {
    if (value == null) {
      return const [];
    }
    if (value is List) {
      return value
          .map((item) => item?.toString().trim() ?? '')
          .where((item) => item.isNotEmpty)
          .toList();
    }
    if (value is String) {
      final trimmed = value.trim();
      if (trimmed.isEmpty) {
        return const [];
      }
      try {
        final decoded = jsonDecode(trimmed);
        return _readStringList(decoded);
      } catch (_) {
        return trimmed
            .split(',')
            .map((item) => item.trim())
            .where((item) => item.isNotEmpty)
            .toList();
      }
    }
    return const [];
  }

  static String _slugify(String value) {
    final slug = value
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9]+'), '_')
        .replaceAll(RegExp(r'^_+|_+$'), '');

    if (slug.isNotEmpty) {
      return slug;
    }
    return 'disease_${value.hashCode.abs()}';
  }
}

class _DiseaseAssetSet {
  static const String _assetFolder = 'assets/images/diseases';

  final String mainImageUrl;
  final List<String> galleryImageUrls;

  const _DiseaseAssetSet({
    required this.mainImageUrl,
    this.galleryImageUrls = const [],
  });

  factory _DiseaseAssetSet.fromDiseaseName({
    required String name,
    required String englishName,
    required String rawName,
  }) {
    final searchText = '$name $englishName $rawName'.toLowerCase();

    if (searchText.contains('black spot') || searchText.contains('đốm đen')) {
      return const _DiseaseAssetSet(
        mainImageUrl: '$_assetFolder/benh_dom_den.jpg',
        galleryImageUrls: [
          '$_assetFolder/Black_spot.jpg',
        ],
      );
    }

    if (searchText.contains('soft rot') || searchText.contains('thối nhũn')) {
      return const _DiseaseAssetSet(
        mainImageUrl: '$_assetFolder/Bệnh-thối-nhũn.jpg',
      );
    }

    if (searchText.contains('powdery mildew') ||
        searchText.contains('phấn trắng')) {
      return const _DiseaseAssetSet(
        mainImageUrl: '$_assetFolder/benh_phan_trang.jpg',
      );
    }

    if (searchText.contains('leaf yellowing') ||
        searchText.contains('chlorosis') ||
        searchText.contains('vàng lá')) {
      return const _DiseaseAssetSet(
        mainImageUrl: '$_assetFolder/bệnh-vàng-lá.jpg',
      );
    }

    if (searchText.contains('anthracnose') || searchText.contains('thán thư')) {
      return const _DiseaseAssetSet(
        mainImageUrl: '$_assetFolder/bệnh-thán-thư.jpg',
      );
    }

    if (searchText.contains('fusarium wilt') || searchText.contains('héo rũ')) {
      return const _DiseaseAssetSet(
        mainImageUrl: '$_assetFolder/bệnh-héo-rũ.jpg',
      );
    }

    if (searchText.contains('aphids') || searchText.contains('rệp')) {
      return const _DiseaseAssetSet(
        mainImageUrl: '$_assetFolder/rệp-hoa-hồng.jpg',
      );
    }

    if (searchText.contains('spider mites') || searchText.contains('nhện đỏ')) {
      return const _DiseaseAssetSet(
        mainImageUrl: '$_assetFolder/nhện-đỏ.jpg',
      );
    }

    if (searchText.contains('leaf rollers') ||
        searchText.contains('sâu cuốn lá')) {
      return const _DiseaseAssetSet(
        mainImageUrl: '$_assetFolder/sâu-cuốn-lá.jpg',
      );
    }

    if (searchText.contains('thrips') || searchText.contains('bọ trĩ')) {
      return const _DiseaseAssetSet(
        mainImageUrl: '$_assetFolder/benh_bo_tri.jpg',
      );
    }

    return const _DiseaseAssetSet(mainImageUrl: '');
  }
}

class SusceptiblePlant {
  final String name;
  final String description;
  final int rank;

  const SusceptiblePlant({
    required this.name,
    required this.description,
    required this.rank,
  });
}

class _DiseaseNameParts {
  final String name;
  final String englishName;

  const _DiseaseNameParts({
    required this.name,
    required this.englishName,
  });

  factory _DiseaseNameParts.from(String rawName) {
    final trimmed = rawName.trim();
    final match = RegExp(r'^(.*?)\s*\(([^()]*)\)\s*$').firstMatch(trimmed);

    if (match == null) {
      return _DiseaseNameParts(name: trimmed, englishName: '');
    }

    return _DiseaseNameParts(
      name: match.group(1)?.trim() ?? trimmed,
      englishName: match.group(2)?.trim() ?? '',
    );
  }
}
