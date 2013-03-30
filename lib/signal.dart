part of observable_datastructures;

class SignalController<T> {

  StreamController<T> _updates;
  Signal<T> signal;

  SignalController(T initialValue) {
    _updates = new StreamController.broadcast();
    signal = new Signal(initialValue, _updates.stream);
  }

  void update(T newValue) {
    _updates.add(newValue);
  }

}

class Signal<T> {

  T value;
  Stream<T> updates;

  Signal(this.value, this.updates);

  Signal.derived(Iterable<Signal<T>> signals, Function computation) {
    var controller = new StreamController.broadcast();
    var recompute = () => Function.apply(computation, signals.map((s) => s.value));
    signals.forEach((signal) {
      signal.updates.listen((_) {
        controller.update(recompute());
      });
    });
    var initialVal = recompute();
    // initialize
    this.value = recompute();
    this.updates = controller.stream;
  }

  Signal<dynamic> map(dynamic mapper(T val)) => new Signal(mapper(value), updates.map(mapper));

  void bindToProperty(Object object, String property) {
    var mirror = reflect(object);
    updates.listen((newVal) => mirror.setField(property, newVal));
  }

}
