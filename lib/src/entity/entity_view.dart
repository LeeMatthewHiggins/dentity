import 'package:dentity/dentity.dart';

class EntityView implements Iterable<Entity> {
  final EntityManager _entityManager;
  final Archetype archetype;
  final Map<Type, SparseList<Component>> _componentArrays;
  Map<Type, SparseList<Component>> get componentLists => _componentArrays;

  EntityView(this._entityManager, this.archetype)
      : _componentArrays =
            _entityManager.componentManager.componentsForArchetype(
          archetype,
        );

  factory EntityView.fromTypes(
    EntityManager entityManager,
    Set<Type> componentTypes,
  ) {
    final archetype = entityManager.componentManager.archetypeManager
        .getArchetype(componentTypes);
    return EntityView(entityManager, archetype);
  }

  Iterable<Entity> get _entities =>
      _entityManager.getEntitiesMatching(archetype);

  SparseList<Component>? getComponentArray(Type type) => _componentArrays[type];

  Component? getComponentForType(Type type, Entity entity) =>
      _componentArrays[type]?[entity];

  T? getComponent<T>(Entity entity) => _componentArrays[T]?[entity] as T?;

  @override
  Iterator<Entity> get iterator => _entities.iterator;

  @override
  int get length => _entities.length;

  @override
  bool any(bool Function(Entity entity) test) => _entities.any(test);

  @override
  bool contains(Object? element) => _entities.contains(element);

  @override
  Entity elementAt(int index) => _entities.elementAt(index);

  @override
  bool every(bool Function(Entity entity) test) => _entities.every(test);

  @override
  Iterable<R> expand<R>(Iterable<R> Function(Entity entity) toElements) =>
      _entities.expand(toElements);

  @override
  Entity get first => _entities.first;

  @override
  Entity firstWhere(bool Function(Entity entity) test,
          {Entity Function()? orElse}) =>
      _entities.firstWhere(test, orElse: orElse);

  @override
  T fold<T>(
          T initialValue,
          T Function(
            T previousValue,
            Entity entity,
          ) combine) =>
      _entities.fold(initialValue, combine);

  @override
  Iterable<Entity> followedBy(Iterable<Entity> other) =>
      _entities.followedBy(other);

  @override
  void forEach(void Function(Entity entity) f) => _entities.forEach(f);

  @override
  Iterable<Entity> cast<Entity>() => _entities.cast<Entity>();

  @override
  Entity get last => _entities.last;

  @override
  Entity lastWhere(bool Function(Entity entity) test,
          {Entity Function()? orElse}) =>
      _entities.lastWhere(test, orElse: orElse);

  @override
  Iterable<R> map<R>(R Function(Entity entity) f) => _entities.map(f);

  @override
  Entity reduce(Entity Function(Entity value, Entity element) combine) =>
      _entities.reduce(combine);

  @override
  Iterable<Entity> skip(int count) => _entities.skip(count);

  @override
  Iterable<Entity> skipWhile(bool Function(Entity value) test) =>
      _entities.skipWhile(test);

  @override
  Iterable<Entity> take(int count) => _entities.take(count);

  @override
  Iterable<Entity> takeWhile(bool Function(Entity value) test) =>
      _entities.takeWhile(test);

  @override
  List<Entity> toList({bool growable = true}) =>
      _entities.toList(growable: growable);

  @override
  Set<Entity> toSet() => _entities.toSet();

  @override
  Iterable<Entity> where(bool Function(Entity entity) test) =>
      _entities.where(test);

  @override
  Iterable<T> whereType<T>() => _entities.whereType<T>();

  @override
  String join([String separator = '']) => _entities.join(separator);

  @override
  bool get isEmpty => _entities.isEmpty;

  @override
  bool get isNotEmpty => _entities.isNotEmpty;

  @override
  Entity get single => _entities.single;

  @override
  Entity singleWhere(bool Function(Entity element) test,
          {Entity Function()? orElse}) =>
      _entities.singleWhere(test, orElse: orElse);
}

extension EntityViewOnEntityManager on EntityManager {
  EntityView view(Archetype archetype) => EntityView(this, archetype);
  EntityView viewForTypes(Set<Type> types) => EntityView.fromTypes(this, types);
}
