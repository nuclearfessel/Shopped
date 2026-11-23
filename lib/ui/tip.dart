import 'package:flutter/material.dart';

/// A tooltip with the app's standard timing. Every control the user can click
/// or tap should have one; wrap buttons (which have no tooltip of their own)
/// and the text of tappable rows in a [Tip].
///
/// Pass [triggerMode] as [TooltipTriggerMode.manual] when a long-press on the
/// child starts another gesture (for example category drag). Mouse hover still
/// shows the tip; touch long-press does not.
class Tip extends StatelessWidget {
  const Tip(this.message, {super.key, required this.child, this.triggerMode});

  final String message;
  final Widget child;
  final TooltipTriggerMode? triggerMode;

  @override
  Widget build(BuildContext context) => Tooltip(
    message: message,
    waitDuration: const Duration(milliseconds: 500),
    triggerMode: triggerMode,
    child: child,
  );
}

/// Compact More-menu row (40 logical px) with a [Tip] on the label.
PopupMenuItem<String> tipMenuItem({
  required String value,
  required String tip,
  required String label,
}) => PopupMenuItem<String>(
  value: value,
  height: 40,
  child: Tip(tip, child: Text(label)),
);
