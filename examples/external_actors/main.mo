import Ledger "canister:icp_ledger";

persistent actor {
  public func query_symbol() : async Text {
    let result = await Ledger.symbol();
    result.symbol;
  };
};
