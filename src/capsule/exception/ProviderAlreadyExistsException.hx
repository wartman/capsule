package capsule.exception;

import haxe.Exception;

class ProviderAlreadyExistsException extends Exception {
  public function new(?previous) {
    super(
      'A provider already exists.',
      previous
    );
  }
}
