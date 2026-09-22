import 'package:flutter/material.dart';

import '../l10n/strings.dart';
import '../model/roulette.dart';
import '../services/roulette_store.dart';
import '../theme/wheel_themes.dart';
import '../widgets/banner_ad_widget.dart';
import 'edit_screen.dart';
import 'wheel_screen.dart';

/// 홈: 룰렛 목록. 탭하면 돌리는 화면, 길게 누르면 편집/복제/삭제.
class HomeScreen extends StatefulWidget {
  final RouletteStore store;
  const HomeScreen({super.key, required this.store});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  S get _s => S.of(context);

  Future<void> _open(Roulette r) =>
      Navigator.push(context, MaterialPageRoute(builder: (_) => WheelScreen(store: widget.store, rouletteId: r.id)));

  Future<void> _create() async {
    final r = await Navigator.push<Roulette>(context, MaterialPageRoute(builder: (_) => const EditScreen()));
    if (r == null || !mounted) return;
    await widget.store.add(r);
    if (mounted) _open(r);
  }

  Future<void> _edit(Roulette r) async {
    final edited = await Navigator.push<Roulette>(context, MaterialPageRoute(builder: (_) => EditScreen(initial: r)));
    if (edited != null) await widget.store.update(edited);
  }

  Future<void> _delete(Roulette r) async {
    final s = _s;
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(s.deleteTitle),
        content: Text(s.deleteBody(r.title)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(s.cancel)),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: Text(s.delete)),
        ],
      ),
    );
    if (ok == true) await widget.store.remove(r.id);
  }

  Future<void> _showMenu(Roulette r) async {
    final s = _s;
    final action = await showModalBottomSheet<String>(
      context: context,
      showDragHandle: true,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(title: Text(r.title, style: Theme.of(ctx).textTheme.titleMedium), subtitle: Text(s.itemCount(r.items.length))),
            const Divider(height: 1),
            ListTile(leading: const Icon(Icons.edit_outlined), title: Text(s.edit), onTap: () => Navigator.pop(ctx, 'edit')),
            ListTile(leading: const Icon(Icons.copy_outlined), title: Text(s.duplicate), onTap: () => Navigator.pop(ctx, 'dup')),
            ListTile(
              leading: Icon(Icons.delete_outline, color: Theme.of(ctx).colorScheme.error),
              title: Text(s.delete, style: TextStyle(color: Theme.of(ctx).colorScheme.error)),
              onTap: () => Navigator.pop(ctx, 'del'),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
    if (!mounted) return;
    switch (action) {
      case 'edit':
        _edit(r);
      case 'dup':
        widget.store.duplicate(r, s.copySuffix);
      case 'del':
        _delete(r);
    }
  }

  Future<void> _showLanguage() async {
    final s = _s;
    final controller = LocaleController.of(context);
    final picked = await showDialog<Locale?>(
      context: context,
      builder: (ctx) => SimpleDialog(
        title: Text(s.language),
        children: [
          for (final l in <Locale?>[null, ...S.supported])
            RadioListTile<Locale?>(
              value: l,
              groupValue: controller.value,
              title: Text(l == null ? s.systemLanguage : S.nativeName(l)),
              onChanged: (v) => Navigator.pop(ctx, v ?? const Locale('und')),
            ),
        ],
      ),
    );
    if (!mounted || picked == null) return; // 바깥 탭으로 닫음
    controller.value = picked.languageCode == 'und' ? null : picked;
  }

  void _showHelp() {
    final s = _s;
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(s.howToUse),
        content: SingleChildScrollView(child: Text(s.helpBody)),
        actions: [TextButton(onPressed: () => Navigator.pop(ctx), child: Text(s.ok))],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final s = _s;
    final cs = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(
        title: Text(s.appTitle),
        actions: [
          IconButton(tooltip: s.language, icon: const Icon(Icons.language_rounded), onPressed: _showLanguage),
          IconButton(tooltip: s.howToUse, icon: const Icon(Icons.help_outline_rounded), onPressed: _showHelp),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _create,
        icon: const Icon(Icons.add_rounded),
        label: Text(s.newRoulette),
      ),
      bottomNavigationBar: const BannerAdWidget(),
      body: ListenableBuilder(
        listenable: widget.store,
        builder: (context, _) {
          final list = widget.store.all;
          if (list.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Text(s.emptyHome, textAlign: TextAlign.center, style: Theme.of(context).textTheme.titleMedium),
              ),
            );
          }
          return ListView.separated(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 96),
            itemCount: list.length,
            separatorBuilder: (_, __) => const SizedBox(height: 10),
            itemBuilder: (context, i) {
              final r = list[i];
              return Card(
                clipBehavior: Clip.antiAlias,
                child: ListTile(
                  key: ValueKey(r.id),
                  onTap: () => _open(r),
                  onLongPress: () => _showMenu(r),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                  leading: _MiniWheel(n: r.items.length, theme: WheelTheme.byId(widget.store.storage.themeId)),
                  title: Text(r.title, maxLines: 1, overflow: TextOverflow.ellipsis),
                  subtitle: Text(
                    r.items.join(' · '),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(color: cs.onSurfaceVariant),
                  ),
                  trailing: IconButton(
                    icon: const Icon(Icons.more_vert_rounded),
                    onPressed: () => _showMenu(r),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}

/// 목록에 보이는 작은 룰렛 미리보기.
class _MiniWheel extends StatelessWidget {
  final int n;
  final WheelTheme theme;
  const _MiniWheel({required this.n, required this.theme});

  @override
  Widget build(BuildContext context) => SizedBox(
        width: 44,
        height: 44,
        child: CustomPaint(painter: _MiniWheelPainter(n, theme)),
      );
}

class _MiniWheelPainter extends CustomPainter {
  final int n;
  final WheelTheme theme;
  _MiniWheelPainter(this.n, this.theme);

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final sweep = 6.283185 / n;
    for (var i = 0; i < n; i++) {
      canvas.drawArc(rect, -1.5708 + i * sweep, sweep, true, Paint()..color = theme.colorAt(i, n));
    }
    canvas.drawCircle(rect.center, size.width * 0.14, Paint()..color = Colors.white);
  }

  @override
  bool shouldRepaint(_MiniWheelPainter old) => old.n != n || old.theme != theme;
}
