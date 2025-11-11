import 'package:dentity/dentity.dart';

class _AsteroidsConstants {
  static const int largeAsteroidSize = 3;
  static const int mediumAsteroidSize = 2;
  static const int smallAsteroidSize = 1;

  static const int largeAsteroidPoints = 20;
  static const int mediumAsteroidPoints = 50;
  static const int smallAsteroidPoints = 100;
}

class Ship extends Component {
  @override
  Ship clone() => Ship();

  @override
  bool operator ==(Object other) => other is Ship;

  @override
  int get hashCode => 0;

  @override
  int compareTo(other) => other is Ship ? 0 : -1;
}

class Asteroid extends Component {
  int size;
  int points;

  Asteroid(this.size, this.points);

  Asteroid.large()
      : size = _AsteroidsConstants.largeAsteroidSize,
        points = _AsteroidsConstants.largeAsteroidPoints;

  Asteroid.medium()
      : size = _AsteroidsConstants.mediumAsteroidSize,
        points = _AsteroidsConstants.mediumAsteroidPoints;

  Asteroid.small()
      : size = _AsteroidsConstants.smallAsteroidSize,
        points = _AsteroidsConstants.smallAsteroidPoints;

  @override
  Asteroid clone() => Asteroid(size, points);

  @override
  bool operator ==(Object other) =>
      other is Asteroid && size == other.size && points == other.points;

  @override
  int get hashCode => size.hashCode ^ points.hashCode;

  @override
  int compareTo(other) {
    if (other is Asteroid) {
      return size.compareTo(other.size);
    }
    return -1;
  }
}

class Laser extends Component {
  @override
  Laser clone() => Laser();

  @override
  bool operator ==(Object other) => other is Laser;

  @override
  int get hashCode => 0;

  @override
  int compareTo(other) => other is Laser ? 0 : -1;
}

class Bounds extends Component {
  double width;
  double height;

  Bounds(this.width, this.height);

  @override
  Bounds clone() => Bounds(width, height);

  @override
  bool operator ==(Object other) =>
      other is Bounds && width == other.width && height == other.height;

  @override
  int get hashCode => width.hashCode ^ height.hashCode;

  @override
  int compareTo(other) {
    if (other is Bounds) {
      return width.compareTo(other.width);
    }
    return -1;
  }
}

class ThrustForce extends Component {
  double magnitude;

  ThrustForce(this.magnitude);

  @override
  ThrustForce clone() => ThrustForce(magnitude);

  @override
  bool operator ==(Object other) =>
      other is ThrustForce && magnitude == other.magnitude;

  @override
  int get hashCode => magnitude.hashCode;

  @override
  int compareTo(other) {
    if (other is ThrustForce) {
      return magnitude.compareTo(other.magnitude);
    }
    return -1;
  }
}

class InputState extends Component {
  bool rotateLeft;
  bool rotateRight;
  bool thrust;
  bool fire;

  InputState({
    this.rotateLeft = false,
    this.rotateRight = false,
    this.thrust = false,
    this.fire = false,
  });

  @override
  InputState clone() => InputState(
        rotateLeft: rotateLeft,
        rotateRight: rotateRight,
        thrust: thrust,
        fire: fire,
      );

  @override
  bool operator ==(Object other) =>
      other is InputState &&
      rotateLeft == other.rotateLeft &&
      rotateRight == other.rotateRight &&
      thrust == other.thrust &&
      fire == other.fire;

  @override
  int get hashCode =>
      rotateLeft.hashCode ^
      rotateRight.hashCode ^
      thrust.hashCode ^
      fire.hashCode;

  @override
  int compareTo(other) {
    if (other is InputState) {
      return 0;
    }
    return -1;
  }
}

class Shield extends Component {
  double current;
  double maximum;

  Shield(this.current, this.maximum);

  @override
  Shield clone() => Shield(current, maximum);

  @override
  bool operator ==(Object other) =>
      other is Shield && current == other.current && maximum == other.maximum;

  @override
  int get hashCode => current.hashCode ^ maximum.hashCode;

  @override
  int compareTo(other) {
    if (other is Shield) {
      return current.compareTo(other.current);
    }
    return -1;
  }
}

class Score extends Component {
  int value;

  Score(this.value);

  @override
  Score clone() => Score(value);

  @override
  bool operator ==(Object other) => other is Score && value == other.value;

  @override
  int get hashCode => value.hashCode;

  @override
  int compareTo(other) {
    if (other is Score) {
      return value.compareTo(other.value);
    }
    return -1;
  }
}

final Map<Type, ComponentListFactory> asteroidsComponentFactories = {
  Ship: () => ContiguousSparseList<Ship>(),
  Asteroid: () => ContiguousSparseList<Asteroid>(),
  Laser: () => ContiguousSparseList<Laser>(),
  Bounds: () => ContiguousSparseList<Bounds>(),
  ThrustForce: () => ContiguousSparseList<ThrustForce>(),
  InputState: () => ContiguousSparseList<InputState>(),
  Shield: () => ContiguousSparseList<Shield>(),
  Score: () => ContiguousSparseList<Score>(),
};
