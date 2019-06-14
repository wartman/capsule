package capsule.refactor;

class ProviderDoesNotExistError {
  
  final message:String;

  public function new(id:Identifier, ?reason:String) {
    message = 'No provider exists for this mapping: ${id.toString()}';
    if (reason != null) {
      message += ' ' + reason;
    }
  }

  public function toString() {
    return message;
  }

}
