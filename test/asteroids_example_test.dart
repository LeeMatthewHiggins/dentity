import 'package:test/test.dart';
import 'package:dentity/dentity.dart';
import 'package:dentity/dentity_examples.dart';

// Importing the example file directly to access components and potentially systems or collision handlers
import 'package:dentity/src/examples/asteroids_example.dart';


void main() {
  group('Asteroids Example Tests', () {
    late World world;
    late PlayerInputSystem playerInputSystem;
    late Entity playerEntity;
    const double testWorldWidth = 800;
    const double testWorldHeight = 600;

    setUp(() {
      world = createAsteroidsWorld(worldWidth: testWorldWidth, worldHeight: testWorldHeight, withGravity: false);

      final players = world.queryEntities(const {Player});
      // Ensure player entity is found, otherwise tests depending on it will fail.
      expect(players.isNotEmpty, isTrue, reason: "Player entity should exist in the created world.");
      playerEntity = players.first;

      playerInputSystem = world.systems.firstWhere((sys) => sys is PlayerInputSystem) as PlayerInputSystem;
    });

    test('World Creation', () {
      expect(world, isNotNull);
      expect(world.systems.isNotEmpty, isTrue, reason: "Systems should be added.");

      // Player already found in setUp, re-asserting its presence.
      final players = world.queryEntities(const {Player});
      expect(players.length, 1, reason: "Should have one player entity.");

      final asteroids = world.queryEntities(const {Asteroid});
      expect(asteroids.isNotEmpty, reason: "Should have initial asteroids.");

      expect(world.hasComponent<Transform>(playerEntity), isTrue);
      expect(world.hasComponent<Velocity>(playerEntity), isTrue);
      expect(world.hasComponent<Health>(playerEntity), isTrue);
      expect(world.hasComponent<Collider>(playerEntity), isTrue);
    });

    test('Player Input - Acceleration and Rotation', () {
      final initialTransform = world.getComponent<Transform>(playerEntity)!.clone();
      final initialVelocity = world.getComponent<Velocity>(playerEntity)!.clone();

      playerInputSystem.accelerate(true);
      playerInputSystem.rotateRight(true);
      world.process(Duration(milliseconds: 16));

      final newTransform = world.getComponent<Transform>(playerEntity)!;
      final newVelocity = world.getComponent<Velocity>(playerEntity)!;

      expect(newTransform.rotation, greaterThan(initialTransform.rotation), reason: "Player should rotate right.");
      // Player starts facing -PI/2 (up). Rotating right moves towards 0.
      // Accelerating while facing up (-PI/2 rotation) means Y velocity decreases (more negative).
      // After slight right rotation, X velocity should become positive.
      expect(newVelocity.y, lessThan(initialVelocity.y), reason: "Player Y velocity should decrease (move up).");
      expect(newVelocity.x, greaterThan(initialVelocity.x), reason: "Player X velocity should increase (move right after rotation).");

      playerInputSystem.accelerate(false);
      playerInputSystem.rotateRight(false);
    });

    test('Player Input - Shooting creates Bullet', () {
      int initialBulletCount = world.queryEntities(const {Bullet}).length;
      playerInputSystem.shoot();
      world.process(Duration(milliseconds: 16));

      int finalBulletCount = world.queryEntities(const {Bullet}).length;
      expect(finalBulletCount, greaterThan(initialBulletCount), reason: "A bullet should be created.");

      final bullet = world.queryEntities(const {Bullet}).last;
      expect(world.hasComponent<Transform>(bullet), isTrue);
      expect(world.hasComponent<Velocity>(bullet), isTrue);
      expect(world.getComponent<Bullet>(bullet)!.owner, playerEntity);
    });

    test('Movement System updates Transform', () {
      final transform = world.getComponent<Transform>(playerEntity)!;
      final initialX = transform.x;
      final initialY = transform.y;

      final velocity = world.getComponent<Velocity>(playerEntity)!;
      velocity.x = 10; // units per second
      velocity.y = -10; // units per second

      // MovementSystem scales velocity by (delta.inMilliseconds / 16.0)
      // If delta is 16ms, scale is 1.0.
      // If speed is units per second, it should be scaled by (delta / 1000.0)
      // The current MovementSystem applies velocity as units_per_tick where tick is 16ms effectively.
      // So, if velocity is 10, it moves 10 units if delta is 16ms.
      world.process(Duration(milliseconds: 16));

      expect(transform.x, equals(initialX + 10), reason: "X position should update based on velocity.");
      expect(transform.y, equals(initialY - 10), reason: "Y position should update based on velocity.");
    });

    test('Asteroid Spawning System creates Asteroids', () {
      final spawnSystem = world.systems.firstWhere((sys) => sys is AsteroidSpawnSystem) as AsteroidSpawnSystem;
      int initialAsteroidCount = world.queryEntities(const {Asteroid}).length;

      // Simulate time for spawn system to trigger. Interval is 4s in createAsteroidsWorld.
      int ticksToSpawn = (spawnSystem.spawnInterval * 1000 / 16).ceil();
      for(int i=0; i < ticksToSpawn + 5; i++) { // Add a few extra ticks
          world.process(Duration(milliseconds: 16));
      }

      int finalAsteroidCount = world.queryEntities(const {Asteroid}).length;
      expect(finalAsteroidCount, greaterThan(initialAsteroidCount), reason: "Should spawn new asteroids over time.");
    });

    test('Collision - Player vs Asteroid', () {
      final List<Entity> asteroids = world.queryEntities(const {Asteroid}).toList();
      expect(asteroids.isNotEmpty, isTrue, reason: "Test requires at least one asteroid.");
      final asteroid = asteroids.first;

      final playerHealth = world.getComponent<Health>(playerEntity)!;
      final initialLives = playerHealth.currentLives;

      final playerTransform = world.getComponent<Transform>(playerEntity)!;
      final asteroidTransform = world.getComponent<Transform>(asteroid)!;

      // Ensure radii are what we expect for the test. These are set in createAsteroidsWorld.
      final playerCollider = world.getComponent<Collider>(playerEntity)!; // radius ~10
      final asteroidCollider = world.getComponent<Collider>(asteroid)!;   // radius ~30 (large)

      // Position them for collision
      playerTransform.x = 50; playerTransform.y = 50;
      asteroidTransform.x = playerTransform.x + (playerCollider.radius + asteroidCollider.radius) / 2 -1; // Ensure overlap
      asteroidTransform.y = playerTransform.y;

      world.process(Duration(milliseconds: 16));

      expect(playerHealth.currentLives, lessThan(initialLives), reason: "Player health should decrease on collision.");
      expect(world.entityManager.isAlive(asteroid), isFalse, reason: "Asteroid should be destroyed on collision with player.");
    });

    test('Collision - Bullet vs Asteroid', () {
      final List<Entity> asteroids = world.queryEntities(const {Asteroid}).toList();
      expect(asteroids.isNotEmpty, isTrue, reason: "Test requires at least one asteroid to shoot.");
      final asteroid = asteroids.first;
      final asteroidTransform = world.getComponent<Transform>(asteroid)!;

      final playerTransform = world.getComponent<Transform>(playerEntity)!;
      playerTransform.x = asteroidTransform.x - 100; // Position player to the left
      playerTransform.y = asteroidTransform.y;     // Align vertically
      playerTransform.rotation = 0; // Face right (towards positive X)

      playerInputSystem.shoot();

      // Process enough ticks for bullet to travel and hit.
      // Bullet spawns 15 units ahead of player. Distance to cover: 100 - 15 = 85 units.
      // Bullet speed is 5 units/tick (PlayerInputSystem bulletSpeedValue = 5.0, MovementSystem scales by 1 for 16ms delta)
      // Ticks needed: 85 / 5 = 17 ticks.
      bool asteroidDestroyed = false;
      for(int i = 0; i < 25; i++) {
          world.process(Duration(milliseconds: 16));
          if (!world.entityManager.isAlive(asteroid)) {
              asteroidDestroyed = true;
              break;
          }
      }

      expect(asteroidDestroyed, isTrue, reason: "Asteroid should be destroyed by bullet.");

      int bulletCount = world.queryEntities(const {Bullet}).length;
      expect(bulletCount, 0, reason: "Bullet should be destroyed on impact with asteroid (handled by bullet's onCollide).");
    });

    test('Gravity System affects entities with Mass (if enabled)', () {
      world = createAsteroidsWorld(worldWidth: testWorldWidth, worldHeight: testWorldHeight, withGravity: true);
      playerEntity = world.queryEntities(const {Player}).first; // Re-fetch player from new world

      final velocity = world.getComponent<Velocity>(playerEntity)!;
      final initialYVelocity = velocity.y;

      // Let gravity act for a noticeable period
      for(int i=0; i<10; i++) { // 10 ticks = 160 ms
          world.process(Duration(milliseconds: 16));
      }

      expect(velocity.y, greaterThan(initialYVelocity), reason: "Y velocity should increase due to gravity (positive Y is down).");
    });

    test('Bullet Lifecycle System removes old/off-screen bullets', () {
      playerInputSystem.shoot();
      world.process(Duration(milliseconds: 16)); // Bullet created

      final List<Entity> bullets = world.queryEntities(const {Bullet}).toList();
      expect(bullets.isNotEmpty, isTrue, reason: "A bullet must be created for this test.");
      final bullet = bullets.first;

      final bulletLifecycleSystem = world.systems.firstWhere((s) => s is BulletLifecycleSystem) as BulletLifecycleSystem;

      // 1. Test max lifetime
      int ticksToLive = (bulletLifecycleSystem.maxLifetime * 1000 / 16).ceil();
      bool aliveAfterLifetime = true;
      for (int i = 0; i < ticksToLive + 5; i++) {
        world.process(Duration(milliseconds: 16));
        if (!world.entityManager.isAlive(bullet)) {
          aliveAfterLifetime = false;
          break;
        }
      }
      expect(aliveAfterLifetime, isFalse, reason: "Bullet should be removed after its max lifetime.");

      // 2. Test off-screen removal
      playerInputSystem.shoot();
      world.process(Duration(milliseconds: 16)); // Create new bullet

      final List<Entity> bullets2 = world.queryEntities(const {Bullet}).toList();
      expect(bullets2.isNotEmpty, isTrue, reason: "A second bullet must be created.");
      final bullet2 = bullets2.first; // get new bullet

      final bullet2Transform = world.getComponent<Transform>(bullet2)!;
      // Use the worldWidth from the system, as that's what it uses for boundary checks
      bullet2Transform.x = bulletLifecycleSystem.worldWidth + 100; // Move it well off-screen

      world.process(Duration(milliseconds: 16));
      expect(world.entityManager.isAlive(bullet2), isFalse, reason: "Bullet should be removed if it goes off-screen.");
    });

  });
}
