part of observable_datastructures;

class SignalController<T> {

  StreamController<T> _updates;
  Signal<T> signal;

  SignalController(T initialValue) {
    _updates = new StreamController();
    signal = new Signal(initialValue, _updates.stream);
  }

  void update(T newValue) {
    _updates.add(newValue);
    signal.value = newValue;
  }

}

class IntSignalController extends SignalController<int> {

  IntSignalController(int val) : super(val);

  void changeBy(int delta) {
    update(signal.value + delta);
  }

}

class Signal<T> {

  T value;
  Stream<T> updates;

  Signal(this.value, this.updates);

  factory Signal.fold(T initialValue, Stream<dynamic> stream, T combiner(T val, dynamic evt)) {
    var controller = new SignalController(initialValue);
    stream.listen((evt) {
      var oldValue = controller.signal.value;
      controller.update(combiner(oldValue, evt));
    });
    return controller.signal;
  }

  Signal.constant(T initialValue) {
    this.value = initialValue;
    this.updates = new StreamController().stream;
  }

  Signal.derived(Iterable<Signal<T>> signals, Function computation) {
    var controller = new StreamController();
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
