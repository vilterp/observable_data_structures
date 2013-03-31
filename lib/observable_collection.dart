part of observable_datastructures;

abstract class ObservableCollection<T> {

  Signal<int> get size;

}

abstract class ObservableSingleElementCollection<T> extends ObservableCollection {

  ObservableCollection<T> filtered(bool pred(T item));
  ObservableCollection<T> mapped(dynamic fun(T item));
  Collection<T> get currentItems;

}

abstract class CollectionEvent<T> {}
