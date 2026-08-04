class ClientCertificateConfig {
  const ClientCertificateConfig({this.rootCaPath, this.clientPrivateKeyPath, this.clientCertificatePath});

  final String? rootCaPath;
  final String? clientPrivateKeyPath;
  final String? clientCertificatePath;

  bool get isEmpty => rootCaPath == null && clientPrivateKeyPath == null && clientCertificatePath == null;

  bool get isComplete => rootCaPath != null && clientPrivateKeyPath != null && clientCertificatePath != null;

  ClientCertificateConfig copyWith({String? rootCaPath, String? clientPrivateKeyPath, String? clientCertificatePath, bool clearRootCa = false, bool clearClientPrivateKey = false, bool clearClientCertificate = false}) {
    return ClientCertificateConfig(rootCaPath: clearRootCa ? null : rootCaPath ?? this.rootCaPath, clientPrivateKeyPath: clearClientPrivateKey ? null : clientPrivateKeyPath ?? this.clientPrivateKeyPath, clientCertificatePath: clearClientCertificate ? null : clientCertificatePath ?? this.clientCertificatePath);
  }

  factory ClientCertificateConfig.fromJson(Map<String, dynamic> json) {
    return ClientCertificateConfig(rootCaPath: json['rootCaPath'] as String?, clientPrivateKeyPath: json['clientPrivateKeyPath'] as String?, clientCertificatePath: json['clientCertificatePath'] as String?);
  }

  Map<String, dynamic> toJson() => {if (rootCaPath != null) 'rootCaPath': rootCaPath, if (clientPrivateKeyPath != null) 'clientPrivateKeyPath': clientPrivateKeyPath, if (clientCertificatePath != null) 'clientCertificatePath': clientCertificatePath};
}
