import 'package:dentity/dentity.dart';
import 'package:dentity/dentity_examples.dart';
import 'package:test/test.dart';

void main() {
  group('ContiguousSparseList', () {
    test('supports add, retrieve and remove', () {
      final list = ContiguousSparseList<int>();
      list[2] = 10;
      list[5] = 20;
      expect(list[2], equals(10));
      expect(list[5], equals(20));
      expect(list.indices, containsAll(<int>[2, 5]));
      list.remove(2);
      expect(list[2], isNull);
      expect(list.indices, contains(5));
      expect(list.length, equals(1));
      list.clear();
      expect(list.isEmpty, isTrue);
    });
  });

  group('SimpleSparseList', () {
    test('basic operations', () {
      final list = SimpleSparseList<String>();
      list[1] = 'a';
      list[3] = 'b';
      expect(list[1], 'a');
      expect(list.values.toList(), containsAll(['a', 'b']));
      list.remove(1);
      expect(list[1], isNull);
      expect(list.indices, contains(3));
      list.clear();
      expect(list.isEmpty, isTrue);
    });
  });

  group('EntitySerialiserJson error handling', () {
    test('throws on invalid serialize component', () {
      final world = createBasicExampleWorld();
      final serialiser = EntitySerialiserJson(world.entityManager, {
        Position: PositionJsonSerializer(),
        Velocity: VelocityJsonSerializer(),
      });
      expect(
        () => serialiser.serializeEntityComponents(0, ['bad']),
        throwsArgumentError,
      );
    });

    test('throws on invalid deserialize data', () {
      final world = createBasicExampleWorld();
      final serialiser = EntitySerialiserJson(world.entityManager, {
        Position: PositionJsonSerializer(),
        Velocity: VelocityJsonSerializer(),
      });
      expect(() => serialiser.deserializeEntityComponents('nope'),
          throwsArgumentError);
      expect(
        () => serialiser.deserializeEntityComponents({'components': []}),
        throwsArgumentError,
      );
    });
  });
}
