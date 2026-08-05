class ClientCertificateConfig {
  const ClientCertificateConfig({this.rootCaPath, this.clientPrivateKeyPath, this.clientCertificatePath});

  final String? rootCaPath;
  final String? clientPrivateKeyPath;
  final String? clientCertificatePath;

  bool get isEmpty => rootCaPath == null && clientPrivateKeyPath == null && clientCertificatePath == null;

  /// Whether the client private key and client certificate are both set —
  /// the minimum required for mutual TLS. The [rootCaPath] is optional;
  /// when omitted the connection validates against the OS trusted roots
  /// (e.g. Let's Encrypt).
  bool get isComplete => clientPrivateKeyPath != null && clientCertificatePath != null;

  /// Whether a custom Root CA was provided in addition to the client creds.
  bool get hasRootCa => rootCaPath != null;

  ClientCertificateConfig copyWith({String? rootCaPath, String? clientPrivateKeyPath, String? clientCertificatePath, bool clearRootCa = false, bool clearClientPrivateKey = false, bool clearClientCertificate = false}) {
    return ClientCertificateConfig(rootCaPath: clearRootCa ? null : rootCaPath ?? this.rootCaPath, clientPrivateKeyPath: clearClientPrivateKey ? null : clientPrivateKeyPath ?? this.clientPrivateKeyPath, clientCertificatePath: clearClientCertificate ? null : clientCertificatePath ?? this.clientCertificatePath);
  }

  factory ClientCertificateConfig.fromJson(Map<String, dynamic> json) {
    return ClientCertificateConfig(rootCaPath: json['rootCaPath'] as String?, clientPrivateKeyPath: json['clientPrivateKeyPath'] as String?, clientCertificatePath: json['clientCertificatePath'] as String?);
  }

  Map<String, dynamic> toJson() => {if (rootCaPath != null) 'rootCaPath': rootCaPath, if (clientPrivateKeyPath != null) 'clientPrivateKeyPath': clientPrivateKeyPath, if (clientCertificatePath != null) 'clientCertificatePath': clientCertificatePath};
}
