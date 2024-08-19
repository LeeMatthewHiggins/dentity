import 'package:dentity/dentity.dart';

abstract class System {
  final Archetype archetype;
  final EntityManager entityManager;
  Set<Type> get filterTypes;

  System(this.entityManager, this.archetype);

  void process() {
    for (var entity in entityManager.getEntitiesForArchetype(archetype)) {
      processEntity(entity);
    }
  }

  void processEntity(Entity entity);
}
