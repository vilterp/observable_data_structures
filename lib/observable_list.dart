part of observable_datastructures;

// TODO: streams#multiplex

// TODO: major refactor(?)
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
    items.add(item);
    _additions.add(new ListAdditionEvent(items.length, item));
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
    // TODO: ImmutableObservableList or something
//    return new ObservableList.fromStreams(additions.map((evt) => new ListAdditionEvent(evt.index, mapper(evt.item))),
//                                          mutations.map((evt) => new ListMutationEvent(evt.index, mapped((evt.newValue)))),
//                                          deletions);
  }

  void bindToList(List<T> list) {
    assert(list.isEmpty);
    additions.listen((evt) => list.insert(evt.index, evt.item));
    removals.listen((evt) => list.removeAt(evt.index));
    mutations.listen((evt) => list[evt.index] = evt.newValue);
  }

}

// TODO: ObservableSet

// list events
abstract class ListEvent<T> extends CollectionEvent {}

class ListAdditionEvent<T> extends ListEvent {

  int index;
  T item;

  ListAdditionEvent(this.index, this.item);

}

class ListRemovalEvent<T> extends ListEvent {

  int index;

  ListRemovalEvent(this.index);

}

class ListMutationEvent<T> extends ListEvent {

  int index;
  T newValue;

  ListMutationEvent(this.index, this.newValue);

}
