package capsule.provider;

import capsule.exception.ProviderDoesNotExistException;

class NullProvider<T> implements Provider<T> {
  final id:Identifier;
  
  public function new(id) {
    this.id = id;
  }
  
  public function resolve(container:Container):T {
    throw new ProviderDoesNotExistException(id);
  }
  
  public function extend(transform:(value:T)->T) {
    throw new ProviderDoesNotExistException(id, 'Cannot extend a null provider');
  }

  public function asShared():Provider<T> {
    throw new ProviderDoesNotExistException(id, 'Cannot share a null provider');
  }
}
