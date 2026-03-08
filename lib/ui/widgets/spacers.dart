import 'package:flutter/widgets.dart';

/// Vertical blank space of [size] logical pixels.
/// Replaces `SizedBox(height: n)` throughout the app.
class VSpacer extends StatelessWidget {
  const VSpacer(this.size, {super.key});
  final double size;

  @override
  Widget build(BuildContext context) => SizedBox(height: size);
}

/// Horizontal blank space of [size] logical pixels.
/// Replaces `SizedBox(width: n)` throughout the app.
class HSpacer extends StatelessWidget {
  const HSpacer(this.size, {super.key});
  final double size;

  @override
  Widget build(BuildContext context) => SizedBox(width: size);
}
