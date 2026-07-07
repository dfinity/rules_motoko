// Exercises the `motoko_test` rule using mo:core. It mirrors the bookkeeping the
// Publisher actor performs: keeping subscribers in a mo:core/List and counting
// the ones whose topic matches when publishing.

import List "mo:core/List";

type Subscriber = { topic : Text };

let subscribers = List.empty<Subscriber>();
assert List.isEmpty(subscribers);

List.add(subscribers, { topic = "counter" });
List.add(subscribers, { topic = "clock" });
List.add(subscribers, { topic = "counter" });
assert List.size(subscribers) == 3;

func matching(topic : Text) : Nat {
  var count = 0;
  for (subscriber in List.values(subscribers)) {
    if (subscriber.topic == topic) {
      count += 1;
    };
  };
  count;
};

assert matching("counter") == 2;
assert matching("clock") == 1;
assert matching("missing") == 0;
