import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../theme/wheel_themes.dart';

/// 룰렛 판. [rotation] 라디안만큼 시계 방향으로 돌아간 상태를 그린다 (포인터는 12시 고정).
/// [disabled] 에 든 항목은 흐리게 그린다 (당첨 항목 제외 모드).
class WheelWidget extends StatefulWidget {
  final List<String> items;
  final double rotation;
  final WheelTheme theme;
  final Set<int> disabled;
  final VoidCallback? onTap;

  const WheelWidget({
    super.key,
    required this.items,
    required this.rotation,
    required this.theme,
    this.disabled = const {},
    this.onTap,
  });

  @override
  State<WheelWidget> createState() => _WheelWidgetState();
}

class _WheelWidgetState extends State<WheelWidget> {
  /// 라벨 TextPainter 는 회전 중 매 프레임 다시 만들면 느린 기기에서 프레임이 밀리므로
  /// (항목·테마·크기가 같으면) 한 번만 레이아웃해 재사용한다.
  final _labels = _LabelCache();

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return GestureDetector(
      onTap: widget.onTap,
      child: AspectRatio(
        aspectRatio: 1,
        child: Stack(
          fit: StackFit.expand,
          children: [
            CustomPaint(
              painter: _WheelPainter(
                items: widget.items,
                rotation: widget.rotation,
                theme: widget.theme,
                disabled: widget.disabled,
                labels: _labels,
                rim: cs.surfaceContainerHighest,
                hub: cs.surface,
                hubIcon: cs.primary,
              ),
            ),
            Align(
              alignment: Alignment.topCenter,
              child: CustomPaint(size: const Size(36, 44), painter: _PointerPainter(cs.primary, cs.onPrimary)),
            ),
          ],
        ),
      ),
    );
  }
}

class _WheelPainter extends CustomPainter {
  final List<String> items;
  final double rotation;
  final WheelTheme theme;
  final Set<int> disabled;
  final _LabelCache labels;
  final Color rim;
  final Color hub;
  final Color hubIcon;

  _WheelPainter({
    required this.items,
    required this.rotation,
    required this.theme,
    required this.disabled,
    required this.labels,
    required this.rim,
    required this.hub,
    required this.hubIcon,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final n = items.length;
    final c = size.center(Offset.zero);
    final r = size.shortestSide / 2 - 6; // 포인터가 튀어나올 여유
    final sweep = 2 * math.pi / n;

    // 테두리 그림자 + 림
    canvas.drawCircle(c.translate(0, 4), r + 4, Paint()..color = Colors.black.withValues(alpha: 0.18)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8));
    canvas.drawCircle(c, r + 4, Paint()..color = rim);

    canvas.save();
    canvas.translate(c.dx, c.dy);
    canvas.rotate(rotation);

    final rect = Rect.fromCircle(center: Offset.zero, radius: r);
    final painters = labels.get(items, theme, disabled, r);
    for (var i = 0; i < n; i++) {
      final start = -math.pi / 2 + i * sweep;
      var color = theme.colorAt(i, n);
      if (disabled.contains(i)) color = Color.lerp(color, Colors.grey.shade400, 0.75)!;
      canvas.drawArc(rect, start, sweep, true, Paint()..color = color);
      if (n > 1) {
        canvas.drawArc(rect, start, sweep, true, Paint()
          ..color = Colors.white.withValues(alpha: 0.55)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.5);
      }

      // 글자: 조각 가운데 각도로 회전한 뒤 반지름 방향으로 그린다 (바깥쪽 정렬).
      canvas.save();
      canvas.rotate(start + sweep / 2);
      final tp = painters[i];
      tp.paint(canvas, Offset(r * 0.94 - tp.width, -tp.height / 2));
      canvas.restore();
    }
    canvas.restore();

    // 가운데 허브
    canvas.drawCircle(c, r * 0.13 + 3, Paint()..color = rim);
    canvas.drawCircle(c, r * 0.13, Paint()..color = hub);
    canvas.drawCircle(c, r * 0.045, Paint()..color = hubIcon);
  }

  @override
  bool shouldRepaint(_WheelPainter old) =>
      old.rotation != rotation || old.items != items || old.theme != theme || old.disabled != disabled ||
      old.rim != rim || old.hub != hub;
}

/// 조각 라벨 TextPainter 캐시. 항목 목록·테마·비활성 집합·반지름이 바뀔 때만 다시 레이아웃한다.
class _LabelCache {
  List<String>? _items;
  WheelTheme? _theme;
  Set<int>? _disabled;
  double _r = -1;
  List<TextPainter> _painters = const [];

  List<TextPainter> get(List<String> items, WheelTheme theme, Set<int> disabled, double r) {
    if (identical(items, _items) && theme == _theme && setEquals(disabled, _disabled) && r == _r) return _painters;
    _items = items;
    _theme = theme;
    _disabled = Set.of(disabled);
    _r = r;
    final n = items.length;
    final fontSize = n <= 4 ? 22.0 : n <= 8 ? 17.0 : n <= 12 ? 14.0 : n <= 16 ? 12.0 : 10.5;
    // 허브 바깥(0.2r)부터 테두리 안쪽(0.94r)까지 쓰고, 안 들어가면 글자를 줄이다가 말줄임.
    final maxW = r * 0.74;
    _painters = List.generate(n, (i) {
      final textColor = disabled.contains(i) ? theme.textColor.withValues(alpha: 0.5) : theme.textColor;
      var size = fontSize;
      while (true) {
        final tp = TextPainter(
          text: TextSpan(
            text: items[i],
            style: TextStyle(
              color: textColor,
              fontSize: size,
              fontWeight: FontWeight.w700,
              shadows: theme.textColor == Colors.white
                  ? const [Shadow(color: Colors.black26, blurRadius: 3, offset: Offset(0, 1))]
                  : null,
            ),
          ),
          textDirection: TextDirection.ltr,
          maxLines: 1,
          ellipsis: '…',
        )..layout(maxWidth: maxW);
        if (!tp.didExceedMaxLines || size <= fontSize * 0.7) return tp;
        size -= 1;
      }
    });
    return _painters;
  }
}

/// 12시 방향 포인터 (아래를 향한 물방울 모양).
class _PointerPainter extends CustomPainter {
  final Color color;
  final Color dot;
  _PointerPainter(this.color, this.dot);

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width, h = size.height;
    final path = Path()
      ..moveTo(w / 2, h)
      ..quadraticBezierTo(w * 0.05, h * 0.45, w * 0.12, h * 0.25)
      ..arcToPoint(Offset(w * 0.88, h * 0.25), radius: Radius.circular(w * 0.42))
      ..quadraticBezierTo(w * 0.95, h * 0.45, w / 2, h)
      ..close();
    canvas.drawShadow(path, Colors.black, 4, false);
    canvas.drawPath(path, Paint()..color = color);
    canvas.drawCircle(Offset(w / 2, h * 0.3), w * 0.14, Paint()..color = dot);
  }

  @override
  bool shouldRepaint(_PointerPainter old) => old.color != color || old.dot != dot;
}
