typedef Container = capsule.Container;
typedef Mapping<T> = capsule.Mapping<T>;
typedef ServiceProvider = capsule.ServiceProvider;

class Capsule {

  private static var instance:Container;

  public static function getGlobalContainer() {
    if (instance == null) instance = new Container();
    return instance;
  }

}
