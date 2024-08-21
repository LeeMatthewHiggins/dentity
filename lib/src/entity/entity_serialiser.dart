import 'package:dentity/dentity.dart';

typedef EntityRepresentation = Object;

abstract class EntitySerialiser {
  final EntityManager _entityManager;
  late final EntityComponentsSerializer _componentsSerializer;

  EntitySerialiser(
    this._entityManager,
    Map<Type, ComponentSerializer> serializers,
  ) {
    _componentsSerializer = EntityComponentsSerializer(
      _entityManager.componentManager,
      serializers,
    );
  }

  EntityRepresentation serializeEntity(Entity entity) {
    final components = _componentsSerializer.serializeComponents(entity);
    return serializeEntityComponents(entity, components);
  }

  EntityRepresentation serializeEntityComponents(
    Entity entity,
    Iterable<ComponentRepresentation> components,
  );

  Iterable<ComponentRepresentation> deserializeEntityComponents(
    EntityRepresentation data,
  );

  Entity deserializeEntity(EntityRepresentation data) {
    final components = deserializeEntityComponents(data);
    return _entityManager.createEntity(
      _componentsSerializer.deserializeComponents(components),
    );
  }
}
