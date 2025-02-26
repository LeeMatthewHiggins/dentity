import 'package:dentity/dentity.dart';

typedef EntityRepresentation = Object;

abstract class EntitySerialiser {
  final EntityManager _entityManager;
  late final EntityComponentsSerializer componentsSerializer;

  EntitySerialiser(
    this._entityManager,
    Map<Type, ComponentSerializer> serializers,
  ) {
    componentsSerializer = EntityComponentsSerializer(
      serializers,
    );
  }

  EntityRepresentation serializeEntity(Entity entity) {
    final components = _entityManager.componentManager.getComponents(entity);
    final serialisedComponents =
        componentsSerializer.serializeComponents(components);
    return serializeEntityComponents(entity, serialisedComponents);
  }

  EntityRepresentation serializeEntityComponents(
    Entity entity,
    Iterable<ComponentRepresentation> components,
  );

  Iterable<ComponentRepresentation> deserializeEntityComponents(
    EntityRepresentation data,
  );

  Entity deserializeEntity(EntityRepresentation data) {
    final components = componentsSerializer.deserializeComponents(
      deserializeEntityComponents(data),
    );
    return _entityManager.createEntity(components);
  }
}
