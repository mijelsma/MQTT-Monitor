import 'dart:math';

import 'client_certificate_config.dart';
import 'mqtt_protocol_version.dart';
import 'subscription_entry.dart';

/// Describes a persisted broker profile plus its hydrated runtime secret.
class BrokerEntry {
  /// Creates a broker profile.
  const BrokerEntry({
    required this.id,
    required this.name,
    required this.host,
    this.port = 1883,
    this.protocolVersion = MqttProtocolVersion.v311,
    this.clientCertificates = const ClientCertificateConfig(),
    this.useSSL = false,
    this.validateCertificates = false,
    this.username,
    this.password,
    this.passwordReference,
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
  final ClientCertificateConfig clientCertificates;
  final bool useSSL;
  final bool validateCertificates;
  final String? username;

  /// Contains the hydrated password in memory and is never serialized.
  final String? password;

  /// Identifies the password in protected storage without containing its value.
  final String? passwordReference;
  final String? clientId;
  final bool randomClientIdSuffix;
  final int colorIndex;
  final List<SubscriptionEntry> subscriptions;

  /// Builds the MQTT client ID, adding a random suffix when configured.
  String get effectiveClientId {
    final base = (clientId != null && clientId!.isNotEmpty) ? clientId! : 'mqtt-monitor';
    if (!randomClientIdSuffix) return base;
    final hex = Random().nextInt(0xFFFFFF).toRadixString(16).toUpperCase().padLeft(6, '0');
    return '${base}_$hex';
  }

  /// Returns the broker address in a user-readable URI form.
  String get displayAddress => '${useSSL ? 'mqtts' : 'mqtt'}://$host:$port';

  /// Returns a copy with selected profile and runtime credential values changed.
  BrokerEntry copyWith({
    String? name,
    String? host,
    int? port,
    MqttProtocolVersion? protocolVersion,
    ClientCertificateConfig? clientCertificates,
    bool? useSSL,
    bool? validateCertificates,
    String? username,
    String? password,
    String? passwordReference,
    String? clientId,
    bool? randomClientIdSuffix,
    int? colorIndex,
    List<SubscriptionEntry>? subscriptions,
    bool clearUsername = false,
    bool clearPassword = false,
    bool clearPasswordReference = false,
    bool clearClientId = false,
  }) {
    return BrokerEntry(
      id: id,
      name: name ?? this.name,
      host: host ?? this.host,
      port: port ?? this.port,
      protocolVersion: protocolVersion ?? this.protocolVersion,
      clientCertificates: clientCertificates ?? this.clientCertificates,
      useSSL: useSSL ?? this.useSSL,
      validateCertificates: validateCertificates ?? this.validateCertificates,
      username: clearUsername ? null : username ?? this.username,
      password: clearPassword ? null : password ?? this.password,
      passwordReference: clearPasswordReference ? null : passwordReference ?? this.passwordReference,
      clientId: clearClientId ? null : clientId ?? this.clientId,
      randomClientIdSuffix: randomClientIdSuffix ?? this.randomClientIdSuffix,
      colorIndex: colorIndex ?? this.colorIndex,
      subscriptions: subscriptions ?? this.subscriptions,
    );
  }

  /// Decodes persisted profile metadata without accepting plaintext secrets.
  factory BrokerEntry.fromJson(Map<String, dynamic> json) => BrokerEntry(
    id: json['id'] as String? ?? '',
    name: json['name'] as String? ?? '',
    host: json['host'] as String? ?? '',
    port: json['port'] as int? ?? 1883,
    protocolVersion: MqttProtocolVersion.values.firstWhere((value) => value.name == json['protocolVersion'], orElse: () => MqttProtocolVersion.v311),
    clientCertificates: json['clientCertificates'] is Map<String, dynamic> ? ClientCertificateConfig.fromJson(json['clientCertificates'] as Map<String, dynamic>) : const ClientCertificateConfig(),
    useSSL: json['useSSL'] as bool? ?? false,
    validateCertificates: json['validateCertificates'] as bool? ?? false,
    username: json['username'] as String?,
    passwordReference: json['passwordReference'] as String?,
    clientId: json['clientId'] as String?,
    randomClientIdSuffix: json['randomClientIdSuffix'] as bool? ?? true,
    colorIndex: json['colorIndex'] as int? ?? 0,
    subscriptions: (json['subscriptions'] as List<dynamic>? ?? []).map((e) => SubscriptionEntry.fromJson(e as Map<String, dynamic>)).toList(),
  );

  /// Encodes profile metadata while deliberately excluding the runtime password.
  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'host': host,
    'port': port,
    'protocolVersion': protocolVersion.name,
    if (!clientCertificates.isEmpty) 'clientCertificates': clientCertificates.toJson(),
    'useSSL': useSSL,
    'validateCertificates': validateCertificates,
    if (username != null) 'username': username,
    if (passwordReference != null) 'passwordReference': passwordReference,
    if (clientId != null) 'clientId': clientId,
    'randomClientIdSuffix': randomClientIdSuffix,
    'colorIndex': colorIndex,
    'subscriptions': subscriptions.map((s) => s.toJson()).toList(),
  };
}
