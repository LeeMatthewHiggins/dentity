import 'package:dentity/dentity.dart';
import 'package:dentity/src/archetype.dart';

abstract class System {
  late final EntityView view;
  late final EntityManager entityManager;
  late final ArchetypeManager archetypeManager;
  Set<Type> get filterTypes;

  void attach(EntityManager entityManager) {
    archetypeManager = entityManager.componentManager.archetypeManager;
    final archetype = archetypeManager.getArchetype(filterTypes);
    view = entityManager.view(archetype);
    this.entityManager = entityManager;
  }

  void process() {
    for (var entity in view) {
      processEntity(entity);
    }
  }

  void processEntity(Entity entity);
}
