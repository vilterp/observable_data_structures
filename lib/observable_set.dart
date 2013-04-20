part of observable_datastructures;

class ObservableSetController<T> {

  StreamController<SetEvent<T>> _updates;
  ObservableSet<T> _set;

  ObservableSet<T> get set => _set;

  ObservableSetController() {
    _updates = new StreamController();
    _set = new ObservableSet(_updates.stream.asBroadcastStream());
  }

  factory ObservableSetController.pipe(Stream<SetEvent> updates) {
    var controller = new ObservableSetController();
    updates.listen((evt) => controller._update(evt));
    return controller;
  }

  void _update(SetEvent<T> event) {
    _updates.add(event);
  }

  void add(T item) {
    if(set.currentItems.contains(item)) {
      _updates.add(new SetAdditionEvent(item));
    }
  }

  void remove(T item) {
    if(set.currentItems.contains(item)) {
      _updates.add(new SetRemovalEvent(item));
    }
  }

}

class ObservableSet<T> extends ObservableSingleElementCollection<T> {

  Set<T> _items;
  Stream<SetEvent<T>> updates;
  Signal<int> _size;

  Set<T> get currentItems => _items;
  Signal<int> get size => _size;

  // TODO: entirely too many allocations here.
  static ObservableSet<T> EMPTY = new ObservableSet(new StreamController().stream.asBroadcastStream());

  ObservableSet(this.updates) {
    _items = new Set<T>();
    bindToSet(_items);
    _size = new Signal.fold(0, updates, (curSize, evt) => curSize + (evt is SetAdditionEvent ? 1 : -1));
  }

  factory ObservableSet.fromStream(Stream<SetEvent<T>> updates, [Iterable<T> initialItems]) {
    var controller = new ObservableSetController.pipe(updates);
    initialItems.forEach((item) => controller.add(item));
    return controller.set;
  }

  @override
  ObservableSet<dynamic> mapped(dynamic mapper(T item)) {
    // TODO
  }

  @override
  ObservableSet<T> filtered(bool pred(T item)) {
    // TODO
  }

  // TODO contains

  // TODO union

  // TODO intersection

  void bindToSet(Set<T> set) {
    assert(set.isEmpty);
    set.addAll(currentItems);
    updates.listen((evt) {
      if(evt is SetAdditionEvent) {
        _items.add(evt.item);
      } else {
        _items.remove(evt.item);
      }
    });
  }

}

abstract class SetEvent<T> {
  T item;
  SetEvent(this.item);
}

class SetAdditionEvent<T> extends SetEvent {
  SetAdditionEvent(T item) : super(item);
}

class SetRemovalEvent<T> extends SetEvent {
  SetRemovalEvent(T item) : super(item);
}
