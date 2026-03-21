import 'package:flutter/material.dart';

import 'chart_type.dart';
import 'data_point.dart';
import 'interpolation_mode.dart';

class GraphCardModel {
  GraphCardModel({
    required this.id,
    required this.topic,
    this.jsonKeyPath,
    required this.displayName,
    this.unit,
    required this.color,
    this.chartType = ChartType.line,
    this.interpolation = InterpolationMode.curved,
    this.colSpan = 1,
    this.rowSpan = 1,
    this.gridCol = 0,
    this.gridRow = 0,
    this.position = 0,
    this.maxDataPoints = 0,
    this.dotSize = 4.0,
    this.showFill = true,
    this.fillOpacity = 0.08,
    this.yMin,
    this.yMax,
    List<DataPoint>? dataPoints,
  }) : dataPoints = dataPoints ?? [];

  final String id;
  String topic;
  final String? jsonKeyPath;
  String displayName;
  String? unit;
  Color color;
  ChartType chartType;
  InterpolationMode interpolation;
  int colSpan;
  int rowSpan;
  int gridCol;
  int gridRow;
  int position;
  int maxDataPoints;
  double dotSize;
  bool showFill;
  double fillOpacity;
  double? yMin;
  double? yMax;
  final List<DataPoint> dataPoints;

  /// Adds a data point, trimming the buffer if it exceeds [maxDataPoints].
  /// When [maxDataPoints] is 0 all values are kept (unlimited).
  void addDataPoint(DataPoint point) {
    dataPoints.add(point);
    if (maxDataPoints > 0 && dataPoints.length > maxDataPoints) {
      dataPoints.removeRange(0, dataPoints.length - maxDataPoints);
    }
  }

  GraphCardModel copyWith({String? topic, String? displayName, String? unit, Color? color, ChartType? chartType, InterpolationMode? interpolation, int? colSpan, int? rowSpan, int? gridCol, int? gridRow, int? position, int? maxDataPoints, double? dotSize, bool? showFill, double? fillOpacity, double? Function()? yMin, double? Function()? yMax}) {
    return GraphCardModel(
      id: id,
      topic: topic ?? this.topic,
      jsonKeyPath: jsonKeyPath,
      displayName: displayName ?? this.displayName,
      unit: unit ?? this.unit,
      color: color ?? this.color,
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
      dataPoints: dataPoints,
    );
  }

  factory GraphCardModel.fromJson(Map<String, dynamic> json) {
    return GraphCardModel(
      id: json['id'] as String,
      topic: json['topic'] as String,
      jsonKeyPath: json['jsonKeyPath'] as String?,
      displayName: json['displayName'] as String,
      unit: json['unit'] as String?,
      color: Color(json['color'] as int),
      chartType: ChartType.values.firstWhere((e) => e.name == json['chartType'], orElse: () => ChartType.line),
      interpolation: InterpolationMode.values.firstWhere((e) => e.name == json['interpolation'], orElse: () => InterpolationMode.curved),
      colSpan: json['colSpan'] as int? ?? 1,
      rowSpan: json['rowSpan'] as int? ?? 1,
      gridCol: json['gridCol'] as int? ?? 0,
      gridRow: json['gridRow'] as int? ?? 0,
      position: json['position'] as int? ?? 0,
      maxDataPoints: json['maxDataPoints'] as int? ?? 0,
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
    'color': color.toARGB32(),
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
