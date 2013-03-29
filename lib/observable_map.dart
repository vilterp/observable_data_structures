part of observable_datastructures;

class ObservableMap<K,V> implements Map, ObservableCollection {

  StreamController<MapPutEvent<K,V>> _puts;
  StreamController<MapRemovalEvent<K,V>> _removals;

  Map<K,V> items;

  Signal<int> size;

  ObservableMap() {
    items = <K,V>{};
    _puts = new StreamController.broadcast();
    _removals = new StreamController.broadcast();
    size = new Signal(0);
  }

  void _incrSize() {
    size.update(size.value + 1);
  }

  void _decrSize() {
    size.update(size.value - 1);
  }

  Iterable<K> get keys => items.keys;
  Iterable<V> get values => items.values;

  int get length => items.length;
  bool get isEmpty => items.isEmpty;
  bool containsValue(V val) => items.containsValue(val);
  bool containsKey(K key) => items.containsKey(key);
  V operator [](K key) => items[key];

  void operator []=(K key, V value) {
    if(!containsKey(key)) {
      _incrSize();
    }
    items[key] = value;
    _puts.add(new MapPutEvent(key, value));
  }

  @override
  V putIfAbsent(K key, V ifAbsent()) {
    if(containsKey(key)) {
      return this[key];
    } else {
      V newVal = ifAbsent();
      items[key] = newVal;
      _puts.add(new MapPutEvent(key, newVal));
      _incrSize();
      return newVal;
    }
  }

  @override
  V remove(K key) {
    if(containsKey(key)) {
      _removals.add(new MapRemovalEvent(key));
      _decrSize();
    }
    return items.remove(key);
  }

  @override
  void clear() {
    keys.forEach(remove);
  }

  @override
  void forEach(void action(K key, V value)) {
    for(K the_key in keys) {
      action(the_key, this[the_key]);
    }
  }

  @override
  ObservableMap<dynamic,dynamic> mapped(Tuple<dynamic,dynamic> mapper(Tuple<K,V> entry)) {
    // TODO: does this make sense?
    throw new UnimplementedError("TODO");
  }

  @override
  ObservableMap<dynamic,dynamic> filtered(bool pred(Tuple<K,V> entry)) {
    // TODO: does this make sense?
    throw new UnimplementedError("TODO");
  }

  // TODO: observable sets of entries, keys, values

}

abstract class MapEvent<K,V> extends CollectionEvent {}

class MapPutEvent<K,V> extends MapEvent {

  K key;
  V value;

  MapPutEvent(this.key, this.value);

}

class MapRemovalEvent<K,V> extends MapEvent {

  K key;

  MapRemovalEvent(this.key);

}
