import 'package:dentity/dentity.dart';
import 'package:dentity/src/entity/entity_serialiser_json.dart';

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

class PositionSerializer extends ComponentSerializer<Position> {
  static const type = 'Position';
  @override
  ComponentRepresentation? serialize(Position component) {
    return {
      'x': component.x,
      'y': component.y,
      EntitySerialiserJson.typeField: type
    };
  }

  @override
  Position deserialize(ComponentRepresentation data) {
    final positionData = data as Map<String, dynamic>;
    return Position(
      positionData['x'] as double,
      positionData['y'] as double,
    );
  }

  @override
  bool canSerialize(Object component) {
    return component is Position;
  }

  @override
  bool canDeserialize(ComponentRepresentation data) {
    return data is Map<String, dynamic> &&
        data[EntitySerialiserJson.typeField] == type;
  }
}

class VelocitySerializer extends ComponentSerializer<Velocity> {
  static const type = 'Velocity';
  @override
  ComponentRepresentation? serialize(Velocity component) {
    return {
      'x': component.x,
      'y': component.y,
      EntitySerialiserJson.typeField: type
    };
  }

  @override
  Velocity deserialize(ComponentRepresentation data) {
    final velocityData = data as Map<String, dynamic>;
    return Velocity(
      velocityData['x'] as double,
      velocityData['y'] as double,
    );
  }

  @override
  bool canSerialize(Object component) {
    return component is Velocity;
  }

  @override
  bool canDeserialize(ComponentRepresentation data) {
    return data is Map<String, dynamic> &&
        data[EntitySerialiserJson.typeField] == 'Velocity';
  }
}

class OtherComponentSerializer extends ComponentSerializer<OtherComponent> {
  static const type = 'OtherComponent';
  @override
  ComponentRepresentation? serialize(OtherComponent component) {
    return {EntitySerialiserJson.typeField: type};
  }

  @override
  OtherComponent deserialize(ComponentRepresentation data) {
    return OtherComponent();
  }

  @override
  bool canSerialize(Object component) {
    return component is OtherComponent;
  }

  @override
  bool canDeserialize(ComponentRepresentation data) {
    return data is Map<String, dynamic> &&
        data[EntitySerialiserJson.typeField] == type;
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
    Map<Type, SparseList<Component>> componentLists,
    Duration delta,
  ) {
    final position = componentLists[Position]?[entity] as Position;
    final velocity = componentLists[Velocity]?[entity] as Velocity;
    position.x += velocity.x;
    position.y += velocity.y;
  }
}

ComponentManager _createContiguousComponentManager() {
  return ComponentManager(
    archetypeManagerFactory: (types) => ArchetypeManagerBigInt(types),
    componentArrayFactories: {
      Position: () => ContiguousSparseList<Position>(),
      Velocity: () => ContiguousSparseList<Velocity>(),
      OtherComponent: () => ContiguousSparseList<OtherComponent>(),
      ...componentListFactories
    },
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

//Dummy components for testing

class OtherComponent1 extends OtherComponent {}

class OtherComponent2 extends OtherComponent {}

class OtherComponent3 extends OtherComponent {}

class OtherComponent4 extends OtherComponent {}

class OtherComponent5 extends OtherComponent {}

class OtherComponent6 extends OtherComponent {}

class OtherComponent7 extends OtherComponent {}

class OtherComponent8 extends OtherComponent {}

class OtherComponent9 extends OtherComponent {}

class OtherComponent10 extends OtherComponent {}

class OtherComponent11 extends OtherComponent {}

class OtherComponent12 extends OtherComponent {}

class OtherComponent13 extends OtherComponent {}

class OtherComponent14 extends OtherComponent {}

class OtherComponent15 extends OtherComponent {}

class OtherComponent16 extends OtherComponent {}

class OtherComponent17 extends OtherComponent {}

class OtherComponent18 extends OtherComponent {}

class OtherComponent19 extends OtherComponent {}

class OtherComponent20 extends OtherComponent {}

class OtherComponent21 extends OtherComponent {}

class OtherComponent22 extends OtherComponent {}

class OtherComponent23 extends OtherComponent {}

class OtherComponent24 extends OtherComponent {}

class OtherComponent25 extends OtherComponent {}

class OtherComponent26 extends OtherComponent {}

class OtherComponent27 extends OtherComponent {}

class OtherComponent28 extends OtherComponent {}

class OtherComponent29 extends OtherComponent {}

class OtherComponent30 extends OtherComponent {}

class OtherComponent31 extends OtherComponent {}

class OtherComponent32 extends OtherComponent {}

class OtherComponent33 extends OtherComponent {}

class OtherComponent34 extends OtherComponent {}

class OtherComponent35 extends OtherComponent {}

class OtherComponent36 extends OtherComponent {}

class OtherComponent37 extends OtherComponent {}

class OtherComponent38 extends OtherComponent {}

class OtherComponent39 extends OtherComponent {}

class OtherComponent40 extends OtherComponent {}

class OtherComponent41 extends OtherComponent {}

class OtherComponent42 extends OtherComponent {}

class OtherComponent43 extends OtherComponent {}

class OtherComponent44 extends OtherComponent {}

class OtherComponent45 extends OtherComponent {}

class OtherComponent46 extends OtherComponent {}

class OtherComponent47 extends OtherComponent {}

class OtherComponent48 extends OtherComponent {}

class OtherComponent49 extends OtherComponent {}

class OtherComponent50 extends OtherComponent {}

class OtherComponent51 extends OtherComponent {}

class OtherComponent52 extends OtherComponent {}

class OtherComponent53 extends OtherComponent {}

class OtherComponent54 extends OtherComponent {}

class OtherComponent55 extends OtherComponent {}

class OtherComponent56 extends OtherComponent {}

class OtherComponent57 extends OtherComponent {}

class OtherComponent58 extends OtherComponent {}

class OtherComponent59 extends OtherComponent {}

class OtherComponent60 extends OtherComponent {}

class OtherComponent61 extends OtherComponent {}

class OtherComponent62 extends OtherComponent {}

class OtherComponent63 extends OtherComponent {}

class OtherComponent64 extends OtherComponent {}

class OtherComponent65 extends OtherComponent {}

const allOtherTypes = [
  OtherComponent1,
  OtherComponent2,
  OtherComponent3,
  OtherComponent4,
  OtherComponent5,
  OtherComponent6,
  OtherComponent7,
  OtherComponent8,
  OtherComponent9,
  OtherComponent10,
  OtherComponent11,
  OtherComponent12,
  OtherComponent13,
  OtherComponent14,
  OtherComponent15,
  OtherComponent16,
  OtherComponent17,
  OtherComponent18,
  OtherComponent19,
  OtherComponent20,
  OtherComponent21,
  OtherComponent22,
  OtherComponent23,
  OtherComponent24,
  OtherComponent25,
  OtherComponent26,
  OtherComponent27,
  OtherComponent28,
  OtherComponent29,
  OtherComponent30,
  OtherComponent31,
  OtherComponent32,
  OtherComponent33,
  OtherComponent34,
  OtherComponent35,
  OtherComponent36,
  OtherComponent37,
  OtherComponent38,
  OtherComponent39,
  OtherComponent40,
  OtherComponent41,
  OtherComponent42,
  OtherComponent43,
  OtherComponent44,
  OtherComponent45,
  OtherComponent46,
  OtherComponent47,
  OtherComponent48,
  OtherComponent49,
  OtherComponent50,
  OtherComponent51,
  OtherComponent52,
  OtherComponent53,
  OtherComponent54,
  OtherComponent55,
  OtherComponent56,
  OtherComponent57,
  OtherComponent58,
  OtherComponent59,
  OtherComponent60,
  OtherComponent61,
  OtherComponent62,
  OtherComponent63,
  OtherComponent64,
  OtherComponent65,
];
final allOtherTypesInstances = <Component>[
  OtherComponent1(),
  OtherComponent2(),
  OtherComponent3(),
  OtherComponent4(),
  OtherComponent5(),
  OtherComponent6(),
  OtherComponent7(),
  OtherComponent8(),
  OtherComponent9(),
  OtherComponent10(),
  OtherComponent11(),
  OtherComponent12(),
  OtherComponent13(),
  OtherComponent14(),
  OtherComponent15(),
  OtherComponent16(),
  OtherComponent17(),
  OtherComponent18(),
  OtherComponent19(),
  OtherComponent20(),
  OtherComponent21(),
  OtherComponent22(),
  OtherComponent23(),
  OtherComponent24(),
  OtherComponent25(),
  OtherComponent26(),
  OtherComponent27(),
  OtherComponent28(),
  OtherComponent29(),
  OtherComponent30(),
  OtherComponent31(),
  OtherComponent32(),
  OtherComponent33(),
  OtherComponent34(),
  OtherComponent35(),
  OtherComponent36(),
  OtherComponent37(),
  OtherComponent38(),
  OtherComponent39(),
  OtherComponent40(),
  OtherComponent41(),
  OtherComponent42(),
  OtherComponent43(),
  OtherComponent44(),
  OtherComponent45(),
  OtherComponent46(),
  OtherComponent47(),
  OtherComponent48(),
  OtherComponent49(),
  OtherComponent50(),
  OtherComponent51(),
  OtherComponent52(),
  OtherComponent53(),
  OtherComponent54(),
  OtherComponent55(),
  OtherComponent56(),
  OtherComponent57(),
  OtherComponent58(),
  OtherComponent59(),
  OtherComponent60(),
  OtherComponent61(),
  OtherComponent62(),
  OtherComponent63(),
  OtherComponent64(),
  OtherComponent65(),
];

Map<Type, ComponentListFactory> componentListFactories = {
  OtherComponent1: () => ContiguousSparseList<OtherComponent1>(),
  OtherComponent2: () => ContiguousSparseList<OtherComponent2>(),
  OtherComponent3: () => ContiguousSparseList<OtherComponent3>(),
  OtherComponent4: () => ContiguousSparseList<OtherComponent4>(),
  OtherComponent5: () => ContiguousSparseList<OtherComponent5>(),
  OtherComponent6: () => ContiguousSparseList<OtherComponent6>(),
  OtherComponent7: () => ContiguousSparseList<OtherComponent7>(),
  OtherComponent8: () => ContiguousSparseList<OtherComponent8>(),
  OtherComponent9: () => ContiguousSparseList<OtherComponent9>(),
  OtherComponent10: () => ContiguousSparseList<OtherComponent10>(),
  OtherComponent11: () => ContiguousSparseList<OtherComponent11>(),
  OtherComponent12: () => ContiguousSparseList<OtherComponent12>(),
  OtherComponent13: () => ContiguousSparseList<OtherComponent13>(),
  OtherComponent14: () => ContiguousSparseList<OtherComponent14>(),
  OtherComponent15: () => ContiguousSparseList<OtherComponent15>(),
  OtherComponent16: () => ContiguousSparseList<OtherComponent16>(),
  OtherComponent17: () => ContiguousSparseList<OtherComponent17>(),
  OtherComponent18: () => ContiguousSparseList<OtherComponent18>(),
  OtherComponent19: () => ContiguousSparseList<OtherComponent19>(),
  OtherComponent20: () => ContiguousSparseList<OtherComponent20>(),
  OtherComponent21: () => ContiguousSparseList<OtherComponent21>(),
  OtherComponent22: () => ContiguousSparseList<OtherComponent22>(),
  OtherComponent23: () => ContiguousSparseList<OtherComponent23>(),
  OtherComponent24: () => ContiguousSparseList<OtherComponent24>(),
  OtherComponent25: () => ContiguousSparseList<OtherComponent25>(),
  OtherComponent26: () => ContiguousSparseList<OtherComponent26>(),
  OtherComponent27: () => ContiguousSparseList<OtherComponent27>(),
  OtherComponent28: () => ContiguousSparseList<OtherComponent28>(),
  OtherComponent29: () => ContiguousSparseList<OtherComponent29>(),
  OtherComponent30: () => ContiguousSparseList<OtherComponent30>(),
  OtherComponent31: () => ContiguousSparseList<OtherComponent31>(),
  OtherComponent32: () => ContiguousSparseList<OtherComponent32>(),
  OtherComponent33: () => ContiguousSparseList<OtherComponent33>(),
  OtherComponent34: () => ContiguousSparseList<OtherComponent34>(),
  OtherComponent35: () => ContiguousSparseList<OtherComponent35>(),
  OtherComponent36: () => ContiguousSparseList<OtherComponent36>(),
  OtherComponent37: () => ContiguousSparseList<OtherComponent37>(),
  OtherComponent38: () => ContiguousSparseList<OtherComponent38>(),
  OtherComponent39: () => ContiguousSparseList<OtherComponent39>(),
  OtherComponent40: () => ContiguousSparseList<OtherComponent40>(),
  OtherComponent41: () => ContiguousSparseList<OtherComponent41>(),
  OtherComponent42: () => ContiguousSparseList<OtherComponent42>(),
  OtherComponent43: () => ContiguousSparseList<OtherComponent43>(),
  OtherComponent44: () => ContiguousSparseList<OtherComponent44>(),
  OtherComponent45: () => ContiguousSparseList<OtherComponent45>(),
  OtherComponent46: () => ContiguousSparseList<OtherComponent46>(),
  OtherComponent47: () => ContiguousSparseList<OtherComponent47>(),
  OtherComponent48: () => ContiguousSparseList<OtherComponent48>(),
  OtherComponent49: () => ContiguousSparseList<OtherComponent49>(),
  OtherComponent50: () => ContiguousSparseList<OtherComponent50>(),
  OtherComponent51: () => ContiguousSparseList<OtherComponent51>(),
  OtherComponent52: () => ContiguousSparseList<OtherComponent52>(),
  OtherComponent53: () => ContiguousSparseList<OtherComponent53>(),
  OtherComponent54: () => ContiguousSparseList<OtherComponent54>(),
  OtherComponent55: () => ContiguousSparseList<OtherComponent55>(),
  OtherComponent56: () => ContiguousSparseList<OtherComponent56>(),
  OtherComponent57: () => ContiguousSparseList<OtherComponent57>(),
  OtherComponent58: () => ContiguousSparseList<OtherComponent58>(),
  OtherComponent59: () => ContiguousSparseList<OtherComponent59>(),
  OtherComponent60: () => ContiguousSparseList<OtherComponent60>(),
  OtherComponent61: () => ContiguousSparseList<OtherComponent61>(),
  OtherComponent62: () => ContiguousSparseList<OtherComponent62>(),
  OtherComponent63: () => ContiguousSparseList<OtherComponent63>(),
  OtherComponent64: () => ContiguousSparseList<OtherComponent64>(),
  OtherComponent65: () => ContiguousSparseList<OtherComponent65>(),
};
