import 'state_key.dart';

/// Controls whether a [StateKey] gets saved to SharedPreferences.
///
/// Three modes:
///  - [always] — always persisted.
///  - [never] — runtime only, lost on restart.
///  - [when] — persisted only when a boolean gate key is true.
class Persist {
  const Persist._(this._always, this._gate);

  final bool? _always;
  final StateKey<bool>? _gate;

  /// Always save to disk.
  static const always = Persist._(true, null);

  /// Never save to disk.
  static const never = Persist._(false, null);

  /// Save to disk only when [gate] is true.
  static Persist when(StateKey<bool> gate) => Persist._(null, gate);

  /// Returns true if the value should be persisted right now.
  /// [read] is used to look up the gate key's current value.
  bool resolve(bool Function(StateKey<bool>) read) {
    return _gate != null ? read(_gate) : _always!;
  }
}
