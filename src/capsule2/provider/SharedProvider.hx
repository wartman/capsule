package capsule2.provider;

class SharedProvider<T> implements Provider<T> {
  final provider:Provider<T>;
  var value:Null<T> = null;
  
  public function new(provider) {
    this.provider = provider;
  }
  
  public function resolve(container:Container):T {
    if (value == null) {
      value = provider.resolve(container);
    }
    return value;
  }
}
