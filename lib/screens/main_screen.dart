import 'package:flutter/material.dart';
import '../widgets/app_bar/app_bar.dart';

class MainScreen extends StatelessWidget {
  const MainScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      appBar: AppHeader(title: 'MQTT Monitor'),
      body: SizedBox.expand(),
    );
  }
}
