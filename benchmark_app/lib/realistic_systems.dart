import 'dart:math' as math;
import 'package:dentity/dentity.dart';
import 'basic_example.dart';
import 'realistic_components.dart';

class PhysicsSystem extends EntitySystem {
  static const _dragCoefficient = 0.99;

  @override
  String get name => 'PhysicsSystem';

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
    final acceleration = componentLists.get<Acceleration>(entity);

    if (acceleration != null) {
      velocity.x += acceleration.x * delta.inMilliseconds / 1000.0;
      velocity.y += acceleration.y * delta.inMilliseconds / 1000.0;
    }

    position.x += velocity.x * delta.inMilliseconds / 1000.0;
    position.y += velocity.y * delta.inMilliseconds / 1000.0;

    velocity.x *= _dragCoefficient;
    velocity.y *= _dragCoefficient;
  }
}

class RotationSystem extends EntitySystem {
  static const _twoPi = 2 * math.pi;

  @override
  String get name => 'RotationSystem';

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

class LifetimeSystem extends EntitySystem {
  final List<Entity> _entitiesToDestroy = [];

  @override
  String get name => 'LifetimeSystem';

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

class SimplifiedCollisionSystem extends EntitySystem {
  static const _gridSize = 100.0;
  final Map<_GridCell, List<Entity>> _grid = {};

  @override
  String get name => 'SimplifiedCollisionSystem';

  @override
  Set<Type> get filterTypes => const {Position, BoundingBox, Team};

  @override
  void process(Duration delta) {
    _grid.clear();

    final view = world.viewForTypes(filterTypes);
    for (final entity in view) {
      final position = view.componentLists.get<Position>(entity)!;
      final cell = _GridCell(
        (position.x / _gridSize).floor(),
        (position.y / _gridSize).floor(),
      );
      _grid.putIfAbsent(cell, () => []).add(entity);
    }

    for (final entities in _grid.values) {
      if (entities.length < 2) continue;

      for (var i = 0; i < entities.length; i++) {
        for (var j = i + 1; j < entities.length; j++) {
          _checkCollision(entities[i], entities[j], view.componentLists);
        }
      }
    }
  }

  void _checkCollision(Entity a, Entity b, EntityComposition components) {
    final posA = components.get<Position>(a)!;
    final posB = components.get<Position>(b)!;
    final boxA = components.get<BoundingBox>(a)!;
    final boxB = components.get<BoundingBox>(b)!;
    final teamA = components.get<Team>(a)!;
    final teamB = components.get<Team>(b)!;

    if (teamA.teamId == teamB.teamId) return;

    final dx = (posA.x + boxA.offsetX) - (posB.x + boxB.offsetX);
    final dy = (posA.y + boxA.offsetY) - (posB.y + boxB.offsetY);
    final halfWidths = (boxA.width + boxB.width) / 2;
    final halfHeights = (boxA.height + boxB.height) / 2;

    if (dx.abs() < halfWidths && dy.abs() < halfHeights) {
      world.addComponents(a, {Damage(10)});
      world.addComponents(b, {Damage(10)});
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

class _GridCell {
  final int x;
  final int y;

  _GridCell(this.x, this.y);

  @override
  bool operator ==(Object other) =>
      other is _GridCell && x == other.x && y == other.y;

  @override
  int get hashCode => x.hashCode ^ y.hashCode;
}

class DamageSystem extends EntitySystem {
  final List<Entity> _entitiesToKill = [];

  @override
  String get name => 'DamageSystem';

  @override
  Set<Type> get filterTypes => const {Health, Damage};

  @override
  void processEntity(
    Entity entity,
    EntityComposition componentLists,
    Duration delta,
  ) {
    final health = componentLists.get<Health>(entity)!;
    final damage = componentLists.get<Damage>(entity)!;

    health.current -= damage.amount;
    world.removeComponents(entity, [Damage]);

    if (health.current <= 0) {
      _entitiesToKill.add(entity);
    }
  }

  @override
  void process(Duration delta) {
    _entitiesToKill.clear();
    super.process(delta);

    for (final entity in _entitiesToKill) {
      world.destroyEntity(entity);
    }
  }
}

class HealthRegenerationSystem extends EntitySystem {
  @override
  String get name => 'HealthRegenerationSystem';

  @override
  Set<Type> get filterTypes => const {Health};

  @override
  void processEntity(
    Entity entity,
    EntityComposition componentLists,
    Duration delta,
  ) {
    final health = componentLists.get<Health>(entity)!;
    if (health.regenerationRate > 0 && health.current < health.max) {
      health.current += health.regenerationRate * delta.inMilliseconds / 1000.0;
      if (health.current > health.max) {
        health.current = health.max;
      }
    }
  }
}

class TargetingSystem extends EntitySystem {
  static const _maxTargetRange = 1000.0;
  static const _maxTargetRangeSquared = _maxTargetRange * _maxTargetRange;
  static const _gridSize = 500.0;
  final Map<_GridCell, List<Entity>> _grid = {};

  @override
  String get name => 'TargetingSystem';

  @override
  Set<Type> get filterTypes => const {Position, Team};

  @override
  void process(Duration delta) {
    _grid.clear();

    final allEntities = world.viewForTypes(filterTypes);
    final entitiesWithTarget = world.viewForTypes({Position, Team, Target});

    for (final entity in allEntities) {
      final position = allEntities.componentLists.get<Position>(entity)!;
      final cell = _GridCell(
        (position.x / _gridSize).floor(),
        (position.y / _gridSize).floor(),
      );
      _grid.putIfAbsent(cell, () => []).add(entity);
    }

    for (final entity in entitiesWithTarget) {
      final position = entitiesWithTarget.componentLists.get<Position>(entity)!;
      final team = entitiesWithTarget.componentLists.get<Team>(entity)!;
      final target = entitiesWithTarget.componentLists.get<Target>(entity)!;

      final entityCell = _GridCell(
        (position.x / _gridSize).floor(),
        (position.y / _gridSize).floor(),
      );

      Entity? nearestEnemy;
      double nearestDistanceSquared = _maxTargetRangeSquared;

      for (var dx = -1; dx <= 1; dx++) {
        for (var dy = -1; dy <= 1; dy++) {
          final checkCell = _GridCell(entityCell.x + dx, entityCell.y + dy);
          final cellEntities = _grid[checkCell];
          if (cellEntities == null) continue;

          for (final otherEntity in cellEntities) {
            if (otherEntity == entity) continue;

            final otherTeam = allEntities.componentLists.get<Team>(otherEntity)!;
            if (otherTeam.teamId == team.teamId) continue;

            final otherPosition = allEntities.componentLists.get<Position>(otherEntity)!;
            final deltaX = position.x - otherPosition.x;
            final deltaY = position.y - otherPosition.y;
            final distSquared = deltaX * deltaX + deltaY * deltaY;

            if (distSquared < nearestDistanceSquared) {
              nearestDistanceSquared = distSquared;
              nearestEnemy = otherEntity;
            }
          }
        }
      }

      target.targetEntity = nearestEnemy;
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

class WeaponSystem extends EntitySystem {
  @override
  String get name => 'WeaponSystem';

  @override
  Set<Type> get filterTypes => const {Position, Weapon, Target, Team};

  @override
  void processEntity(
    Entity entity,
    EntityComposition componentLists,
    Duration delta,
  ) {
    final weapon = componentLists.get<Weapon>(entity)!;

    weapon.currentCooldown -= delta.inMilliseconds;
    if (weapon.currentCooldown <= 0) {
      weapon.currentCooldown = 0;
    }

    final target = componentLists.get<Target>(entity);
    if (target?.targetEntity == null || weapon.currentCooldown > 0) {
      return;
    }

    if (weapon.ammo == 0) return;
    if (weapon.ammo > 0) weapon.ammo--;

    final position = componentLists.get<Position>(entity)!;
    final targetPosition = world.getComponent<Position>(target!.targetEntity!);
    if (targetPosition == null) return;

    final dx = targetPosition.x - position.x;
    final dy = targetPosition.y - position.y;
    final distance = math.sqrt(dx * dx + dy * dy);

    if (distance <= weapon.range) {
      const bulletSpeed = 500.0;
      final velocityX = (dx / distance) * bulletSpeed;
      final velocityY = (dy / distance) * bulletSpeed;

      world.createEntity({
        Position(position.x, position.y),
        Velocity(velocityX, velocityY),
        Damage(weapon.damage),
        Lifetime(800),
        BoundingBox(2, 2),
        componentLists.get<Team>(entity)!.clone(),
      });

      weapon.currentCooldown = weapon.cooldownMs;
    }
  }
}

class AnimationSystem extends EntitySystem {
  @override
  String get name => 'AnimationSystem';

  @override
  Set<Type> get filterTypes => const {Animation};

  @override
  void processEntity(
    Entity entity,
    EntityComposition componentLists,
    Duration delta,
  ) {
    final animation = componentLists.get<Animation>(entity)!;
    animation.elapsedTime += delta.inMilliseconds / 1000.0;

    while (animation.elapsedTime >= animation.frameTime) {
      animation.elapsedTime -= animation.frameTime;
      animation.currentFrame = (animation.currentFrame + 1) % animation.frameCount;
    }
  }
}

class RenderingSystem extends EntitySystem {
  final List<_RenderItem> _renderQueue = [];

  @override
  String get name => 'RenderingSystem';

  @override
  Set<Type> get filterTypes => const {Position, Sprite};

  @override
  void process(Duration delta) {
    _renderQueue.clear();
    super.process(delta);
    _renderQueue.sort((a, b) => a.layer.compareTo(b.layer));
  }

  @override
  void processEntity(
    Entity entity,
    EntityComposition componentLists,
    Duration delta,
  ) {
    final position = componentLists.get<Position>(entity)!;
    final sprite = componentLists.get<Sprite>(entity)!;

    _renderQueue.add(_RenderItem(
      entity: entity,
      x: position.x,
      y: position.y,
      textureId: sprite.textureId,
      layer: sprite.layer,
      opacity: sprite.opacity,
    ));
  }
}

class _RenderItem {
  final Entity entity;
  final double x;
  final double y;
  final String textureId;
  final int layer;
  final double opacity;

  _RenderItem({
    required this.entity,
    required this.x,
    required this.y,
    required this.textureId,
    required this.layer,
    required this.opacity,
  });
}
