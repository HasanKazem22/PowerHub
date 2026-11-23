import 'package:flutter/material.dart';

import '../../core/theme/app_spacing.dart';
import '../widgets/misc/app_glass.dart';
import '../widgets/navigation/app_bottom_nav.dart';
import '../widgets/navigation/app_header_action.dart';

/// How far a header button's tap area reaches past its disc on each side.
const _tapInset = (AppSpacing.headerActionTap - AppSpacing.headerAction) / 2;

/// The app's one page scaffold, so every screen shares the same frame:
///
/// * a frosted-glass app bar with the title on the left and round
///   [AppHeaderAction]s on the right (spaced automatically — pass just the
///   actions);
/// * a round back button on pushed pages;
/// * a scrolling list with the page's side padding that runs smoothly under
///   the frosted app bar and the bottom navigation.
///
/// Pass [children] for the usual scrolling page, or [body] for a custom one.
class AppPage extends StatelessWidget {
  const AppPage({
    super.key,
    this.title,
    this.titleWidget,
    this.actions = const [],
    this.children,
    this.body,
    this.bottomBar,
  }) : assert((children == null) != (body == null), 'Pass either children or body');

  final String? title;

  /// Replaces [title] (e.g. the wordmark on Home).
  final Widget? titleWidget;

  /// Usually [AppHeaderAction]s.
  final List<Widget> actions;
  final List<Widget>? children;
  final Widget? body;

  /// Pinned under the content, e.g. a "Save" button on a form.
  final Widget? bottomBar;

  @override
  Widget build(BuildContext context) {
    final scrolling = children != null;
    final canPop = ModalRoute.of(context)?.impliesAppBarDismissal ?? false;

    return Scaffold(
      // A scrolling page runs underneath the frosted app bar and shows through it.
      extendBodyBehindAppBar: scrolling,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        // The button's tap area overhangs its disc; shift it so the disc lines up with the page edge.
        leadingWidth: canPop ? AppSpacing.page + AppSpacing.headerActionTap - _tapInset : null,
        leading: canPop
            ? Padding(
                padding: const EdgeInsets.only(left: AppSpacing.page - _tapInset),
                child: Center(
                  child: AppHeaderAction(
                    icon: Icons.arrow_back_rounded,
                    tooltip: MaterialLocalizations.of(context).backButtonTooltip,
                    onPressed: () => Navigator.maybePop(context),
                  ),
                ),
              )
            : null,
        titleSpacing: canPop ? AppSpacing.sm : AppSpacing.page,
        title: titleWidget ?? (title == null ? null : Text(title!)),
        actions: [
          // Tap areas sit side by side; their overhang already gives the discs an 8px gap.
          ...actions,
          if (actions.isNotEmpty) const SizedBox(width: AppSpacing.page - _tapInset),
        ],
        backgroundColor: Colors.transparent,
        flexibleSpace: const AppGlass(edge: AppGlassEdge.bottom, shadow: false, child: SizedBox.expand()),
      ),
      body: scrolling
          ? Builder(
              // Builder: reads the Scaffold's insets (app bar on top, bottom bar below).
              builder: (context) => ListView(
                padding: EdgeInsets.fromLTRB(
                  AppSpacing.page,
                  MediaQuery.paddingOf(context).top + AppSpacing.md,
                  AppSpacing.page,
                  AppSpacing.xxxl + AppBottomNav.bottomInset(context),
                ),
                children: children!,
              ),
            )
          : body,
      bottomNavigationBar: bottomBar == null
          ? null
          : SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(AppSpacing.page, AppSpacing.sm, AppSpacing.page, AppSpacing.md),
                child: bottomBar,
              ),
            ),
    );
  }
}
