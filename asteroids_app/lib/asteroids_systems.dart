import 'dart:math' as math;
import 'package:dentity/dentity.dart';
import 'asteroids_components.dart';
import 'basic_components.dart';

class _GameConstants {
  static const double shipRotationSpeed = 3.5;
  static const double maxVelocity = 10.0;
  static const double laserSpeed = 20.0;
  static const int laserLifetimeMs = 2000;
  static const double laserCooldownMs = 250.0;

  static const double largeAsteroidRadius = 40.0;
  static const double mediumAsteroidRadius = 25.0;
  static const double smallAsteroidRadius = 15.0;

  static const double shipRadius = 15.0;
  static const double laserRadius = 2.0;

  static const double shipShieldMax = 100.0;
  static const double shieldContactTimeToDestroy = 1.5;
  static const double asteroidDamagePerSecond = shipShieldMax / shieldContactTimeToDestroy;
  static const double shieldRechargeRate = 5.0;
}

class InputSystem extends EntitySystem {
  @override
  Set<Type> get filterTypes => const {Ship, InputState, Rotation, ThrustForce};

  @override
  void processEntity(
    Entity entity,
    EntityComposition componentLists,
    Duration delta,
  ) {
    final input = componentLists.get<InputState>(entity)!;
    final rotation = componentLists.get<Rotation>(entity)!;

    if (input.rotateLeft) {
      rotation.angularVelocity = -_GameConstants.shipRotationSpeed;
    } else if (input.rotateRight) {
      rotation.angularVelocity = _GameConstants.shipRotationSpeed;
    } else {
      rotation.angularVelocity = 0;
    }
  }
}

class ThrustSystem extends EntitySystem {
  @override
  Set<Type> get filterTypes => const {Ship, InputState, ThrustForce, Rotation, Velocity};

  @override
  void processEntity(
    Entity entity,
    EntityComposition componentLists,
    Duration delta,
  ) {
    final input = componentLists.get<InputState>(entity)!;
    final thrust = componentLists.get<ThrustForce>(entity)!;
    final rotation = componentLists.get<Rotation>(entity)!;
    final velocity = componentLists.get<Velocity>(entity)!;

    if (input.thrust) {
      final deltaSeconds = delta.inMilliseconds / 1000.0;
      velocity.x += math.cos(rotation.angle) * thrust.magnitude * deltaSeconds;
      velocity.y += math.sin(rotation.angle) * thrust.magnitude * deltaSeconds;

      final speed = math.sqrt(velocity.x * velocity.x + velocity.y * velocity.y);
      if (speed > _GameConstants.maxVelocity) {
        velocity.x = (velocity.x / speed) * _GameConstants.maxVelocity;
        velocity.y = (velocity.y / speed) * _GameConstants.maxVelocity;
      }
    }
  }
}


class AsteroidsRotationSystem extends EntitySystem {
  static const _twoPi = 2 * math.pi;

  @override
  Set<Type> get filterTypes => const {Rotation};

  @override
  void processEntity(
    Entity entity,
    EntityComposition componentLists,
    Duration delta,
  ) {
    final rotation = componentLists.get<Rotation>(entity)!;
    rotation.angle += rotation.angularVelocity * delta.inMilliseconds / 1000.0;

    while (rotation.angle >= _twoPi) {
      rotation.angle -= _twoPi;
    }
    while (rotation.angle < 0) {
      rotation.angle += _twoPi;
    }
  }
}

class BoundsWrappingSystem extends EntitySystem {
  @override
  Set<Type> get filterTypes => const {Position, Bounds};

  @override
  void processEntity(
    Entity entity,
    EntityComposition componentLists,
    Duration delta,
  ) {
    final position = componentLists.get<Position>(entity)!;
    final bounds = componentLists.get<Bounds>(entity)!;

    if (position.x < 0) {
      position.x += bounds.width;
    } else if (position.x > bounds.width) {
      position.x -= bounds.width;
    }

    if (position.y < 0) {
      position.y += bounds.height;
    } else if (position.y > bounds.height) {
      position.y -= bounds.height;
    }
  }
}

class AsteroidsCollisionSystem extends EntitySystem {
  final List<_CollisionPair> _collisions = [];
  final math.Random _random = math.Random();

  @override
  Set<Type> get filterTypes => const {Position};

  @override
  void process(Duration delta) {
    _collisions.clear();

    final view = world.viewForTypes(filterTypes);
    final entities = view.toList();

    for (var i = 0; i < entities.length; i++) {
      for (var j = i + 1; j < entities.length; j++) {
        final entityA = entities[i];
        final entityB = entities[j];

        if (_checkCollision(entityA, entityB, view.componentLists)) {
          _collisions.add(_CollisionPair(entityA, entityB));
        }
      }
    }

    for (final collision in _collisions) {
      _handleCollision(collision.entityA, collision.entityB, delta);
    }
  }

  bool _checkCollision(Entity a, Entity b, EntityComposition components) {
    final posA = components.get<Position>(a)!;
    final posB = components.get<Position>(b)!;

    final radiusA = _getRadius(a);
    final radiusB = _getRadius(b);

    if (radiusA == 0 || radiusB == 0) return false;

    final dx = posA.x - posB.x;
    final dy = posA.y - posB.y;
    final distanceSquared = dx * dx + dy * dy;
    final radiusSum = radiusA + radiusB;

    return distanceSquared < radiusSum * radiusSum;
  }

  double _getRadius(Entity entity) {
    final asteroid = world.getComponent<Asteroid>(entity);
    if (asteroid != null) {
      if (asteroid.size == 3) return _GameConstants.largeAsteroidRadius;
      if (asteroid.size == 2) return _GameConstants.mediumAsteroidRadius;
      if (asteroid.size == 1) return _GameConstants.smallAsteroidRadius;
    }

    if (world.getComponent<Ship>(entity) != null) {
      return _GameConstants.shipRadius;
    }

    if (world.getComponent<Laser>(entity) != null) {
      return _GameConstants.laserRadius;
    }

    return 0;
  }

  void _handleCollision(Entity entityA, Entity entityB, Duration delta) {
    final asteroidA = world.getComponent<Asteroid>(entityA);
    final asteroidB = world.getComponent<Asteroid>(entityB);
    final laserA = world.getComponent<Laser>(entityA);
    final laserB = world.getComponent<Laser>(entityB);
    final shipA = world.getComponent<Ship>(entityA);
    final shipB = world.getComponent<Ship>(entityB);

    if (laserA != null && asteroidB != null) {
      _destroyLaser(entityA);
      _splitAsteroid(entityB);
      _awardPoints(asteroidB.points);
    } else if (laserB != null && asteroidA != null) {
      _destroyLaser(entityB);
      _splitAsteroid(entityA);
      _awardPoints(asteroidA.points);
    } else if (shipA != null && asteroidB != null) {
      _damageShip(entityA, delta);
    } else if (shipB != null && asteroidA != null) {
      _damageShip(entityB, delta);
    }
  }

  void _awardPoints(int points) {
    final shipView = world.viewForTypes({Ship, Score});
    if (shipView.isNotEmpty) {
      final shipEntity = shipView.first;
      final score = shipView.componentLists.get<Score>(shipEntity);
      if (score != null) {
        score.value += points;
      }
    }
  }

  void _damageShip(Entity ship, Duration delta) {
    final shield = world.getComponent<Shield>(ship);
    if (shield != null) {
      final deltaSeconds = delta.inMilliseconds / 1000.0;
      shield.current -= _GameConstants.asteroidDamagePerSecond * deltaSeconds;
      if (shield.current <= 0) {
        world.destroyEntity(ship);
      }
    } else {
      world.destroyEntity(ship);
    }
  }

  void _destroyLaser(Entity laser) {
    world.destroyEntity(laser);
  }

  void _splitAsteroid(Entity asteroid) {
    final asteroidComp = world.getComponent<Asteroid>(asteroid);
    final position = world.getComponent<Position>(asteroid);
    final bounds = world.getComponent<Bounds>(asteroid);

    if (asteroidComp == null || position == null) return;

    world.destroyEntity(asteroid);

    if (asteroidComp.size > 1) {
      final newSize = asteroidComp.size - 1;
      final Asteroid newAsteroid;

      if (newSize == 2) {
        newAsteroid = Asteroid.medium();
      } else {
        newAsteroid = Asteroid.small();
      }

      for (var i = 0; i < 2; i++) {
        final angle = _random.nextDouble() * 2 * math.pi;
        final speed = 2.0 + _random.nextDouble() * 3.0;

        world.createEntity({
          Position(position.x, position.y),
          Velocity(math.cos(angle) * speed, math.sin(angle) * speed),
          Rotation(_random.nextDouble() * 2 * math.pi, (_random.nextDouble() - 0.5) * 2),
          newAsteroid.clone(),
          if (bounds != null) bounds.clone(),
        });
      }
    }
  }

  @override
  void processEntity(
    Entity entity,
    EntityComposition componentLists,
    Duration delta,
  ) {
  }
}

class _CollisionPair {
  final Entity entityA;
  final Entity entityB;

  _CollisionPair(this.entityA, this.entityB);
}

class LaserSpawnSystem extends EntitySystem {
  double _cooldownRemaining = 0;

  @override
  Set<Type> get filterTypes => const {Ship, InputState, Position, Rotation};

  @override
  void processEntity(
    Entity entity,
    EntityComposition componentLists,
    Duration delta,
  ) {
    if (_cooldownRemaining > 0) {
      _cooldownRemaining -= delta.inMilliseconds;
    }

    final input = componentLists.get<InputState>(entity)!;

    if (input.fire && _cooldownRemaining <= 0) {
      final position = componentLists.get<Position>(entity)!;
      final rotation = componentLists.get<Rotation>(entity)!;
      final bounds = componentLists.get<Bounds>(entity);

      final laserVx = math.cos(rotation.angle) * _GameConstants.laserSpeed;
      final laserVy = math.sin(rotation.angle) * _GameConstants.laserSpeed;

      final shipVelocity = componentLists.get<Velocity>(entity);
      final finalVx = laserVx + (shipVelocity?.x ?? 0);
      final finalVy = laserVy + (shipVelocity?.y ?? 0);

      final spawnOffset = _GameConstants.shipRadius + 5;
      final spawnX = position.x + math.cos(rotation.angle) * spawnOffset;
      final spawnY = position.y + math.sin(rotation.angle) * spawnOffset;

      world.createEntity({
        Position(spawnX, spawnY),
        Velocity(finalVx, finalVy),
        Laser(),
        Lifetime(_GameConstants.laserLifetimeMs),
        if (bounds != null) bounds.clone(),
      });

      _cooldownRemaining = _GameConstants.laserCooldownMs;
    }
  }
}

class AsteroidsLifetimeSystem extends EntitySystem {
  final List<Entity> _entitiesToDestroy = [];

  @override
  Set<Type> get filterTypes => const {Lifetime};

  @override
  void processEntity(
    Entity entity,
    EntityComposition componentLists,
    Duration delta,
  ) {
    final lifetime = componentLists.get<Lifetime>(entity)!;
    lifetime.remainingMs -= delta.inMilliseconds;

    if (lifetime.remainingMs <= 0) {
      _entitiesToDestroy.add(entity);
    }
  }

  @override
  void process(Duration delta) {
    _entitiesToDestroy.clear();
    super.process(delta);

    for (final entity in _entitiesToDestroy) {
      world.destroyEntity(entity);
    }
  }
}

class ShieldRechargeSystem extends EntitySystem {
  @override
  Set<Type> get filterTypes => const {Shield};

  @override
  void processEntity(
    Entity entity,
    EntityComposition componentLists,
    Duration delta,
  ) {
    final shield = componentLists.get<Shield>(entity)!;
    if (shield.current < shield.maximum) {
      final deltaSeconds = delta.inMilliseconds / 1000.0;
      shield.current += _GameConstants.shieldRechargeRate * deltaSeconds;
      if (shield.current > shield.maximum) {
        shield.current = shield.maximum;
      }
    }
  }
}
