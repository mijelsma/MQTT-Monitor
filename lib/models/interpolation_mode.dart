enum InterpolationMode {
  /// Smooth curved interpolation between points.
  curved,

  /// Straight lines between consecutive data points.
  linear,

  /// Horizontal step, then vertical jump at the next point.
  stepped,
}
