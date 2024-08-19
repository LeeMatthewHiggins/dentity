import 'package:dentity/dentity.dart';
import 'package:dentity/src/dentity_base.dart';

typedef Entity = int;

class EntityManager {
  Entity _newEntity = 0;
  final ComponentManager _componentManager;

  final Map<Archetype, Set<Entity>> _recycleBin = {};

  EntityManager(this._componentManager);

  Entity createEntity(Iterable<Component> components) {
    final archetype = _componentManager.getArchetypeForComponentTypes(
      components.map((c) => c.runtimeType),
    );
    final recycleBin = _recycleBin.putIfAbsent(archetype, () => {});
    final recycled = recycleBin.firstOrNull;
    if (recycled != null) {
      _componentManager.addComponents(recycled, components);
      recycleBin.remove(recycled);
      return recycled;
    }
    _componentManager.addComponents(_newEntity, components);
    return _newEntity++;
  }

  void removeEntity(Entity entity) {
    final archetype = _componentManager.getArchetype(entity);
    if (archetype == null) {
      return;
    }
    _recycleBin.putIfAbsent(archetype, () => {}).add(entity);
    _componentManager.removeAllComponents(entity);
  }

  T? getComponent<T extends Component>(Entity entity) {
    return _componentManager.getComponent<T>(entity);
  }
}
