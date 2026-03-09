import 'subscription_entry.dart';

class BrokerEntry {
  const BrokerEntry({required this.id, required this.name, required this.host, this.port = 1883, this.useSSL = false, this.username, this.password, this.subscriptions = const []});

  final String id;
  final String name;
  final String host;
  final int port;
  final bool useSSL;
  final String? username;
  final String? password;
  final List<SubscriptionEntry> subscriptions;

  String get displayAddress => '${useSSL ? 'mqtts' : 'mqtt'}://$host:$port';

  BrokerEntry copyWith({String? name, String? host, int? port, bool? useSSL, String? username, String? password, List<SubscriptionEntry>? subscriptions}) {
    return BrokerEntry(id: id, name: name ?? this.name, host: host ?? this.host, port: port ?? this.port, useSSL: useSSL ?? this.useSSL, username: username ?? this.username, password: password ?? this.password, subscriptions: subscriptions ?? this.subscriptions);
  }

  factory BrokerEntry.fromJson(Map<String, dynamic> json) => BrokerEntry(
    id: json['id'] as String? ?? '',
    name: json['name'] as String? ?? '',
    host: json['host'] as String? ?? '',
    port: json['port'] as int? ?? 1883,
    useSSL: json['useSSL'] as bool? ?? false,
    username: json['username'] as String?,
    password: json['password'] as String?,
    subscriptions: (json['subscriptions'] as List<dynamic>? ?? []).map((e) => SubscriptionEntry.fromJson(e as Map<String, dynamic>)).toList(),
  );

  Map<String, dynamic> toJson() => {'id': id, 'name': name, 'host': host, 'port': port, 'useSSL': useSSL, if (username != null) 'username': username, if (password != null) 'password': password, 'subscriptions': subscriptions.map((s) => s.toJson()).toList()};
}
