import 'package:flutter/material.dart';

/// 룰렛 조각 색상 팔레트. [locked] 인 테마는 보상형 광고를 보면 영구 해제된다.
class WheelTheme {
  final String id;
  final List<Color> colors;
  final bool locked;

  /// 조각 위 글자색 (팔레트가 밝으면 어두운 글자).
  final Color textColor;

  const WheelTheme(this.id, this.colors, {this.locked = false, this.textColor = Colors.white});

  /// i번째 조각 색. 항목 수가 팔레트 길이의 배수가 아닐 때 첫 조각과 마지막 조각이 같은 색이 되면
  /// 마지막 조각을 한 칸 밀어 붙어 보이지 않게 한다.
  Color colorAt(int i, int n) {
    final base = colors[i % colors.length];
    if (i == n - 1 && n > 1 && n % colors.length == 1) return colors[(i + 1) % colors.length];
    return base;
  }

  static const all = [
    WheelTheme('classic', [
      Color(0xFFE53935), Color(0xFF1E88E5), Color(0xFFFDD835), Color(0xFF43A047),
      Color(0xFFFB8C00), Color(0xFF8E24AA), Color(0xFF00ACC1), Color(0xFFD81B60),
    ]),
    WheelTheme('pastel', [
      Color(0xFFFFB3BA), Color(0xFFFFDFBA), Color(0xFFFFFFBA), Color(0xFFBAFFC9),
      Color(0xFFBAE1FF), Color(0xFFE0BBE4), Color(0xFFFFC8DD), Color(0xFFCDE7BE),
    ], textColor: Color(0xFF3A3A4A)),
    WheelTheme('neon', [
      Color(0xFF00E5FF), Color(0xFFFF1744), Color(0xFF76FF03), Color(0xFFFFEA00),
      Color(0xFFD500F9), Color(0xFFFF9100), Color(0xFF1DE9B6), Color(0xFF2979FF),
    ], locked: true, textColor: Color(0xFF14121F)),
    WheelTheme('sunset', [
      Color(0xFFFF6B6B), Color(0xFFFF8E53), Color(0xFFFFB347), Color(0xFFFFD166),
      Color(0xFFEF476F), Color(0xFFC44569), Color(0xFF9B5DE5), Color(0xFF6A4C93),
    ], locked: true),
    WheelTheme('forest', [
      Color(0xFF2D6A4F), Color(0xFF40916C), Color(0xFF52B788), Color(0xFF74C69D),
      Color(0xFF95D5B2), Color(0xFF1B4332), Color(0xFF80B918), Color(0xFF55A630),
    ], locked: true),
    WheelTheme('ocean', [
      Color(0xFF023E8A), Color(0xFF0077B6), Color(0xFF0096C7), Color(0xFF00B4D8),
      Color(0xFF48CAE4), Color(0xFF90E0EF), Color(0xFF03045E), Color(0xFF0353A4),
    ], locked: true),
  ];

  static WheelTheme byId(String? id) => all.firstWhere((t) => t.id == id, orElse: () => all.first);
}

/// 앱 시드 색 (아이콘·스토어 자산과 맞춤).
class AppColors {
  AppColors._();
  static const seed = Color(0xFF7B3FE4);
}
