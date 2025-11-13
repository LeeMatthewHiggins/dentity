import 'dart:math' as math;
import 'package:dentity/dentity.dart';
import 'realistic_components.dart';
import 'realistic_systems.dart';
import 'enhanced_benchmark_result.dart';
import 'basic_example.dart';

World _createRealisticWorld({
  required List<System> systems,
  bool enableStats = true,
}) {
  final componentManager = ComponentManager(
    archetypeManagerFactory: (types) => ArchetypeManagerBigInt(types),
    componentArrayFactories: {
      Position: () => ContiguousSparseList<Position>(),
      Velocity: () => ContiguousSparseList<Velocity>(),
      ...realisticComponentFactories,
    },
  );

  final entityManager = EntityManager(componentManager);

  return World(
    componentManager,
    entityManager,
    systems,
    enableStats: enableStats,
  );
}

class RealisticScenarios {
  static const _worldWidth = 10000.0;
  static const _worldHeight = 10000.0;

  static EnhancedBenchmarkResult spaceShooter({
    int bulletCount = 50000,
    int enemyCount = 10000,
    int particleCount = 1000,
    int frameCount = 120,
  }) {
    final systems = [
      PhysicsSystem(),
      LifetimeSystem(),
      SimplifiedCollisionSystem(),
      WeaponSystem(),
      DamageSystem(),
      AnimationSystem(),
      RenderingSystem(),
    ];

    final world = _createRealisticWorld(systems: systems);
    final random = math.Random(42);
    final frameSnapshots = <FrameSnapshot>[];
    final systemBreakdown = <String, Duration>{};

    for (var i = 0; i < bulletCount; i++) {
      world.createEntity({
        Position(
          random.nextDouble() * _worldWidth,
          random.nextDouble() * _worldHeight,
        ),
        Velocity(
          random.nextDouble() * 200 - 100,
          random.nextDouble() * 200 - 100,
        ),
        Lifetime(random.nextInt(800) + 400),
        Damage(10),
        BoundingBox(2, 2),
        Sprite('bullet', layer: 1),
        Team(random.nextInt(2)),
      });
    }

    for (var i = 0; i < enemyCount; i++) {
      world.createEntity({
        Position(
          random.nextDouble() * _worldWidth,
          random.nextDouble() * _worldHeight,
        ),
        Velocity(
          random.nextDouble() * 40 - 20,
          random.nextDouble() * 40 - 20,
        ),
        Health(100, 100),
        Sprite('enemy', layer: 2),
        AIState('patrol'),
        Weapon(200, 15, 300, ammo: 100),
        Target(null),
        BoundingBox(16, 16),
        Team(random.nextInt(2)),
      });
    }

    for (var i = 0; i < particleCount; i++) {
      world.createEntity({
        Position(
          random.nextDouble() * _worldWidth,
          random.nextDouble() * _worldHeight,
        ),
        Velocity(
          random.nextDouble() * 100 - 50,
          random.nextDouble() * 100 - 50,
        ),
        Lifetime(random.nextInt(600) + 300),
        Sprite('particle', layer: 0, opacity: 0.7),
        Animation(8, 0.05),
      });
    }

    final totalEntityCount = bulletCount + enemyCount + particleCount;
    final sw = Stopwatch()..start();

    for (var frame = 0; frame < frameCount; frame++) {
      final frameSw = Stopwatch()..start();
      world.process(delta: const Duration(milliseconds: 16));
      frameSw.stop();

      frameSnapshots.add(FrameSnapshot(
        frameNumber: frame,
        activeEntities: world.entityManager.entities.length,
        recycledEntities: world.stats?.entities.recycledCount ?? 0,
        frameDuration: frameSw.elapsed,
        systemTimes: {},
      ));
    }

    sw.stop();

    for (final system in world.stats?.systems ?? []) {
      systemBreakdown[system.name] = system.totalTime;
    }

    final stats = world.stats;
    return EnhancedBenchmarkResult(
      name: 'Space Shooter',
      duration: sw.elapsed,
      entityCount: totalEntityCount,
      operations: totalEntityCount * frameCount,
      stats: stats,
      systemBreakdown: systemBreakdown,
      frameSnapshots: frameSnapshots,
      archetypeMetrics: stats != null ? ArchetypeMetrics.fromStats(stats) : null,
      cacheMetrics: ViewCacheMetrics.fromEntityManager(
        world.entityManager,
        frameCount * systems.length,
      ),
      lifecycleMetrics: stats != null
          ? EntityLifecycleMetrics.fromStats(stats, sw.elapsed)
          : null,
    );
  }

  static EnhancedBenchmarkResult rtsUnits({
    int unitCount = 5000,
    int buildingCount = 100,
    int frameCount = 120,
  }) {
    final systems = [
      PhysicsSystem(),
      TargetingSystem(),
      WeaponSystem(),
      DamageSystem(),
      HealthRegenerationSystem(),
      RenderingSystem(),
    ];

    final world = _createRealisticWorld(systems: systems);
    final random = math.Random(42);
    final frameSnapshots = <FrameSnapshot>[];
    final systemBreakdown = <String, Duration>{};

    for (var i = 0; i < unitCount; i++) {
      world.createEntity({
        Position(
          random.nextDouble() * _worldWidth,
          random.nextDouble() * _worldHeight,
        ),
        Velocity(
          random.nextDouble() * 60 - 30,
          random.nextDouble() * 60 - 30,
        ),
        Health(150, 150, regenerationRate: 1.0),
        Team(i % 4),
        Target(null),
        Weapon(1000, 20, 400, ammo: -1),
        Sprite('unit', layer: 1),
      });
    }

    for (var i = 0; i < buildingCount; i++) {
      world.createEntity({
        Position(
          random.nextDouble() * _worldWidth,
          random.nextDouble() * _worldHeight,
        ),
        Health(500, 500),
        Team(i % 4),
        Sprite('building', layer: 0),
      });
    }

    final totalEntityCount = unitCount + buildingCount;
    final sw = Stopwatch()..start();

    for (var frame = 0; frame < frameCount; frame++) {
      final frameSw = Stopwatch()..start();
      world.process(delta: const Duration(milliseconds: 16));
      frameSw.stop();

      frameSnapshots.add(FrameSnapshot(
        frameNumber: frame,
        activeEntities: world.entityManager.entities.length,
        recycledEntities: world.stats?.entities.recycledCount ?? 0,
        frameDuration: frameSw.elapsed,
        systemTimes: {},
      ));
    }

    sw.stop();

    for (final system in world.stats?.systems ?? []) {
      systemBreakdown[system.name] = system.totalTime;
    }

    final stats = world.stats;
    return EnhancedBenchmarkResult(
      name: 'RTS Units',
      duration: sw.elapsed,
      entityCount: totalEntityCount,
      operations: totalEntityCount * frameCount,
      stats: stats,
      systemBreakdown: systemBreakdown,
      frameSnapshots: frameSnapshots,
      archetypeMetrics: stats != null ? ArchetypeMetrics.fromStats(stats) : null,
      cacheMetrics: ViewCacheMetrics.fromEntityManager(
        world.entityManager,
        frameCount * systems.length,
      ),
      lifecycleMetrics: stats != null
          ? EntityLifecycleMetrics.fromStats(stats, sw.elapsed)
          : null,
    );
  }

  static EnhancedBenchmarkResult archetypeChaos({
    int entityCount = 10000,
    int frameCount = 120,
  }) {
    final systems = [
      PhysicsSystem(),
      RotationSystem(),
      LifetimeSystem(),
      HealthRegenerationSystem(),
      AnimationSystem(),
      RenderingSystem(),
    ];

    final world = _createRealisticWorld(systems: systems);
    final random = math.Random(42);
    final frameSnapshots = <FrameSnapshot>[];
    final systemBreakdown = <String, Duration>{};

    final availableComponents = [
      Position(0, 0),
      Velocity(0, 0),
      Acceleration(0, 0),
      Rotation(0, 0),
      Health(100, 100),
      Lifetime(5000),
      Sprite('sprite', layer: 0),
      Animation(4, 0.1),
      Team(0),
      BoundingBox(10, 10),
    ];

    for (var i = 0; i < entityCount; i++) {
      final componentCount = random.nextInt(6) + 2;
      final selectedComponents = <Component>{};

      for (var j = 0; j < componentCount; j++) {
        final component = availableComponents[random.nextInt(availableComponents.length)].clone();

        if (component is Position) {
          component.x = random.nextDouble() * _worldWidth;
          component.y = random.nextDouble() * _worldHeight;
        } else if (component is Velocity) {
          component.x = random.nextDouble() * 100 - 50;
          component.y = random.nextDouble() * 100 - 50;
        } else if (component is Team) {
          component.teamId = random.nextInt(5);
        }

        selectedComponents.add(component);
      }

      world.createEntity(selectedComponents);
    }

    final sw = Stopwatch()..start();

    for (var frame = 0; frame < frameCount; frame++) {
      final frameSw = Stopwatch()..start();
      world.process(delta: const Duration(milliseconds: 16));
      frameSw.stop();

      frameSnapshots.add(FrameSnapshot(
        frameNumber: frame,
        activeEntities: world.entityManager.entities.length,
        recycledEntities: world.stats?.entities.recycledCount ?? 0,
        frameDuration: frameSw.elapsed,
        systemTimes: {},
      ));
    }

    sw.stop();

    for (final system in world.stats?.systems ?? []) {
      systemBreakdown[system.name] = system.totalTime;
    }

    final stats = world.stats;
    return EnhancedBenchmarkResult(
      name: 'Archetype Chaos',
      duration: sw.elapsed,
      entityCount: entityCount,
      operations: entityCount * frameCount,
      stats: stats,
      systemBreakdown: systemBreakdown,
      frameSnapshots: frameSnapshots,
      archetypeMetrics: stats != null ? ArchetypeMetrics.fromStats(stats) : null,
      cacheMetrics: ViewCacheMetrics.fromEntityManager(
        world.entityManager,
        frameCount * systems.length,
      ),
      lifecycleMetrics: stats != null
          ? EntityLifecycleMetrics.fromStats(stats, sw.elapsed)
          : null,
    );
  }

  static EnhancedBenchmarkResult statusEffects({
    int entityCount = 1000,
    int frameCount = 120,
  }) {
    final systems = [
      PhysicsSystem(),
      HealthRegenerationSystem(),
      DamageSystem(),
      RenderingSystem(),
    ];

    final world = _createRealisticWorld(systems: systems);
    final random = math.Random(42);
    final frameSnapshots = <FrameSnapshot>[];
    final systemBreakdown = <String, Duration>{};
    final entities = <Entity>[];

    for (var i = 0; i < entityCount; i++) {
      final entity = world.createEntity({
        Position(
          random.nextDouble() * _worldWidth,
          random.nextDouble() * _worldHeight,
        ),
        Velocity(
          random.nextDouble() * 40 - 20,
          random.nextDouble() * 40 - 20,
        ),
        Health(200, 200, regenerationRate: 2.0),
        Sprite('character', layer: 1),
      });
      entities.add(entity);
    }

    final sw = Stopwatch()..start();
    int totalComponentChanges = 0;

    for (var frame = 0; frame < frameCount; frame++) {
      if (frame % 10 == 0) {
        for (var i = 0; i < entities.length; i += 10) {
          if (entities[i] < world.entityManager.entities.length) {
            world.addComponents(entities[i], {Acceleration(10, 10)});
            totalComponentChanges++;
          }
        }
      }

      if (frame % 15 == 0) {
        for (var i = 0; i < entities.length; i += 15) {
          if (entities[i] < world.entityManager.entities.length) {
            world.removeComponents(entities[i], [Acceleration]);
            totalComponentChanges++;
          }
        }
      }

      if (frame % 20 == 0) {
        for (var i = 0; i < entities.length; i += 20) {
          if (entities[i] < world.entityManager.entities.length) {
            world.addComponents(entities[i], {Damage(5)});
            totalComponentChanges++;
          }
        }
      }

      final frameSw = Stopwatch()..start();
      world.process(delta: const Duration(milliseconds: 16));
      frameSw.stop();

      frameSnapshots.add(FrameSnapshot(
        frameNumber: frame,
        activeEntities: world.entityManager.entities.length,
        recycledEntities: world.stats?.entities.recycledCount ?? 0,
        frameDuration: frameSw.elapsed,
        systemTimes: {},
      ));
    }

    sw.stop();

    for (final system in world.stats?.systems ?? []) {
      systemBreakdown[system.name] = system.totalTime;
    }

    final stats = world.stats;
    return EnhancedBenchmarkResult(
      name: 'Status Effects',
      duration: sw.elapsed,
      entityCount: entityCount,
      operations: (entityCount * frameCount) + totalComponentChanges,
      stats: stats,
      systemBreakdown: systemBreakdown,
      frameSnapshots: frameSnapshots,
      archetypeMetrics: stats != null ? ArchetypeMetrics.fromStats(stats) : null,
      cacheMetrics: ViewCacheMetrics.fromEntityManager(
        world.entityManager,
        frameCount * systems.length,
      ),
      lifecycleMetrics: stats != null
          ? EntityLifecycleMetrics.fromStats(stats, sw.elapsed)
          : null,
    );
  }

  static List<EnhancedBenchmarkResult> scalabilityTest({
    List<int> entityCounts = const [1000, 5000, 10000, 25000, 50000, 100000],
    int frameCount = 60,
  }) {
    final results = <EnhancedBenchmarkResult>[];

    for (final count in entityCounts) {
      final systems = [PhysicsSystem()];
      final world = _createRealisticWorld(systems: systems);
      final random = math.Random(42);
      final frameSnapshots = <FrameSnapshot>[];
      final systemBreakdown = <String, Duration>{};

      for (var i = 0; i < count; i++) {
        world.createEntity({
          Position(
            random.nextDouble() * _worldWidth,
            random.nextDouble() * _worldHeight,
          ),
          Velocity(
            random.nextDouble() * 100 - 50,
            random.nextDouble() * 100 - 50,
          ),
        });
      }

      final sw = Stopwatch()..start();

      for (var frame = 0; frame < frameCount; frame++) {
        final frameSw = Stopwatch()..start();
        world.process(delta: const Duration(milliseconds: 16));
        frameSw.stop();

        frameSnapshots.add(FrameSnapshot(
          frameNumber: frame,
          activeEntities: world.entityManager.entities.length,
          recycledEntities: world.stats?.entities.recycledCount ?? 0,
          frameDuration: frameSw.elapsed,
          systemTimes: {},
        ));
      }

      sw.stop();

      for (final system in world.stats?.systems ?? []) {
        systemBreakdown[system.name] = Duration(
          microseconds: (system.totalTimeMs * 1000).toInt(),
        );
      }

      final stats = world.stats;
      results.add(EnhancedBenchmarkResult(
        name: 'Scalability ($count entities)',
        duration: sw.elapsed,
        entityCount: count,
        operations: count * frameCount,
        stats: stats,
        systemBreakdown: systemBreakdown,
        frameSnapshots: frameSnapshots,
        archetypeMetrics: stats != null ? ArchetypeMetrics.fromStats(stats) : null,
        cacheMetrics: ViewCacheMetrics.fromEntityManager(
          world.entityManager,
          frameCount * systems.length,
        ),
        lifecycleMetrics: stats != null
            ? EntityLifecycleMetrics.fromStats(stats, sw.elapsed)
            : null,
      ));
    }

    return results;
  }
}
