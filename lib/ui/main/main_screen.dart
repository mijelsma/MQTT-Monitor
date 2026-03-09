import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'widgets/app_bar_bottom/app_bar_bottom.dart';
import 'widgets/app_bar_top/app_bar_top.dart';
import '../../state/app_state.dart';
import '../../state/keys/settings_keys.dart';
import '../../theme/app_colors.dart';

class MainScreen extends StatelessWidget {
  const MainScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final showStatusBar = context.watch<AppStateManager>().read(SettingsKeys.showStatusBar);

    return Scaffold(appBar: const AppBarTop(), backgroundColor: Theme.of(context).scaffoldBackgroundColor, body: const _EmptyState(), bottomNavigationBar: showStatusBar ? const AppBarBottom() : null);
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Broker icon
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: AppColors.brokerGradient),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [BoxShadow(color: AppColors.brokerGradient.first.withValues(alpha: 0.30), blurRadius: 24, offset: const Offset(0, 8))],
              ),
              child: const Icon(Icons.dns_rounded, size: 32, color: Colors.white),
            ),

            // Spacer
            const SizedBox(height: 20),

            // Text
            Text('No brokers configured', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600)),

            // Spacer
            const SizedBox(height: 6),

            // Subtext
            Text('Add a broker to start monitoring messages.', style: theme.textTheme.bodySmall, textAlign: TextAlign.center),

            // Spacer
            const SizedBox(height: 24),

            // Add Broker button
            FilledButton.icon(
              onPressed: () {},
              icon: const Icon(Icons.add, size: 18),
              label: const Text('Add Broker'),
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
