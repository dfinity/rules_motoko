import Ledger "canister:icp_ledger";

actor {
  public func query_symbol() : async Text {
    let result = await Ledger.symbol();
    result.symbol
  };
};
