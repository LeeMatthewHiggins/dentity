import 'package:dentity/dentity.dart';

abstract class System {
  late final EntityManager entityManager;
  late final ComponentManagerReadOnlyInterface componentManager;

  void attach(EntityManager entityManager) {
    componentManager = entityManager.componentManager;
    this.entityManager = entityManager;
  }

  void process(Duration delta);
}

abstract class EntitySystem extends System {
  late final EntityView view;
  Set<Type> get filterTypes;

  @override
  void attach(EntityManager entityManager) {
    view = entityManager.viewForTypes(filterTypes);
    super.attach(entityManager);
  }

  @override
  void process(Duration delta) {
    final components = view.componentLists;
    for (var entity in view) {
      processEntity(entity, components, delta);
    }
  }

  void processEntity(
    Entity entity,
    Map<Type, SparseList<Component>> componentLists,
    Duration delta,
  );
}
