part of observable_datastructures;

class Signal<T> {

  T value;
  StreamController<T> updatesController = new StreamController<T>.broadcast();

  Signal(this.value);

  void update(T newVal) {
    value = newVal;
    updatesController.add(newVal);
  }

  Stream<T> get stream => updatesController.stream;

}
