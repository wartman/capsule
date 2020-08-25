package fixture;

import fixture.params.BaseParams;
import fixture.params.UsesBaseParams;

class CorrectlyFollowsComplexParams<T> implements UsesBaseParams<T, String> {
  public var baseParams:BaseParams<T, String>;

  public function new(baseParams:BaseParams<T, String>) {
    this.baseParams = baseParams;
  }
}
