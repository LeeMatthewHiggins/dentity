import 'package:dentity/dentity.dart';
import 'package:test/test.dart';

class Position extends Component {
  double x;
  double y;

  Position(this.x, this.y);
}

class Velocity extends Component {
  double x;
  double y;

  Velocity(this.x, this.y);
}

class OtherComponent extends Component {
  OtherComponent();
}

class MovementSystem extends System {
  MovementSystem();
  @override
  Set<Type> get filterTypes => const {Position, Velocity};

  @override
  void processEntity(Entity entity) {
    var position = view.getComponent<Position>(entity)!;
    var velocity = view.getComponent<Velocity>(entity)!;
    position.x += velocity.x;
    position.y += velocity.y;
  }
}

ComponentManager _createComponentManager() {
  return ComponentManager(
    componentArrayFactories: {
      Position: () => SimpleSparseArray<Position>(),
      Velocity: () => SimpleSparseArray<Velocity>(),
      OtherComponent: () => SimpleSparseArray<OtherComponent>(),
    },
  );
}

World _createWorld() {
  final componentManager = _createComponentManager();
  final entityManager = EntityManager(componentManager);
  final movementSystem = MovementSystem();
  return World(
    entityManager,
    [movementSystem],
  );
}

void main() {
  group(
    'Test Functionality',
    () {
      test(
        'Test an example system runs only on entities it should',
        () {
          final world = _createWorld();
          final testEntity = world.createEntity(
            [
              Position(0, 0),
              Velocity(1, 1),
            ],
          );
          final controlEntity = world.createEntity(
            [
              Position(0, 0),
              OtherComponent(),
            ],
          );

          world.process();

          final position = world.getComponent<Position>(testEntity);
          expect(position!.x, 1);
          expect(position.y, 1);

          final controlPosition = world.getComponent<Position>(controlEntity);
          expect(controlPosition!.x, 0);
          expect(controlPosition.y, 0);
        },
      );

      test(
        'Test an example system runs multiple times correctly',
        () {
          const runTimes = 10;
          final world = _createWorld();
          final testEntity = world.createEntity(
            [
              Position(0, 0),
              Velocity(1, 1),
            ],
          );

          for (var i = 0; i < runTimes; i++) {
            world.process();
          }

          final position = world.getComponent<Position>(testEntity);
          expect(position!.x, runTimes);
          expect(position.y, runTimes);
        },
      );

      test(
        'Test system does not process entities without required components',
        () {
          final world = _createWorld();
          final entityWithoutVelocity = world.createEntity([Position(0, 0)]);

          world.process();

          final position = world.getComponent<Position>(entityWithoutVelocity);
          expect(position!.x, 0);
          expect(position.y, 0);
        },
      );

      test(
        'Test system processes multiple entities correctly',
        () {
          final world = _createWorld();

          final entity1 = world.createEntity([Position(0, 0), Velocity(1, 1)]);
          final entity2 =
              world.createEntity([Position(10, 10), Velocity(-1, -1)]);

          world.process();

          final position1 = world.getComponent<Position>(entity1);
          expect(position1!.x, 1);
          expect(position1.y, 1);

          final position2 = world.getComponent<Position>(entity2);
          expect(position2!.x, 9);
          expect(position2.y, 9);
        },
      );

      test(
        'Test system does not fail with no entities',
        () {
          final world = _createWorld();
          // No entities created
          world.process();
          // No assertions needed, just ensuring no exceptions are thrown
        },
      );

      test(
        'Test system handles an entity removal correctly',
        () {
          final world = _createWorld();

          final entity = world.createEntity([Position(0, 0), Velocity(1, 1)]);
          world.process();

          world.removeEntity(entity);
          world.process();

          // Ensure the entity is removed
          final position = world.getComponent<Position>(entity);
          expect(position, isNull);
        },
      );

      test('Reuse of entities', () {
        final world = _createWorld();
        world.createEntity([Position(0, 0), Velocity(1, 1)]);
        final positionOnly = world.createEntity([Position(0, 0)]);
        final entity2 = world.createEntity([Position(0, 0), Velocity(1, 1)]);
        world.removeEntity(positionOnly);
        world.removeEntity(entity2);
        final recycledPositionOnly = world.createEntity([Position(0, 0)]);
        expect(recycledPositionOnly, equals(positionOnly));
        final newPositionOnly = world.createEntity([Position(0, 0)]);
        expect(newPositionOnly, isNot(recycledPositionOnly));
      });

      test('test mutation of entity', () {
        final world = _createWorld();
        final entity1 = world.createEntity({Position(0, 0), Velocity(1, 1)});
        final entity2 = world.createEntity({Position(0, 0), Velocity(1, 1)});
        world.removeComponents(entity1, {Position});
        world.addComponents(entity2, {OtherComponent()});
        final position = world.getComponent<Position>(entity1);
        expect(position, isNull);
        final velocity = world.getComponent<Velocity>(entity1);
        expect(velocity, isNotNull);

        final otherComponent = world.getComponent<OtherComponent>(entity2);
        expect(otherComponent, isNotNull);
      });
    },
  );

  group('Test Performance', () {
    const runTimes = 1000;
    test('Creation', () {
      final world = _createWorld();
      final sw = Stopwatch()..start();
      for (var i = 0; i < runTimes; i++) {
        world.createEntity([Position(0, 0), Velocity(1, 1)]);
      }
      sw.stop();
      print('Creation benchmark took ${sw.elapsedMilliseconds}ms');
      expect(sw.elapsedMilliseconds, lessThan(10));
    });

    test('Processing', () {
      final world = _createWorld();
      for (var i = 0; i < runTimes; i++) {
        world.createEntity([Position(0, 0), Velocity(1, 1)]);
      }

      final sw = Stopwatch()..start();
      for (var i = 0; i < runTimes; i++) {
        world.process();
      }
      sw.stop();
      print('Processing Benchmark took ${sw.elapsedMilliseconds}ms');
      expect(sw.elapsedMilliseconds, lessThan(50));
    });

    test('Removal', () {
      final world = _createWorld();
      final entities = <Entity>[];
      for (var i = 0; i < runTimes; i++) {
        entities.add(world.createEntity([Position(0, 0), Velocity(1, 1)]));
      }

      final sw = Stopwatch()..start();
      for (var i = 0; i < runTimes; i++) {
        world.removeEntity(entities[i]);
      }
      sw.stop();
      print('Removal Benchmark took ${sw.elapsedMilliseconds}ms');
      expect(sw.elapsedMilliseconds, lessThan(10));
    });
  });
}
