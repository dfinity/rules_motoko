import List "mo:core/List";

persistent actor Publisher {

  type Counter = {
    topic : Text;
    value : Nat;
  };

  type Subscriber = {
    topic : Text;
    callback : shared Counter -> ();
  };

  transient let subscribers = List.empty<Subscriber>();

  public func subscribe(subscriber : Subscriber) : () {
    List.add(subscribers, subscriber);
  };

  public func publish(counter : Counter) : () {
    for (subscriber in List.values(subscribers)) {
      if (subscriber.topic == counter.topic) {
        subscriber.callback(counter);
      };
    };
  };
};
