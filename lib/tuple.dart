// taken from [bot](https://github.com/kevmoo/bot.dart/) -- didn't want to depend on the whole lib.
// hopefully this gets added to the core libs!
part of observable_datastructures;

class Tuple<T1, T2> {
  final T1 item1;
  final T2 item2;

  const Tuple(this.item1, this.item2);

  bool operator ==(Tuple<T1, T2> other) {
    return other != null && item1 == other.item1 && item2 == other.item2;
  }

  String toString() => "{item1: $item1, item2: $item2}";

  int get hashCode => _getHash([item1, item2]);

  int _getHash(Iterable source) {
    int hash = 0;
    for (final h in source) {
      int next = h == null ? 0 : h.hashCode;
      hash = 0x1fffffff & (hash + next);
      hash = 0x1fffffff & (hash + ((0x0007ffff & hash) << 10));
      hash ^= hash >> 6;
    }
    hash = 0x1fffffff & (hash + ((0x03ffffff & hash) << 3));
    hash ^= hash >> 11;
    return 0x1fffffff & (hash + ((0x00003fff & hash) << 15));
  }

  dynamic toJson() => { 'item1' : item1, 'item2' : item2 };
}
