part of corsac_di;

/// Middleware for [DIContainer].
///
/// Middlewares are free to define how they want to handle resolution of
/// particular entry.
///
/// Possible use cases for middlewares are: decorating particular container
/// entry or defining a "proxy".
abstract class DIMiddleware {
  dynamic resolve(id, DIMiddlewarePipeline next);
}

class DIMiddlewarePipeline {
  final Queue<DIMiddleware> _queue;
  final _DIContainer _container;

  DIMiddlewarePipeline._(this._queue, this._container);

  dynamic resolve(id) {
    if (_queue.isEmpty) {
      return _container.getResolver(id).resolve(_container);
    } else {
      var i = _queue.removeFirst();
      return i.resolve(id, this);
    }
  }
}
