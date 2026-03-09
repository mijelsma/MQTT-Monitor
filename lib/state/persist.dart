import 'state_key.dart';

class Persist {
  const Persist._(this._always, this._gate);

  final bool? _always;
  final StateKey<bool>? _gate;

  static const always = Persist._(true, null);
  static const never = Persist._(false, null);
  static Persist when(StateKey<bool> gate) => Persist._(null, gate);

  bool resolve(bool Function(StateKey<bool>) read) => _gate != null ? read(_gate) : _always!;
}
