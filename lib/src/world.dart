import 'package:dentity/dentity.dart';

class World {
  final EntityManager _entityManager;
  final ComponentManager _componentManager;
  final List<System> _systems;

  World(
    this._componentManager,
    this._entityManager,
    this._systems,
  ) {
    for (var system in _systems) {
      system.attach(_entityManager);
    }
  }

  void process({Duration delta = const Duration(milliseconds: 16)}) {
    for (var system in _systems) {
      system.process(delta);
    }
  }

  int createEntity(Iterable<Component> components) {
    return _entityManager.createEntity(components);
  }

  T? getComponent<T extends Component>(Entity entity) {
    return _componentManager.getComponent<T>(entity);
  }

  void addComponents(Entity entity, Iterable<Component> components) {
    _entityManager.addComponents(entity, components);
  }

  void removeComponents(Entity entity, Iterable<Type> componentTypes) {
    _entityManager.removeComponents(entity, componentTypes);
  }

  void destroyEntity(Entity entity) {
    _entityManager.destroyEntity(entity);
  }
}

extension EntityViewOnWorld on World {
  EntityView view(Archetype archetype) {
    return EntityView(_entityManager, archetype);
  }

  EntityView viewForTypes(Set<Type> types) {
    return EntityView.fromTypes(_entityManager, types);
  }
}
