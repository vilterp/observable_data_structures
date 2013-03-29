part of observable_datastructures;

class ObservableTreeNode<T> {

  T value;
  ObservableList<ObservableTreeNode<T>> children;

  ObservableTreeNode(this.value, this.children);

  ObservableList<T> get preorder => null; // TODO
  ObservableList<T> get postorder => null; // TODO

}
