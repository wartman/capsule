package capsule;

import haxe.PosInfos;

class MappingNotFoundError {
  
  final message:String;
  #if debug
    final pos:PosInfos;
  #end

  public function new(id:Identifier #if debug , ?pos:PosInfos #end) {
    message = 'Mapping not found: ${id.toString()}';
    #if debug
      this.pos = pos;
    #end
  }

  public function toString() {
    #if debug
      return '$message @${pos.className}.${pos.methodName}:${pos.lineNumber}';
    #else
      return message;
    #end
  }

}
