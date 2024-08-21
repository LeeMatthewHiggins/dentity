import 'package:dentity/dentity.dart';

typedef WorldRepresentation = Object;

abstract class WorldSerialiser {
  final EntityManager _entityManager;
  final EntitySerialiser _entitySerialiser;

  WorldSerialiser(
    this._entityManager,
    this._entitySerialiser,
  );

  WorldRepresentation serialize() {
    final entities = _entityManager.entities;
    final entityReps =
        entities.map((e) => _entitySerialiser.serializeEntity(e));
    return serializeEntities(entityReps);
  }

  WorldRepresentation serializeEntities(
    Iterable<EntityRepresentation> entities,
  );
}
