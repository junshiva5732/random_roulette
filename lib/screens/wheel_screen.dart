import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../ads/ad_manager.dart';
import '../l10n/strings.dart';
import '../model/roulette.dart';
import '../services/roulette_store.dart';
import '../theme/wheel_themes.dart';
import '../widgets/banner_ad_widget.dart';
import '../widgets/wheel_widget.dart';
import 'edit_screen.dart';

/// 룰렛 돌리기 화면.
class WheelScreen extends StatefulWidget {
  final RouletteStore store;
  final String rouletteId;
  const WheelScreen({super.key, required this.store, required this.rouletteId});

  @override
  State<WheelScreen> createState() => _WheelScreenState();
}

class _WheelScreenState extends State<WheelScreen> with SingleTickerProviderStateMixin {
  static const _spinDuration = Duration(milliseconds: 4200);
  static const _maxHistory = 12;

  late final AnimationController _ctrl;
  Animation<double>? _anim;
  final _rng = math.Random();

  double _rotation = 0;
  int _lastTickIndex = -1;
  bool _removeWinner = false;
  final Set<int> _picked = {};
  final List<String> _history = [];
  late WheelTheme _theme;

  S get _s => S.of(context);
  Roulette? get _roulette => widget.store.byId(widget.rouletteId);
  bool get _spinning => _ctrl.isAnimating;

  @override
  void initState() {
    super.initState();
    _theme = WheelTheme.byId(widget.store.storage.themeId);
    _ctrl = AnimationController(vsync: this, duration: _spinDuration)
      ..addListener(_onTick)
      ..addStatusListener((st) {
        if (st == AnimationStatus.completed) _onStopped();
      });
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  // ------------------------------------------------------------------ 회전

  void _onTick() {
    final r = _roulette;
    if (r == null) return;
    // 룰렛만 AnimatedBuilder 로 다시 그린다 (화면 전체 setState 는 느린 기기에서 프레임이 밀린다).
    _rotation = _anim!.value;
    // 조각 경계를 지날 때마다 틱 진동
    final idx = SpinMath.indexAt(_rotation, r.items.length);
    if (idx != _lastTickIndex) {
      _lastTickIndex = idx;
      HapticFeedback.selectionClick();
    }
  }

  List<int> _available(Roulette r) =>
      [for (var i = 0; i < r.items.length; i++) if (!_removeWinner || !_picked.contains(i)) i];

  void _spin() {
    final r = _roulette;
    if (r == null || _spinning) return;
    final avail = _available(r);
    if (avail.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(_s.allPicked)));
      return;
    }
    final n = r.items.length;
    final winner = avail[_rng.nextInt(avail.length)];
    final fraction = 0.1 + _rng.nextDouble() * 0.8;
    final turns = 4 + _rng.nextInt(3);
    final target = SpinMath.targetRotation(_rotation, winner, n, fraction: fraction, fullTurns: turns);
    _anim = Tween<double>(begin: _rotation, end: target)
        .animate(CurvedAnimation(parent: _ctrl, curve: const Cubic(0.12, 0.8, 0.2, 1)));
    _lastTickIndex = SpinMath.indexAt(_rotation, n);
    _ctrl.forward(from: 0);
    setState(() {}); // SPIN 버튼 → "돌아가는 중…"
    widget.store.countSpin(r.id);
  }

  Future<void> _onStopped() async {
    final r = _roulette;
    if (r == null) return;
    final idx = SpinMath.indexAt(_rotation, r.items.length);
    final label = r.items[idx];
    HapticFeedback.heavyImpact();
    setState(() {
      _picked.add(idx);
      _history.insert(0, label);
      if (_history.length > _maxHistory) _history.removeLast();
    });
    final again = await _showResult(label);
    if (!mounted) return;
    // 결과 창을 닫을 때 n번에 한 번 전면 광고. 광고가 끝난 뒤 "다시 돌리기"를 이어간다.
    AdManager.instance.showInterstitialThen(() {
      if (again == true && mounted) _spin();
    });
  }

  Future<bool?> _showResult(String label) {
    final s = _s;
    return showDialog<bool>(
      context: context,
      builder: (ctx) {
        final cs = Theme.of(ctx).colorScheme;
        return AlertDialog(
          title: Row(
            children: [
              Icon(Icons.celebration_rounded, color: cs.primary),
              const SizedBox(width: 8),
              Text(s.result),
            ],
          ),
          content: Container(
            width: double.maxFinite,
            padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 12),
            decoration: BoxDecoration(color: cs.primaryContainer, borderRadius: BorderRadius.circular(16)),
            child: Text(
              label,
              textAlign: TextAlign.center,
              style: Theme.of(ctx).textTheme.headlineMedium?.copyWith(
                    color: cs.onPrimaryContainer,
                    fontWeight: FontWeight.w800,
                  ),
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(s.close)),
            FilledButton.icon(
              onPressed: () => Navigator.pop(ctx, true),
              icon: const Icon(Icons.refresh_rounded),
              label: Text(s.spinAgain),
            ),
          ],
        );
      },
    );
  }

  void _reset() => setState(_picked.clear);

  // ------------------------------------------------------------------ 테마

  Future<void> _showThemes() async {
    final s = _s;
    final storage = widget.store.storage;
    final picked = await showModalBottomSheet<WheelTheme>(
      context: context,
      showDragHandle: true,
      builder: (ctx) {
        final unlocked = storage.unlockedThemes;
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(s.theme, style: Theme.of(ctx).textTheme.titleLarge),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: [
                    for (final t in WheelTheme.all)
                      _ThemeChip(
                        theme: t,
                        name: s.themeName(t.id),
                        selected: t.id == _theme.id,
                        locked: t.locked && !unlocked.contains(t.id),
                        onTap: () => Navigator.pop(ctx, t),
                      ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
    if (picked == null || !mounted) return;
    if (picked.locked && !storage.unlockedThemes.contains(picked.id)) {
      await _unlock(picked);
    } else {
      _applyTheme(picked);
    }
  }

  void _applyTheme(WheelTheme t) {
    setState(() => _theme = t);
    widget.store.storage.setThemeId(t.id);
  }

  Future<void> _unlock(WheelTheme t) async {
    final s = _s;
    final watch = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(s.unlockTitle),
        content: Text(s.unlockBody(s.themeName(t.id))),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(s.cancel)),
          FilledButton.icon(
            onPressed: () => Navigator.pop(ctx, true),
            icon: const Icon(Icons.play_circle_outline),
            label: Text(s.watchAd),
          ),
        ],
      ),
    );
    if (watch != true || !mounted) return;
    final shown = AdManager.instance.showRewarded(
      onReward: () async {
        await widget.store.storage.unlockTheme(t.id);
        if (!mounted) return;
        _applyTheme(t);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(s.unlocked)));
      },
    );
    if (!shown) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(s.adNotReady)));
    }
  }

  Future<void> _edit() async {
    final r = _roulette;
    if (r == null || _spinning) return;
    final edited = await Navigator.push<Roulette>(context, MaterialPageRoute(builder: (_) => EditScreen(initial: r)));
    if (edited == null || !mounted) return;
    await widget.store.update(edited);
    setState(() {
      _picked.clear();
      _rotation = 0;
    });
  }

  // ------------------------------------------------------------------ UI

  @override
  Widget build(BuildContext context) {
    final s = _s;
    final cs = Theme.of(context).colorScheme;
    return ListenableBuilder(
      listenable: widget.store,
      builder: (context, _) {
        final r = _roulette;
        if (r == null) return const Scaffold(body: SizedBox());
        final avail = _available(r).length;
        final disabled = _removeWinner ? _picked : const <int>{};
        return Scaffold(
          appBar: AppBar(
            title: Text(r.title, maxLines: 1, overflow: TextOverflow.ellipsis),
            actions: [
              IconButton(tooltip: s.theme, icon: const Icon(Icons.palette_outlined), onPressed: _spinning ? null : _showThemes),
              IconButton(tooltip: s.edit, icon: const Icon(Icons.edit_outlined), onPressed: _spinning ? null : _edit),
            ],
          ),
          bottomNavigationBar: const BannerAdWidget(),
          body: SafeArea(
            child: Column(
              children: [
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 8, 20, 4),
                    child: Center(
                      child: AnimatedBuilder(
                        animation: _ctrl,
                        builder: (context, _) => WheelWidget(
                          items: r.items,
                          rotation: _rotation,
                          theme: _theme,
                          disabled: disabled,
                          onTap: _spin,
                        ),
                      ),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    children: [
                      Switch(
                        value: _removeWinner,
                        onChanged: _spinning ? null : (v) => setState(() => _removeWinner = v),
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(s.removeWinner, style: Theme.of(context).textTheme.bodyLarge),
                            if (_removeWinner)
                              Text(s.remaining(avail, r.items.length),
                                  style: TextStyle(color: cs.onSurfaceVariant, fontSize: 12)),
                          ],
                        ),
                      ),
                      if (_removeWinner && _picked.isNotEmpty)
                        TextButton.icon(
                          onPressed: _spinning ? null : _reset,
                          icon: const Icon(Icons.restart_alt_rounded, size: 18),
                          label: Text(s.reset),
                        ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 6, 24, 8),
                  child: SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: FilledButton(
                      onPressed: _spinning || avail == 0 ? null : _spin,
                      style: FilledButton.styleFrom(
                        textStyle: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800, letterSpacing: 4),
                      ),
                      child: Text(_spinning ? s.spinning : s.spin),
                    ),
                  ),
                ),
                SizedBox(
                  height: 44,
                  child: _history.isEmpty
                      ? null
                      : ListView(
                          scrollDirection: Axis.horizontal,
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          children: [
                            Center(child: Text('${s.history}: ', style: TextStyle(color: cs.onSurfaceVariant))),
                            for (final h in _history)
                              Padding(
                                padding: const EdgeInsets.only(right: 6),
                                child: Chip(label: Text(h), visualDensity: VisualDensity.compact),
                              ),
                            Center(
                              child: TextButton(
                                onPressed: () => setState(_history.clear),
                                child: Text(s.clearHistory),
                              ),
                            ),
                          ],
                        ),
                ),
                const SizedBox(height: 4),
              ],
            ),
          ),
        );
      },
    );
  }
}

/// 테마 선택 시트의 한 칸: 색상 미리보기 + 이름 (+ 잠금 아이콘).
class _ThemeChip extends StatelessWidget {
  final WheelTheme theme;
  final String name;
  final bool selected;
  final bool locked;
  final VoidCallback onTap;
  const _ThemeChip({required this.theme, required this.name, required this.selected, required this.locked, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        width: 96,
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: selected ? cs.primary : cs.outlineVariant, width: selected ? 2.5 : 1),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Stack(
              alignment: Alignment.center,
              children: [
                SizedBox(width: 56, height: 56, child: CustomPaint(painter: _PalettePainter(theme))),
                if (locked)
                  Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(color: Colors.black.withValues(alpha: 0.45), shape: BoxShape.circle),
                    child: const Icon(Icons.lock_rounded, color: Colors.white, size: 24),
                  ),
              ],
            ),
            const SizedBox(height: 6),
            Text(name, style: Theme.of(context).textTheme.labelMedium, maxLines: 1, overflow: TextOverflow.ellipsis),
          ],
        ),
      ),
    );
  }
}

class _PalettePainter extends CustomPainter {
  final WheelTheme theme;
  _PalettePainter(this.theme);

  @override
  void paint(Canvas canvas, Size size) {
    final n = theme.colors.length;
    final sweep = 2 * math.pi / n;
    for (var i = 0; i < n; i++) {
      canvas.drawArc(Offset.zero & size, -math.pi / 2 + i * sweep, sweep, true, Paint()..color = theme.colors[i]);
    }
  }

  @override
  bool shouldRepaint(_PalettePainter old) => old.theme != theme;
}
