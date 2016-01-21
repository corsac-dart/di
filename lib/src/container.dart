part of corsac_di;

/// Service container.
abstract class Container {
  /// Returns service specified by [id] from this Container.
  dynamic get(dynamic id);

  /// Creates new container.
  ///
  /// If you want to pass configurations for container entries use the `build()`
  /// factory instead.
  factory Container() {
    return new _Container(new Map());
  }

  /// Builds new container based on configuration provided in [configs].
  factory Container.build(List<Map<dynamic, dynamic>> configs) {
    var resolvers = new Map();
    for (var definitions in configs) {
      for (var id in definitions.keys) {
        var def = definitions[id];
        if (def is Iterable) {
          resolvers[id] = new ListResolver(def);
        } else if (def is ListExtensionHelper) {
          Iterable items = def.items;
          if (resolvers.containsKey(id)) {
            (resolvers[id] as ListResolver).list.addAll(items);
          } else {
            resolvers[id] = new ListResolver(items);
          }
        } else if (def is DefinitionResolver) {
          if (def is ObjectResolver) {
            def.type ??= id;
          }
          resolvers[id] = def;
        } else {
          resolvers[id] = new StaticValueResolver(def);
        }
      }
    }
    return new _Container(resolvers);
  }
}

class _Container implements Container {
  final Map<dynamic, dynamic> resolvers;
  final Map<dynamic, dynamic> _singletons = {};

  _Container(this.resolvers);

  @override
  dynamic get(dynamic id) {
    // Check if entry already exists in the singleton map.
    if (_singletons.containsKey(id)) {
      return _singletons[id];
    }

    var resolver = getResolver(id);
    _singletons[id] = resolver.resolve(this);
    return _singletons[id];
  }

  DefinitionResolver getResolver(dynamic id) {
    if (resolvers.containsKey(id)) {
      return resolvers[id];
    } else if (id is Type) {
      return new ObjectResolver()..type = id;
    } else {
      throw new DIError("Can't find resolver for ${id}");
    }
  }
}
