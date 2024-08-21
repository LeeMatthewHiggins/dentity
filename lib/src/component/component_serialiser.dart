import 'package:dentity/dentity.dart';

typedef ComponentRepresentation = Object;

abstract class ComponentSerializer<T> {
  ComponentRepresentation? serialize(T component);
  T deserialize(ComponentRepresentation data);
  bool canSerialize(Object component);
  bool canDeserialize(ComponentRepresentation data);
}

class EntityComponentsSerializer {
  final ComponentManager _componentManager;
  final Map<Type, ComponentSerializer> _serializers;

  EntityComponentsSerializer(this._componentManager, this._serializers);

  ComponentRepresentation? serializeComponent(Component component) {
    final serializer = _serializers[component.runtimeType];
    if (serializer == null) {
      return null;
    }
    return serializer.serialize(component);
  }

  Iterable<ComponentRepresentation> serializeComponents(Entity entity) {
    final components = _componentManager.getComponents(entity);
    return components
        .map(serializeComponent)
        .where((c) => c != null)
        .cast<ComponentRepresentation>();
  }

  Component deserializeComponent(ComponentRepresentation data) {
    final serializer = _serializers.values.firstWhere(
      (entry) => entry.canDeserialize(data),
      orElse: () => throw ArgumentError('No serializer found for $data'),
    );
    return serializer.deserialize(data);
  }

  Iterable<Component> deserializeComponents(
    Iterable<ComponentRepresentation> data,
  ) {
    return data.map(deserializeComponent);
  }
}
