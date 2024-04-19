import 'dart:collection';

class CustomList<E> extends ListBase<E> {
  final List<E> l = [];
  CustomList();

  void set length(int newLength) { l.length = newLength; }

  @override
  void add(E element) {
    // TODO: implement add
    l.add(element);
  }

  int get length => l.length;
  E operator [](int index) => l[index];
  void operator []=(int index, E value) { l[index] = value; }

// your custom methods
}