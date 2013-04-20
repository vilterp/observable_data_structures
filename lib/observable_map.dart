part of observable_datastructures;

class ObservableMapController<K,V> {

  ObservableMap<K,V> _map;
  StreamController<MapEvent<K,V>> _updates;

  ObservableMap<K,V> get map => _map;

  ObservableMapController() {
    _updates = new StreamController();
    _map = new ObservableMap(_updates.stream.asBroadcastStream());
  }

  factory ObservableMapController.pipe(Stream<MapEvent<K,V>> updates) {
    var controller = new ObservableMapController();
    updates.listen((evt) => controller._update(evt));
    return controller;
  }

  void _update(MapEvent<K,V> evt) {
    _updates.add(evt);
  }

  void operator []=(K key, V value) {
    _updates.add(new MapPutEvent(key, value));
  }

  Option<V> remove(K key) {
    if(map.currentItems.containsKey(key)) {
      V val = map.currentItems[key];
      _updates.add(new MapRemovalEvent(key));
      return new Some(val);
    }
    return const None();
  }

}

class ObservableMap<K,V> implements ObservableCollection {

  Signal<int> _size;
  Map<K,V> _items;
  Stream<MapEvent<K,V>> updates; // TODO: should I make everything private and make getters for everything? grr

  static ObservableMap<dynamic,dynamic> EMPTY = new ObservableMap.fromStream(new StreamController().stream.asBroadcastStream());

  ObservableMap(this.updates) {
    _items = new Map<K,V>();
    bindToMap(_items);
    Stream<int> sizeUpdates = updates.map((update) {
      if(update is MapRemovalEvent) {
        return -1;
      } else if(update is MapPutEvent) {
        return _items.containsKey((update as MapPutEvent<K,V>).key) ? 0 : 1;
      }
    });
    _size = new Signal(0, sizeUpdates);
  }

  factory ObservableMap.fromStream(Stream<MapEvent<K,V>> updates, [Map<K,V> initialItems]) {
    var controller = new ObservableMapController.pipe(updates);
    initialItems.forEach((k,v) => controller[k] = v);
    return controller.map;
  }

  factory ObservableMap.constant(Map<K,V> items) {
    return new ObservableMap.fromStream(new StreamController().stream.asBroadcastStream(), items);
  }

  @override
  Signal<int> get size => _size;

  Map<K,V> get currentItems => _items; // TODO: why isn't there an UnmodifiableMapView class?

  ObservableSet<Tuple<K,V>> _entries;
  ObservableSet<Tuple<K,V>> get entries {
    if(_entries == null) {
      // TODO: initialize...
    }
    return _entries;
  }

  void bindToMap(Map<K,V> map) {
    map.forEach((k, v) => _items[k] = v);
    updates.listen((evt) {
      if(evt is MapPutEvent) {
        var put = evt as MapPutEvent;
        map[put.key] = put.value;
      } else {
        map.remove((evt as MapRemovalEvent).key);
      }
    });
  }

  // TODO: contains[...] => Signal<bool>

  // TODO: operator [] => Signal<Option<T>>

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
