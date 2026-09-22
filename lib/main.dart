import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'ads/ad_manager.dart';
import 'l10n/strings.dart';
import 'screens/home_screen.dart';
import 'services/roulette_store.dart';
import 'services/storage.dart';
import 'theme/wheel_themes.dart';

/// 스크린샷 촬영용 언어 강제 (디버그 빌드에서만 동작).
/// 예: flutter build apk --debug --dart-define=LOCALE=ja
const _localeOverride = String.fromEnvironment('LOCALE');

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // 광고 SDK 초기화는 앱 표시를 막지 않도록 기다리지 않는다.
  AdManager.instance.init();
  await SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  final storage = await Storage.create();
  runApp(RouletteApp(storage: storage));
}

class RouletteApp extends StatefulWidget {
  final Storage storage;
  const RouletteApp({super.key, required this.storage});

  @override
  State<RouletteApp> createState() => _RouletteAppState();
}

class _RouletteAppState extends State<RouletteApp> {
  late final LocaleController _locale;
  late final RouletteStore _store;

  @override
  void initState() {
    super.initState();
    _locale = LocaleController(LocaleController.fromCode(widget.storage.localeCode));
    _locale.addListener(() => widget.storage.setLocaleCode(_locale.value?.languageCode));
    _store = RouletteStore(widget.storage);
    // 첫 실행: 실제로 표시될 언어로 기본 룰렛을 만든다.
    final effective = kDebugMode && _localeOverride.isNotEmpty
        ? Locale(_localeOverride)
        : (_locale.value ?? PlatformDispatcher.instance.locale);
    _store.seedIfEmpty(S(S.resolve(effective)));
  }

  @override
  void dispose() {
    _locale.dispose();
    _store.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return LocaleScope(
      controller: _locale,
      child: ListenableBuilder(
        listenable: _locale,
        builder: (context, _) => MaterialApp(
          onGenerateTitle: (context) => S.of(context).appTitle,
          debugShowCheckedModeBanner: false,
          theme: ThemeData(colorSchemeSeed: AppColors.seed, useMaterial3: true),
          darkTheme: ThemeData(colorSchemeSeed: AppColors.seed, brightness: Brightness.dark, useMaterial3: true),
          localizationsDelegates: const [S.delegate, ...GlobalMaterialLocalizations.delegates],
          supportedLocales: S.supported,
          // 우선순위: 스크린샷용 강제 > 사용자 설정 > 시스템 언어
          locale: kDebugMode && _localeOverride.isNotEmpty ? Locale(_localeOverride) : _locale.value,
          home: HomeScreen(store: _store),
        ),
      ),
    );
  }
}
