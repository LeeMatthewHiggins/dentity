import 'package:dentity/dentity.dart';

class EntitySerialiserJson extends EntitySerialiser {
  static const String typeField = '_type';
  static const String componentsField = 'components';

  EntitySerialiserJson(
    super.entityManager,
    super.serializers,
  );

  @override
  EntityRepresentation serializeEntityComponents(
    Entity entity,
    Iterable<ComponentRepresentation> components,
  ) {
    final componentList = <ComponentRepresentation>[];
    for (var component in components) {
      if (component is Map<String, dynamic>) {
        final type = component[typeField];
        if (type is String && type.isNotEmpty) {
          componentList.add(component);
        } else {
          throw ArgumentError('Component missing or invalid $typeField field');
        }
      } else {
        throw ArgumentError(
            'Invalid component representation: expected Map<String, dynamic>');
      }
    }

    return {componentsField: componentList};
  }

  @override
  Iterable<ComponentRepresentation> deserializeEntityComponents(
    EntityRepresentation data,
  ) {
    if (data is Map<String, dynamic>) {
      final components = data[componentsField];
      if (components is List<dynamic>) {
        return components.whereType<Object>();
      } else {
        throw ArgumentError(
            'Invalid entity representation: expected List<Map<String, dynamic>> got ${components.runtimeType}');
      }
    } else {
      throw ArgumentError(
          'Invalid entity representation: expected Map<String, dynamic>');
    }
  }
}
