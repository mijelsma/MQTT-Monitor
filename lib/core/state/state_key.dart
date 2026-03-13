import 'dart:convert';

import 'persist.dart';

/// A typed key for [AppStateManager]. Knows how to encode/decode its value
/// for SharedPreferences, what its default is, and whether it should be
/// persisted at all (see [Persist]).
///
/// Use the named factories below instead of the private constructor.
class StateKey<T> {
  const StateKey._(this.key, {required this.defaultValue, required this.persist, required Object? Function(T) encode, required T Function(Object?) decode}) : _encode = encode, _decode = decode;

  final String key;
  final T defaultValue;
  final Persist persist;
  final Object? Function(T) _encode;
  final T Function(Object?) _decode;

  /// Converts [value] to a SharedPreferences-compatible type.
  Object? encode(T value) => _encode(value);

  /// Converts a raw SharedPreferences value back to [T].
  T decode(Object? raw) => _decode(raw);

  /// A simple bool key. Stored as-is.
  static StateKey<bool> boolean(String key, {bool defaultValue = false, Persist persist = Persist.always}) {
    return StateKey._(key, defaultValue: defaultValue, persist: persist, encode: (v) => v, decode: (r) => r is bool ? r : false);
  }

  /// A simple int key. Stored as-is.
  static StateKey<int> integer(String key, {int defaultValue = 0, Persist persist = Persist.always}) {
    return StateKey._(key, defaultValue: defaultValue, persist: persist, encode: (v) => v, decode: (r) => r is int ? r : 0);
  }

  /// A simple double key. Accepts num on decode for int→double safety.
  static StateKey<double> decimal(String key, {double defaultValue = 0.0, Persist persist = Persist.always}) {
    return StateKey._(key, defaultValue: defaultValue, persist: persist, encode: (v) => v, decode: (r) => r is num ? r.toDouble() : 0.0);
  }

  /// A simple String key. Stored as-is.
  static StateKey<String> string(String key, {String defaultValue = '', Persist persist = Persist.always}) {
    return StateKey._(key, defaultValue: defaultValue, persist: persist, encode: (v) => v, decode: (r) => r is String ? r : '');
  }

  /// A nullable String key. Returns null when missing or wrong type.
  static StateKey<String?> nullableString(String key, {Persist persist = Persist.always}) {
    return StateKey._(key, defaultValue: null, persist: persist, encode: (v) => v, decode: (r) => r is String ? r : null);
  }

  /// An enum key. Persisted by [Enum.name], matched back on decode.
  static StateKey<E> forEnum<E extends Enum>(String key, List<E> values, {required E defaultValue, Persist persist = Persist.always}) {
    return StateKey._(
      key,
      defaultValue: defaultValue,
      persist: persist,
      encode: (v) => v.name,
      decode: (r) => values.firstWhere((e) => e.name == r, orElse: () => defaultValue),
    );
  }

  /// A complex object key. Stored as a JSON string. Falls back to
  /// [defaultValue] if decoding fails.
  static StateKey<T> fromJson<T>(String key, {required T defaultValue, required Object? Function(T) toJson, required T Function(dynamic) fromJson, Persist persist = Persist.always}) {
    return StateKey._(
      key,
      defaultValue: defaultValue,
      persist: persist,
      encode: (v) => jsonEncode(toJson(v)),
      decode: (r) {
        if (r is! String) return defaultValue;
        try {
          return fromJson(jsonDecode(r));
        } catch (_) {
          return defaultValue;
        }
      },
    );
  }
}
