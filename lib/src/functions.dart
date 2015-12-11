part of dart_di;

ObjectResolver object([Type type]) {
  return new ObjectResolver()..type = type;
}

FactoryResolver factory(EntryFactory func) => new FactoryResolver(func);

EnvironmentVariableResolver env(String variableName) {
  return new EnvironmentVariableResolver(variableName);
}

ReferenceResolver get(dynamic id) => new ReferenceResolver(id);
