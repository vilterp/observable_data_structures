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
      initialItems.forEach(controller.add);
      return controller._list;
    } else {
      return new ObservableList(updates);
    }
  }

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

}

/*
class ObservableList<T> implements ObservableCollection, Collection {

  StreamController<ListAdditionEvent<T>> _additions;
  StreamController<ListRemovalEvent<T>> _removals;
  StreamController<ListMutationEvent<T>> _mutations;
  SignalController<int> _size;

  List<T> items;

  ObservableList() {
    this.items = [];
    this._size = new SignalController(0);
    this._additions = new StreamController.broadcast();
    this._mutations = new StreamController.broadcast();
    this._removals = new StreamController.broadcast();
  }

  static ObservableList<T> log(Stream<T> stream) {
    // TODO: really, want to do this with a constructor. should really separate controller & list.
    var list = new ObservableList<T>();
    stream.listen((evt) => list.add(evt), unsubscribeOnError: true);
    return list;
  }

  Stream<ListAdditionEvent<T>> get additions => _additions.stream;
  Stream<ListRemovalEvent<T>> get removals => _removals.stream;
  Stream<ListMutationEvent<T>> get mutations => _mutations.stream;
  Signal<int> get size => _size.signal;

  // TODO: these should be in ObservableCollection. was having strange inheritance issue
  void _incrSize() {
    _size.update(size.value + 1);
  }

  void _decrSize() {
    _size.update(size.value - 1);
  }

  @override
  T operator [](int ind) {
    return items[ind];
  }

  @override
  void operator []=(int ind, T value) {
    items[ind] = value;
    _mutations.add(new ListMutationEvent(ind, value));
  }

  @override
  void add(T item) {
    _additions.add(new ListAdditionEvent(items.length, item));
    items.add(item);
    _incrSize();
  }

  @override
  void addAll(Iterable<T> items) {
    items.forEach(add); // ooh sweet
  }

  @override
  ObservableList<T> get reversed {
    // TODO
    throw new UnimplementedError("TODO");
  }

  @override
  void sort([int compare(T a, T b)]) {
    throw new UnimplementedError("use [sorted] instead");
  }

  ObservableList<T> get sorted {
    // TODO
    throw new UnimplementedError("TODO");
  }

  @override
  void clear() {
    while(items.length > 0) {
      removeAt(0);
    }
  }

  @override
  void insert(int index, T element) {
    items.insert(index, element);
    _additions.add(new ListAdditionEvent(index, element));
    _decrSize();
  }

  @override
  T removeAt(int index) {
    T item = items.removeAt(index);
    _removals.add(new ListRemovalEvent(index));
    _decrSize();
    return item;
  }

  @override
  T removeLast() {
    T item = items.removeLast(); // TODO: wat happens when length is 0? hopefully this throws exception
    var ind = items.length - 1;
    _removals.add(new ListRemovalEvent(ind));
    _decrSize();
    return item;
  }

  @override
  void setRange(int start, int length, List<T> from, [int startFrom]) {
    if(length < 0) {
      throw new ArgumentError("length < 0");
    }
    var startFromInd = ?startFrom ? startFrom : 0;
    var setInd = start;
    for(int fromInd=startFromInd;
        fromInd < from.length - startFrom;
        fromInd++, setInd++) {
      this[setInd] = from[fromInd];
    }
  }

  @override
  void removeRange(int start, int length) {
    if(length < 0) {
      throw new ArgumentError("length < 0");
    }
    for(int i=start; i < start + length; i++) {
      remove(i);
    }
  }

  @override
  void insertRange(int start, int length, [T fill]) {
    if(length < 0) {
      throw new ArgumentError("length < 0");
    }
    if(start < 0) {
      throw new ArgumentError("start < 0");
    }
    for(int i=0; i < length; i++) {
      insert(start, fill);
    }
  }

  @override
  void remove(T obj) {
    removeAt(indexOf(obj));
  }

  @override
  void removeAll(Iterable<T> objects) {
    objects.forEach(remove);
  }

  @override
  void retainAll(Iterable<T> objects) {
    removeWhere((elem) => !objects.contains(elem));
  }

  @override
  void removeWhere(bool pred(T item)) {
    List<int> deleteIndicies = [];
    for(int i=0; i < this.length; i++) {
      if(pred(this[i])) {
        deleteIndicies.add(i);
      }
    }
    deleteIndicies.reversed.forEach((i) => removeAt(i));
  }

  @override
  void retainWhere(bool pred(T item)) {
    removeWhere((T item) => !pred(item));
  }

  @override
  int get length => items.length;

  @override
  void set length(int newLength) {
    if(newLength > length) {
      items.length = newLength;
      for(int i=length; i < newLength; i++) {
        _additions.add(new ListAdditionEvent(i, null));
      }
    }
  }

  @override
  void addLast(T item) {
    throw new UnimplementedError("deprecated");
  }

  @override
  ObservableList<T> filtered(bool pred(T elem)) {
    // TODO
    throw new UnimplementedError("TODO");
  }

  @override
  ObservableList<T> mapped(dynamic mapper(T item)) {
    // TODO: ImmutableObservableList or something. create from mapped streams.
    var list = new ObservableList<T>();
    additions.listen((evt) => list.insert(evt.index, mapper(evt.item)));
    removals.listen((evt) => list.removeAt(evt.index));
    mutations.listen((evt) => list[evt.index] = mapper(evt.newValue));
    return list;
  }

  void bindToList(List<T> list) {
    assert(list.isEmpty);
    additions.listen((evt) => list.insert(evt.index, evt.item));
    removals.listen((evt) => list.removeAt(evt.index));
    mutations.listen((evt) => list[evt.index] = evt.newValue);
  }

}
*/

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

  ListMutationEvent(int index, T newValue) : super(index, item);
  
  ListMutationEvent<T> withIndex(int idx) => new ListMutationEvent(idx, item);
  ListMutationEvent<T> withItem(T newItem) => new ListMutationEvent(index, newItem);  

}
