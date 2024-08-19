import 'package:dentity/dentity.dart';

class World {
  final EntityManager _entityManager;
  final List<System> _systems;

  World(
    this._entityManager,
    this._systems,
  );

  int createEntity(Iterable<Component> components) {
    return _entityManager.createEntity(components);
  }

  T? getComponent<T extends Component>(Entity entity) {
    return _entityManager.getComponent<T>(entity);
  }

  void removeEntity(Entity entity) {
    _entityManager.removeEntity(entity);
  }

  void process() {
    for (var system in _systems) {
      system.process();
    }
  }
}
