part of dart_di;

abstract class Container {
  /// Returns service specified by [id] from this Container.
  dynamic get(dynamic id);

  /// Checks whether service exists in this Container.
  bool has(dynamic id);

  factory Container() => new _Container({});

  factory Container.build(Map<dynamic, dynamic> definitions) {
    var resolvers = {};
    for (var id in definitions.keys) {
      if (definitions[id] is DefinitionResolver) {
        if (definitions[id] is ObjectResolver) {
          ObjectResolver resolver = definitions[id];
          if (resolver.type == null) resolver.type = id;
        }
        resolvers[id] = definitions[id];
      } else {
        resolvers[id] = new StaticValueResolver(definitions[id]);
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
      throw new StateError("Can't find resolver for ${id}");
    }
  }

  @override
  bool has(id) {
    return false;
  }
}
