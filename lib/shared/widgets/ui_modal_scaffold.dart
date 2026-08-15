import 'package:flutter/material.dart';
import '../../generated/l10n.dart';
import '../../theme/accent_contrast.dart';
import '../../theme/app_tokens/app_tokens.dart';
import '../../theme/ui_layout.dart';

class UiModalScaffold extends StatelessWidget {
  const UiModalScaffold({super.key, required this.title, this.isEditing = false, this.onDelete, required this.body, required this.onCancel, required this.onSubmit, this.submitLabel = 'Save'});

  final String title;
  final bool isEditing;
  final VoidCallback? onDelete;
  final Widget body;
  final VoidCallback onCancel;
  final VoidCallback onSubmit;
  final String submitLabel;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final accent = tokens.primary;
    final layout = context.uiLayout;
    final panelRadius = BorderRadius.all(Radius.circular(tokens.panelRadius));
    final maxH = MediaQuery.sizeOf(context).height * 0.88;
    final bottomInset = MediaQuery.viewInsetsOf(context).bottom;

    return Dialog(
      backgroundColor: tokens.surface,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(borderRadius: panelRadius),
      insetPadding: const EdgeInsets.symmetric(horizontal: 40, vertical: 24),
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: 560, maxHeight: maxH),
        child: ClipRRect(
          borderRadius: panelRadius,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 20, 12, 10),
                child: Row(
                  children: [
                    Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
                    const Spacer(),
                    if (isEditing && onDelete != null)
                      IconButton(
                        onPressed: onDelete,
                        icon: Icon(Icons.delete_outline_rounded, color: tokens.error),
                        padding: const EdgeInsets.all(8),
                        constraints: const BoxConstraints(),
                        visualDensity: VisualDensity.compact,
                        tooltip: S.of(context).delete,
                      ),
                    IconButton(
                      onPressed: onCancel,
                      icon: Icon(Icons.close_rounded, color: tokens.textSecondary),
                      padding: const EdgeInsets.all(8),
                      constraints: const BoxConstraints(),
                      visualDensity: VisualDensity.compact,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 4),
              Divider(height: 0.5, thickness: 0.5, color: tokens.border),
              Flexible(
                child: SingleChildScrollView(padding: EdgeInsets.fromLTRB(24, layout.isCompact ? 16 : 20, 24, 24), child: body),
              ),
              Divider(height: 0.5, thickness: 0.5, color: tokens.border),
              Padding(
                padding: EdgeInsets.fromLTRB(24, 14, 24, 20 + bottomInset),
                child: Row(
                  children: [
                    const Spacer(),
                    TextButton(onPressed: onCancel, child: Text(S.of(context).cancel)),
                    const SizedBox(width: 8),
                    FilledButton(
                      onPressed: onSubmit,
                      style: FilledButton.styleFrom(backgroundColor: accentFillForWhiteForeground(accent), foregroundColor: tokens.onPrimary),
                      child: Text(submitLabel),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
