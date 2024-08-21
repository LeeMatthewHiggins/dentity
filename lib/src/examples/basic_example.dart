import 'package:dentity/dentity.dart';
import 'package:dentity/src/archetypes/archetype_manager_big_int.dart';

class Position extends Component {
  double x;
  double y;

  Position(this.x, this.y);

  @override
  Position clone() {
    return Position(x, y);
  }

  @override
  bool operator ==(Object other) {
    if (other is Position) {
      return x == other.x && y == other.y;
    }
    return false;
  }

  @override
  int get hashCode => x.hashCode ^ y.hashCode;

  @override
  int compareTo(other) {
    if (other is Position) {
      return x.compareTo(other.x) + y.compareTo(other.y);
    }
    return -1;
  }
}

class Velocity extends Component {
  double x;
  double y;

  Velocity(this.x, this.y);

  @override
  Velocity clone() {
    return Velocity(x, y);
  }

  @override
  bool operator ==(Object other) {
    if (other is Velocity) {
      return x == other.x && y == other.y;
    }
    return false;
  }

  @override
  int get hashCode => x.hashCode ^ y.hashCode;

  @override
  int compareTo(other) {
    if (other is Velocity) {
      return x.compareTo(other.x) + y.compareTo(other.y);
    }
    return -1;
  }
}

class OtherComponent extends Component {
  OtherComponent();

  @override
  OtherComponent clone() {
    return OtherComponent();
  }

  @override
  bool operator ==(Object other) {
    return other is OtherComponent;
  }

  @override
  int get hashCode => 0;

  @override
  int compareTo(other) {
    if (other is OtherComponent) {
      return 0;
    }
    return -1;
  }
}

class MovementSystem extends EntitySystem {
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
    archetypeManagerFactory: (types) => ArchetypeManagerBigInt(types),
    componentArrayFactories: {
      Position: () => SimpleSparseList<Position>(),
      Velocity: () => SimpleSparseList<Velocity>(),
      OtherComponent: () => SimpleSparseList<OtherComponent>(),
    },
  );
}

ComponentManager _createContiguousComponentManager() {
  return ComponentManager(
    archetypeManagerFactory: (types) => ArchetypeManagerBigInt(types),
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
