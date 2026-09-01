/// Simple in-memory TTL cache for a single typed value.
/// Used to avoid redundant API calls within the same session.
class TtlCache<T> {
  final Duration ttl;
  TtlCache({required this.ttl});

  T? _value;
  DateTime? _setAt;

  bool get hasValue => _value != null && _setAt != null &&
      DateTime.now().difference(_setAt!) < ttl;

  T? get() => hasValue ? _value : null;

  void set(T value) {
    _value = value;
    _setAt = DateTime.now();
  }

  void invalidate() {
    _value = null;
    _setAt = null;
  }
}
