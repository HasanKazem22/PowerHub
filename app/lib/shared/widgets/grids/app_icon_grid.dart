import 'package:flutter/material.dart';

import '../../../core/theme/app_spacing.dart';
import '../buttons/app_pill_button.dart';
import '../cards/app_card.dart';
import 'app_icon_tile.dart';

/// White panel of icon tiles in equal columns. Shows [collapsedRows] full
/// rows with the top of the next fading out under a "See more" pill; tapping
/// it opens the rest in place, "Show less" folds them away. Anything passed as
/// [footer] (e.g. a promo banner) sits in the same panel below the tiles.
class AppIconGrid extends StatefulWidget {
  const AppIconGrid({super.key, required this.tiles, this.columns = 4, this.collapsedRows = 2, this.footer});

  final List<AppIconTileData> tiles;
  final int columns;
  final int collapsedRows;
  final Widget? footer;

  @override
  State<AppIconGrid> createState() => _AppIconGridState();
}

class _AppIconGridState extends State<AppIconGrid> {
  /// How much of the next row shows while collapsed: the discs, no labels.
  static const double _peekHeight = 46;

  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final rows = <List<AppIconTileData>>[
      for (var i = 0; i < widget.tiles.length; i += widget.columns) widget.tiles.skip(i).take(widget.columns).toList(),
    ];
    final canCollapse = rows.length > widget.collapsedRows;

    return AppCard(
      radius: AppRadius.panel,
      padding: const EdgeInsets.fromLTRB(AppSpacing.sm, AppSpacing.lg, AppSpacing.sm, AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AnimatedSize(
            duration: const Duration(milliseconds: 320),
            curve: Curves.easeInOutCubic,
            alignment: Alignment.topCenter,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                for (var i = 0; i < rows.length; i++)
                  if (_expanded || !canCollapse || i < widget.collapsedRows) ...[
                    if (i > 0) const SizedBox(height: 10),
                    _Row(tiles: rows[i], columns: widget.columns),
                  ],
                if (canCollapse && !_expanded) ...[
                  const SizedBox(height: 10),
                  _Peek(
                    height: _peekHeight,
                    row: _Row(tiles: rows[widget.collapsedRows], columns: widget.columns),
                    pill: AppPillButton(
                      label: 'See more',
                      icon: Icons.keyboard_arrow_down_rounded,
                      variant: AppPillVariant.light,
                      onPressed: () => setState(() => _expanded = true),
                    ),
                  ),
                ],
                if (canCollapse && _expanded) ...[
                  const SizedBox(height: 14),
                  Center(
                    child: AppPillButton(
                      label: 'Show less',
                      icon: Icons.keyboard_arrow_up_rounded,
                      variant: AppPillVariant.light,
                      onPressed: () => setState(() => _expanded = false),
                    ),
                  ),
                ],
              ],
            ),
          ),
          if (widget.footer != null) ...[
            const SizedBox(height: AppSpacing.lg),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xs),
              child: widget.footer,
            ),
          ],
        ],
      ),
    );
  }
}

/// One row of equal-width columns; a short last row keeps its columns.
class _Row extends StatelessWidget {
  const _Row({required this.tiles, required this.columns});
  final List<AppIconTileData> tiles;
  final int columns;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (var i = 0; i < columns; i++)
          Expanded(child: i < tiles.length ? AppIconTile(data: tiles[i]) : const SizedBox.shrink()),
      ],
    );
  }
}

/// The top of the next row fading into the panel, with the pill over it.
class _Peek extends StatelessWidget {
  const _Peek({required this.row, required this.height, required this.pill});
  final Widget row;
  final double height;
  final Widget pill;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: height,
      child: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.center,
        children: [
          Positioned.fill(
            child: IgnorePointer(
              child: ShaderMask(
                blendMode: BlendMode.dstIn,
                shaderCallback: (bounds) => const LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Color(0x99000000), Color(0x00000000)],
                ).createShader(bounds),
                child: ClipRect(
                  child: OverflowBox(alignment: Alignment.topCenter, maxHeight: double.infinity, child: row),
                ),
              ),
            ),
          ),
          pill,
        ],
      ),
    );
  }
}
