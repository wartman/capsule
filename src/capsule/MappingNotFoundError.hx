package capsule;

class MappingNotFoundError {
  
  final message:String;

  public function new(id:Identifier) {
    message = 'Mapping not found: ${id.toString()}';
  }

  public function toString() {
    return message;
  }

}
