part of observable_datastructures;

abstract class ObservableCollection<T> {

  ObservableCollection<T> filtered(bool pred(T item));
  ObservableCollection<T> mapped(dynamic fun(T item));

  /**
  * (actual Collection interface defines [length])
  */
  Signal<int> get size;

}

abstract class CollectionEvent<T> {}
