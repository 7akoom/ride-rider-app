import 'package:flutter/material.dart';

import '../../../core/l10n/l10n.dart';
import '../../design_context.dart';
import '../../tokens/metrics.dart';
import '../buttons/app_icon_button.dart';

/// The top bar: back button at the start (right in Arabic and Kurdish), the title, and
/// optional actions at the end. Never a logo or avatar.
class AppTopBar extends StatelessWidget implements PreferredSizeWidget {
  const AppTopBar({
    super.key,
    this.title,
    this.actions = const [],
    this.showBack,
    this.onBack,
  });

  final String? title;
  final List<Widget> actions;

  /// Defaults to "there is a screen to go back to".
  final bool? showBack;
  final VoidCallback? onBack;

  static const double height = 64;

  @override
  Size get preferredSize => const Size.fromHeight(height);

  @override
  Widget build(BuildContext context) {
    final canPop = showBack ?? Navigator.of(context).canPop();

    return SafeArea(
      bottom: false,
      child: SizedBox(
        height: height,
        child: Padding(
          padding: const EdgeInsetsDirectional.symmetric(horizontal: Space.gutter),
          child: Row(
            children: [
              if (canPop) ...[
                AppIconButton(
                  icon: Icons.arrow_back,
                  semanticLabel: context.l10n.actionBack,
                  onPressed: onBack ?? () => Navigator.of(context).maybePop(),
                ),
                const SizedBox(width: Space.x3),
              ],
              Expanded(
                child: title == null
                    ? const SizedBox.shrink()
                    : Semantics(
                        header: true,
                        child: Text(
                          title!,
                          style: context.typo.h3,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
              ),
              for (final action in actions) ...[
                const SizedBox(width: Space.x2),
                action,
              ],
            ],
          ),
        ),
      ),
    );
  }
}
