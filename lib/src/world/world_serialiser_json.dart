import 'package:dentity/dentity.dart';

class WorldSerialiserJson extends WorldSerialiser {
  static const String entitiesField = 'entities';

  WorldSerialiserJson(
    super.entityManager,
    super.serializers,
  );

  @override
  WorldRepresentation serializeEntities(
    Iterable<EntityRepresentation> entities,
  ) {
    return {entitiesField: entities.toList()};
  }

  @override
  Iterable<EntityRepresentation> deserializeEntities(
    WorldRepresentation data,
  ) {
    if (data is Map<String, dynamic>) {
      final entities = data[entitiesField];
      if (entities is List) {
        return entities.cast<EntityRepresentation>();
      } else {
        throw ArgumentError(
            'Invalid world representation: expected List<EntityRepresentation>');
      }
    } else {
      throw ArgumentError(
          'Invalid world representation: expected Map<String, dynamic>');
    }
  }
}
