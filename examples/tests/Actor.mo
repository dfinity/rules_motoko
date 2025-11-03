import SHA256 "mo:sha/SHA256"

persistent actor {
  public shared func sha256(bytes : [Nat8]) : async [Nat8] {
    SHA256.sha256(bytes);
  };
};
