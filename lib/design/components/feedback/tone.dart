import 'package:flutter/material.dart';

import '../../tokens/palette.dart';

/// The meaning of a message, which decides its colours and icon.
enum Tone { info, success, warning, danger }

extension ToneStyle on Tone {
  Color foreground(Palette p) => switch (this) {
        Tone.info => p.info,
        Tone.success => p.success,
        Tone.warning => p.warning,
        Tone.danger => p.danger,
      };

  Color background(Palette p) => switch (this) {
        Tone.info => p.infoSoft,
        Tone.success => p.successSoft,
        Tone.warning => p.warningSoft,
        Tone.danger => p.dangerSoft,
      };

  IconData get icon => switch (this) {
        Tone.info => Icons.info_outline,
        Tone.success => Icons.check_circle_outline,
        Tone.warning => Icons.warning_amber_rounded,
        Tone.danger => Icons.error_outline,
      };
}
