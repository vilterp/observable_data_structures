part of observable_datastructures;

class ObservableListController<T> {

  ObservableList<T> _list;
  StreamController<ListEvent<T>> _updates;

  ObservableListController() {
    _updates = new StreamController<ListEvent<T>>.broadcast();
    _list = new ObservableList(_updates.stream);
  }

  ObservableList<T> get list => _list;

  factory ObservableListController.pipe(Stream<ListEvent<T>> updates) {
    var controller = new ObservableListController<T>();
    updates.listen((evt) => controller._update(evt));
    return controller;
  }

  void _update(ListEvent<T> event) => _updates.add(event);

  void add(T item) {
    _updates.add(new ListAdditionEvent(_list._size.value, item));
  }

  void addAll(Iterable<T> items) {
    items.forEach(add);
  }

  void insertAt(int index, T item) {
    _updates.add(new ListAdditionEvent(index, item));
  }

  void removeAt(int index) {
    _updates.add(new ListRemovalEvent(index));
  }

  void clear() {
    for(int i=0; i < list._size.value; i++) {
      removeAt(0);
    }
  }

  void operator []=(int index, T newValue) {
    _updates.add(new ListMutationEvent(index, newValue));
  }

}

class ObservableList<T> extends ObservableSingleElementCollection {

  List<T> _items;
  Signal<int> _size;
  Stream<ListEvent<T>> updates;

  ObservableList(this.updates) {
    _items = <T>[];
    bindToList(_items);
    Stream<int> sizeUpdates = updates.map((evt) {
      if(evt is ListAdditionEvent) {
        return (evt as ListAdditionEvent).index == _size.value ? 1 : 0;
      } else if(evt is ListRemovalEvent) {
        return -1;
      } else {
        return 0;
      }
    });
    _size = new Signal(0, sizeUpdates);
  }

  factory ObservableList.fromStream(Stream<ListEvent<T>> updates, [Iterable<T> initialItems]) {
    if(?initialItems) {
      var controller = new ObservableListController<T>.pipe(updates);
      controller.addAll(initialItems);
      return controller._list;
    } else {
      return new ObservableList(updates);
    }
  }

  factory ObservableList.constant(Iterable<T> items) {
    return new ObservableList.fromStream(new StreamController.broadcast().stream, items);
  }

  static ObservableList<dynamic> EMPTY = new ObservableList(new StreamController().stream);

  factory ObservableList.logEvents(Stream<T> events) {
    // would be nice to do this just by piping :P
    var controller = new ObservableListController();
    events.listen((evt) => controller.add(evt));
    return controller._list;
  }

  List<T> get currentItems => new UnmodifiableListView(_items);
  Signal<int> get size => _size;

  @override
  ObservableList<T> mapped(dynamic mapper(T item)) {
    var mappedUpdates = updates.map((update) {
      if(update is ListEventWithItem) {
        var upd = update as ListEventWithItem<T>;
        return upd.withItem(mapper(upd.item));
      } else {
        return update;
      }
    });
    return new ObservableList.fromStream(mappedUpdates, currentItems.map(mapper));
  }

  @override
  ObservableList<T> filtered(bool pred(T item)) {
    // TODO: map indicies....
    throw new UnimplementedError("TODO");
  }

  ObservableList<T> sorted([Comparator<T> comparator]) {
    // TODO
    throw new UnimplementedError("TODO");
  }

  ObservableList<T> _reversed = null;
  ObservableList<T> get reversed {
    if(_reversed == null) {
      _reversed = new ObservableList.fromStream(updates.map((evt) {
        return evt.withIndex(_size.value - evt.index - 1);
      }), currentItems.reversed);
    }
    return _reversed;
  }

  ObservableList<T> _unique = null;
  ObservableList<T> get unique {
    if(_unique == null) {
      // TODO: initialize...
    }
    return _unique;
  }

  void bindToList(List<T> list) {
    _items.forEach((item) => list.add(item));
    updates.listen((evt) {
      if(evt is ListAdditionEvent) {
        list.insert(evt.index, (evt as ListAdditionEvent<T>).item);
      } else if(evt is ListRemovalEvent) {
        list.removeAt(evt.index);
      } else {
        list[evt.index] = (evt as ListMutationEvent<T>).item;
      }
    });
  }

  // TODO: sublist => Signal<Option<ObservableList<T>>>

}

// TODO: ObservableSet

// list events
// would be nice if the compiler wrote all these "with" methods for me
abstract class ListEvent<T> extends CollectionEvent {
  int index;
  ListEvent(this.index);
  ListEvent<T> withIndex(int idx);
}

class ListRemovalEvent<T> extends ListEvent {

  ListRemovalEvent(int index) : super(index);
  
  ListRemovalEvent<T> withIndex(int idx) => new ListRemovalEvent(idx); 

}

abstract class ListEventWithItem<T> extends ListEvent {
  T item;
  ListEventWithItem(int index, this.item) : super(index);
  ListEventWithItem<T> withItem(T item);
}

class ListAdditionEvent<T> extends ListEventWithItem {

  ListAdditionEvent(int index, T item) : super(index, item);
  
  ListAdditionEvent<T> withIndex(int idx) => new ListAdditionEvent(idx, item);
  ListAdditionEvent<T> withItem(T newItem) => new ListAdditionEvent(index, newItem);

}

class ListMutationEvent<T> extends ListEventWithItem {

  ListMutationEvent(int index, T newValue) : super(index, newValue);
  
  ListMutationEvent<T> withIndex(int idx) => new ListMutationEvent(idx, item);
  ListMutationEvent<T> withItem(T newItem) => new ListMutationEvent(index, newItem);  

}
