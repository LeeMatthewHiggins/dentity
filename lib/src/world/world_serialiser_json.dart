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
}
