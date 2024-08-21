typedef Archetype = Object;

abstract class ArchetypeManagerInterface {
  Archetype getArchetype(Iterable<Type> componentTypes);
  Iterable<Type> getComponentTypes(Archetype archetype);
  bool isSubtype(Archetype a, Archetype b);
  bool isSupertype(Archetype a, Archetype b);
}
