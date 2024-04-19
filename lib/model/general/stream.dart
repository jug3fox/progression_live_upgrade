import 'dart:async';

class StreamElement<T> {
  final StreamController<T> _streamController = StreamController<T>.broadcast();
  Stream<T> get stream => _streamController.stream;
  Future<T>? future;

  void add(T element) {
    _streamController.add(element);
  }
}