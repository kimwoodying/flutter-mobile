import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:intl/intl.dart';
import 'package:kakao_map_plugin/kakao_map_plugin.dart';

import 'config/map_config.dart';
import 'screens/main_shell.dart';
import 'services/doctor_repository.dart';
import 'theme/app_theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Hive.initFlutter();

  // 캐시 클리어 (개발 중에만 사용 - 프로덕션에서는 제거)
  final doctorRepo = DoctorRepository();
  await doctorRepo.clearCache();

  // 백그라운드에서 의사 데이터 미리 로드
  doctorRepo.preloadDoctors();

  await initializeDateFormatting('ko_KR', null);
  Intl.defaultLocale = 'ko_KR';
  AuthRepository.initialize(appKey: MapConfig.kakaoMapAppKey);
  runApp(const HospitalNaviApp());
}

class HospitalNaviApp extends StatelessWidget {
  const HospitalNaviApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'CDSSentials',
      debugShowCheckedModeBanner: false,
      locale: const Locale('ko', 'KR'),
      supportedLocales: const [
        Locale('ko', 'KR'),
        Locale('en', 'US'),
      ],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      theme: AppTheme.light(),
      home: const MainShell(),
    );
  }
}
