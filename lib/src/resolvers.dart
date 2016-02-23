part of corsac_di;

/// Interface for definition resolvers.
abstract class DefinitionResolver {
  dynamic resolve(DIContainer container);
}

class ReferenceResolver implements DefinitionResolver {
  final dynamic id;

  ReferenceResolver(this.id);

  @override
  resolve(DIContainer container) => container.get(id);
}

class StaticValueResolver implements DefinitionResolver {
  final dynamic value;

  StaticValueResolver(this.value);

  @override
  dynamic resolve(DIContainer container) => value;
}

typedef dynamic EntryFactory(DIContainer container);

class FactoryResolver implements DefinitionResolver {
  final EntryFactory func;

  FactoryResolver(this.func);
  @override
  resolve(DIContainer container) {
    return func(container);
  }
}

/// Resolves container entries for objects and creates a new instance
/// accodring to the definition.
class ObjectResolver implements DefinitionResolver {
  Type type;
  String constructor;
  Map<Symbol, DefinitionResolver> _parameters = {};
  bool _isResolving = false;

  ObjectResolver();

  void bindParameter(String parameterName, dynamic value) {
    value =
        (value is DefinitionResolver) ? value : new StaticValueResolver(value);
    if (value is ObjectResolver) {
      throw new DIError(
          'Unsupported. Please use DI.get() instead of DI.object() when binding constructor parameters.');
    }
    _parameters[new Symbol(parameterName)] = value;
  }

  @override
  dynamic resolve(DIContainer container) {
    if (_isResolving)
      throw new DIError('Circular dependency detected for ${type}.');

    try {
      _isResolving = true;
      ClassMirror mirror = reflectType(type);

      var _constructor = _getConstructorName(mirror);
      var parameters = _resolvePositionalParameters(mirror, container);
      return mirror.newInstance(_constructor, parameters).reflectee;
    } finally {
      _isResolving = false;
    }
  }

  Symbol _getConstructorName(ClassMirror mirror) {
    if (constructor is String && constructor.isNotEmpty) {
      return new Symbol(constructor);
    } else {
      return new Symbol('');
    }
  }

  List<dynamic> _resolvePositionalParameters(
      ClassMirror mirror, DIContainer container) {
    var resolvedValues = [];
    var constructorSymbol = (constructor is String)
        ? new Symbol(mirror.reflectedType.toString() + '.' + constructor)
        : mirror.simpleName;
    if (mirror.declarations.containsKey(constructorSymbol)) {
      MethodMirror method = mirror.declarations[constructorSymbol];
      var requiredPositionalList =
          method.parameters.where((p) => !p.isNamed && !p.isOptional);
      for (var param in requiredPositionalList) {
        if (_parameters.containsKey(param.simpleName)) {
          var resolver = _parameters[param.simpleName];
          resolvedValues.add(resolver.resolve(container));
        } else {
          if (param.type.hasReflectedType) {
            try {
              resolvedValues.add(container.get(param.type.reflectedType));
            } catch (e) {
              if (e is DIError) {
                rethrow;
              } else {
                throw new DIError(
                    'Can not resolve parameter ${param.simpleName}. Error: ${e}.');
              }
            }
          } else {
            throw new DIError(
                'Constructor parameters must either have type annotations or be explicitly bound via bindParameter().');
          }
        }
      }

      var optionalPositionalList =
          method.parameters.where((p) => !p.isNamed && p.isOptional);
      for (var param in optionalPositionalList) {
        if (_parameters.containsKey(param.simpleName)) {
          var resolver = _parameters[param.simpleName];
          resolvedValues.add(resolver.resolve(container));
        } else {
          resolvedValues.add(null);
        }
      }
    }
    return resolvedValues;
  }
}

class EnvironmentVariableResolver implements DefinitionResolver {
  final String variableName;

  EnvironmentVariableResolver(this.variableName);

  @override
  dynamic resolve(DIContainer container) {
    if (dotenv.env.containsKey(variableName)) {
      return dotenv.env[variableName];
    } else {
      throw new DIError(
          'Specified environment variable ${variableName} is not set.');
    }
  }
}

/// Resolver for dynamic lists.
class ListResolver implements DefinitionResolver {
  final List list = new List();

  List _resolvedList;

  ListResolver(Iterable items) {
    list.addAll(items);
  }

  @override
  dynamic resolve(DIContainer container) {
    if (_resolvedList == null) {
      _resolvedList = new List();
      for (var item in list) {
        if (item is DefinitionResolver) {
          _resolvedList.add(item.resolve(container));
        } else {
          _resolvedList.add(item);
        }
      }
    }

    return _resolvedList;
  }
}

/// Helper for extending dynamic lists.
class ListExtensionHelper {
  /// Items to add to the list.
  final Iterable items;

  ListExtensionHelper(this.items);
}

/// Resolver for string expressions.
///
/// Expression parameters must be enclosed in curly braces and can contain
/// only alphanumeric characters (`a-zA-Z0-9`), dot (`.`) and underscore (`_`).
class StringExpressionResolver implements DefinitionResolver {
  static final RegExp paramMatcher = new RegExp(r"{[a-zA-Z0-9\._]+}");

  final String expression;
  final List<String> parameters;

  Map<String, String> _cache = new Map();

  StringExpressionResolver(String expression)
      : expression = expression,
        parameters = _extract(expression);

  static List<String> _extract(String expression) {
    var params = [];
    var param = paramMatcher.stringMatch(expression);
    while (param != null) {
      expression = expression.replaceFirst(param, '');
      param = param.substring(1, param.length - 1);
      params.add(param);
      param = paramMatcher.stringMatch(expression); // get next
    }
    return new List.unmodifiable(params);
  }

  @override
  resolve(DIContainer container) {
    if (!_cache.containsKey(expression)) {
      var result = expression;
      for (var id in parameters) {
        var param = '{${id}}';
        var value = container.get(id);
        result = result.replaceFirst(param, value);
      }
      _cache[expression] = result;
    }

    return _cache[expression];
  }
}
