import 'dart:math'; // For cos, sin, Random, pow, pi

import 'package:dentity/dentity.dart';
import 'package:dentity/src/component/component_serialiser.dart';
import 'package:dentity/src/entity/entity_serialiser_json.dart';
// Entity is already exported by dentity.dart

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
    return Collider(radius, collidesWith: Set<Type>.from(collidesWith), onCollide: onCollide);
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
      return owner.id.compareTo(other.owner.id);
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

// --- Component Serializers ---

class TransformJsonSerializer extends ComponentSerializer<Transform> {
  static const type = 'Transform';
  @override
  ComponentRepresentation? serialize(Transform component) {
    return {
      'x': component.x,
      'y': component.y,
      'rotation': component.rotation,
      EntitySerialiserJson.typeField: type
    };
  }

  @override
  Transform deserialize(ComponentRepresentation data) {
    final transformData = data as Map<String, dynamic>;
    return Transform(
      transformData['x'] as double,
      transformData['y'] as double,
      rotation: transformData['rotation'] as double,
    );
  }

  @override
  bool canSerialize(Object component) => component is Transform;
  @override
  bool canDeserialize(ComponentRepresentation data) =>
      data is Map<String, dynamic> && data[EntitySerialiserJson.typeField] == type;
}

class VelocityJsonSerializer extends ComponentSerializer<Velocity> {
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
  bool canSerialize(Object component) => component is Velocity;
  @override
  bool canDeserialize(ComponentRepresentation data) =>
      data is Map<String, dynamic> && data[EntitySerialiserJson.typeField] == type;
}

class RenderableJsonSerializer extends ComponentSerializer<Renderable> {
  static const type = 'Renderable';
  @override
  ComponentRepresentation? serialize(Renderable component) {
    return {
      'shape': component.shape,
      'color': component.color,
      EntitySerialiserJson.typeField: type
    };
  }

  @override
  Renderable deserialize(ComponentRepresentation data) {
    final renderableData = data as Map<String, dynamic>;
    return Renderable(
      renderableData['shape'] as String,
      renderableData['color'] as String,
    );
  }

  @override
  bool canSerialize(Object component) => component is Renderable;
  @override
  bool canDeserialize(ComponentRepresentation data) =>
      data is Map<String, dynamic> && data[EntitySerialiserJson.typeField] == type;
}

class MassJsonSerializer extends ComponentSerializer<Mass> {
  static const type = 'Mass';
  @override
  ComponentRepresentation? serialize(Mass component) {
    return {
      'value': component.value,
      EntitySerialiserJson.typeField: type
    };
  }

  @override
  Mass deserialize(ComponentRepresentation data) {
    final massData = data as Map<String, dynamic>;
    return Mass(massData['value'] as double);
  }

  @override
  bool canSerialize(Object component) => component is Mass;
  @override
  bool canDeserialize(ComponentRepresentation data) =>
      data is Map<String, dynamic> && data[EntitySerialiserJson.typeField] == type;
}

class ColliderJsonSerializer extends ComponentSerializer<Collider> {
  static const type = 'Collider';
  @override
  ComponentRepresentation? serialize(Collider component) {
    return {
      'radius': component.radius,
      'collidesWith': component.collidesWith.map((t) => t.toString()).toList(),
      EntitySerialiserJson.typeField: type
    };
  }

  @override
  Collider deserialize(ComponentRepresentation data) {
    final colliderData = data as Map<String, dynamic>;
    Set<Type> collidesWithTypes = (colliderData['collidesWith'] as List)
        .map((typeName) {
          // This is a simplified mapping. A robust solution needs a type registry.
          if (typeName == (Player).toString()) return Player;
          if (typeName == (Asteroid).toString()) return Asteroid;
          if (typeName == (Bullet).toString()) return Bullet;
          // Add other types if needed or use a more generic mapping solution.
          return Component; // Fallback
        })
        .toSet();
    return Collider(
      colliderData['radius'] as double,
      collidesWith: collidesWithTypes,
      // onCollide would be re-established here, possibly via a lookup if serialized as an identifier.
    );
  }

  @override
  bool canSerialize(Object component) => component is Collider;
  @override
  bool canDeserialize(ComponentRepresentation data) =>
      data is Map<String, dynamic> && data[EntitySerialiserJson.typeField] == type;
}

class PlayerJsonSerializer extends ComponentSerializer<Player> {
  static const type = 'Player';
  @override
  ComponentRepresentation? serialize(Player component) {
    return {EntitySerialiserJson.typeField: type};
  }

  @override
  Player deserialize(ComponentRepresentation data) {
    return Player();
  }

  @override
  bool canSerialize(Object component) => component is Player;
  @override
  bool canDeserialize(ComponentRepresentation data) =>
      data is Map<String, dynamic> && data[EntitySerialiserJson.typeField] == type;
}

class AsteroidJsonSerializer extends ComponentSerializer<Asteroid> {
  static const type = 'Asteroid';
  @override
  ComponentRepresentation? serialize(Asteroid component) {
    return {
      'size': component.size,
      EntitySerialiserJson.typeField: type
    };
  }

  @override
  Asteroid deserialize(ComponentRepresentation data) {
    final asteroidData = data as Map<String, dynamic>;
    return Asteroid(size: asteroidData['size'] as String);
  }

  @override
  bool canSerialize(Object component) => component is Asteroid;
  @override
  bool canDeserialize(ComponentRepresentation data) =>
      data is Map<String, dynamic> && data[EntitySerialiserJson.typeField] == type;
}

class BulletJsonSerializer extends ComponentSerializer<Bullet> {
  static const type = 'Bullet';
  @override
  ComponentRepresentation? serialize(Bullet component) {
    return {
      'ownerId': component.owner.id,
      EntitySerialiserJson.typeField: type
    };
  }

  @override
  Bullet deserialize(ComponentRepresentation data) {
    final bulletData = data as Map<String, dynamic>;
    return Bullet(Entity(bulletData['ownerId'] as int));
  }

  @override
  bool canSerialize(Object component) => component is Bullet;
  @override
  bool canDeserialize(ComponentRepresentation data) =>
      data is Map<String, dynamic> && data[EntitySerialiserJson.typeField] == type;
}

class HealthJsonSerializer extends ComponentSerializer<Health> {
  static const type = 'Health';
  @override
  ComponentRepresentation? serialize(Health component) {
    return {
      'currentLives': component.currentLives,
      'maxLives': component.maxLives,
      EntitySerialiserJson.typeField: type
    };
  }

  @override
  Health deserialize(ComponentRepresentation data) {
    final healthData = data as Map<String, dynamic>;
    return Health(
      currentLives: healthData['currentLives'] as int,
      maxLives: healthData['maxLives'] as int,
    );
  }

  @override
  bool canSerialize(Object component) => component is Health;
  @override
  bool canDeserialize(ComponentRepresentation data) =>
      data is Map<String, dynamic> && data[EntitySerialiserJson.typeField] == type;
}

final asteroidsComponentSerializers = <ComponentSerializer>[
  TransformJsonSerializer(),
  VelocityJsonSerializer(),
  RenderableJsonSerializer(),
  PlayerJsonSerializer(),
  AsteroidJsonSerializer(),
  BulletJsonSerializer(),
  HealthJsonSerializer(),
  MassJsonSerializer(),
  ColliderJsonSerializer(), // Added ColliderJsonSerializer
];

// --- Game Systems ---

class PlayerInputSystem extends EntitySystem {
  bool isAccelerating = false;
  bool isRotatingLeft = false;
  bool isRotatingRight = false;
  bool isShooting = false;

  double accelerationPower = 0.1;
  double rotationSpeed = 0.05;
  // double bulletSpeed = 5.0; // Bullet speed is now handled by createAsteroidsWorld

  World world;
  PlayerInputSystem(this.world); // Modified constructor


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
      final bulletX = transform.x + cos(transform.rotation) * 15; // Spawn slightly ahead of player
      final bulletY = transform.y + sin(transform.rotation) * 15;
      const bulletSpeedValue = 5.0; // Actual bullet speed

      final bulletEntity = world.createEntity();
      world.addComponent(bulletEntity, Bullet(entity)); // Pass player entity as owner
      world.addComponent(bulletEntity, Transform(bulletX, bulletY, rotation: transform.rotation));
      world.addComponent(bulletEntity, Velocity(
        cos(transform.rotation) * bulletSpeedValue,
        sin(transform.rotation) * bulletSpeedValue
      ));
      world.addComponent(bulletEntity, Renderable("circle_small", "yellow")); // Smaller circle for bullet
      world.addComponent(bulletEntity, Mass(0.1));
      world.addComponent(bulletEntity, Collider(2.0, collidesWith: {Asteroid}, onCollide: handleBulletCollision));

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
  if (world.hasComponent<Asteroid>(other)) {
    // print("Bullet ${bullet.id} hit Asteroid ${other.id}. Bullet removed.");
    world.removeEntity(bullet);
  }
}


class GravitySystem extends EntitySystem {
  final double gravitationalConstant;

  GravitySystem({this.gravitationalConstant = 0.0}); // Defaulting to 0 for asteroids, can be set otherwise

  @override
  Set<Type> get filterTypes => const {Velocity, Mass}; // Transform no longer needed for simple Y-axis gravity

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

  MovementSystem({this.worldWidth = 800, this.worldHeight = 600, this.wrapAround = true});

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
    final potentialColliders = world.queryEntities(filterTypes);

    for (final entityB in potentialColliders) {
      if (entityA.id >= entityB.id) continue; // Avoid self-collision and duplicate pairs (A-B is same as B-A)

      // String pairKey = '${entityA.id}-${entityB.id}'; // Ensured by A.id < B.id check
      // if (_processedPairs.contains(pairKey)) continue; // Already handled by A.id < B.id

      final transformB = world.getComponent<Transform>(entityB);
      final colliderB = world.getComponent<Collider>(entityB);

      if (transformB == null || colliderB == null) continue;

      bool canACollideWithBType = colliderA.collidesWith.any((type) => world.hasComponent(entityB, type));
      bool canBCollideWithTypeA = colliderB.collidesWith.any((type) => world.hasComponent(entityA, type));

      if (!canACollideWithBType || !canBCollideWithTypeA) continue;

      double distanceSq = pow(transformA.x - transformB.x, 2) + pow(transformA.y - transformB.y, 2);
      double radiiSumSq = pow(colliderA.radius + colliderB.radius, 2);

      if (distanceSq < radiiSumSq) {
        // Collision detected!
        // _processedPairs.add(pairKey); // Not strictly needed due to ordered ID check

        // Invoke callbacks. The world is passed to allow for entity creation/deletion.
        colliderA.onCollide?.call(entityA, entityB, world);
        colliderB.onCollide?.call(entityB, entityA, world); // Call B's handler as well
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

  AsteroidSpawnSystem(this.world, {this.spawnInterval = 5.0, this.worldWidth = 800, this.worldHeight = 600});

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
    double speed = (random.nextDouble() * 0.5 + 0.5) * 2.0; // Adjusted for ~60fps, results in 0.5 to 1.0 units per frame scaled by time.

    if (random.nextBool()) {
      x = random.nextBool() ? -30.0 : worldWidth + 30.0; // Spawn off-screen
      y = random.nextDouble() * worldHeight;
      vx = (x < worldWidth / 2 ? 1 : -1) * speed * (random.nextDouble() * 0.5 + 0.5);
      vy = (random.nextDouble() - 0.5) * speed;
    } else {
      y = random.nextBool() ? -30.0 : worldHeight + 30.0; // Spawn off-screen
      x = random.nextDouble() * worldWidth;
      vy = (y < worldHeight / 2 ? 1 : -1) * speed * (random.nextDouble() * 0.5 + 0.5);
      vx = (random.nextDouble() - 0.5) * speed;
    }

    final asteroidEntity = world.createEntity();
    world.addComponent(asteroidEntity, Asteroid(size: "large"));
    world.addComponent(asteroidEntity, Transform(x, y, rotation: random.nextDouble() * 2 * pi));
    world.addComponent(asteroidEntity, Velocity(vx, vy)); // Store as per-second, Movement system will scale
    world.addComponent(asteroidEntity, Mass(30.0));
    world.addComponent(asteroidEntity, Renderable("polygon_asteroid_large", "grey")); // Unique shape for large
    world.addComponent(asteroidEntity, Collider(30.0, collidesWith: {Player, Bullet}, onCollide: handleAsteroidCollision));
  }

  @override
  void processEntity(Entity entity, Map<Type, SparseList<Component>> componentLists, Duration delta) {
    // Not used
  }
}

void handleAsteroidCollision(Entity asteroidEntity, Entity otherEntity, World world) {
  // This function is the callback for Asteroid's Collider component.
  // It defines what happens *to the asteroid* when it collides.

  final asteroidComponent = world.getComponent<Asteroid>(asteroidEntity);
  if (asteroidComponent == null) return; // Should not happen if called on an asteroid

  if (world.hasComponent<Bullet>(otherEntity)) {
    // Asteroid hit by a bullet
    // print("Asteroid ${asteroidEntity.id} (size: ${asteroidComponent.size}) hit by Bullet ${otherEntity.id}");
    world.removeEntity(asteroidEntity); // Destroy this asteroid
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

  } else if (world.hasComponent<Player>(otherEntity)) {
    // Asteroid collided with Player
    // print("Asteroid ${asteroidEntity.id} collided with Player ${otherEntity.id}");
    world.removeEntity(asteroidEntity); // Destroy the asteroid

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

void _spawnSmallerAsteroid(World world, Transform parentTransform, String newSize) {
  Random random = Random();
  double baseSpeed = 0.0; // Per-frame, assuming 60fps scaling in movement
  double radius = 0;
  double mass = 0;
  String renderShape = "polygon_asteroid_default";

  if (newSize == "medium") {
    baseSpeed = 1.2 * (1/60.0) ; // Adjusted for 60fps scaling
    radius = 15.0;
    mass = 15.0;
    renderShape = "polygon_asteroid_medium";
  } else if (newSize == "small") {
    baseSpeed = 1.5 * (1/60.0); // Adjusted for 60fps scaling
    radius = 8.0;
    mass = 7.0;
    renderShape = "polygon_asteroid_small";
  } else {
    return; // Unknown size
  }

  for (int i = 0; i < 2; i++) {
    final newAsteroid = world.createEntity();
    double angle = random.nextDouble() * 2 * pi;
    // Velocity is per-second, MovementSystem will scale by delta.
    double speedMagnitude = baseSpeed * 60 * (random.nextDouble() * 0.5 + 0.75); // Make them a bit faster

    world.addComponent(newAsteroid, Asteroid(size: newSize));
    world.addComponent(newAsteroid, Transform(parentTransform.x, parentTransform.y, rotation: random.nextDouble() * 2 * pi));
    world.addComponent(newAsteroid, Velocity(cos(angle) * speedMagnitude, sin(angle) * speedMagnitude));
    world.addComponent(newAsteroid, Mass(mass));
    world.addComponent(newAsteroid, Renderable(renderShape, "grey"));
    world.addComponent(newAsteroid, Collider(radius, collidesWith: {Player, Bullet}, onCollide: handleAsteroidCollision));
    // print("Spawned smaller asteroid ${newAsteroid.id} (size: $newSize)");
  }
}


class BulletLifecycleSystem extends EntitySystem {
  double maxLifetime;
  Map<Entity, double> bulletAge = {};
  World world;

  final double worldWidth;
  final double worldHeight;

  BulletLifecycleSystem(this.world, {this.maxLifetime = 2.0, this.worldWidth = 800, this.worldHeight = 600});

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
      if (transform.x < -50 || transform.x > worldWidth + 50 || transform.y < -50 || transform.y > worldHeight + 50) {
        shouldRemove = true;
      }
    }

    if (shouldRemove) {
      world.removeEntity(entity);
      // bulletAge.remove(entity) will be handled by onEntityRemoved
      // print("Bullet ${entity.id} removed.");
    }
  }

  @override
  void onEntityRemoved(Entity entity) {
    bulletAge.remove(entity);
  }
}
