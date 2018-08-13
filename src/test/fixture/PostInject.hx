package test.fixture;

class PostInject {

  @:inject('foo') public var foo:String;
  public var ran:String = '';

  public function new() {}

  @:inject.post(3) public function four() {
    ran += ':four';
  }

  @:inject.post public function one() {
    ran += foo + ':one';
  }

  @:inject.post(1) public function two() {
    ran += ':two';
  }

  // Should be added after the previous `@:inject.post(1)`
  // because it is declared later. Might be a bit brittle.
  @:inject.post(1) public function three() {
    ran += ':three';
  }

}
