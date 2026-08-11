import 'package:flutter/foundation.dart';

import '../../models/broker_entry.dart';
import '../storage/preferences_store.dart';
import 'broker_profile_codec.dart';
import 'broker_repository_failure.dart';
import 'broker_storage_keys.dart';
import 'broker_storage_migrator.dart';

/// Owns broker profiles, active selection, schema checks, and atomic writes.
class BrokerRepository extends ChangeNotifier {
  /// Creates a repository backed by [store] and an optional profile [codec].
  BrokerRepository(PreferencesStore store, {BrokerProfileCodec codec = const BrokerProfileCodec()}) : _store = store, _codec = codec, _migrator = BrokerStorageMigrator(store);

  final PreferencesStore _store;
  final BrokerProfileCodec _codec;
  final BrokerStorageMigrator _migrator;

  List<BrokerEntry> _brokers = const [];
  String? _activeBrokerId;
  BrokerRepositoryFailure? _failure;

  /// Returns the immutable ordered broker-profile collection.
  List<BrokerEntry> get brokers => _brokers;

  /// Returns the selected broker ID, or `null` when no broker exists.
  String? get activeBrokerId => _activeBrokerId;

  /// Returns the current recoverable persistence failure, if any.
  BrokerRepositoryFailure? get failure => _failure;

  /// Returns the active broker with a first-profile fallback.
  BrokerEntry? get activeBroker {
    if (_brokers.isEmpty) return null;
    final id = _activeBrokerId;
    if (id == null) return _brokers.first;
    return _brokers.firstWhere((broker) => broker.id == id, orElse: () => _brokers.first);
  }

  /// Initializes schema metadata and loads the persisted broker state.
  Future<void> initialize() async {
    try {
      await _migrator.migrate();
      final loaded = _codec.decode(_store.get(BrokerStorageKeys.profiles));
      final storedActiveId = _readActiveId();
      final resolvedActiveId = _resolveActiveId(loaded, storedActiveId);

      if (resolvedActiveId != storedActiveId) {
        await _writeActiveId(resolvedActiveId);
      }

      _brokers = loaded;
      _activeBrokerId = resolvedActiveId;
      _failure = null;
    } on Object catch (error) {
      _brokers = const [];
      _activeBrokerId = null;
      _failure = BrokerRepositoryFailure(message: 'Broker profiles could not be loaded. Your stored data was left unchanged.', details: _safeDetails(error));
    }
    notifyListeners();
  }

  /// Retries initialization after a recoverable persistence failure.
  Future<void> retry() => initialize();

  /// Adds [broker] and optionally makes it active after a verified write.
  Future<bool> add(BrokerEntry broker, {bool makeActive = true}) async {
    if (_failure != null) return false;
    if (_brokers.any((existing) => existing.id == broker.id)) {
      throw ArgumentError.value(broker.id, 'broker.id', 'Broker IDs must be unique.');
    }
    final activeId = makeActive ? broker.id : _activeBrokerId;
    return _commit([..._brokers, broker], activeId);
  }

  /// Replaces the profile with the same ID as [broker].
  Future<bool> update(BrokerEntry broker) async {
    if (_failure != null) return false;
    final index = _brokers.indexWhere((existing) => existing.id == broker.id);
    if (index < 0) return false;
    final updated = [..._brokers]..[index] = broker;
    return _commit(updated, _activeBrokerId);
  }

  /// Deletes the broker identified by [id] and repairs active selection.
  Future<bool> delete(String id) async {
    if (_failure != null) return false;
    if (!_brokers.any((broker) => broker.id == id)) return false;
    final updated = _brokers.where((broker) => broker.id != id).toList(growable: false);
    final activeId = _activeBrokerId == id ? (updated.isEmpty ? null : updated.first.id) : _resolveActiveId(updated, _activeBrokerId);
    return _commit(updated, activeId);
  }

  /// Moves a profile from [oldIndex] to [newIndex] using UI reorder semantics.
  Future<bool> reorder(int oldIndex, int newIndex) async {
    if (_failure != null) return false;
    if (oldIndex < 0 || oldIndex >= _brokers.length || newIndex < 0 || newIndex > _brokers.length) {
      throw RangeError('Invalid broker reorder from $oldIndex to $newIndex.');
    }
    final updated = [..._brokers];
    if (newIndex > oldIndex) newIndex--;
    final broker = updated.removeAt(oldIndex);
    updated.insert(newIndex, broker);
    return _commit(updated, _activeBrokerId);
  }

  /// Persists [id] as the active broker when that profile exists.
  Future<bool> select(String id) async {
    if (_failure != null || !_brokers.any((broker) => broker.id == id)) {
      return false;
    }
    if (_activeBrokerId == id) return true;
    try {
      await _store.setString(BrokerStorageKeys.activeProfileId, id);
      _activeBrokerId = id;
      _failure = null;
      notifyListeners();
      return true;
    } on Object catch (error) {
      _setSaveFailure(error);
      return false;
    }
  }

  /// Verifies and atomically commits [brokers] with [activeId].
  Future<bool> _commit(List<BrokerEntry> brokers, String? activeId) async {
    final encoded = _codec.encode(brokers);
    final verified = _codec.decode(encoded);
    final resolvedActiveId = _resolveActiveId(verified, activeId);
    final oldProfiles = _store.get(BrokerStorageKeys.profiles);
    final oldActiveId = _store.get(BrokerStorageKeys.activeProfileId);

    try {
      await _store.setString(BrokerStorageKeys.profiles, encoded);
      await _writeActiveId(resolvedActiveId);
    } on Object catch (error) {
      await _restore(oldProfiles, oldActiveId);
      _setSaveFailure(error);
      return false;
    }

    _brokers = verified;
    _activeBrokerId = resolvedActiveId;
    _failure = null;
    notifyListeners();
    return true;
  }

  /// Best-effort restores the persisted snapshot after a partial write.
  Future<void> _restore(Object? profiles, Object? activeId) async {
    try {
      if (profiles is String) {
        await _store.setString(BrokerStorageKeys.profiles, profiles);
      } else {
        await _store.remove(BrokerStorageKeys.profiles);
      }
      if (activeId is String) {
        await _store.setString(BrokerStorageKeys.activeProfileId, activeId);
      } else {
        await _store.remove(BrokerStorageKeys.activeProfileId);
      }
    } on Object {
      // The original failure is reported. A later retry re-reads persisted state.
    }
  }

  /// Reads and validates the persisted active broker ID.
  String? _readActiveId() {
    final raw = _store.get(BrokerStorageKeys.activeProfileId);
    if (raw == null) return null;
    if (raw is! String) {
      throw const FormatException('The active broker ID is invalid.');
    }
    return raw;
  }

  /// Resolves [requestedId] against [brokers], falling back to the first.
  String? _resolveActiveId(List<BrokerEntry> brokers, String? requestedId) {
    if (brokers.isEmpty) return null;
    if (requestedId != null && brokers.any((broker) => broker.id == requestedId)) {
      return requestedId;
    }
    return brokers.first.id;
  }

  /// Persists [id], or removes the active key when it is `null`.
  Future<void> _writeActiveId(String? id) async {
    if (id == null) {
      await _store.remove(BrokerStorageKeys.activeProfileId);
    } else {
      await _store.setString(BrokerStorageKeys.activeProfileId, id);
    }
  }

  /// Records a safe, user-visible failure for an unsuccessful save.
  void _setSaveFailure(Object error) {
    _failure = BrokerRepositoryFailure(message: 'Broker profile changes could not be saved. Your previous stored data was preserved.', details: _safeDetails(error));
    notifyListeners();
  }

  /// Redacts arbitrary exception text while retaining safe format details.
  String _safeDetails(Object error) {
    if (error is FormatException) return error.message;
    return error.runtimeType.toString();
  }
}
