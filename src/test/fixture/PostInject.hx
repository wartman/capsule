package test.fixture;

class PostInject {

  @:inject('foo') public var foo:String;
  public var ran:String = '';

  public function new() {}

  @:postInject(3) public function four() {
    ran += ':four';
  }

  @:postInject public function one() {
    ran += foo + ':one';
  }

  @:postInject(1) public function two() {
    ran += ':two';
  }

  // Should be added after the previous `@:postInject(1)`
  // because it is declared later. Might be a bit brittle.
  @:postInject(1) public function three() {
    ran += ':three';
  }

}
