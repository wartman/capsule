package capsule.refactor;

class ProviderAlreadyExistsError {
  
  final message:String;

  public function new(id:Identifier) {
    message = 'A provider already exists for this mapping: ${id.toString()}';
  }

  public function toString() {
    return message;
  }

}
