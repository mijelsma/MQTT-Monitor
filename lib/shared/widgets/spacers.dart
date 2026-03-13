import 'package:flutter/widgets.dart';

class VSpacer extends StatelessWidget {
  const VSpacer(this.size, {super.key});
  final double size;

  @override
  Widget build(BuildContext context) => SizedBox(height: size);
}

class HSpacer extends StatelessWidget {
  const HSpacer(this.size, {super.key});
  final double size;

  @override
  Widget build(BuildContext context) => SizedBox(width: size);
}
