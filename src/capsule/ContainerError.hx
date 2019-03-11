package capsule;

import haxe.PosInfos;

class ContainerError {

  final message:String;
  final pos:PosInfos;

  public function new(message:String, ?pos:PosInfos) {
    this.message = message;
    this.pos = pos;
  }

  public function toString() {
    return '${pos.fileName}:${pos.lineNumber} - $message';
  }

}