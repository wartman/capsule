package capsule.refactor;

enum ProviderImpl<T> {
  None;
  ProvideValue(value:T);
  ProvideFactory(factory:Factory<T>);
  ProvideShared(factory:Factory<T>);
  ProvideAlias(id:Identifier);
}

abstract Provider<T>(ProviderImpl<T>) from ProviderImpl<T> to ProviderImpl<T> {
  
  @:from public static inline function value<T>(value:T):Provider<T> {
    return ProvideValue(value);
  }

  public static inline function empty<T>():Provider<T> {
    return None;
  }

  @:from public static inline function factory<T>(factory:Factory<T>):Provider<T> {
    return ProvideFactory(factory);
  }

  public static inline function shared<T>(factory:Factory<T>):Provider<T> {
    return ProvideShared(factory);
  }

  public inline function new(factory:Factory<T>) {
    this = ProvideFactory(factory);
  }

  public inline function unbox():ProviderImpl<T> {
    return this;
  }

}
