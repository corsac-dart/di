part of corsac_di;

/// Dependency Injection container.
abstract class DIContainer {
  /// Returns an entry specified by [id] from this DIContainer.
  get(id);

  /// Sets an entry with [id] to a specified [value].
  ///
  /// The value can be any object as well as definition resolver such
  /// as returned by `DI.get()`, `DI.env()`, `DI.string()` and other helpers:
  ///
  ///     container.set('host', 'localhost');
  ///     container.set(MyService, new MyService());
  ///     container.set(ServiceInterface, DI.get(ServiceImplementation));
  ///
  /// Note that if container definition with the same [id] already exist and
  /// has been resolved (returned with call to `DIContainer.get(id)`) this
  /// method will throw a `DIError` exception. This is to prevent having
  /// more than one instance of the same entry returned from the container which
  /// can lead to unexpected behavour.
  ///
  /// This means that overriding container entries is only allowed before
  /// they accessed with `DIContainer.get()`.
  void set(id, value);

  /// Registers middleware with this container.
  ///
  /// Middlewares provide a way to extend resolution of container entries.
  void addMiddleware(DIMiddleware middleware);

  /// Creates new container.
  ///
  /// If you want to pass configurations for container entries use the
  /// `DIContainer.build` factory instead.
  factory DIContainer() {
    return new _DIContainer(new Map());
  }

  /// Builds new container based on configurations provided in [configs].
  ///
  /// Please note that order of configurations in the [configs] list matters.
  /// If configurations have entries with the same keys then later config
  /// overwrites any previously set definitions. With one exception for
  /// "dynamic lists" which are treated separately.
  factory DIContainer.build(List<Map<dynamic, dynamic>> configs) {
    var container = new DIContainer();
    // var resolvers = new Map();
    for (var definitions in configs) {
      for (var id in definitions.keys) {
        var def = definitions[id];
        container.set(id, def);
      }
    }
    return container;
  }
}

class _DIContainer implements DIContainer {
  final Map resolvers;
  final Map _singletons = {};
  final List<DIMiddleware> _middlewares = [];

  _DIContainer(this.resolvers);

  @override
  get(id) {
    var entryId = (id is diType) ? id.type : id;

    // Check if entry already exists in the singleton map.
    if (_singletons.containsKey(entryId)) {
      return _singletons[entryId];
    }

    var queue = new Queue.from(_middlewares);
    var pipeline = new DIMiddlewarePipeline._(queue, this);

    _singletons[entryId] = pipeline.resolve(entryId);
    return _singletons[entryId];
  }

  @override
  void set(id, value) {
    var entryId = (id is diType) ? id.type : id;

    if (_singletons.containsKey(entryId)) {
      throw new DIError(
          'Can not override container entry as it has been resolved already.');
    }

    if (value is Iterable) {
      resolvers[entryId] = new ListResolver(value);
    } else if (value is ListExtensionHelper) {
      Iterable items = value.items;
      if (resolvers.containsKey(entryId)) {
        (resolvers[entryId] as ListResolver).list.addAll(items);
      } else {
        resolvers[entryId] = new ListResolver(items);
      }
    } else if (value is DefinitionResolver) {
      if (value is ObjectResolver) {
        value.type ??= entryId;
      }
      resolvers[entryId] = value;
    } else {
      resolvers[entryId] = new StaticValueResolver(value);
    }
  }

  DefinitionResolver getResolver(id) {
    if (resolvers.containsKey(id)) {
      return resolvers[id];
    } else if (id is Type) {
      resolvers[id] = new ObjectResolver()..type = id;
      return resolvers[id];
    } else {
      throw new DIError("Can't find resolver for ${id}");
    }
  }

  @override
  void addMiddleware(DIMiddleware middleware) {
    _middlewares.add(middleware);
  }
}
