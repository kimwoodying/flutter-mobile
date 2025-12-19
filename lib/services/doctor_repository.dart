import 'package:hive_flutter/hive_flutter.dart';
import '../models/doctor.dart';
import 'api_client.dart';

class DoctorRepository {
  DoctorRepository({ApiClient? client}) : _client = client ?? ApiClient();

  final ApiClient _client;
  static const String _boxName = 'doctors_cache';

  Future<List<Doctor>> fetchDoctors({String? department}) async {
    final box = await Hive.openBox(_boxName);
    final cacheKey = 'doctors_${department ?? 'all'}';

    // 캐시 만료 시간 체크 (1시간)
    final cacheTimestamp = box.get('${cacheKey}_timestamp') as int?;
    final now = DateTime.now().millisecondsSinceEpoch;
    const cacheExpiryMs = 60 * 60 * 1000; // 1시간

    final isExpired = cacheTimestamp == null || (now - cacheTimestamp) > cacheExpiryMs;

    // 캐시된 데이터가 있고 만료되지 않았으면 반환
    final cachedData = box.get(cacheKey);
    if (cachedData != null && cachedData is List && !isExpired) {
      final cachedDoctors = cachedData
          .whereType<Map<String, dynamic>>()
          .map(Doctor.fromJson)
          .toList();
      if (cachedDoctors.isNotEmpty) {
        // 백그라운드에서 최신 데이터 가져오기 (UI 블록킹 방지)
        Future.microtask(() => _fetchAndCacheDoctors(department, cacheKey, box));
        return cachedDoctors;
      }
    }

    // 캐시가 없거나 만료되었으면 API 호출
    return await _fetchAndCacheDoctors(department, cacheKey, box);
  }

  Future<List<Doctor>> _fetchAndCacheDoctors(
    String? department,
    String cacheKey,
    Box box,
  ) async {
    try {
      final data = await _client.get(
        '/api/auth/doctors/',
        query: department == null || department.isEmpty
            ? null
            : {'department': department},
      );

      List<Doctor> doctors = [];
      if (data is Map<String, dynamic> && data['doctors'] is List) {
        final list = data['doctors'] as List<dynamic>;
        doctors = list
            .whereType<Map<String, dynamic>>()
            .map(Doctor.fromJson)
            .toList();
      }

      // 캐시에 저장 (버전 정보 추가)
      await box.put('${cacheKey}_timestamp', DateTime.now().millisecondsSinceEpoch);
      await box.put(cacheKey, doctors.map((d) => d.toJson()).toList());
      return doctors;
    } catch (e) {
      // API 실패 시 캐시된 데이터 반환 (없으면 빈 리스트)
      final cachedData = box.get(cacheKey);
      if (cachedData != null && cachedData is List) {
        return cachedData
            .whereType<Map<String, dynamic>>()
            .map(Doctor.fromJson)
            .toList();
      }
      rethrow;
    }
  }

  /// 백그라운드에서 의사 데이터 미리 로드
  Future<void> preloadDoctors() async {
    try {
      // 메인 스레드 블록킹 방지
      Future.delayed(const Duration(seconds: 2), () async {
        await fetchDoctors(); // 전체 의사 목록
        await fetchDoctors(department: 'respiratory'); // 호흡기내과
        await fetchDoctors(department: 'cardiology'); // 심장내과
        // 필요한 부서들 추가
      });
    } catch (e) {
      // 미리 로드 실패 시 무시 (앱 실행에 영향 없음)
    }
  }

  /// 캐시 클리어 (새로운 데이터 강제 로드용)
  Future<void> clearCache() async {
    final box = await Hive.openBox(_boxName);
    await box.clear();
  }

  /// 특정 부서 캐시 클리어
  Future<void> clearDepartmentCache(String? department) async {
    final box = await Hive.openBox(_boxName);
    final cacheKey = 'doctors_${department ?? 'all'}';
    await box.delete(cacheKey);
    await box.delete('${cacheKey}_timestamp');
  }
}
