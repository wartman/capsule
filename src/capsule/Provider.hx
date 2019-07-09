package capsule;

enum Provider<T> {
  ProvideNone;
  ProvideValue(value:T);
  ProvideFactory(factory:Factory<T>);
  ProvideShared(factory:Factory<T>);
  ProvideAlias(id:Identifier);
}
