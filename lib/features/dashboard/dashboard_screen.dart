import 'package:flutter/material.dart';

class GraphDashboardScreen extends StatelessWidget {
  const GraphDashboardScreen({super.key, required this.brokerId, required this.brokerName});

  final String brokerId;
  final String brokerName;

  @override
  Widget build(BuildContext context) {
    return Scaffold(appBar: AppBar(title: Text(brokerName)));
  }
}
