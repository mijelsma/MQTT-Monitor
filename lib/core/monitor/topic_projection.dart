import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../models/topic_node.dart';
import '../broker/broker_repository.dart';
import '../ingestion/ingested_message.dart';
import '../ingestion/message_ingestion_coordinator.dart';
import 'topic_tree_index.dart';

/// Maintains the latest broker-scoped topic tree with granular node signals.
class TopicProjection extends ChangeNotifier {
  TopicProjection(this._ingestion, this._brokers);

  final MessageIngestionCoordinator _ingestion;
  final BrokerRepository _brokers;
  final TopicTreeIndex _index = TopicTreeIndex();
  final ValueNotifier<({IngestedMessage message, List<TopicTreeNode> path, bool structureChanged, bool topicCreated})?> updates = ValueNotifier(null);

  StreamSubscription<IngestedMessage>? _subscription;
  Future<void>? _shutdown;
  bool _notifierDisposed = false;
  String? _activeBrokerId;

  /// Returns roots in stable display order.
  Iterable<TopicTreeNode> get roots => _index.roots;

  /// Returns the broker that owns the current projection.
  String? get brokerId => _activeBrokerId;

  /// Starts ingestion and broker ownership observation once.
  void initialize() {
    if (_subscription != null) return;
    _activeBrokerId = _brokers.activeBrokerId;
    _brokers.addListener(_onBrokerChanged);
    _subscription = _ingestion.messages.listen(_onMessage);
  }

  /// Returns the current node path for [topic], or an empty list if absent.
  List<TopicTreeNode> pathFor(String topic) => _index.pathFor(topic);

  /// Removes a subtree and returns its concrete topic paths.
  List<String> delete(TopicTreeNode node) {
    final removed = _index.delete(node);
    if (removed.isNotEmpty) {
      final brokerId = _activeBrokerId;
      if (brokerId != null) _ingestion.resetTopics(brokerId, removed);
      notifyListeners();
    }
    return removed;
  }

  /// Clears all projected topics for the active broker.
  void clear() {
    if (_index.isEmpty) return;
    _index.clear();
    _ingestion.resetActiveBroker();
    notifyListeners();
  }

  void _onMessage(IngestedMessage message) {
    if (message.brokerId != _brokers.activeBrokerId) return;
    final result = _index.insert(message);
    if (result.path.isEmpty) return;
    if (result.structureChanged) notifyListeners();
    updates.value = (message: message, path: result.path, structureChanged: result.structureChanged, topicCreated: result.topicCreated);
  }

  void _onBrokerChanged() {
    final brokerId = _brokers.activeBrokerId;
    if (brokerId == _activeBrokerId) return;
    _activeBrokerId = brokerId;
    clear();
  }

  /// Stops projection input and waits for the stream subscription to detach.
  Future<void> shutdown() => _shutdown ??= _shutdownResources();

  Future<void> _shutdownResources() async {
    _brokers.removeListener(_onBrokerChanged);
    final subscription = _subscription;
    _subscription = null;
    await subscription?.cancel();
  }

  /// Releases projection listeners and signals.
  @override
  void dispose() {
    if (_notifierDisposed) return;
    _notifierDisposed = true;
    unawaited(shutdown());
    updates.dispose();
    super.dispose();
  }
}
