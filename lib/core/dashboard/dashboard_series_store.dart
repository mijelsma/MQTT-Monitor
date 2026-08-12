import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../models/data_point.dart';
import '../ingestion/ingested_message.dart';
import '../state/app_state.dart';
import '../state/keys/settings_keys.dart';
import 'dashboard_repository.dart';
import 'dashboard_value_extractor.dart';

final _variablePlaceholderPattern = RegExp(r'\$\{([^}]+)\}');

/// Owns all bounded, process-lifetime dashboard series and routes messages.
class DashboardSeriesStore {
  DashboardSeriesStore({required Stream<IngestedMessage> messages, required DashboardRepository repository, required AppStateManager state, DashboardValueExtractor? extractor}) : _messages = messages, _repository = repository, _state = state, _extractor = extractor ?? DashboardValueExtractor();

  final Stream<IngestedMessage> _messages;
  final DashboardRepository _repository;
  final AppStateManager _state;
  final DashboardValueExtractor _extractor;

  final Map<_SeriesKey, ValueNotifier<List<DataPoint>>> _signals = {};
  final Map<_TopicKey, List<_Route>> _routes = {};
  final Map<_SeriesKey, _RouteFingerprint> _fingerprints = {};
  StreamSubscription<IngestedMessage>? _subscription;
  Map<String, String> _variableValues = const {};

  void initialize() {
    if (_subscription != null) return;
    _variableValues = Map.unmodifiable(_state.read(SettingsKeys.environmentVariableValues));
    _repository.addListener(_onConfigurationChanged);
    _state.addListener(_onStateChanged);
    _rebuildRoutes();
    _subscription = _messages.listen(_onMessage);
  }

  ValueListenable<List<DataPoint>> seriesFor(String brokerId, String cardId) {
    return _signals.putIfAbsent(_SeriesKey(brokerId, cardId), () => ValueNotifier<List<DataPoint>>(const []));
  }

  List<DataPoint> currentSeries(String brokerId, String cardId) {
    return _signals[_SeriesKey(brokerId, cardId)]?.value ?? const [];
  }

  void clearCards(String brokerId, Iterable<String> cardIds) {
    for (final cardId in cardIds) {
      final signal = _signals[_SeriesKey(brokerId, cardId)];
      if (signal != null && signal.value.isNotEmpty) signal.value = const [];
    }
  }

  void _onMessage(IngestedMessage message) {
    final routes = _routes[_TopicKey(message.brokerId, message.topic)];
    if (routes == null || routes.isEmpty) return;

    final payload = message.value.payload;
    final direct = DashboardValueExtractor.numericValue(payload);
    Object? decoded;
    var decodedPayload = false;

    for (final route in routes) {
      double? value;
      if ((route.jsonKeyPath == null || route.jsonKeyPath!.isEmpty) && direct != null) {
        value = direct;
      } else {
        if (!decodedPayload) {
          decodedPayload = true;
          try {
            decoded = _extractor.decode(payload);
          } on Object {
            decoded = null;
          }
        }
        try {
          value = _extractor.extract(decoded, route.jsonKeyPath);
        } on FormatException {
          value = null;
        }
      }
      if (value == null) continue;

      final signal = _signals[route.seriesKey]!;
      final next = [...signal.value, DataPoint(timestamp: message.value.receivedAt, value: value)];
      final excess = next.length - route.maximumSamples;
      signal.value = List.unmodifiable(excess > 0 ? next.sublist(excess) : next);
    }
  }

  void _onConfigurationChanged() => _rebuildRoutes();

  void _onStateChanged() {
    final values = _state.read(SettingsKeys.environmentVariableValues);
    if (mapEquals(values, _variableValues)) return;
    _variableValues = Map.unmodifiable(values);
    _rebuildRoutes();
  }

  void _rebuildRoutes() {
    final nextRoutes = <_TopicKey, List<_Route>>{};
    final nextFingerprints = <_SeriesKey, _RouteFingerprint>{};
    final liveKeys = <_SeriesKey>{};

    for (final broker in _repositoryBrokerIds()) {
      for (final card in _repository.cardsForBroker(broker)) {
        final seriesKey = _SeriesKey(broker, card.id);
        final topic = resolveDashboardTopic(card.topic, _variableValues);
        final fingerprint = _RouteFingerprint(topic, card.jsonKeyPath, card.maxDataPoints);
        liveKeys.add(seriesKey);
        final signal = _signals.putIfAbsent(seriesKey, () => ValueNotifier<List<DataPoint>>(const []));
        final previous = _fingerprints[seriesKey];
        if (previous != null && (previous.topic != topic || previous.jsonKeyPath != card.jsonKeyPath)) {
          signal.value = const [];
        } else if (signal.value.length > card.maxDataPoints) {
          signal.value = List.unmodifiable(signal.value.sublist(signal.value.length - card.maxDataPoints));
        }
        nextFingerprints[seriesKey] = fingerprint;
        nextRoutes.putIfAbsent(_TopicKey(broker, topic), () => []).add(_Route(seriesKey, card.jsonKeyPath, card.maxDataPoints));
      }
    }

    for (final key in _signals.keys.where((key) => !liveKeys.contains(key)).toList()) {
      _signals.remove(key)?.dispose();
    }
    _routes
      ..clear()
      ..addAll(nextRoutes);
    _fingerprints
      ..clear()
      ..addAll(nextFingerprints);
  }

  Iterable<String> _repositoryBrokerIds() sync* {
    // Cards are persisted only for real brokers. The repository intentionally
    // exposes broker IDs through its card map to keep routing independent from UI.
    yield* _repository.brokerIds;
  }

  Future<void> dispose() async {
    _repository.removeListener(_onConfigurationChanged);
    _state.removeListener(_onStateChanged);
    await _subscription?.cancel();
    _subscription = null;
    for (final signal in _signals.values) {
      signal.dispose();
    }
    _signals.clear();
  }
}

String resolveDashboardTopic(String template, Map<String, String> values) {
  return template.replaceAllMapped(_variablePlaceholderPattern, (match) => values[match.group(1)!] ?? match.group(0)!);
}

class _SeriesKey {
  const _SeriesKey(this.brokerId, this.cardId);
  final String brokerId;
  final String cardId;

  @override
  bool operator ==(Object other) => other is _SeriesKey && other.brokerId == brokerId && other.cardId == cardId;

  @override
  int get hashCode => Object.hash(brokerId, cardId);
}

class _TopicKey {
  const _TopicKey(this.brokerId, this.topic);
  final String brokerId;
  final String topic;

  @override
  bool operator ==(Object other) => other is _TopicKey && other.brokerId == brokerId && other.topic == topic;

  @override
  int get hashCode => Object.hash(brokerId, topic);
}

class _Route {
  const _Route(this.seriesKey, this.jsonKeyPath, this.maximumSamples);
  final _SeriesKey seriesKey;
  final String? jsonKeyPath;
  final int maximumSamples;
}

class _RouteFingerprint {
  const _RouteFingerprint(this.topic, this.jsonKeyPath, this.maximumSamples);
  final String topic;
  final String? jsonKeyPath;
  final int maximumSamples;
}
