import 'dart:math' as math;
import 'package:dentity/dentity.dart';
import 'asteroids_components.dart';
import 'asteroids_systems.dart';
import 'basic_example.dart';
import 'realistic_components.dart';

class _WorldConfig {
  static const double defaultWidth = 800.0;
  static const double defaultHeight = 600.0;
}

class _ShipConfig {
  static const double shipThrustForce = 7.5;
  static const double shipStartX = _WorldConfig.defaultWidth / 2;
  static const double shipStartY = _WorldConfig.defaultHeight / 2;
}

class _AsteroidConfig {
  static const int initialLargeAsteroids = 4;
  static const double minSpeed = 1.25;
  static const double maxSpeed = 3.0;
  static const double minRotationSpeed = -1.0;
  static const double maxRotationSpeed = 1.0;
}

World createAsteroidsWorld({
  bool enableStats = false,
  double worldWidth = _WorldConfig.defaultWidth,
  double worldHeight = _WorldConfig.defaultHeight,
}) {
  final componentManager = _createAsteroidsComponentManager();
  final entityManager = EntityManager(componentManager);

  final systems = <System>[
    InputSystem(),
    ThrustSystem(),
    MovementSystem(),
    AsteroidsRotationSystem(),
    BoundsWrappingSystem(),
    LaserSpawnSystem(),
    AsteroidsCollisionSystem(),
    AsteroidsLifetimeSystem(),
    ShieldRechargeSystem(),
  ];

  final world = World(
    componentManager,
    entityManager,
    systems,
    enableStats: enableStats,
  );

  spawnShip(world, worldWidth, worldHeight);
  spawnInitialAsteroids(world, worldWidth, worldHeight);

  return world;
}

ComponentManager _createAsteroidsComponentManager() {
  return ComponentManager(
    archetypeManagerFactory: (types) => ArchetypeManagerBigInt(types),
    componentArrayFactories: {
      Position: () => ContiguousSparseList<Position>(),
      Velocity: () => ContiguousSparseList<Velocity>(),
      Rotation: () => ContiguousSparseList<Rotation>(),
      Lifetime: () => ContiguousSparseList<Lifetime>(),
      ...asteroidsComponentFactories,
    },
  );
}

Entity spawnShip(World world, double worldWidth, double worldHeight) {
  return world.createEntity({
    Position(_ShipConfig.shipStartX, _ShipConfig.shipStartY),
    Velocity(0, 0),
    Rotation(0, 0),
    Ship(),
    ThrustForce(_ShipConfig.shipThrustForce),
    InputState(),
    Bounds(worldWidth, worldHeight),
    Shield(100.0, 100.0),
    Score(0),
  });
}

void spawnInitialAsteroids(World world, double worldWidth, double worldHeight) {
  final random = math.Random();

  for (var i = 0; i < _AsteroidConfig.initialLargeAsteroids; i++) {
    spawnLargeAsteroid(world, worldWidth, worldHeight, random);
  }
}

Entity spawnLargeAsteroid(
  World world,
  double worldWidth,
  double worldHeight,
  math.Random random,
) {
  final x = random.nextDouble() * worldWidth;
  final y = random.nextDouble() * worldHeight;
  final angle = random.nextDouble() * 2 * math.pi;
  final speed = _AsteroidConfig.minSpeed +
      random.nextDouble() * (_AsteroidConfig.maxSpeed - _AsteroidConfig.minSpeed);
  final rotationSpeed = _AsteroidConfig.minRotationSpeed +
      random.nextDouble() *
          (_AsteroidConfig.maxRotationSpeed - _AsteroidConfig.minRotationSpeed);

  return world.createEntity({
    Position(x, y),
    Velocity(math.cos(angle) * speed, math.sin(angle) * speed),
    Rotation(random.nextDouble() * 2 * math.pi, rotationSpeed),
    Asteroid.large(),
    Bounds(worldWidth, worldHeight),
  });
}

Entity spawnMediumAsteroid(
  World world,
  double x,
  double y,
  double vx,
  double vy,
  double worldWidth,
  double worldHeight,
  math.Random random,
) {
  return world.createEntity({
    Position(x, y),
    Velocity(vx, vy),
    Rotation(
      random.nextDouble() * 2 * math.pi,
      _AsteroidConfig.minRotationSpeed +
          random.nextDouble() *
              (_AsteroidConfig.maxRotationSpeed - _AsteroidConfig.minRotationSpeed),
    ),
    Asteroid.medium(),
    Bounds(worldWidth, worldHeight),
  });
}

Entity spawnSmallAsteroid(
  World world,
  double x,
  double y,
  double vx,
  double vy,
  double worldWidth,
  double worldHeight,
  math.Random random,
) {
  return world.createEntity({
    Position(x, y),
    Velocity(vx, vy),
    Rotation(
      random.nextDouble() * 2 * math.pi,
      _AsteroidConfig.minRotationSpeed +
          random.nextDouble() *
              (_AsteroidConfig.maxRotationSpeed - _AsteroidConfig.minRotationSpeed),
    ),
    Asteroid.small(),
    Bounds(worldWidth, worldHeight),
  });
}
