import 'package:flutter/services.dart' show rootBundle;

class DepartmentMapping {
  const DepartmentMapping({
    required this.title,
    required this.category,
    required this.version,
    required this.language,
    required this.entries,
  });

  final String title;
  final String category;
  final String version;
  final String language;
  final List<String> entries;

  static Future<DepartmentMapping> load() async {
    final content = await rootBundle.loadString('assets/raw/department_mapping.txt');
    return _parseContent(content);
  }

  static DepartmentMapping _parseContent(String content) {
    final lines = content.split('\n').where((line) => line.trim().isNotEmpty).toList();

    String title = '';
    String category = '';
    String version = '';
    String language = '';
    final entries = <String>[];

    bool inHeader = true;

    for (final line in lines) {
      if (line.startsWith('---')) {
        if (inHeader) {
          inHeader = false;
        }
        continue;
      }

      if (inHeader) {
        if (line.startsWith('title:')) {
          title = line.substring(6).trim();
        } else if (line.startsWith('category:')) {
          category = line.substring(9).trim();
        } else if (line.startsWith('version:')) {
          version = line.substring(8).trim();
        } else if (line.startsWith('language:')) {
          language = line.substring(9).trim();
        }
      } else {
        if (line.trim().isNotEmpty) {
          entries.add(line.trim());
        }
      }
    }

    return DepartmentMapping(
      title: title,
      category: category,
      version: version,
      language: language,
      entries: entries,
    );
  }

  /// 증상에 맞는 진료과 추천
  String? findDepartmentForSymptom(String symptom) {
    for (final entry in entries) {
      if (entry.contains(symptom) || symptom.contains(entry.split(' ')[0])) {
        // 간단한 매칭 로직 - 실제로는 더 정교한 NLP 필요
        if (entry.contains('호흡기내과')) return '호흡기내과';
        if (entry.contains('유방외과')) return '유방외과';
        if (entry.contains('영상의학과')) return '영상의학과';
        if (entry.contains('방사선과')) return '방사선과';
      }
    }
    return null;
  }
}