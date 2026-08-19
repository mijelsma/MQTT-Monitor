import 'dart:convert';

import 'package:flutter/foundation.dart';

import '../../../core/broker/models/broker_entry_model.dart';
import '../../../core/broker/models/client_certificate_config_model.dart';
import '../../history/history_policy_rules.dart';
import '../../storage/preferences_store.dart';
import '../broker_profile_codec.dart';
import '../broker_repository_failure.dart';
import '../broker_storage_keys.dart';
import '../interfaces/certificate_storage_interface.dart';
import '../interfaces/credential_store_interface.dart';
import '../../mqtt/client_certificate_kind.dart';

/// Owns broker profiles, active selection, schema checks, and atomic writes.
class BrokerRepository extends ChangeNotifier {
  /// Creates a repository backed by profile, credential, and certificate stores.
  BrokerRepository(PreferencesStore store, {required CredentialStoreInterface credentials, required CertificateStorageInterface certificates, BrokerProfileCodec codec = const BrokerProfileCodec()}) : _store = store, _credentials = credentials, _certificates = certificates, _codec = codec;

  final PreferencesStore _store;
  final CredentialStoreInterface _credentials;
  final CertificateStorageInterface _certificates;
  final BrokerProfileCodec _codec;

  List<BrokerEntryModel> _brokers = const [];
  String? _activeBrokerId;
  BrokerRepositoryFailure? _failure;

  /// Returns the immutable ordered broker-profile collection.
  List<BrokerEntryModel> get brokers => _brokers;

  /// Returns the selected broker ID, or `null` when no broker exists.
  String? get activeBrokerId => _activeBrokerId;

  /// Returns the current recoverable persistence failure, if any.
  BrokerRepositoryFailure? get failure => _failure;

  /// Returns the active broker with a first-profile fallback.
  BrokerEntryModel? get activeBroker {
    if (_brokers.isEmpty) return null;
    final id = _activeBrokerId;
    if (id == null) return _brokers.first;
    return _brokers.firstWhere((broker) => broker.id == id, orElse: () => _brokers.first);
  }

  /// Initializes schema metadata and loads the persisted broker state.
  Future<void> initialize() async {
    try {
      await _ensureSchema();
      await _runPendingCleanup();
      final loaded = _codec.decode(_store.get(BrokerStorageKeys.profiles));
      final hydrated = await _hydrateCredentials(loaded);
      final storedActiveId = _readActiveId();
      final resolvedActiveId = _resolveActiveId(hydrated, storedActiveId);

      if (resolvedActiveId != storedActiveId) {
        await _writeActiveId(resolvedActiveId);
      }

      _brokers = hydrated;
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

  Future<void> _ensureSchema() async {
    final rawVersion = _store.get(BrokerStorageKeys.schemaVersion);
    if (rawVersion != null && rawVersion is! int) {
      throw const FormatException('The storage schema version is invalid.');
    }
    if (rawVersion == null) {
      await _store.setInt(BrokerStorageKeys.schemaVersion, BrokerStorageKeys.currentSchemaVersion);
      return;
    }
    final version = rawVersion as int;
    if (version > BrokerStorageKeys.currentSchemaVersion) {
      throw FormatException('Storage schema version $version is newer than this app supports.');
    }
    if (version < BrokerStorageKeys.currentSchemaVersion) {
      throw FormatException('Storage schema version $version is not supported by this pre-release schema.');
    }
  }

  /// Adds [broker] and optionally makes it active after a verified write.
  Future<bool> add(BrokerEntryModel broker, {bool makeActive = true}) async {
    if (_failure != null) return false;
    if (_brokers.any((existing) => existing.id == broker.id)) {
      throw ArgumentError.value(broker.id, 'broker.id', 'Broker IDs must be unique.');
    }
    _CredentialRollback? credentialRollback;
    try {
      final prepared = await _prepareCredential(broker);
      credentialRollback = prepared.rollback;
      final activeId = makeActive ? broker.id : _activeBrokerId;
      final saved = await _commit([..._brokers, prepared.broker], activeId, const _CleanupPlan());
      if (!saved) {
        await _restoreCredential(credentialRollback);
        await _discardUncommittedCertificates(_certificatePaths(prepared.broker));
      }
      return saved;
    } on Object catch (error) {
      await _restoreCredential(credentialRollback);
      await _discardUncommittedCertificates(_certificatePaths(broker));
      _setSaveFailure(error);
      return false;
    }
  }

  /// Replaces the profile with the same ID as [broker].
  Future<bool> update(BrokerEntryModel broker) async {
    if (_failure != null) return false;
    final index = _brokers.indexWhere((existing) => existing.id == broker.id);
    if (index < 0) return false;
    final previous = _brokers[index];
    _CredentialRollback? credentialRollback;
    try {
      final prepared = await _prepareCredential(broker, previous: previous);
      credentialRollback = prepared.rollback;
      final updated = [..._brokers]..[index] = prepared.broker;
      final cleanup = _cleanupBetween(previous, prepared.broker);
      final saved = await _commit(updated, _activeBrokerId, cleanup);
      if (!saved) {
        await _restoreCredential(credentialRollback);
        await _discardUncommittedCertificates(_certificatePaths(prepared.broker).difference(_certificatePaths(previous)));
      }
      return saved;
    } on Object catch (error) {
      await _restoreCredential(credentialRollback);
      await _discardUncommittedCertificates(_certificatePaths(broker).difference(_certificatePaths(previous)));
      _setSaveFailure(error);
      return false;
    }
  }

  /// Creates a fully independent copy directly after the source profile.
  Future<bool> duplicate(String id) async {
    if (_failure != null) return false;
    final index = _brokers.indexWhere((broker) => broker.id == id);
    if (index < 0) return false;

    var sequence = DateTime.now().microsecondsSinceEpoch;
    var duplicateId = 'broker_$sequence';
    while (_brokers.any((broker) => broker.id == duplicateId)) {
      duplicateId = 'broker_${++sequence}';
    }

    final copiedCertificatePaths = <String>{};
    _CredentialRollback? credentialRollback;
    try {
      final source = _brokers[index];
      final certificates = await _duplicateCertificates(source.clientCertificates, duplicateId, copiedCertificatePaths);
      final duplicate = source.copyWith(id: duplicateId, clientCertificates: certificates, clearPasswordReference: true);
      final prepared = await _prepareCredential(duplicate);
      credentialRollback = prepared.rollback;
      final updated = [..._brokers]..insert(index + 1, prepared.broker);
      final saved = await _commit(updated, _activeBrokerId, const _CleanupPlan());
      if (!saved) {
        await _restoreCredential(credentialRollback);
        await _discardUncommittedCertificates(copiedCertificatePaths);
      }
      return saved;
    } on Object catch (error) {
      await _restoreCredential(credentialRollback);
      await _discardUncommittedCertificates(copiedCertificatePaths);
      _setSaveFailure(error);
      return false;
    }
  }

  /// Deletes the broker identified by [id] and repairs active selection.
  Future<bool> delete(String id) async {
    if (_failure != null) return false;
    final removed = _brokers.where((broker) => broker.id == id).firstOrNull;
    if (removed == null) return false;
    final updated = _brokers.where((broker) => broker.id != id).toList(growable: false);
    final activeId = _activeBrokerId == id ? (updated.isEmpty ? null : updated.first.id) : _resolveActiveId(updated, _activeBrokerId);
    return _commit(updated, activeId, _cleanupFor(removed));
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
    return _commit(updated, _activeBrokerId, const _CleanupPlan());
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

  /// Clamps every saved subscription policy to a confirmed global maximum.
  Future<bool> clampSubscriptionHistory(int maximum) async {
    HistoryPolicyRules.validateMaximum(maximum);
    if (_failure != null) return false;
    var changed = false;
    final updated = _brokers
        .map(
          (broker) => broker.copyWith(
            subscriptions: broker.subscriptions
                .map((subscription) {
                  if (subscription.history.retention <= maximum) {
                    return subscription;
                  }
                  changed = true;
                  return subscription.copyWith(history: subscription.history.copyWith(retention: maximum));
                })
                .toList(growable: false),
          ),
        )
        .toList(growable: false);
    if (!changed) return true;
    return _commit(updated, _activeBrokerId, const _CleanupPlan());
  }

  /// Removes broker profiles and their owned secrets and certificates.
  ///
  /// Resource references are collected leniently so reset remains available
  /// when strict broker decoding has failed. Cleanup failures are reported as a
  /// count because preferences have already been reset successfully.
  Future<({bool succeeded, int cleanupFailures})> resetToDefaults() async {
    final cleanup = _resetCleanupPlan();
    const keys = [BrokerStorageKeys.profiles, BrokerStorageKeys.activeProfileId, BrokerStorageKeys.pendingResourceCleanup];
    final previous = {for (final key in keys) key: _store.get(key)};
    try {
      for (final key in keys) {
        await _store.remove(key);
      }
      await _store.setInt(BrokerStorageKeys.schemaVersion, BrokerStorageKeys.currentSchemaVersion);
    } on Object catch (error) {
      await _restoreResetSnapshot(previous);
      _setSaveFailure(error);
      return (succeeded: false, cleanupFailures: 0);
    }

    _brokers = const [];
    _activeBrokerId = null;
    _failure = null;

    var cleanupFailures = 0;
    for (final reference in cleanup.credentialReferences) {
      try {
        await _credentials.delete(reference);
      } on Object {
        cleanupFailures++;
      }
    }
    for (final filePath in cleanup.certificatePaths) {
      try {
        await _certificates.delete(filePath);
      } on Object {
        cleanupFailures++;
      }
    }
    notifyListeners();
    return (succeeded: true, cleanupFailures: cleanupFailures);
  }

  Future<void> _restoreResetSnapshot(Map<String, Object?> snapshot) async {
    for (final entry in snapshot.entries) {
      try {
        final value = entry.value;
        if (value is int) {
          await _store.setInt(entry.key, value);
        } else if (value is String) {
          await _store.setString(entry.key, value);
        } else {
          await _store.remove(entry.key);
        }
      } on Object {
        // The original reset failure remains the actionable error.
      }
    }
  }

  /// Verifies and atomically commits [brokers], [activeId], and [cleanup].
  Future<bool> _commit(List<BrokerEntryModel> brokers, String? activeId, _CleanupPlan cleanup) async {
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

    final runtimeById = {for (final broker in brokers) broker.id: broker};
    _brokers = List.unmodifiable(verified.map((stored) => stored.copyWith(password: runtimeById[stored.id]?.password, clearPassword: runtimeById[stored.id]?.password == null)));
    _activeBrokerId = resolvedActiveId;
    _failure = null;
    if (!cleanup.isEmpty) {
      try {
        await _performCleanup(cleanup);
      } on Object catch (error) {
        try {
          await _store.setString(BrokerStorageKeys.pendingResourceCleanup, cleanup.encode());
        } on Object {
          // The cleanup failure remains visible even if retry cannot be queued.
        }
        _failure = BrokerRepositoryFailure(message: 'The broker change was saved, but old credentials could not be removed. Retry cleanup before making more changes.', details: _safeDetails(error));
      }
    }
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

  /// Loads each referenced password without placing it in profile persistence.
  Future<List<BrokerEntryModel>> _hydrateCredentials(List<BrokerEntryModel> brokers) async {
    final hydrated = <BrokerEntryModel>[];
    for (final broker in brokers) {
      final reference = broker.passwordReference;
      if (reference == null) {
        hydrated.add(broker);
        continue;
      }
      if (reference.trim().isEmpty) {
        throw const _BrokerStorageException('A saved broker credential reference is invalid.');
      }
      final password = await _credentials.read(reference);
      if (password == null) {
        throw const _BrokerStorageException('A saved broker password is unavailable in protected storage.');
      }
      hydrated.add(broker.copyWith(password: password));
    }
    return List.unmodifiable(hydrated);
  }

  /// Writes and verifies the runtime password before profile metadata is saved.
  Future<_PreparedCredential> _prepareCredential(BrokerEntryModel broker, {BrokerEntryModel? previous}) async {
    final password = broker.password;
    if (password == null) {
      return _PreparedCredential(broker.copyWith(clearPassword: true, clearPasswordReference: true));
    }

    final reference = previous?.passwordReference ?? _passwordReference(broker.id);
    final oldValue = await _credentials.read(reference);
    final rollback = _CredentialRollback(reference, oldValue);
    try {
      await _credentials.write(reference, password);
      if (await _credentials.read(reference) != password) {
        throw const _BrokerStorageException('Protected storage could not verify the saved broker password.');
      }
    } on Object {
      await _restoreCredential(rollback);
      rethrow;
    }
    return _PreparedCredential(broker.copyWith(passwordReference: reference), rollback: rollback);
  }

  /// Restores the protected value captured before a failed profile write.
  Future<void> _restoreCredential(_CredentialRollback? rollback) async {
    if (rollback == null) return;
    try {
      if (rollback.previousValue == null) {
        await _credentials.delete(rollback.reference);
      } else {
        await _credentials.write(rollback.reference, rollback.previousValue!);
      }
    } on Object {
      // The repository failure blocks writes until initialization rechecks data.
    }
  }

  /// Runs a persisted cleanup plan and removes it only after every deletion.
  Future<void> _runPendingCleanup() async {
    final raw = _store.get(BrokerStorageKeys.pendingResourceCleanup);
    if (raw == null) return;
    final cleanup = _CleanupPlan.decode(raw);
    await _performCleanup(cleanup);
    await _store.remove(BrokerStorageKeys.pendingResourceCleanup);
  }

  /// Deletes every resource in [cleanup] using idempotent store operations.
  Future<void> _performCleanup(_CleanupPlan cleanup) async {
    for (final reference in cleanup.credentialReferences) {
      await _credentials.delete(reference);
    }
    for (final filePath in cleanup.certificatePaths) {
      await _certificates.delete(filePath);
    }
  }

  /// Deletes uncommitted certificate imports or queues failures for retry.
  Future<void> _discardUncommittedCertificates(Set<String> filePaths) async {
    final failed = <String>{};
    for (final filePath in filePaths) {
      try {
        await _certificates.delete(filePath);
      } on Object {
        failed.add(filePath);
      }
    }
    if (failed.isEmpty) return;
    try {
      await _store.setString(BrokerStorageKeys.pendingResourceCleanup, _CleanupPlan(certificatePaths: failed).encode());
    } on Object {
      // The original save failure remains the actionable repository failure.
    }
  }

  /// Returns resources that became unreferenced between two profile versions.
  _CleanupPlan _cleanupBetween(BrokerEntryModel previous, BrokerEntryModel next) {
    final references = <String>{};
    final oldReference = previous.passwordReference;
    if (oldReference != null && oldReference != next.passwordReference) {
      references.add(oldReference);
    }
    return _CleanupPlan(credentialReferences: references, certificatePaths: _certificatePaths(previous).difference(_certificatePaths(next)));
  }

  /// Returns every owned resource referenced by [broker].
  _CleanupPlan _cleanupFor(BrokerEntryModel broker) {
    return _CleanupPlan(credentialReferences: {if (broker.passwordReference != null) broker.passwordReference!}, certificatePaths: _certificatePaths(broker));
  }

  /// Returns the non-null app-owned certificate paths in [broker].
  Set<String> _certificatePaths(BrokerEntryModel broker) => {
    if (broker.clientCertificates.rootCaPath != null) broker.clientCertificates.rootCaPath!,
    if (broker.clientCertificates.clientPrivateKeyPath != null) broker.clientCertificates.clientPrivateKeyPath!,
    if (broker.clientCertificates.clientCertificatePath != null) broker.clientCertificates.clientCertificatePath!,
  };

  Future<ClientCertificateConfigModel> _duplicateCertificates(ClientCertificateConfigModel source, String brokerId, Set<String> copiedPaths) async {
    Future<String?> copy(String? filePath, ClientCertificateKind kind) async {
      if (filePath == null) return null;
      final copied = await _certificates.duplicate(filePath, brokerId: brokerId, kind: kind);
      copiedPaths.add(copied);
      return copied;
    }

    return ClientCertificateConfigModel(rootCaPath: await copy(source.rootCaPath, ClientCertificateKind.rootCa), clientPrivateKeyPath: await copy(source.clientPrivateKeyPath, ClientCertificateKind.privateKey), clientCertificatePath: await copy(source.clientCertificatePath, ClientCertificateKind.clientCertificate));
  }

  /// Finds every broker-owned resource, including references in invalid JSON.
  _CleanupPlan _resetCleanupPlan() {
    final credentialReferences = <String>{};
    final certificatePaths = <String>{};

    for (final broker in _brokers) {
      final cleanup = _cleanupFor(broker);
      credentialReferences.addAll(cleanup.credentialReferences);
      certificatePaths.addAll(cleanup.certificatePaths);
    }

    final rawProfiles = _store.get(BrokerStorageKeys.profiles);
    if (rawProfiles is String) {
      try {
        final decoded = jsonDecode(rawProfiles);
        if (decoded is List) {
          for (final rawBroker in decoded.whereType<Map>()) {
            final reference = rawBroker['passwordReference'];
            if (reference is String && reference.isNotEmpty) {
              credentialReferences.add(reference);
            }
            final certificates = rawBroker['clientCertificates'];
            if (certificates is Map) {
              for (final key in const ['rootCaPath', 'clientPrivateKeyPath', 'clientCertificatePath']) {
                final filePath = certificates[key];
                if (filePath is String && filePath.isNotEmpty) {
                  certificatePaths.add(filePath);
                }
              }
            }
          }
        }
      } on Object {
        // Reset must remain available for malformed development data.
      }
    }

    final pending = _store.get(BrokerStorageKeys.pendingResourceCleanup);
    if (pending != null) {
      try {
        final cleanup = _CleanupPlan.decode(pending);
        credentialReferences.addAll(cleanup.credentialReferences);
        certificatePaths.addAll(cleanup.certificatePaths);
      } on Object {
        // A malformed cleanup record must not prevent a full reset.
      }
    }
    return _CleanupPlan(credentialReferences: credentialReferences, certificatePaths: certificatePaths);
  }

  /// Creates an opaque protected-storage reference from [brokerId].
  String _passwordReference(String brokerId) => 'mqtt-monitor.broker.${base64Url.encode(utf8.encode(brokerId))}.password';

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
  String? _resolveActiveId(List<BrokerEntryModel> brokers, String? requestedId) {
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
    if (error is _BrokerStorageException) return error.message;
    return error.runtimeType.toString();
  }
}

/// Holds a profile whose runtime password has been persisted and verified.
class _PreparedCredential {
  /// Creates a prepared profile and its optional rollback snapshot.
  const _PreparedCredential(this.broker, {this.rollback});

  final BrokerEntryModel broker;
  final _CredentialRollback? rollback;
}

/// Captures one protected-storage value for transactional rollback.
class _CredentialRollback {
  /// Creates a rollback snapshot for [reference].
  const _CredentialRollback(this.reference, this.previousValue);

  final String reference;
  final String? previousValue;
}

/// Describes idempotent resource deletion that can survive process restarts.
class _CleanupPlan {
  /// Creates a cleanup plan from credential references and certificate paths.
  const _CleanupPlan({this.credentialReferences = const {}, this.certificatePaths = const {}});

  final Set<String> credentialReferences;
  final Set<String> certificatePaths;

  /// Returns whether the plan has no work.
  bool get isEmpty => credentialReferences.isEmpty && certificatePaths.isEmpty;

  /// Encodes the cleanup plan without secret material.
  String encode() => jsonEncode({'credentialReferences': credentialReferences.toList(growable: false), 'certificatePaths': certificatePaths.toList(growable: false)});

  /// Decodes and validates a persisted cleanup plan.
  factory _CleanupPlan.decode(Object raw) {
    if (raw is! String) {
      throw const FormatException('Pending broker cleanup must be stored as JSON text.');
    }
    final decoded = jsonDecode(raw);
    if (decoded is! Map) {
      throw const FormatException('Pending broker cleanup must contain a JSON object.');
    }
    return _CleanupPlan(credentialReferences: _stringSet(decoded['credentialReferences'], 'credential references'), certificatePaths: _stringSet(decoded['certificatePaths'], 'certificate paths'));
  }

  /// Validates a persisted string list stored in [value].
  static Set<String> _stringSet(Object? value, String label) {
    if (value is! List || value.any((item) => item is! String || item.isEmpty)) {
      throw FormatException('Pending broker cleanup contains invalid $label.');
    }
    return value.cast<String>().toSet();
  }
}

/// Carries a safe broker-storage failure message without secret values.
class _BrokerStorageException implements Exception {
  /// Creates a storage exception with a safe user-visible [message].
  const _BrokerStorageException(this.message);

  final String message;
}
