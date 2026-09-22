# 랜덤 룰렛 (random_roulette)

항목을 넣고 돌려서 하나를 뽑는 결정 룰렛. AdMob 광고(배너 / 전면 / 보상형)로 수익화.
Flutter 로 작성, Android + iOS 대상. 한국어 · 영어 · 일본어 · 중국어(간체) 지원, 앱 안에서 언어 변경 가능.

## 구조

```
lib/
  main.dart                     앱 진입, 테마 (세로 고정), 스크린샷용 LOCALE 강제, 첫 실행 기본 룰렛 시딩
  l10n/strings.dart             문자열 en/ko/ja/zh + 기본 룰렛(presets) + LocaleController
  ads/ad_ids.dart               AdMob 광고 단위 ID  ← 출시 전 교체
  ads/ad_manager.dart           전면·보상형 광고 로드/노출 싱글톤
  widgets/banner_ad_widget.dart 하단 적응형 배너
  model/roulette.dart           Roulette (id/제목/항목/spins, json) + SpinMath (회전각 ↔ 조각 번호)
  theme/wheel_themes.dart       룰렛 팔레트 6종 (classic·pastel 무료, 나머지 보상형 해제) + 앱 시드색
  services/storage.dart         SharedPreferences: 룰렛 목록, 언어, 테마, 해제된 테마
  services/roulette_store.dart  룰렛 목록 ChangeNotifier (추가/수정/삭제/복제/시딩)
  widgets/wheel_widget.dart     룰렛 판 CustomPaint (조각·라벨·허브) + 12시 포인터
  screens/home_screen.dart      홈 (룰렛 목록, 길게 눌러 편집/복제/삭제, 언어, 사용 방법)
  screens/edit_screen.dart      룰렛 만들기/편집 (제목, 항목 2~20개, 섞기)
  screens/wheel_screen.dart     돌리기 화면 (애니메이션, 결과 다이얼로그, 당첨 제외 모드, 기록, 테마)
test/spin_math_test.dart        회전 수학·모델 유닛 테스트
test/locale_test.dart           기본 룰렛·로케일 테스트
```

## 동작 / 상수

| 항목 | 값 | 위치 |
|---|---|---|
| 항목 수 | 2 ~ 20 | `Roulette.minItems/maxItems` |
| 회전 시간 | 4.2초, 4~6바퀴 + 랜덤 | `wheel_screen.dart` `_spinDuration`, `_spin()` |
| 기록 보관 | 최근 12개 (세션 내) | `_maxHistory` |
| 기본 룰렛 | 5종, 첫 실행 시 표시 언어로 생성 | `S.presets` |

회전 수학은 `SpinMath` 하나에 모여 있다: 승자를 먼저 정하고 그 조각의 가운데 80% 안에 포인터가 멈추도록 최종 회전각을 계산한다
(`targetRotation`), 멈춘 뒤 `indexAt` 으로 다시 읽어 결과를 표시하므로 둘이 어긋날 수 없다 (테스트로 검증).

## 광고 노출 지점

| 위치 | 종류 | 동작 |
|---|---|---|
| 홈·룰렛 화면 하단 | 배너 | 항상 표시 |
| 결과 다이얼로그를 닫을 때 | 전면 | 3회 회전마다 1회 (`AdManager.interstitialEvery = 3`). 광고가 끝난 뒤 "다시 돌리기"가 이어진다. 로드 안 됐으면 광고 없이 진행 |
| 테마 시트에서 잠긴 테마 선택 | 보상형 | 끝까지 시청 시 해당 테마 영구 해제 (`Storage.unlockTheme`) |

전면 빈도는 출시 후 이탈률을 보고 조정. 값은 `ad_manager.dart` 상수 하나.

## 개발 빌드

```bash
flutter pub get
flutter test
flutter build apk --debug
```

에뮬레이터: `flutter emulators --launch Small_Phone_API_35` 후 `flutter run`.

언어 확인: `flutter run --dart-define=LOCALE=ja` (디버그 전용, ko/en/ja/zh — 사용자 설정보다 우선).
스토어 스크린샷: `bash tool/capture_screens.sh <ko|en|ja|zh> [adb serial]` → `python tool/make_store_assets.py`.

### 이 PC 전용 메모
Java 의 AF_UNIX 소켓이 `%TEMP%` 아래에서 실패해 Gradle 이 "Unable to establish loopback connection" 으로
죽는 문제가 있어, `android/gradle.properties` 와 `android/gradlew.bat` 에
`-Djdk.net.unixdomain.tmpdir=C:/tmp` 를 넣어 두었다. `C:\tmp` 폴더가 있어야 한다.

## 출시 체크리스트

### 1. AdMob
- [ ] https://admob.google.com 에서 Android 앱 "Random Roulette" 등록 (스토어 연결은 Play 게시 후)
- [ ] 광고 단위 3개 생성: 배너 / 전면 / 보상형
- [ ] `lib/ads/ad_ids.dart` 의 `_androidReal` 을 실제 ID 로 교체 (지금은 `_androidTest` 를 가리킴)
- [ ] `android/app/src/main/AndroidManifest.xml` 의 `APPLICATION_ID` 교체 (지금은 Google 테스트 App ID)
- [ ] `ios/Runner/Info.plist` 의 `GADApplicationIdentifier` 교체
- [ ] 개발 중 실제 ID로 광고 클릭 금지 (계정 정지 사유). 테스트 기기 등록 권장.
- [x] AdMob 결제·세금 정보 (오늘의 운세와 같은 계정)

### 2. 개인정보 / 정책
- [x] 개인정보처리방침: https://junshiva5732.github.io/random_roulette/privacy-policy.html (원본 `docs/privacy-policy.html`, GitHub Pages `main` / `/docs`)
- [ ] iOS: ATT(앱 추적 투명성) 팝업 — `Info.plist` 에 문구는 넣어둠. 필요 시 `app_tracking_transparency` 패키지로 요청.
- [ ] EU 대상이면 UMP(동의 메시지) 설정 — `google_mobile_ads` 의 `ConsentInformation` API.

### 3. Android 출시
- [x] 릴리즈 서명 키: `android/upload-keystore.jks` + `android/key.properties` (git 제외 — **반드시 백업**, 별칭 `upload`, PKCS12, 2026-09-22 생성)
- [x] 앱 아이콘: `tool/make_icon.py` → `dart run flutter_launcher_icons`
- [x] `flutter build appbundle --release` → `build/app/outputs/bundle/release/app-release.aab` (targetSdk 36)
- [ ] Play Console 개발자 계정 본인 확인 완료 후 앱 생성 (개발자 ID 6377501318049789563)
- [x] 스토어 등록 정보: `store/listing.md` — ko/en/ja/zh-CN 설명문(ASO 키워드 반영), 카테고리, 데이터 보안 양식 답변
- [x] 그래픽: `store/icon-512.png`, `store/<ko|en|ja|zh>/feature-graphic.png`, `store/<lang>/screenshots/01~04.png`
- [ ] 내부 테스트 → 비공개 테스트(테스터 12명, 14일) → 프로덕션 (신규 개인 계정 요건)
- [ ] 프로덕션 출시 후 AdMob "앱 스토어 연결"

### 4. iOS 출시 (Mac 필요)
- [ ] Apple Developer Program 가입 (연 $99)
- [ ] Xcode 에서 Bundle ID / 팀 설정, `pod install`
- [ ] `flutter build ipa` → Transporter 또는 Xcode 로 App Store Connect 업로드
- [ ] 심사 시 광고 사용 여부 "예" 표시

### 5. 출시 후 확장 아이디어
- [ ] 효과음(틱·당첨) + 사운드 토글
- [ ] 항목별 가중치(확률) 설정
- [ ] 결과 공유(이미지/텍스트), 룰렛 공유 링크
- [ ] 홈 위젯 / 바로가기로 자주 쓰는 룰렛 바로 돌리기
