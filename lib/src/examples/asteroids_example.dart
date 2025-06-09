import 'dart:math'; // For cos, sin, Random, pow, pi

import 'package:dentity/dentity.dart';

// --- Core Components ---

class Transform extends Component {
  double x;
  double y;
  double rotation; // In radians

  Transform(this.x, this.y, {this.rotation = 0.0});

  @override
  Transform clone() {
    return Transform(x, y, rotation: rotation);
  }

  @override
  bool operator ==(Object other) {
    if (other is Transform) {
      return x == other.x && y == other.y && rotation == other.rotation;
    }
    return false;
  }

  @override
  int get hashCode => x.hashCode ^ y.hashCode ^ rotation.hashCode;

  @override
  int compareTo(other) {
    if (other is Transform) {
      int xComp = x.compareTo(other.x);
      if (xComp != 0) return xComp;
      int yComp = y.compareTo(other.y);
      if (yComp != 0) return yComp;
      return rotation.compareTo(other.rotation);
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
      int xComp = x.compareTo(other.x);
      if (xComp != 0) return xComp;
      return y.compareTo(other.y);
    }
    return -1;
  }
}

class Renderable extends Component {
  String shape;
  String color;

  Renderable(this.shape, this.color);

  @override
  Renderable clone() {
    return Renderable(shape, color);
  }

  @override
  bool operator ==(Object other) {
    if (other is Renderable) {
      return shape == other.shape && color == other.color;
    }
    return false;
  }

  @override
  int get hashCode => shape.hashCode ^ color.hashCode;

  @override
  int compareTo(other) {
    if (other is Renderable) {
      int shapeComp = shape.compareTo(other.shape);
      if (shapeComp != 0) return shapeComp;
      return color.compareTo(other.color);
    }
    return -1;
  }
}

class Mass extends Component {
  double value;

  Mass(this.value);

  @override
  Mass clone() {
    return Mass(value);
  }

  @override
  bool operator ==(Object other) {
    if (other is Mass) {
      return value == other.value;
    }
    return false;
  }

  @override
  int get hashCode => value.hashCode;

  @override
  int compareTo(other) {
    if (other is Mass) {
      return value.compareTo(other.value);
    }
    return -1;
  }
}

class Collider extends Component {
  double radius;
  Set<Type> collidesWith;
  Function(Entity self, Entity other, World world)? onCollide;

  Collider(this.radius, {Set<Type>? collidesWith, this.onCollide})
      : this.collidesWith = collidesWith ?? const {};

  @override
  Collider clone() {
    return Collider(radius,
        collidesWith: Set<Type>.from(collidesWith), onCollide: onCollide);
  }

  @override
  bool operator ==(Object other) {
    if (other is Collider) {
      if (radius != other.radius) return false;
      if (collidesWith.length != other.collidesWith.length) return false;
      for (final type in collidesWith) {
        if (!other.collidesWith.contains(type)) return false;
      }
      return true; // Note: onCollide function is not compared
    }
    return false;
  }

  @override
  int get hashCode {
    int result = radius.hashCode;
    int setHash = 0;
    for (final type in collidesWith) {
      setHash ^= type.hashCode; // XOR hash codes of types in the set
    }
    return result ^ setHash; // Note: onCollide function is not included in hash
  }

  @override
  int compareTo(other) {
    if (other is Collider) {
      int radiusComp = radius.compareTo(other.radius);
      if (radiusComp != 0) return radiusComp;
      if (collidesWith.length != other.collidesWith.length) {
        return collidesWith.length.compareTo(other.collidesWith.length);
      }
      // Consistent ordering for sets of same length is complex, 0 for now.
      return 0;
    }
    return -1;
  }
}

// --- Tag Components ---

class Player extends Component {
  @override
  Player clone() => Player();
  @override
  bool operator ==(Object other) => other is Player;
  @override
  int get hashCode => runtimeType.hashCode;
  @override
  int compareTo(other) => other is Player ? 0 : -1;
}

class Asteroid extends Component {
  String size;
  Asteroid({this.size = "large"});

  @override
  Asteroid clone() => Asteroid(size: size);
  @override
  bool operator ==(Object other) => other is Asteroid && other.size == size;
  @override
  int get hashCode => runtimeType.hashCode ^ size.hashCode;
  @override
  int compareTo(other) {
    if (other is Asteroid) {
      return size.compareTo(other.size);
    }
    return -1;
  }
}

class Bullet extends Component {
  Entity owner;
  Bullet(this.owner);

  @override
  Bullet clone() => Bullet(owner);
  @override
  bool operator ==(Object other) => other is Bullet && other.owner == owner;
  @override
  int get hashCode => runtimeType.hashCode ^ owner.hashCode;
  @override
  int compareTo(other) {
    if (other is Bullet) {
      return owner.compareTo(other.owner);
    }
    return -1;
  }
}

class Health extends Component {
  int currentLives;
  int maxLives;

  Health({this.currentLives = 3, this.maxLives = 3});

  @override
  Health clone() {
    return Health(currentLives: currentLives, maxLives: maxLives);
  }

  @override
  bool operator ==(Object other) {
    if (other is Health) {
      return currentLives == other.currentLives && maxLives == other.maxLives;
    }
    return false;
  }

  @override
  int get hashCode => currentLives.hashCode ^ maxLives.hashCode;

  @override
  int compareTo(other) {
    if (other is Health) {
      int currentComp = currentLives.compareTo(other.currentLives);
      if (currentComp != 0) return currentComp;
      return maxLives.compareTo(other.maxLives);
    }
    return -1;
  }
}

// --- Game Systems ---

class PlayerInputSystem extends EntitySystem {
  bool isAccelerating = false;
  bool isRotatingLeft = false;
  bool isRotatingRight = false;
  bool isShooting = false;
  Entity playerEntity;

  double accelerationPower = 0.1;
  double rotationSpeed = 0.05;
  // double bulletSpeed = 5.0; // Bullet speed is now handled by createAsteroidsWorld

  World world;
  PlayerInputSystem(this.world, this.playerEntity); // Modified constructor

  @override
  Set<Type> get filterTypes => const {Player, Transform, Velocity, Health};

  @override
  void processEntity(
    Entity entity,
    Map<Type, SparseList<Component>> componentLists,
    Duration delta,
  ) {
    final playerHealth = componentLists[Health]?[entity] as Health?;
    if (playerHealth == null || playerHealth.currentLives <= 0) {
      return;
    }

    final transform = componentLists[Transform]?[entity] as Transform;
    final velocity = componentLists[Velocity]?[entity] as Velocity;

    if (isRotatingLeft) {
      transform.rotation -= rotationSpeed;
    }
    if (isRotatingRight) {
      transform.rotation += rotationSpeed;
    }

    if (isAccelerating) {
      velocity.x += cos(transform.rotation) * accelerationPower;
      velocity.y += sin(transform.rotation) * accelerationPower;
    }

    if (isShooting) {
      final playerHealthCheck = componentLists[Health]?[entity] as Health?;
      if (playerHealthCheck == null || playerHealthCheck.currentLives <= 0) {
        isShooting = false; // Don't shoot if dead
        return;
      }

      // Create a bullet entity
      final bulletX = transform.x +
          cos(transform.rotation) * 15; // Spawn slightly ahead of player
      final bulletY = transform.y + sin(transform.rotation) * 15;
      const bulletSpeedValue = 5.0; // Actual bullet speed

      world.createEntity([
        Bullet(playerEntity),
        Transform(bulletX, bulletY, rotation: transform.rotation),
        Velocity(cos(transform.rotation) * bulletSpeedValue,
            sin(transform.rotation) * bulletSpeedValue),
        Renderable("circle_small", "yellow"),
        Mass(0.1),
        Collider(2.0,
            collidesWith: {Asteroid}, onCollide: handleBulletCollision),
      ]);

      // print("Player ${entity.id} shot bullet ${bulletEntity.id}");
      isShooting = false;
    }
  }

  void accelerate(bool active) => isAccelerating = active;
  void rotateLeft(bool active) => isRotatingLeft = active;
  void rotateRight(bool active) => isRotatingRight = active;
  void shoot() => isShooting = true;
}

void handleBulletCollision(Entity bullet, Entity other, World world) {
  // Bullet specific collision: e.g. just remove self
  // Asteroid collision logic is handled by its own onCollide
  if (world.entityManager.hasEntity(other) &&
      world.getComponent<Asteroid>(other) != null) {
    // print("Bullet ${bullet.id} hit Asteroid ${other.id}. Bullet removed.");
    world.destroyEntity(bullet);
  }
}

class GravitySystem extends EntitySystem {
  final double gravitationalConstant;

  GravitySystem(
      {this.gravitationalConstant =
          0.0}); // Defaulting to 0 for asteroids, can be set otherwise

  @override
  Set<Type> get filterTypes => const {
        Velocity,
        Mass
      }; // Transform no longer needed for simple Y-axis gravity

  @override
  void processEntity(
    Entity entity,
    Map<Type, SparseList<Component>> componentLists,
    Duration delta,
  ) {
    if (gravitationalConstant == 0) return; // No gravity effect

    final velocity = componentLists[Velocity]?[entity] as Velocity;
    final mass = componentLists[Mass]?[entity] as Mass;

    double timeScale = delta.inMilliseconds / 16.0;
    velocity.y += gravitationalConstant * mass.value * timeScale;
  }
}

class MovementSystem extends EntitySystem {
  final double worldWidth;
  final double worldHeight;
  final bool wrapAround;

  MovementSystem(
      {this.worldWidth = 800, this.worldHeight = 600, this.wrapAround = true});

  @override
  Set<Type> get filterTypes => const {Transform, Velocity};

  @override
  void processEntity(
    Entity entity,
    Map<Type, SparseList<Component>> componentLists,
    Duration delta,
  ) {
    final transform = componentLists[Transform]?[entity] as Transform;
    final velocity = componentLists[Velocity]?[entity] as Velocity;

    double timeScale = delta.inMilliseconds / 16.0;

    transform.x += velocity.x * timeScale;
    transform.y += velocity.y * timeScale;

    if (wrapAround) {
      if (transform.x < 0) transform.x += worldWidth;
      if (transform.x > worldWidth) transform.x -= worldWidth;
      if (transform.y < 0) transform.y += worldHeight;
      if (transform.y > worldHeight) transform.y -= worldHeight;
    }
  }
}

class CollisionSystem extends EntitySystem {
  Set<String> _processedPairs = {};
  World world;

  CollisionSystem(this.world);

  @override
  Set<Type> get filterTypes => const {Transform, Collider};

  @override
  void beforeProcess(Duration delta) {
    _processedPairs.clear();
  }

  @override
  void processEntity(
    Entity entityA,
    Map<Type, SparseList<Component>> componentLists, // This is for entityA
    Duration delta,
  ) {
    final transformA = componentLists[Transform]?[entityA] as Transform?;
    final colliderA = componentLists[Collider]?[entityA] as Collider?;

    if (transformA == null || colliderA == null) return;

    // Query all entities that could collide (have Transform and Collider)
    // This approach is simpler than iterating all entities in the world if queryEntities is efficient.
    final potentialColliders = world.viewForTypes(filterTypes);

    for (final entityB in potentialColliders) {
      if (entityA >= entityB)
        continue; // Avoid self-collision and duplicate pairs (A-B is same as B-A)

      // String pairKey = '${entityA.id}-${entityB.id}'; // Ensured by A.id < B.id check
      // if (_processedPairs.contains(pairKey)) continue; // Already handled by A.id < B.id

      final transformB = world.getComponent<Transform>(entityB);
      final colliderB = world.getComponent<Collider>(entityB);

      if (transformB == null || colliderB == null) continue;

      bool canACollideWithBType = colliderA.collidesWith
          .any((type) => world.hasComponent(entityB, type));
      bool canBCollideWithTypeA = colliderB.collidesWith
          .any((type) => world.hasComponent(entityA, type));

      if (!canACollideWithBType || !canBCollideWithTypeA) continue;

      double distanceSq = (transformA.x - transformB.x).pow(2) +
          (transformA.y - transformB.y).pow(2);
      double radiiSumSq = (colliderA.radius + colliderB.radius).pow(2);

      if (distanceSq < radiiSumSq) {
        // Collision detected!
        // _processedPairs.add(pairKey); // Not strictly needed due to ordered ID check

        // Invoke callbacks. The world is passed to allow for entity creation/deletion.
        colliderA.onCollide?.call(entityA, entityB, world);
        colliderB.onCollide
            ?.call(entityB, entityA, world); // Call B's handler as well
      }
    }
  }
}

class AsteroidSpawnSystem extends EntitySystem {
  double spawnInterval;
  double timeSinceLastSpawn = 0;
  Random random = Random();
  World world;

  final double worldWidth;
  final double worldHeight;

  AsteroidSpawnSystem(this.world,
      {this.spawnInterval = 5.0,
      this.worldWidth = 800,
      this.worldHeight = 600});

  @override
  Set<Type> get filterTypes => const {};

  @override
  void process(Duration delta) {
    timeSinceLastSpawn += delta.inMilliseconds / 1000.0;
    if (timeSinceLastSpawn >= spawnInterval) {
      timeSinceLastSpawn = 0;
      _spawnAsteroid();
    }
  }

  void _spawnAsteroid() {
    double x, y;
    double vx, vy;
    // Speed in units per second, will be scaled by time in MovementSystem
    double speed = (random.nextDouble() * 0.5 + 0.5) *
        2.0; // Adjusted for ~60fps, results in 0.5 to 1.0 units per frame scaled by time.

    if (random.nextBool()) {
      x = random.nextBool() ? -30.0 : worldWidth + 30.0; // Spawn off-screen
      y = random.nextDouble() * worldHeight;
      vx = (x < worldWidth / 2 ? 1 : -1) *
          speed *
          (random.nextDouble() * 0.5 + 0.5);
      vy = (random.nextDouble() - 0.5) * speed;
    } else {
      y = random.nextBool() ? -30.0 : worldHeight + 30.0; // Spawn off-screen
      x = random.nextDouble() * worldWidth;
      vy = (y < worldHeight / 2 ? 1 : -1) *
          speed *
          (random.nextDouble() * 0.5 + 0.5);
      vx = (random.nextDouble() - 0.5) * speed;
    }

    world.createEntity([
      Asteroid(size: "large"),
      Transform(x, y, rotation: random.nextDouble() * 2 * pi),
      Velocity(vx, vy),
      Mass(30.0),
      Renderable("polygon_asteroid_large", "grey"),
      Collider(30.0,
          collidesWith: {Player, Bullet}, onCollide: handleAsteroidCollision),
    ]);
  }

  @override
  void processEntity(Entity entity,
      Map<Type, SparseList<Component>> componentLists, Duration delta) {
    // Not used
  }
}

void handleAsteroidCollision(
    Entity asteroidEntity, Entity otherEntity, World world) {
  // This function is the callback for Asteroid's Collider component.
  // It defines what happens *to the asteroid* when it collides.

  final asteroidComponent = world.getComponent<Asteroid>(asteroidEntity);
  if (asteroidComponent == null)
    return; // Should not happen if called on an asteroid

  if (world.getComponent<Bullet>(otherEntity) != null) {
    // Asteroid hit by a bullet
    // print("Asteroid ${asteroidEntity.id} (size: ${asteroidComponent.size}) hit by Bullet ${otherEntity.id}");
    world.destroyEntity(asteroidEntity); // Destroy this asteroid
    // The bullet's onCollide (handleBulletCollision) will handle removing the bullet.

    // Spawn smaller asteroids based on current asteroid's size
    final parentTransform = world.getComponent<Transform>(asteroidEntity);
    if (parentTransform == null) return; // Should have a transform

    if (asteroidComponent.size == "large") {
      for (int i = 0; i < 2; i++) {
        _spawnSmallerAsteroid(world, parentTransform, "medium");
      }
    } else if (asteroidComponent.size == "medium") {
      for (int i = 0; i < 2; i++) {
        _spawnSmallerAsteroid(world, parentTransform, "small");
      }
    }
    // Small asteroids, when hit by a bullet, are just destroyed (no smaller ones spawn).
  } else if (world.getComponent<Player>(otherEntity) != null) {
    // Asteroid collided with Player
    // print("Asteroid ${asteroidEntity.id} collided with Player ${otherEntity.id}");
    world.destroyEntity(asteroidEntity); // Destroy the asteroid

    // Player's health component and its own collision handler (if any) would manage player damage.
    // For direct damage from asteroid:
    final playerHealth = world.getComponent<Health>(otherEntity);
    if (playerHealth != null) {
      playerHealth.currentLives -= 1;
      // print("Player ${otherEntity.id} health reduced to ${playerHealth.currentLives}");
      if (playerHealth.currentLives <= 0) {
        // print("Player ${otherEntity.id} is out of lives!");
        // Game over logic or player destruction would be handled elsewhere,
        // possibly by a system that checks for Health <= 0.
      }
    }
  }
}

void _spawnSmallerAsteroid(
    World world, Transform parentTransform, String newSize) {
  Random random = Random();
  double baseSpeed = 0.0; // Per-frame, assuming 60fps scaling in movement
  double radius = 0;
  double mass = 0;
  String renderShape = "polygon_asteroid_default";

  if (newSize == "medium") {
    baseSpeed = 1.2 * (1 / 60.0); // Adjusted for 60fps scaling
    radius = 15.0;
    mass = 15.0;
    renderShape = "polygon_asteroid_medium";
  } else if (newSize == "small") {
    baseSpeed = 1.5 * (1 / 60.0); // Adjusted for 60fps scaling
    radius = 8.0;
    mass = 7.0;
    renderShape = "polygon_asteroid_small";
  } else {
    return; // Unknown size
  }

  for (int i = 0; i < 2; i++) {
    double angle = random.nextDouble() * 2 * pi;
    // Velocity is per-second, MovementSystem will scale by delta.
    double speedMagnitude = baseSpeed *
        60 *
        (random.nextDouble() * 0.5 + 0.75); // Make them a bit faster
    world.createEntity([
      Asteroid(size: newSize),
      Transform(parentTransform.x, parentTransform.y,
          rotation: random.nextDouble() * 2 * pi),
      Velocity(cos(angle) * speedMagnitude, sin(angle) * speedMagnitude),
      Mass(mass),
      Renderable(renderShape, "grey"),
      Collider(radius,
          collidesWith: {Player, Bullet}, onCollide: handleAsteroidCollision),
    ]);

    // print("Spawned smaller asteroid ${newAsteroid.id} (size: $newSize)");
  }
}

class BulletLifecycleSystem extends EntitySystem {
  double maxLifetime;
  Map<Entity, double> bulletAge = {};
  World world;

  final double worldWidth;
  final double worldHeight;

  BulletLifecycleSystem(this.world,
      {this.maxLifetime = 2.0, this.worldWidth = 800, this.worldHeight = 600});

  @override
  Set<Type> get filterTypes => const {Bullet, Transform};

  @override
  void processEntity(
    Entity entity,
    Map<Type, SparseList<Component>> componentLists,
    Duration delta,
  ) {
    bulletAge.putIfAbsent(entity, () => 0);
    bulletAge[entity] = bulletAge[entity]! + delta.inMilliseconds / 1000.0;

    final transform = componentLists[Transform]?[entity] as Transform?;

    bool shouldRemove = false;
    if (bulletAge[entity]! >= maxLifetime) {
      shouldRemove = true;
    } else if (transform != null) {
      // Remove if bullet is well off-screen
      if (transform.x < -50 ||
          transform.x > worldWidth + 50 ||
          transform.y < -50 ||
          transform.y > worldHeight + 50) {
        shouldRemove = true;
      }
    }

    if (shouldRemove) {
      world.destroyEntity(entity);
      // bulletAge.remove(entity) will be handled by onEntityRemoved
      // print("Bullet ${entity.id} removed.");
    }
  }

  @override
  void onEntityWillDestroy(Entity entity) {
    bulletAge.remove(entity);
  }
}
