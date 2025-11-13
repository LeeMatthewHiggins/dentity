import 'package:dentity/dentity.dart';

class Acceleration extends Component {
  double x;
  double y;

  Acceleration(this.x, this.y);

  @override
  Acceleration clone() => Acceleration(x, y);

  @override
  bool operator ==(Object other) =>
      other is Acceleration && x == other.x && y == other.y;

  @override
  int get hashCode => x.hashCode ^ y.hashCode;

  @override
  int compareTo(other) {
    if (other is Acceleration) {
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
      return angle.compareTo(other.angle);
    }
    return -1;
  }
}

class BoundingBox extends Component {
  double width;
  double height;
  double offsetX;
  double offsetY;

  BoundingBox(this.width, this.height, {this.offsetX = 0, this.offsetY = 0});

  @override
  BoundingBox clone() => BoundingBox(width, height, offsetX: offsetX, offsetY: offsetY);

  @override
  bool operator ==(Object other) =>
      other is BoundingBox &&
      width == other.width &&
      height == other.height &&
      offsetX == other.offsetX &&
      offsetY == other.offsetY;

  @override
  int get hashCode =>
      width.hashCode ^ height.hashCode ^ offsetX.hashCode ^ offsetY.hashCode;

  @override
  int compareTo(other) {
    if (other is BoundingBox) {
      return width.compareTo(other.width);
    }
    return -1;
  }
}

class Health extends Component {
  double current;
  double max;
  double regenerationRate;

  Health(this.current, this.max, {this.regenerationRate = 0});

  @override
  Health clone() => Health(current, max, regenerationRate: regenerationRate);

  @override
  bool operator ==(Object other) =>
      other is Health &&
      current == other.current &&
      max == other.max &&
      regenerationRate == other.regenerationRate;

  @override
  int get hashCode =>
      current.hashCode ^ max.hashCode ^ regenerationRate.hashCode;

  @override
  int compareTo(other) {
    if (other is Health) {
      return current.compareTo(other.current);
    }
    return -1;
  }
}

class Damage extends Component {
  double amount;
  String damageType;

  Damage(this.amount, {this.damageType = 'physical'});

  @override
  Damage clone() => Damage(amount, damageType: damageType);

  @override
  bool operator ==(Object other) =>
      other is Damage && amount == other.amount && damageType == other.damageType;

  @override
  int get hashCode => amount.hashCode ^ damageType.hashCode;

  @override
  int compareTo(other) {
    if (other is Damage) {
      return amount.compareTo(other.amount);
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

class Team extends Component {
  int teamId;

  Team(this.teamId);

  @override
  Team clone() => Team(teamId);

  @override
  bool operator ==(Object other) => other is Team && teamId == other.teamId;

  @override
  int get hashCode => teamId.hashCode;

  @override
  int compareTo(other) {
    if (other is Team) {
      return teamId.compareTo(other.teamId);
    }
    return -1;
  }
}

class Target extends Component {
  Entity? targetEntity;

  Target(this.targetEntity);

  @override
  Target clone() => Target(targetEntity);

  @override
  bool operator ==(Object other) =>
      other is Target && targetEntity == other.targetEntity;

  @override
  int get hashCode => targetEntity.hashCode;

  @override
  int compareTo(other) {
    if (other is Target) {
      if (targetEntity == null && other.targetEntity == null) return 0;
      if (targetEntity == null) return -1;
      if (other.targetEntity == null) return 1;
      return targetEntity!.compareTo(other.targetEntity!);
    }
    return -1;
  }
}

class Sprite extends Component {
  String textureId;
  int layer;
  double opacity;

  Sprite(this.textureId, {this.layer = 0, this.opacity = 1.0});

  @override
  Sprite clone() => Sprite(textureId, layer: layer, opacity: opacity);

  @override
  bool operator ==(Object other) =>
      other is Sprite &&
      textureId == other.textureId &&
      layer == other.layer &&
      opacity == other.opacity;

  @override
  int get hashCode => textureId.hashCode ^ layer.hashCode ^ opacity.hashCode;

  @override
  int compareTo(other) {
    if (other is Sprite) {
      return layer.compareTo(other.layer);
    }
    return -1;
  }
}

class Animation extends Component {
  int currentFrame;
  int frameCount;
  double frameTime;
  double elapsedTime;

  Animation(this.frameCount, this.frameTime, {this.currentFrame = 0, this.elapsedTime = 0});

  @override
  Animation clone() => Animation(frameCount, frameTime, currentFrame: currentFrame, elapsedTime: elapsedTime);

  @override
  bool operator ==(Object other) =>
      other is Animation &&
      currentFrame == other.currentFrame &&
      frameCount == other.frameCount &&
      frameTime == other.frameTime;

  @override
  int get hashCode =>
      currentFrame.hashCode ^ frameCount.hashCode ^ frameTime.hashCode;

  @override
  int compareTo(other) {
    if (other is Animation) {
      return currentFrame.compareTo(other.currentFrame);
    }
    return -1;
  }
}

class AIState extends Component {
  String currentState;
  int stateTimer;

  AIState(this.currentState, {this.stateTimer = 0});

  @override
  AIState clone() => AIState(currentState, stateTimer: stateTimer);

  @override
  bool operator ==(Object other) =>
      other is AIState &&
      currentState == other.currentState &&
      stateTimer == other.stateTimer;

  @override
  int get hashCode => currentState.hashCode ^ stateTimer.hashCode;

  @override
  int compareTo(other) {
    if (other is AIState) {
      return currentState.compareTo(other.currentState);
    }
    return -1;
  }
}

class Weapon extends Component {
  int cooldownMs;
  int currentCooldown;
  double damage;
  double range;
  int ammo;

  Weapon(this.cooldownMs, this.damage, this.range, {this.ammo = -1, this.currentCooldown = 0});

  @override
  Weapon clone() => Weapon(cooldownMs, damage, range, ammo: ammo, currentCooldown: currentCooldown);

  @override
  bool operator ==(Object other) =>
      other is Weapon &&
      cooldownMs == other.cooldownMs &&
      damage == other.damage &&
      range == other.range &&
      ammo == other.ammo;

  @override
  int get hashCode =>
      cooldownMs.hashCode ^ damage.hashCode ^ range.hashCode ^ ammo.hashCode;

  @override
  int compareTo(other) {
    if (other is Weapon) {
      return damage.compareTo(other.damage);
    }
    return -1;
  }
}

final Map<Type, ComponentListFactory> realisticComponentFactories = {
  Acceleration: () => ContiguousSparseList<Acceleration>(),
  Rotation: () => ContiguousSparseList<Rotation>(),
  BoundingBox: () => ContiguousSparseList<BoundingBox>(),
  Health: () => ContiguousSparseList<Health>(),
  Damage: () => ContiguousSparseList<Damage>(),
  Lifetime: () => ContiguousSparseList<Lifetime>(),
  Team: () => ContiguousSparseList<Team>(),
  Target: () => ContiguousSparseList<Target>(),
  Sprite: () => ContiguousSparseList<Sprite>(),
  Animation: () => ContiguousSparseList<Animation>(),
  AIState: () => ContiguousSparseList<AIState>(),
  Weapon: () => ContiguousSparseList<Weapon>(),
};
