import 'package:flutter/foundation.dart';

import '../l10n/strings.dart';
import '../model/roulette.dart';
import 'storage.dart';

/// 룰렛 목록의 메모리 사본. 바뀔 때마다 [Storage] 에 저장하고 리스너에 알린다.
class RouletteStore extends ChangeNotifier {
  final Storage storage;
  final List<Roulette> _list;

  RouletteStore(this.storage) : _list = storage.loadRoulettes();

  List<Roulette> get all => List.unmodifiable(_list);

  /// 첫 실행이면 언어에 맞는 기본 룰렛을 넣는다.
  Future<void> seedIfEmpty(S s) async {
    if (storage.seeded) return;
    if (_list.isEmpty) {
      for (final (title, items) in s.presets) {
        _list.add(Roulette.create(title, items));
      }
    }
    await storage.markSeeded();
    await _save();
  }

  Roulette? byId(String id) => _list.cast<Roulette?>().firstWhere((r) => r!.id == id, orElse: () => null);

  Future<void> add(Roulette r) async {
    _list.insert(0, r);
    await _save();
  }

  Future<void> update(Roulette r) async {
    final i = _list.indexWhere((e) => e.id == r.id);
    if (i < 0) return add(r);
    _list[i] = r;
    await _save();
  }

  Future<void> remove(String id) async {
    _list.removeWhere((r) => r.id == id);
    await _save();
  }

  Future<void> duplicate(Roulette r, String suffix) async {
    final i = _list.indexWhere((e) => e.id == r.id);
    _list.insert(i < 0 ? 0 : i + 1, r.copyWith(id: Roulette.newId(), title: r.title + suffix, spins: 0));
    await _save();
  }

  Future<void> countSpin(String id) async {
    final r = byId(id);
    if (r == null) return;
    r.spins++;
    await _save();
  }

  Future<void> _save() async {
    await storage.saveRoulettes(_list);
    notifyListeners();
  }
}
