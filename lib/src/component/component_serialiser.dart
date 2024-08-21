import 'package:dentity/dentity.dart';

typedef ComponentRepresentation = Object;

abstract class ComponentSerializer<T> {
  ComponentRepresentation? serialize(T component);
  T deserialize(ComponentRepresentation data);
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
}
