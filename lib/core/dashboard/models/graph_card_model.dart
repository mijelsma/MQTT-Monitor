import '../dashboard_series_policy.dart';
import 'chart_type_model.dart';
import 'interpolation_mode_model.dart';

/// Immutable persisted configuration for one dashboard graph.
class GraphCardModel {
  const GraphCardModel({
    required this.id,
    required this.topic,
    this.jsonKeyPath,
    required this.displayName,
    this.unit,
    required this.colorValue,
    this.chartType = ChartTypeModel.line,
    this.interpolation = InterpolationModeModel.curved,
    this.colSpan = 1,
    this.rowSpan = 1,
    this.gridCol = 0,
    this.gridRow = 0,
    this.position = 0,
    this.maxDataPoints = DashboardSeriesPolicy.defaultSamples,
    this.dotSize = 4.0,
    this.showFill = true,
    this.fillOpacity = 0.08,
    this.yMin,
    this.yMax,
  }) : assert(maxDataPoints >= DashboardSeriesPolicy.minimumSamples && maxDataPoints <= DashboardSeriesPolicy.maximumSamples);

  final String id;
  final String topic;
  final String? jsonKeyPath;
  final String displayName;
  final String? unit;
  final int colorValue;
  final ChartTypeModel chartType;
  final InterpolationModeModel interpolation;
  final int colSpan;
  final int rowSpan;
  final int gridCol;
  final int gridRow;
  final int position;
  final int maxDataPoints;
  final double dotSize;
  final bool showFill;
  final double fillOpacity;
  final double? yMin;
  final double? yMax;

  GraphCardModel copyWith({
    String? topic,
    String? Function()? jsonKeyPath,
    String? displayName,
    String? unit,
    bool clearUnit = false,
    int? colorValue,
    ChartTypeModel? chartType,
    InterpolationModeModel? interpolation,
    int? colSpan,
    int? rowSpan,
    int? gridCol,
    int? gridRow,
    int? position,
    int? maxDataPoints,
    double? dotSize,
    bool? showFill,
    double? fillOpacity,
    double? Function()? yMin,
    double? Function()? yMax,
  }) {
    return GraphCardModel(
      id: id,
      topic: topic ?? this.topic,
      jsonKeyPath: jsonKeyPath != null ? jsonKeyPath() : this.jsonKeyPath,
      displayName: displayName ?? this.displayName,
      unit: clearUnit ? null : unit ?? this.unit,
      colorValue: colorValue ?? this.colorValue,
      chartType: chartType ?? this.chartType,
      interpolation: interpolation ?? this.interpolation,
      colSpan: colSpan ?? this.colSpan,
      rowSpan: rowSpan ?? this.rowSpan,
      gridCol: gridCol ?? this.gridCol,
      gridRow: gridRow ?? this.gridRow,
      position: position ?? this.position,
      maxDataPoints: maxDataPoints ?? this.maxDataPoints,
      dotSize: dotSize ?? this.dotSize,
      showFill: showFill ?? this.showFill,
      fillOpacity: fillOpacity ?? this.fillOpacity,
      yMin: yMin != null ? yMin() : this.yMin,
      yMax: yMax != null ? yMax() : this.yMax,
    );
  }

  factory GraphCardModel.fromJson(Map<String, dynamic> json) {
    return GraphCardModel(
      id: json['id'] as String,
      topic: json['topic'] as String,
      jsonKeyPath: json['jsonKeyPath'] as String?,
      displayName: json['displayName'] as String,
      unit: json['unit'] as String?,
      colorValue: json['color'] as int,
      chartType: ChartTypeModel.values.firstWhere((e) => e.name == json['chartType'], orElse: () => ChartTypeModel.line),
      interpolation: InterpolationModeModel.values.firstWhere((e) => e.name == json['interpolation'], orElse: () => InterpolationModeModel.curved),
      colSpan: json['colSpan'] as int? ?? 1,
      rowSpan: json['rowSpan'] as int? ?? 1,
      gridCol: json['gridCol'] as int? ?? 0,
      gridRow: json['gridRow'] as int? ?? 0,
      position: json['position'] as int? ?? 0,
      maxDataPoints: _readMaximum(json['maxDataPoints']),
      dotSize: (json['dotSize'] as num?)?.toDouble() ?? 4.0,
      showFill: json['showFill'] as bool? ?? true,
      fillOpacity: (json['fillOpacity'] as num?)?.toDouble() ?? 0.08,
      yMin: (json['yMin'] as num?)?.toDouble(),
      yMax: (json['yMax'] as num?)?.toDouble(),
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'topic': topic,
    if (jsonKeyPath != null) 'jsonKeyPath': jsonKeyPath,
    'displayName': displayName,
    if (unit != null) 'unit': unit,
    'color': colorValue,
    'chartType': chartType.name,
    'interpolation': interpolation.name,
    'colSpan': colSpan,
    'rowSpan': rowSpan,
    'gridCol': gridCol,
    'gridRow': gridRow,
    'position': position,
    'maxDataPoints': maxDataPoints,
    'dotSize': dotSize,
    'showFill': showFill,
    'fillOpacity': fillOpacity,
    if (yMin != null) 'yMin': yMin,
    if (yMax != null) 'yMax': yMax,
  };
}

int _readMaximum(Object? raw) {
  if (raw is! int) {
    throw const FormatException('Dashboard card maxDataPoints is required');
  }
  DashboardSeriesPolicy.validate(raw);
  return raw;
}
