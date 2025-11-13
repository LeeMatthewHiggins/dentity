import 'package:dentity/dentity.dart';

class Position extends Component {
  double x;
  double y;

  Position(this.x, this.y);

  @override
  Position clone() => Position(x, y);

  @override
  bool operator ==(Object other) =>
      other is Position && x == other.x && y == other.y;

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
  Velocity clone() => Velocity(x, y);

  @override
  bool operator ==(Object other) =>
      other is Velocity && x == other.x && y == other.y;

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

class Rotation extends Component {
  double angle;
  double angularVelocity;

  Rotation(this.angle, this.angularVelocity);

  @override
  Rotation clone() => Rotation(angle, angularVelocity);

  @override
  bool operator ==(Object other) =>
      other is Rotation &&
      angle == other.angle &&
      angularVelocity == other.angularVelocity;

  @override
  int get hashCode => angle.hashCode ^ angularVelocity.hashCode;

  @override
  int compareTo(other) {
    if (other is Rotation) {
      return angle.compareTo(other.angle) +
          angularVelocity.compareTo(other.angularVelocity);
    }
    return -1;
  }
}

class Lifetime extends Component {
  int remainingMs;

  Lifetime(this.remainingMs);

  @override
  Lifetime clone() => Lifetime(remainingMs);

  @override
  bool operator ==(Object other) =>
      other is Lifetime && remainingMs == other.remainingMs;

  @override
  int get hashCode => remainingMs.hashCode;

  @override
  int compareTo(other) {
    if (other is Lifetime) {
      return remainingMs.compareTo(other.remainingMs);
    }
    return -1;
  }
}

class MovementSystem extends EntitySystem {
  @override
  Set<Type> get filterTypes => const {Position, Velocity};

  @override
  void processEntity(
    Entity entity,
    EntityComposition componentLists,
    Duration delta,
  ) {
    final position = componentLists.get<Position>(entity)!;
    final velocity = componentLists.get<Velocity>(entity)!;
    position.x += velocity.x;
    position.y += velocity.y;
  }
}
