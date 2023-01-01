package capsule.provider;

import capsule.exception.ProviderDoesNotExistException;

class NullProvider<T> implements Provider<T> {
  final id:Identifier;
  final extensions:Array<(value:T)->T> = [];

  public function new(id) {
    this.id = id;
  }
  
  public function resolvable() {
    return false;
  }
  
  public function resolve(container:Container):T {
    throw new ProviderDoesNotExistException(id);
  }
  
  public function extend(transform:(value:T)->T) {
    extensions.push(transform);
  }

  public function asShared(options:ProviderSharingOptions):Provider<T> {
    throw new ProviderDoesNotExistException(id, 'Cannot share a null provider');
  }

  public function transitionTo(other:Provider<T>):Provider<T> {
    for (transform in extensions) other.extend(transform);
    return other;
  }

  public function asOverridable():Provider<T> {
    return new OverridableProvider(this);
  }
}
