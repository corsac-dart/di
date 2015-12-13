part of corsac_di;

abstract class DefinitionResolver {
  dynamic resolve(Container container);
}

class ReferenceResolver implements DefinitionResolver {
  final dynamic id;

  ReferenceResolver(this.id);

  @override
  resolve(Container container) => container.get(id);
}

class StaticValueResolver implements DefinitionResolver {
  final dynamic value;

  StaticValueResolver(this.value);

  @override
  dynamic resolve(Container container) => value;
}

typedef dynamic EntryFactory(Container container);

class FactoryResolver implements DefinitionResolver {
  final EntryFactory func;

  FactoryResolver(this.func);
  @override
  resolve(Container container) {
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
      throw new StateError(
          'Unsupported. Please use di.get() instead of di.object() when binding constructor parameters.');
    }
    _parameters[new Symbol(parameterName)] = value;
  }

  @override
  dynamic resolve(Container container) {
    if (_isResolving) throw new StateError(
        'Circular dependency detected for ${type}.');

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
      ClassMirror mirror, Container container) {
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
              throw new StateError(
                  'Can not resolve parameter ${param.simpleName}');
            }
          } else {
            throw new StateError(
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
  dynamic resolve(Container container) {
    if (Platform.environment.containsKey(variableName)) {
      return Platform.environment[variableName];
    } else {
      throw new StateError(
          'Specified environment variable ${variableName} is not set.');
    }
  }
}
