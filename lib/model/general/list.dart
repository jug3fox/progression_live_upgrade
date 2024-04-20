import 'dart:collection';

class CustomList<E> extends ListBase<E> {
  final List<E> _l = [];
  CustomList();

  void set length(int newLength) { _l.length = newLength; }

  @override
  void add(E element) {
    // TODO: implement add
    _l.add(element);
  }

  int get length => _l.length;
  E operator [](int index) => _l[index];
  void operator []=(int index, E value) { _l[index] = value; }

// your custom methods
}