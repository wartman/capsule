package capsule2.exception;

import haxe.Exception;

class ProviderAlreadyExistsException extends Exception {
  public function new(id:Identifier, ?previous) {
    super(
      'A provider already exists for this mapping: ${id.toString()}',
      previous
    );
  }
}
