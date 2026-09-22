import 'package:flutter/material.dart';

import '../l10n/strings.dart';
import '../model/roulette.dart';

/// 룰렛 만들기 / 편집. 저장하면 [Roulette] 을 돌려준다 (저장은 호출한 쪽에서).
class EditScreen extends StatefulWidget {
  final Roulette? initial;
  const EditScreen({super.key, this.initial});

  @override
  State<EditScreen> createState() => _EditScreenState();
}

class _EditScreenState extends State<EditScreen> {
  late final TextEditingController _title;
  final List<TextEditingController> _items = [];
  final List<FocusNode> _focus = [];
  final _formKey = GlobalKey<FormState>();
  final _listKey = GlobalKey<AnimatedListState>();
  bool _dirty = false;

  S get _s => S.of(context);

  @override
  void initState() {
    super.initState();
    _title = TextEditingController(text: widget.initial?.title ?? '');
    final initialItems = widget.initial?.items ?? const ['', '', ''];
    for (final it in initialItems) {
      _addController(it);
    }
  }

  void _addController(String text) {
    _items.add(TextEditingController(text: text));
    _focus.add(FocusNode());
  }

  @override
  void dispose() {
    _title.dispose();
    for (final c in _items) {
      c.dispose();
    }
    for (final f in _focus) {
      f.dispose();
    }
    super.dispose();
  }

  void _add() {
    if (_items.length >= Roulette.maxItems) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(_s.maxItems(Roulette.maxItems))));
      return;
    }
    setState(() {
      _addController('');
      _dirty = true;
    });
    _listKey.currentState?.insertItem(_items.length - 1, duration: const Duration(milliseconds: 200));
    WidgetsBinding.instance.addPostFrameCallback((_) => _focus.last.requestFocus());
  }

  void _removeAt(int i) {
    final c = _items.removeAt(i);
    final f = _focus.removeAt(i);
    _dirty = true;
    _listKey.currentState?.removeItem(
      i,
      (context, anim) => SizeTransition(sizeFactor: anim, child: _row(context, i, c, f, removable: false)),
      duration: const Duration(milliseconds: 180),
    );
    setState(() {});
    // 애니메이션 프레임이 controller 를 참조하므로 끝난 뒤에 해제한다.
    Future.delayed(const Duration(milliseconds: 250), () {
      c.dispose();
      f.dispose();
    });
  }

  void _shuffle() {
    final texts = _items.map((c) => c.text).toList()..shuffle();
    for (var i = 0; i < texts.length; i++) {
      _items[i].text = texts[i];
    }
    setState(() => _dirty = true);
  }

  List<String> get _cleanItems => _items.map((c) => c.text.trim()).where((t) => t.isNotEmpty).toList();

  void _save() {
    final s = _s;
    final title = _title.text.trim();
    if (title.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(s.needTitle)));
      return;
    }
    final items = _cleanItems;
    if (items.length < Roulette.minItems) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(s.needItems(Roulette.minItems))));
      return;
    }
    final r = widget.initial?.copyWith(title: title, items: items) ?? Roulette.create(title, items);
    Navigator.pop(context, r);
  }

  Future<bool> _confirmDiscard() async {
    if (!_dirty) return true;
    final s = _s;
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(s.discardTitle),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(s.cancel)),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: Text(s.discard)),
        ],
      ),
    );
    return ok == true;
  }

  Widget _row(BuildContext context, int i, TextEditingController c, FocusNode f, {bool removable = true}) {
    final s = _s;
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          SizedBox(
            width: 28,
            child: Text('${i + 1}', textAlign: TextAlign.center,
                style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant, fontWeight: FontWeight.w600)),
          ),
          Expanded(
            child: TextField(
              controller: c,
              focusNode: f,
              maxLength: 30,
              textInputAction: TextInputAction.next,
              onChanged: (_) => _dirty = true,
              onSubmitted: (_) {
                if (i == _items.length - 1) {
                  _add();
                } else {
                  _focus[i + 1].requestFocus();
                }
              },
              decoration: InputDecoration(
                hintText: s.itemHint(i + 1),
                isDense: true,
                counterText: '',
                border: const OutlineInputBorder(),
              ),
            ),
          ),
          IconButton(
            tooltip: s.delete,
            icon: const Icon(Icons.remove_circle_outline),
            onPressed: removable && _items.length > 1 ? () => _removeAt(i) : null,
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final s = _s;
    return PopScope(
      canPop: !_dirty,
      onPopInvokedWithResult: (didPop, _) async {
        if (didPop) return;
        final ok = await _confirmDiscard();
        if (!ok || !context.mounted) return;
        Navigator.pop(context);
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(widget.initial == null ? s.newRoulette : s.editRoulette),
          actions: [
            IconButton(tooltip: s.shuffle, icon: const Icon(Icons.shuffle_rounded), onPressed: _shuffle),
            TextButton(onPressed: _save, child: Text(s.save)),
            const SizedBox(width: 4),
          ],
        ),
        body: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
            children: [
              TextField(
                controller: _title,
                maxLength: 40,
                textInputAction: TextInputAction.next,
                onChanged: (_) => _dirty = true,
                decoration: InputDecoration(labelText: s.title, hintText: s.titleHint, border: const OutlineInputBorder()),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Text(s.items, style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(width: 8),
                  Text('${_items.length} / ${Roulette.maxItems}',
                      style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant)),
                ],
              ),
              const SizedBox(height: 8),
              AnimatedList(
                key: _listKey,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                initialItemCount: _items.length,
                itemBuilder: (context, i, anim) =>
                    SizeTransition(sizeFactor: anim, child: _row(context, i, _items[i], _focus[i])),
              ),
              OutlinedButton.icon(
                onPressed: _items.length < Roulette.maxItems ? _add : null,
                icon: const Icon(Icons.add_rounded),
                label: Text(s.addItem),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
