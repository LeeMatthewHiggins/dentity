import 'package:dentity/dentity.dart';

abstract class System {
  late final EntityView view;
  late final EntityManager entityManager;
  late final ComponentsReadOnlyInterface componentManager;
  Set<Type> get filterTypes;

  void attach(EntityManager entityManager) {
    final archetypeManager = entityManager.componentManager.archetypeManager;
    final archetype = archetypeManager.getArchetype(filterTypes);
    view = entityManager.view(archetype);
    componentManager = entityManager.componentManager;
    this.entityManager = entityManager;
  }

  void process() {
    final components = view.componentArrays;
    for (var entity in view) {
      processEntity(entity, components);
    }
  }

  void processEntity(
    Entity entity,
    Map<Type, SparseList<Component>> componentArrays,
  );
}
