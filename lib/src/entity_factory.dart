import 'package:dentity/dentity.dart';

class EntityPrefab {
  final String name;
  final Set<Component> components;

  EntityPrefab({
    required this.name,
    required this.components,
  });
}

class EntityFactory {
  final Map<String, EntityPrefab> prefabs = {};

  EntityFactory({
    required Iterable<EntityPrefab> prefabs,
  }) {
    for (var prefab in prefabs) {
      this.prefabs[prefab.name] = prefab;
    }
  }

  Entity fabricate(String name, World world) {
    if (prefabs.containsKey(name)) {
      return world.createEntity(
        prefabs[name]!.components.map(
              (c) => c.clone(),
            ),
      );
    }
    throw Exception('Prefab $name not found');
  }

  void addPrefab(EntityPrefab prefab) {
    final name = prefab.name;
    if (prefabs.containsKey(name)) {
      throw Exception('Prefab $name already exists');
    }
    prefabs[prefab.name] = prefab;
  }

  void replacePrefab(EntityPrefab prefab) {
    final name = prefab.name;
    prefabs[name] = prefab;
  }

  void removePrefab(String name) {
    if (prefabs.containsKey(name)) {
      prefabs.remove(name);
    }
  }
}
