import 'package:flutter/material.dart';
import 'package:mqtt_monitor/widgets/app_bar_bottom/app_bar_bottom.dart';
import '../widgets/app_bar_top/app_bar_top.dart';

class MainScreen extends StatelessWidget {
  const MainScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const AppBarTop(title: 'MQTT Monitor'),
      body: const SizedBox.expand(),
      bottomNavigationBar: const AppBarBottom(),
    );
  }
}
