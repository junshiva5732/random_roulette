import 'dart:math' as math;

import 'package:flutter_test/flutter_test.dart';
import 'package:random_roulette/model/roulette.dart';

void main() {
  group('SpinMath', () {
    test('rotation 0 points at slice 0', () {
      for (final n in [2, 3, 5, 8, 20]) {
        expect(SpinMath.indexAt(0, n), 0);
      }
    });

    test('targetRotation lands on the requested winner', () {
      final rng = math.Random(42);
      for (var trial = 0; trial < 500; trial++) {
        final n = 2 + rng.nextInt(19);
        final winner = rng.nextInt(n);
        final from = rng.nextDouble() * 40;
        final fraction = 0.1 + rng.nextDouble() * 0.8;
        final turns = 1 + rng.nextInt(6);
        final target = SpinMath.targetRotation(from, winner, n, fraction: fraction, fullTurns: turns);
        expect(target, greaterThan(from));
        expect(target - from, greaterThanOrEqualTo(turns * 2 * math.pi));
        expect(target - from, lessThan((turns + 1) * 2 * math.pi));
        expect(SpinMath.indexAt(target, n), winner, reason: 'n=$n winner=$winner from=$from');
      }
    });

    test('pick returns a consistent winner/target pair', () {
      final rng = math.Random(7);
      for (var i = 0; i < 200; i++) {
        final n = 2 + rng.nextInt(19);
        final res = SpinMath.pick(rng.nextDouble() * 10, n, rng);
        expect(SpinMath.indexAt(res.target, n), res.winner);
      }
    });

    test('every slice is reachable and roughly uniform', () {
      final rng = math.Random(1);
      const n = 6;
      final counts = List.filled(n, 0);
      for (var i = 0; i < 6000; i++) {
        counts[SpinMath.pick(0, n, rng).winner]++;
      }
      for (final c in counts) {
        expect(c, inInclusiveRange(800, 1200));
      }
    });
  });

  group('Roulette', () {
    test('json round trip', () {
      final r = Roulette.create('Lunch', ['A', 'B', 'C'])..spins = 3;
      final back = Roulette.fromJson(r.toJson());
      expect(back.id, r.id);
      expect(back.title, 'Lunch');
      expect(back.items, ['A', 'B', 'C']);
      expect(back.spins, 3);
    });

    test('copyWith copies the item list', () {
      final r = Roulette.create('X', ['A', 'B']);
      final c = r.copyWith();
      c.items.add('C');
      expect(r.items.length, 2);
    });

    test('ids are unique', () {
      final ids = {for (var i = 0; i < 1000; i++) Roulette.newId()};
      expect(ids.length, 1000);
    });
  });
}
