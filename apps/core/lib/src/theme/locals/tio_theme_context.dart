import 'package:flutter/material.dart';

import '../tio_colors.dart';
import '../tio_radius.dart';
import '../tio_shadows.dart';
import '../tio_spacing.dart';
import '../tokens/components/tio_button_tokens.dart';
import '../tokens/components/tio_card_tokens.dart';
import '../tokens/components/tio_input_tokens.dart';
import '../tokens/components/tio_navigation_tokens.dart';
import '../tokens/components/tio_sheet_tokens.dart';
import '../tokens/domain/tio_domain_colors.dart';

extension TioThemeContext on BuildContext {
  TioColors get tioColors {
    return Theme.of(this).extension<TioColors>() ?? TioColors.light;
  }

  TioShadows get tioShadows {
    return Theme.of(this).extension<TioShadows>() ?? TioShadows.standard;
  }

  Type get tioSpacing => TioSpacing;
  Type get tioRadius => TioRadius;
  Type get tioButtonTokens => TioButtonTokens;
  Type get tioCardTokens => TioCardTokens;
  Type get tioInputTokens => TioInputTokens;
  Type get tioNavigationTokens => TioNavigationTokens;
  Type get tioSheetTokens => TioSheetTokens;
  Type get tioDomainColors => TioDomainColors;
}
