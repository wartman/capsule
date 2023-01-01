package capsule;

enum ShareScope {
  Container;
  Parent;
}

typedef ProviderSharingOptions = {
  public final scope:ShareScope;
};

final defaultSharingOptions:ProviderSharingOptions = {
  scope: Container
};
