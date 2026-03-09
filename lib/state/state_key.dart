import 'dart:convert';

import 'persist.dart';

/// Mixin for enums that expose a stable serialization [key], independent of
/// the Dart identifier name. Lets you safely rename enum values later
/// without breaking persisted data.
///
/// ```dart
/// enum AppLanguage with KeyedEnum {
///   en, de;
///   @override String get key => name;
/// }
/// ```
mixin KeyedEnum on Enum {
  String get key;
}

class StateKey<T> {
  const StateKey._(this.key, {required this.defaultValue, required this.persist, required Object? Function(T) encode, required T Function(Object?) decode}) : _encode = encode, _decode = decode;

  final String key;
  final T defaultValue;
  final Persist persist;
  final Object? Function(T) _encode;
  final T Function(Object?) _decode;

  Object? encode(T value) => _encode(value);
  T decode(Object? raw) => _decode(raw);

  // ── Factories ─────────────────────────────────────────────────────────────

  static StateKey<bool> boolean(String key, {bool defaultValue = false, Persist persist = Persist.always}) => StateKey._(key, defaultValue: defaultValue, persist: persist, encode: (v) => v, decode: (r) => r is bool ? r : false);

  static StateKey<int> integer(String key, {int defaultValue = 0, Persist persist = Persist.always}) => StateKey._(key, defaultValue: defaultValue, persist: persist, encode: (v) => v, decode: (r) => r is int ? r : 0);

  static StateKey<double> decimal(String key, {double defaultValue = 0.0, Persist persist = Persist.always}) => StateKey._(key, defaultValue: defaultValue, persist: persist, encode: (v) => v, decode: (r) => r is num ? r.toDouble() : 0.0);

  static StateKey<String> string(String key, {String defaultValue = '', Persist persist = Persist.always}) => StateKey._(key, defaultValue: defaultValue, persist: persist, encode: (v) => v, decode: (r) => r is String ? r : '');

  static StateKey<String?> nullableString(String key, {Persist persist = Persist.always}) => StateKey._(key, defaultValue: null, persist: persist, encode: (v) => v, decode: (r) => r is String ? r : null);

  /// For any enum — stored as its `.name` string.
  static StateKey<E> forEnum<E extends Enum>(String key, List<E> values, {required E defaultValue, Persist persist = Persist.always}) => StateKey._(
    key,
    defaultValue: defaultValue,
    persist: persist,
    encode: (v) => v.name,
    decode: (r) => values.firstWhere((e) => e.name == r, orElse: () => defaultValue),
  );

  /// Like [forEnum] but serializes via [KeyedEnum.key] instead of `.name`.
  static StateKey<E> forKeyedEnum<E extends KeyedEnum>(String key, List<E> values, {required E defaultValue, Persist persist = Persist.always}) => StateKey._(
    key,
    defaultValue: defaultValue,
    persist: persist,
    encode: (v) => v.key,
    decode: (r) => values.firstWhere((e) => e.key == r, orElse: () => defaultValue),
  );

  /// For JSON-serialisable objects or lists.
  ///
  /// ```dart
  /// StateKey.fromJson('settings.brokers',
  ///   defaultValue: const [],
  ///   toJson:   (list) => list.map((e) => e.toJson()).toList(),
  ///   fromJson: (raw)  => (raw as List).map((e) => BrokerEntry.fromJson(e)).toList(),
  /// )
  /// ```
  static StateKey<T> fromJson<T>(String key, {required T defaultValue, required Object? Function(T) toJson, required T Function(dynamic) fromJson, Persist persist = Persist.always}) => StateKey._(
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
