import 'dart:math' as math;

/// 룰렛 하나: 제목과 항목 목록.
class Roulette {
  static const minItems = 2;
  static const maxItems = 20;

  final String id;
  String title;
  List<String> items;

  /// 누적 돌린 횟수 (홈 정렬·통계용).
  int spins;

  Roulette({required this.id, required this.title, required this.items, this.spins = 0});

  factory Roulette.create(String title, List<String> items) =>
      Roulette(id: newId(), title: title, items: List.of(items));

  static String newId() {
    final r = math.Random();
    return '${DateTime.now().microsecondsSinceEpoch.toRadixString(36)}${r.nextInt(1 << 20).toRadixString(36)}';
  }

  Roulette copyWith({String? id, String? title, List<String>? items, int? spins}) => Roulette(
        id: id ?? this.id,
        title: title ?? this.title,
        items: List.of(items ?? this.items),
        spins: spins ?? this.spins,
      );

  Map<String, dynamic> toJson() => {'id': id, 'title': title, 'items': items, 'spins': spins};

  factory Roulette.fromJson(Map<String, dynamic> j) => Roulette(
        id: j['id'] as String,
        title: j['title'] as String,
        items: (j['items'] as List).cast<String>(),
        spins: j['spins'] as int? ?? 0,
      );
}

/// 룰렛 회전 수학. 화면 위쪽(12시)에 고정된 포인터 기준.
///
/// 룰렛은 회전 0 일 때 0번 조각이 12시 방향에서 시작해 시계 방향으로 이어진다.
/// 룰렛이 [rotation] 라디안만큼 시계 방향으로 돌면, 포인터가 가리키는 룰렛 좌표계 각도는 `-rotation` 이다.
class SpinMath {
  SpinMath._();

  static double sweep(int n) => 2 * math.pi / n;

  /// 회전각 [rotation] 에서 포인터가 가리키는 조각 번호.
  static int indexAt(double rotation, int n) {
    final local = (-rotation) % (2 * math.pi);
    return (local / sweep(n)).floor().clamp(0, n - 1);
  }

  /// [winner] 조각의 [fraction] (0~1, 조각 안 위치) 지점에 포인터가 오도록 하는 최종 회전각.
  /// 현재 각 [from] 보다 항상 크며, [fullTurns] 바퀴 이상 더 돈다.
  static double targetRotation(double from, int winner, int n, {double fraction = 0.5, int fullTurns = 5}) {
    final twoPi = 2 * math.pi;
    final wantLocal = (winner + fraction) * sweep(n); // (-rotation) mod 2π 가 되어야 할 값
    // rotation ≡ -wantLocal (mod 2π), from 보다 큰 값 중 fullTurns 바퀴 이상 더 돈 것
    var target = -wantLocal;
    while (target <= from) {
      target += twoPi;
    }
    return target + fullTurns * twoPi;
  }

  /// 승자를 무작위로 고르고 그에 맞는 최종 회전각을 만든다.
  static ({int winner, double target}) pick(double from, int n, math.Random rng, {int fullTurns = 5}) {
    final winner = rng.nextInt(n);
    // 조각 경계에 걸리지 않도록 가운데 80% 안에서 멈춘다.
    final fraction = 0.1 + rng.nextDouble() * 0.8;
    return (winner: winner, target: targetRotation(from, winner, n, fraction: fraction, fullTurns: fullTurns));
  }
}
