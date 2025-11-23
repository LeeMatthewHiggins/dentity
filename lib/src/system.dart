import 'package:dentity/dentity.dart';

abstract class System {
  World? _world;
  late final EntityManager entityManager;
  late final ComponentManagerReadOnlyInterface componentManager;

  World get world => _world!;

  String get name => runtimeType.toString();

  @Deprecated('Use attachWorld instead')
  void attach(EntityManager entityManager) {
    componentManager = entityManager.componentManager;
    this.entityManager = entityManager;
  }

  void attachWorld(World world) {
    _world = world;
    componentManager = world.entityManager.componentManager;
    entityManager = world.entityManager;
  }

  void process(Duration delta);
}

abstract class EntitySystem extends System {
  late final EntityView view;
  Set<Type> get filterTypes;

  @override
  @Deprecated('Use attachToWorld instead')
  void attach(EntityManager entityManager) {
    view = entityManager.viewForTypes(filterTypes);
    super.attach(entityManager);
  }

  @override
  void attachWorld(World world) {
    super.attachWorld(world);
    view = entityManager.viewForTypes(filterTypes);
  }

  @override
  void process(Duration delta) {
    for (var entity in view) {
      processEntity(entity, componentManager, delta);
    }
  }

  void processEntity(
    Entity entity,
    ComponentManagerReadOnlyInterface componentManager,
    Duration delta,
  );
}
