import 'package:flutter/material.dart';
import 'package:mqtt_monitor/ui/widgets/spacers.dart';
import '../../../../theme/app_tokens/app_tokens.dart';
import '../topic_tree/topic_tree_controller.dart';
import 'broker_selector.dart';
import 'connection_button.dart';
import 'settings_button.dart';

class AppBarTop extends StatefulWidget implements PreferredSizeWidget {
  const AppBarTop({super.key, required this.filterController, required this.scope, required this.onScopeChanged});

  final TextEditingController filterController;
  final SearchScope scope;
  final ValueChanged<SearchScope> onScopeChanged;

  static const double _toolbarHeight = 62;

  @override
  Size get preferredSize => const Size.fromHeight(_toolbarHeight + 0.5);

  @override
  State<AppBarTop> createState() => _AppBarTopState();
}

class _AppBarTopState extends State<AppBarTop> {
  @override
  void initState() {
    super.initState();
    widget.filterController.addListener(_onFilterChanged);
  }

  @override
  void didUpdateWidget(AppBarTop oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.filterController != widget.filterController) {
      oldWidget.filterController.removeListener(_onFilterChanged);
      widget.filterController.addListener(_onFilterChanged);
    }
  }

  @override
  void dispose() {
    widget.filterController.removeListener(_onFilterChanged);
    super.dispose();
  }

  void _onFilterChanged() => setState(() {});

  @override
  Widget build(BuildContext context) {
    final hasText = widget.filterController.text.isNotEmpty;

    return AppBar(
      toolbarHeight: AppBarTop._toolbarHeight,
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(1),
        child: Container(height: 0.5, color: Theme.of(context).dividerColor),
      ),
      title: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 280),
        child: _SearchBox(controller: widget.filterController, scope: widget.scope, hasText: hasText, onScopeChanged: widget.onScopeChanged),
      ),
      titleSpacing: 10,
      actions: const [BrokerSelector(), HSpacer(8), ConnectionButton(), HSpacer(8), SettingsButton(), HSpacer(8)],
    );
  }
}

// ---------------------------------------------------------------------------
// Self-contained search box
// ---------------------------------------------------------------------------

class _SearchBox extends StatelessWidget {
  const _SearchBox({required this.controller, required this.scope, required this.hasText, required this.onScopeChanged});

  final TextEditingController controller;
  final SearchScope scope;
  final bool hasText;
  final ValueChanged<SearchScope> onScopeChanged;

  String _scopeLabel(SearchScope s) => switch (s) {
    SearchScope.all => 'All',
    SearchScope.topic => 'Topic',
    SearchScope.value => 'Value',
  };

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;

    return Container(
      height: 34,
      decoration: BoxDecoration(
        color: tokens.inputFill,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: tokens.border, width: 0.5),
      ),
      child: Row(
        children: [
          const SizedBox(width: 8),
          Icon(Icons.search_rounded, size: 15, color: tokens.textTertiary),
          const SizedBox(width: 6),
          Expanded(
            child: TextField(
              controller: controller,
              style: TextStyle(fontSize: 13, color: tokens.textPrimary, height: 1.0),
              decoration: InputDecoration(
                hintText: 'Search ${_scopeLabel(scope).toLowerCase()}s…',
                hintStyle: TextStyle(fontSize: 13, color: tokens.textTertiary, fontWeight: FontWeight.w400),
                border: InputBorder.none,
                isDense: true,
                contentPadding: EdgeInsets.zero,
              ),
              cursorColor: tokens.primary,
              cursorWidth: 1.5,
            ),
          ),
          if (hasText) ...[
            const SizedBox(width: 4),
            GestureDetector(
              onTap: controller.clear,
              child: Icon(Icons.cancel_rounded, size: 14, color: tokens.textTertiary),
            ),
          ],
          const SizedBox(width: 6),
          // Divider between field and scope picker
          Container(width: 0.5, height: 18, color: tokens.border),
          // Scope picker
          _ScopePicker(scope: scope, onChanged: onScopeChanged),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Scope dropdown inside the search box
// ---------------------------------------------------------------------------

class _ScopePicker extends StatelessWidget {
  const _ScopePicker({required this.scope, required this.onChanged});

  final SearchScope scope;
  final ValueChanged<SearchScope> onChanged;

  String _label(SearchScope s) => switch (s) {
    SearchScope.all => 'All',
    SearchScope.topic => 'Topic',
    SearchScope.value => 'Value',
  };

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;

    return PopupMenuButton<SearchScope>(
      onSelected: onChanged,
      color: tokens.surface,
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: BorderSide(color: tokens.border, width: 0.5),
      ),
      offset: const Offset(0, 36),
      itemBuilder: (_) => SearchScope.values
          .map(
            (s) => PopupMenuItem<SearchScope>(
              value: s,
              height: 36,
              child: Text(
                _label(s),
                style: TextStyle(fontSize: 13, fontWeight: s == scope ? FontWeight.w600 : FontWeight.w400, color: s == scope ? tokens.primary : tokens.textSecondary),
              ),
            ),
          )
          .toList(),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              _label(scope),
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: tokens.textSecondary),
            ),
            const SizedBox(width: 2),
            Icon(Icons.keyboard_arrow_down_rounded, size: 13, color: tokens.textTertiary),
          ],
        ),
      ),
    );
  }
}
