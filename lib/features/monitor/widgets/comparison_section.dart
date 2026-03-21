import 'dart:convert';

import 'package:flutter/material.dart';

import '../../../models/topic_node_value.dart';
import '../../../shared/format_helpers.dart';
import '../../../shared/widgets/copy_button.dart';
import '../../../shared/widgets/json_highlighter.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/app_tokens/app_tokens.dart';

/// Shows a side-by-side comparison of two historical messages,
/// with optional unified diff view.
class ComparisonSection extends StatefulWidget {
  const ComparisonSection({super.key, required this.selected, required this.previous});

  final TopicNodeValue selected;
  final TopicNodeValue previous;

  @override
  State<ComparisonSection> createState() => _ComparisonSectionState();
}

class _ComparisonSectionState extends State<ComparisonSection> {
  bool _expanded = true;
  bool _diffMode = false;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header row with expand toggle and diff toggle
        Row(
          children: [
            MouseRegion(
              cursor: SystemMouseCursors.click,
              child: GestureDetector(
                onTap: () => setState(() => _expanded = !_expanded),
                behavior: HitTestBehavior.opaque,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    AnimatedRotation(
                      turns: _expanded ? 0 : -0.25,
                      duration: const Duration(milliseconds: 150),
                      child: Icon(Icons.expand_more_rounded, size: 16, color: tokens.textTertiary),
                    ),
                    const SizedBox(width: 4),
                    Icon(Icons.compare_arrows_rounded, size: 13, color: tokens.textTertiary),
                    const SizedBox(width: 6),
                    Text(
                      'COMPARE WITH PREVIOUS',
                      style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, letterSpacing: 0.8, color: tokens.textTertiary),
                    ),
                  ],
                ),
              ),
            ),
            const Spacer(),
            if (_expanded) _DiffModeToggle(diffMode: _diffMode, onChanged: (v) => setState(() => _diffMode = v)),
          ],
        ),
        if (_expanded) ...[
          const SizedBox(height: 8),
          if (_diffMode)
            _DiffView(selected: widget.selected, previous: widget.previous)
          else
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: _ComparePanel(label: 'Previous (#${widget.previous.seq})', timestamp: widget.previous.receivedAt, value: widget.previous, color: AppColors.info500),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _ComparePanel(label: 'Selected (#${widget.selected.seq})', timestamp: widget.selected.receivedAt, value: widget.selected, color: AppColors.warning500),
                ),
              ],
            ),
        ],
      ],
    );
  }
}

// ── Diff mode toggle ────────────────────────────────────────────────────

class _DiffModeToggle extends StatelessWidget {
  const _DiffModeToggle({required this.diffMode, required this.onChanged});

  final bool diffMode;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    return Container(
      decoration: BoxDecoration(
        color: tokens.surface,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: tokens.border, width: 0.5),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _ToggleOption(label: 'Side by side', selected: !diffMode, onTap: () => onChanged(false)),
          _ToggleOption(label: 'Diff', selected: diffMode, onTap: () => onChanged(true)),
        ],
      ),
    );
  }
}

class _ToggleOption extends StatefulWidget {
  const _ToggleOption({required this.label, required this.selected, required this.onTap});

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  State<_ToggleOption> createState() => _ToggleOptionState();
}

class _ToggleOptionState extends State<_ToggleOption> {
  bool _hovering = false;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hovering = true),
      onExit: (_) => setState(() => _hovering = false),
      child: GestureDetector(
        onTap: widget.onTap,
        behavior: HitTestBehavior.opaque,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
          decoration: BoxDecoration(
            color: widget.selected
                ? tokens.primary.withValues(alpha: 0.1)
                : _hovering
                ? tokens.elevated
                : Colors.transparent,
            borderRadius: BorderRadius.circular(5),
          ),
          child: Text(
            widget.label,
            style: TextStyle(fontSize: 9, fontWeight: FontWeight.w600, color: widget.selected ? tokens.primary : tokens.textTertiary),
          ),
        ),
      ),
    );
  }
}

// ── Diff view ───────────────────────────────────────────────────────────

class _DiffRow {
  const _DiffRow({this.left, this.right});
  final _DiffLine? left;
  final _DiffLine? right;
}

class _DiffView extends StatelessWidget {
  const _DiffView({required this.selected, required this.previous});

  final TopicNodeValue selected;
  final TopicNodeValue previous;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final oldLines = _normalizePayload(previous.payload).split('\n');
    final newLines = _normalizePayload(selected.payload).split('\n');
    final diffLines = _computeDiff(oldLines, newLines);
    final rows = _buildRows(diffLines);

    const monoStyle = TextStyle(fontFamily: 'SF Mono, Menlo, monospace', fontSize: 11, height: 1.5);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Left panel — previous
        Expanded(
          child: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: tokens.inputFill,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AppColors.warning500.withValues(alpha: 0.2), width: 0.5),
            ),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [_diffColumnHeader(tokens, 'Previous (#${previous.seq})', previous.receivedAt, AppColors.info500), const SizedBox(height: 4), for (final row in rows) _diffCell(row.left, monoStyle, tokens)]),
            ),
          ),
        ),
        const SizedBox(width: 6),
        // Right panel — selected
        Expanded(
          child: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: tokens.inputFill,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AppColors.warning500.withValues(alpha: 0.2), width: 0.5),
            ),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [_diffColumnHeader(tokens, 'Selected (#${selected.seq})', selected.receivedAt, AppColors.warning500), const SizedBox(height: 4), for (final row in rows) _diffCell(row.right, monoStyle, tokens)]),
            ),
          ),
        ),
      ],
    );
  }

  Widget _diffColumnHeader(AppTokens tokens, String label, DateTime timestamp, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 6,
              height: 6,
              decoration: BoxDecoration(color: color, shape: BoxShape.circle),
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: color, letterSpacing: 0.3),
            ),
          ],
        ),
        const SizedBox(height: 2),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(width: 12),
            Icon(Icons.access_time_rounded, size: 9, color: tokens.textTertiary),
            const SizedBox(width: 3),
            Text(formatTimestamp(timestamp), style: TextStyle(fontSize: 9, color: tokens.textTertiary)),
          ],
        ),
      ],
    );
  }

  Widget _diffCell(_DiffLine? line, TextStyle base, AppTokens tokens) {
    if (line == null) {
      return SizedBox(height: base.fontSize! * (base.height ?? 1.5), child: const SizedBox.shrink());
    }

    final isChange = line.type != _DiffLineType.same;
    final color = switch (line.type) {
      _DiffLineType.removed => AppColors.error500,
      _DiffLineType.added => AppColors.success500,
      _DiffLineType.same => tokens.textSecondary,
    };
    final bgColor = switch (line.type) {
      _DiffLineType.removed => AppColors.error500.withValues(alpha: 0.08),
      _DiffLineType.added => AppColors.success500.withValues(alpha: 0.08),
      _DiffLineType.same => Colors.transparent,
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 0.5),
      color: bgColor,
      child: Text(
        line.text,
        style: base.copyWith(color: color, fontWeight: isChange ? FontWeight.w600 : FontWeight.normal),
      ),
    );
  }

  static List<_DiffRow> _buildRows(List<_DiffLine> diff) {
    final rows = <_DiffRow>[];
    var i = 0;
    while (i < diff.length) {
      final line = diff[i];
      if (line.type == _DiffLineType.same) {
        rows.add(_DiffRow(left: line, right: line));
        i++;
      } else if (line.type == _DiffLineType.removed) {
        final removed = <_DiffLine>[];
        while (i < diff.length && diff[i].type == _DiffLineType.removed) {
          removed.add(diff[i]);
          i++;
        }
        final added = <_DiffLine>[];
        while (i < diff.length && diff[i].type == _DiffLineType.added) {
          added.add(diff[i]);
          i++;
        }
        final count = removed.length > added.length ? removed.length : added.length;
        for (var j = 0; j < count; j++) {
          rows.add(_DiffRow(left: j < removed.length ? removed[j] : null, right: j < added.length ? added[j] : null));
        }
      } else {
        rows.add(_DiffRow(left: null, right: line));
        i++;
      }
    }
    return rows;
  }

  static String _normalizePayload(String payload) {
    try {
      final parsed = jsonDecode(payload);
      return const JsonEncoder.withIndent('  ').convert(parsed);
    } catch (_) {
      return payload;
    }
  }
}

// ── Compare panel ───────────────────────────────────────────────────────

class _ComparePanel extends StatelessWidget {
  const _ComparePanel({required this.label, required this.timestamp, required this.value, required this.color});

  final String label;
  final DateTime timestamp;
  final TopicNodeValue value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final isJson = JsonHighlighter.isJson(value.payload);

    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: tokens.inputFill,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.25), width: 0.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 6,
                height: 6,
                decoration: BoxDecoration(color: color, shape: BoxShape.circle),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  label,
                  style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: color, letterSpacing: 0.3),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              CopyButton(text: value.payload, size: 12),
            ],
          ),
          const SizedBox(height: 3),
          Row(
            children: [
              const SizedBox(width: 12),
              Icon(Icons.access_time_rounded, size: 9, color: tokens.textTertiary),
              const SizedBox(width: 3),
              Text(formatTimestamp(timestamp), style: TextStyle(fontSize: 9, color: tokens.textTertiary)),
            ],
          ),
          const SizedBox(height: 8),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: isJson
                ? JsonHighlighter(source: value.payload)
                : SelectableText(
                    value.payload,
                    style: TextStyle(fontFamily: 'SF Mono, Menlo, monospace', fontSize: 11, color: tokens.textPrimary, height: 1.5),
                  ),
          ),
        ],
      ),
    );
  }
}

// ── Diff types and algorithm ────────────────────────────────────────────

enum _DiffLineType { same, removed, added }

class _DiffLine {
  const _DiffLine(this.type, this.text);
  final _DiffLineType type;
  final String text;
}

/// Simple line-based diff using longest common subsequence.
List<_DiffLine> _computeDiff(List<String> oldLines, List<String> newLines) {
  final m = oldLines.length;
  final n = newLines.length;

  // Build LCS table.
  final dp = List.generate(m + 1, (_) => List.filled(n + 1, 0));
  for (var i = 1; i <= m; i++) {
    for (var j = 1; j <= n; j++) {
      if (oldLines[i - 1] == newLines[j - 1]) {
        dp[i][j] = dp[i - 1][j - 1] + 1;
      } else {
        dp[i][j] = dp[i - 1][j] > dp[i][j - 1] ? dp[i - 1][j] : dp[i][j - 1];
      }
    }
  }

  // Backtrack to produce diff.
  final result = <_DiffLine>[];
  var i = m, j = n;
  while (i > 0 || j > 0) {
    if (i > 0 && j > 0 && oldLines[i - 1] == newLines[j - 1]) {
      result.add(_DiffLine(_DiffLineType.same, oldLines[i - 1]));
      i--;
      j--;
    } else if (j > 0 && (i == 0 || dp[i][j - 1] >= dp[i - 1][j])) {
      result.add(_DiffLine(_DiffLineType.added, newLines[j - 1]));
      j--;
    } else {
      result.add(_DiffLine(_DiffLineType.removed, oldLines[i - 1]));
      i--;
    }
  }

  return result.reversed.toList();
}
