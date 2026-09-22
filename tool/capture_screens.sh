#!/usr/bin/env bash
# 스토어 스크린샷 원본 캡처. 사용: bash tool/capture_screens.sh <ko|en|ja|zh> [adb serial]
# LOCALE 을 dart-define 으로 강제한 디버그 APK 를 설치하고 4장을 찍는다.
# 탭 좌표는 720x1280 (Small_Phone_API_35) 기준.
set +e
LANG_CODE=$1; SERIAL=${2:-emulator-5554}
ADB="/c/Users/Administrator/AppData/Local/Android/sdk/platform-tools/adb.exe -s $SERIAL"
OUT=store/raw/$LANG_CODE; mkdir -p "$OUT"
PKG=com.jun5731.random_roulette
T() { $ADB shell input tap "$1" "$2"; sleep "${3:-1.5}"; }

if [ "$SKIP_BUILD" != "1" ]; then
  flutter build apk --debug --dart-define=LOCALE=$LANG_CODE 2>&1 | tail -1
fi
$ADB uninstall $PKG >/dev/null 2>&1   # 에뮬레이터 용량이 빡빡해 덮어쓰기 설치가 실패하므로 지우고 설치
$ADB install build/app/outputs/flutter-apk/app-debug.apk | tail -1
$ADB shell pm clear $PKG >/dev/null            # 기본 룰렛이 이 언어로 다시 생성된다
$ADB shell am start -n $PKG/.MainActivity >/dev/null
# 홈 목록(첫 카드)이 그려질 때까지 대기 — 느린 에뮬레이터에서 시작이 30초 넘게 걸리기도 한다.
for i in $(seq 1 60); do
  sleep 2
  $ADB exec-out screencap -p > "$OUT/s_home.png"
  python -c "from PIL import Image; import sys; p=Image.open(sys.argv[1]).convert('RGB').getpixel((115,240)); sys.exit(0 if p[0]>200 and p[1]<120 else 1)" "$OUT/s_home.png" && break
done
sleep 12                                       # 배너 로드·첫 프레임 정리 대기 (디버그 빌드는 느려서 탭이 길게 누르기로 인식되기도 한다)
$ADB exec-out screencap -p > "$OUT/s_home.png"
T 360 275 8                                    # 첫 룰렛 열기
$ADB exec-out screencap -p > "$OUT/s_wheel.png"
T 360 950 10                                    # SPIN → 결과 다이얼로그
$ADB exec-out screencap -p > "$OUT/s_result.png"
T 246 795 3                                    # 닫기
T 671 103 5                                    # 편집
$ADB exec-out screencap -p > "$OUT/s_edit.png"
$ADB shell input keyevent BACK; sleep 1; $ADB shell input keyevent BACK
echo "captured: $OUT"
