import 'package:dentity/dentity.dart';

abstract class System {
  Set<Type> get filterTypes;
  Archetype get archetype =>
      componentManager.getArchetypeForComponentTypes(filterTypes);
  final ReadonlyComponentManager _componentManager;
  ReadonlyComponentManager get componentManager => _componentManager;

  System(ReadonlyComponentManager componentManager)
      : _componentManager = componentManager;

  void process() {
    for (var entity in componentManager.getEntitiesForArchetype(archetype)) {
      processEntity(entity);
    }
  }

  void processEntity(Entity entity);
}
