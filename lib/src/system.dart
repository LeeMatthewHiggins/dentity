import 'package:dentity/dentity.dart';
import 'package:dentity/src/archetype.dart';

abstract class System {
  late final Archetype archetype;
  late final EntityManager entityManager;
  late final ArchetypeManager archetypeManager;
  Set<Type> get filterTypes;

  void attach(EntityManager entityManager) {
    this.entityManager = entityManager;
    archetype = entityManager.componentManager.archetypeManager
        .getArchetype(filterTypes);
  }

  void process() {
    for (var entity in entityManager.getEntitiesForArchetype(archetype)) {
      processEntity(entity);
    }
  }

  void processEntity(Entity entity);
}
