import 'package:dentity/dentity.dart';

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
  void processEntity(
    Entity entity,
    Map<Type, SparseList<Component>> componentArrays,
    Duration delta,
  ) {
    final position = componentArrays[Position]![entity] as Position;
    final velocity = componentArrays[Velocity]![entity] as Velocity;
    position.x += velocity.x;
    position.y += velocity.y;
  }
}

ComponentManager _createSimpleComponentManager() {
  return ComponentManager(
    componentArrayFactories: {
      Position: () => SimpleSparseList<Position>(),
      Velocity: () => SimpleSparseList<Velocity>(),
      OtherComponent: () => SimpleSparseList<OtherComponent>(),
    },
  );
}

ComponentManager _createContiguousComponentManager() {
  return ComponentManager(
    componentArrayFactories: {
      Position: () => ContiguousSparseList<Position>(),
      Velocity: () => ContiguousSparseList<Velocity>(),
      OtherComponent: () => ContiguousSparseList<OtherComponent>(),
    },
  );
}

// ignore: unused_element
World _createSimpleWorld() {
  final componentManager = _createSimpleComponentManager();
  final entityManager = EntityManager(componentManager);
  final movementSystem = MovementSystem();
  return World(
    componentManager,
    entityManager,
    [movementSystem],
  );
}

World _createContiguousWorld() {
  final componentManager = _createContiguousComponentManager();
  final entityManager = EntityManager(componentManager);
  final movementSystem = MovementSystem();
  return World(
    componentManager,
    entityManager,
    [movementSystem],
  );
}

World createBasicExampleWorld() {
  return _createContiguousWorld(); //LH we can switch to _createSimpleWorld if we want to use SimpleSparseList
}
