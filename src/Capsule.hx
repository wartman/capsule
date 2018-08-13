typedef Container = capsule.Container;
typedef Mapping<T> = capsule.Mapping<T>;
typedef ServiceProvider = capsule.ServiceProvider;

class Capsule {

  public static function get() {
    return new Container();
  }

}
