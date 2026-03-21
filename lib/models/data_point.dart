class DataPoint {
  const DataPoint({required this.timestamp, required this.value});

  final DateTime timestamp;
  final double value;

  factory DataPoint.fromJson(Map<String, dynamic> json) => DataPoint(timestamp: DateTime.fromMillisecondsSinceEpoch(json['t'] as int), value: (json['v'] as num).toDouble());

  Map<String, dynamic> toJson() => {'t': timestamp.millisecondsSinceEpoch, 'v': value};
}
