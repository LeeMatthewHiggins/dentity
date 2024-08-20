import 'package:dentity/dentity.dart';

abstract class System {
  late final EntityView view;
  late final EntityManager entityManager;
  late final ComponentsReadOnlyInterface componentManager;
  Set<Type> get filterTypes;

  void attach(EntityManager entityManager) {
    view = entityManager.viewForTypes(filterTypes);
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
