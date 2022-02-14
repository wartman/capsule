package capsule.exception;

import haxe.Exception;
import haxe.PosInfos;

class MappingNotFoundException extends Exception {
  public function new(id:Identifier #if debug , ?pos:PosInfos #end) {
    #if debug
      super('Mapping not found: ${id} @${pos.className}.${pos.methodName}:${pos.lineNumber}');
    #else
      super('Mapping not found: ${id}');
    #end
  }
}
