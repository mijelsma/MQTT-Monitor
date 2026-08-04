import 'dart:math';

import 'subscription_entry.dart';
import 'mqtt_protocol_version.dart';

class BrokerEntry {
  const BrokerEntry({
    required this.id,
    required this.name,
    required this.host,
    this.port = 1883,
    this.protocolVersion = MqttProtocolVersion.v311,
    this.useSSL = false,
    this.validateCertificates = true,
    this.username,
    this.password,
    this.clientId,
    this.randomClientIdSuffix = true,
    this.colorIndex = 0,
    this.subscriptions = const [],
  });

  final String id;
  final String name;
  final String host;
  final int port;
  final MqttProtocolVersion protocolVersion;
  final bool useSSL;
  final bool validateCertificates;
  final String? username;
  final String? password;
  final String? clientId;
  final bool randomClientIdSuffix;
  final int colorIndex;
  final List<SubscriptionEntry> subscriptions;

  String get effectiveClientId {
    final base = (clientId != null && clientId!.isNotEmpty)
        ? clientId!
        : 'mqtt_monitor';
    if (!randomClientIdSuffix) return base;
    final hex = Random()
        .nextInt(0xFFFFFF)
        .toRadixString(16)
        .toUpperCase()
        .padLeft(6, '0');
    return '${base}_$hex';
  }

  String get displayAddress => '${useSSL ? 'mqtts' : 'mqtt'}://$host:$port';

  BrokerEntry copyWith({
    String? name,
    String? host,
    int? port,
    MqttProtocolVersion? protocolVersion,
    bool? useSSL,
    bool? validateCertificates,
    String? username,
    String? password,
    String? clientId,
    bool? randomClientIdSuffix,
    int? colorIndex,
    List<SubscriptionEntry>? subscriptions,
  }) {
    return BrokerEntry(
      id: id,
      name: name ?? this.name,
      host: host ?? this.host,
      port: port ?? this.port,
      protocolVersion: protocolVersion ?? this.protocolVersion,
      useSSL: useSSL ?? this.useSSL,
      validateCertificates: validateCertificates ?? this.validateCertificates,
      username: username ?? this.username,
      password: password ?? this.password,
      clientId: clientId ?? this.clientId,
      randomClientIdSuffix: randomClientIdSuffix ?? this.randomClientIdSuffix,
      colorIndex: colorIndex ?? this.colorIndex,
      subscriptions: subscriptions ?? this.subscriptions,
    );
  }

  factory BrokerEntry.fromJson(Map<String, dynamic> json) => BrokerEntry(
    id: json['id'] as String? ?? '',
    name: json['name'] as String? ?? '',
    host: json['host'] as String? ?? '',
    port: json['port'] as int? ?? 1883,
    protocolVersion: MqttProtocolVersion.values.firstWhere(
      (value) => value.name == json['protocolVersion'],
      orElse: () => MqttProtocolVersion.v311,
    ),
    useSSL: json['useSSL'] as bool? ?? false,
    validateCertificates: json['validateCertificates'] as bool? ?? true,
    username: json['username'] as String?,
    password: json['password'] as String?,
    clientId: json['clientId'] as String?,
    randomClientIdSuffix: json['randomClientIdSuffix'] as bool? ?? true,
    colorIndex: json['colorIndex'] as int? ?? 0,
    subscriptions: (json['subscriptions'] as List<dynamic>? ?? [])
        .map((e) => SubscriptionEntry.fromJson(e as Map<String, dynamic>))
        .toList(),
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'host': host,
    'port': port,
    'protocolVersion': protocolVersion.name,
    'useSSL': useSSL,
    'validateCertificates': validateCertificates,
    if (username != null) 'username': username,
    if (password != null) 'password': password,
    if (clientId != null) 'clientId': clientId,
    'randomClientIdSuffix': randomClientIdSuffix,
    'colorIndex': colorIndex,
    'subscriptions': subscriptions.map((s) => s.toJson()).toList(),
  };
}
