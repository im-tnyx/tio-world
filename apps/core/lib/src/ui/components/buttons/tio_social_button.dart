import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../../theme/theme.dart';
import 'tio_button.dart';

enum TioSocialButtonType { google, truecaller, email, phone }

enum TioSocialButtonLayout { fullWidth, round }

/// Reusable, unified social authentication and provider action component.
///
/// The default constructors preserve the existing full-width button treatment.
/// [TioSocialButton.round] provides the shared round icon + visible label
/// treatment used when multiple provider/mode actions are presented together.
class TioSocialButton extends StatelessWidget {
  const TioSocialButton({
    required this.label,
    required this.onPressed,
    required this.type,
    super.key,
    this.enabled = true,
    this.loading = false,
    this.expand = true,
    this.layout = TioSocialButtonLayout.fullWidth,
  });

  const TioSocialButton.google({
    required this.onPressed,
    this.label = 'Continue with Google',
    super.key,
    this.enabled = true,
    this.loading = false,
    this.expand = true,
  })  : type = TioSocialButtonType.google,
        layout = TioSocialButtonLayout.fullWidth;

  const TioSocialButton.truecaller({
    required this.onPressed,
    this.label = 'Continue with Truecaller',
    super.key,
    this.enabled = true,
    this.loading = false,
    this.expand = true,
  })  : type = TioSocialButtonType.truecaller,
        layout = TioSocialButtonLayout.fullWidth;

  const TioSocialButton.email({
    required this.onPressed,
    this.label = 'Continue with Email',
    super.key,
    this.enabled = true,
    this.loading = false,
    this.expand = true,
  })  : type = TioSocialButtonType.email,
        layout = TioSocialButtonLayout.fullWidth;

  const TioSocialButton.phone({
    required this.onPressed,
    this.label = 'Continue with Phone',
    super.key,
    this.enabled = true,
    this.loading = false,
    this.expand = true,
  })  : type = TioSocialButtonType.phone,
        layout = TioSocialButtonLayout.fullWidth;

  const TioSocialButton.round({
    required this.type,
    required this.label,
    required this.onPressed,
    super.key,
    this.enabled = true,
    this.loading = false,
  })  : expand = false,
        layout = TioSocialButtonLayout.round;

  final String label;
  final VoidCallback? onPressed;
  final TioSocialButtonType type;
  final bool enabled;
  final bool loading;
  final bool expand;
  final TioSocialButtonLayout layout;

  @override
  Widget build(BuildContext context) {
    if (layout == TioSocialButtonLayout.round) {
      return _buildRoundAction(context);
    }
    return _buildFullWidthAction();
  }

  Widget _buildFullWidthAction() {
    return TioButton.secondary(
      label: label,
      onPressed: onPressed,
      enabled: enabled,
      loading: loading,
      expand: expand,
      leading: Padding(
        padding: const EdgeInsets.only(right: TioSpacing.sm),
        child: _providerIcon(size: TioSize.dp20),
      ),
    );
  }

  Widget _buildRoundAction(BuildContext context) {
    final colors = context.tioColors;
    final textTheme = Theme.of(context).textTheme;
    final isInteractive = enabled && !loading && onPressed != null;

    return Semantics(
      button: true,
      enabled: isInteractive,
      label: label,
      child: ExcludeSemantics(
        child: SizedBox(
          width: TioSize.dp72,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Material(
                color: Colors.transparent,
                child: InkResponse(
                  onTap: isInteractive ? onPressed : null,
                  containedInkWell: true,
                  customBorder: const CircleBorder(),
                  radius: TioSize.dp28,
                  child: Container(
                    width: TioSize.dp56,
                    height: TioSize.dp56,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: colors.surfaceRaised,
                      border: Border.all(
                        color: colors.outlineStrong.withValues(
                          alpha: TioOpacity.opacity30,
                        ),
                        width: TioStroke.width1,
                      ),
                    ),
                    child: loading
                        ? SizedBox(
                            width: TioSize.dp20,
                            height: TioSize.dp20,
                            child: CircularProgressIndicator(
                              strokeWidth: TioStroke.width2,
                              color: colors.primary,
                            ),
                          )
                        : _providerIcon(size: TioSize.dp22),
                  ),
                ),
              ),
              const SizedBox(height: TioSpacing.sm),
              Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: textTheme.labelSmall?.copyWith(
                  color: enabled ? colors.textPrimary : colors.textMuted,
                  fontWeight: TioFontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _providerIcon({required double size}) {
    switch (type) {
      case TioSocialButtonType.truecaller:
        return SvgPicture.asset(
          'assets/svg_icon/ic_trucaller.svg',
          package: 'tio_core',
          width: size,
          height: size,
        );
      case TioSocialButtonType.google:
        return SvgPicture.asset(
          'assets/svg_icon/ic_google.svg',
          package: 'tio_core',
          width: size,
          height: size,
        );
      case TioSocialButtonType.email:
        return Icon(Icons.mail_outline, size: size);
      case TioSocialButtonType.phone:
        return Icon(Icons.phone_outlined, size: size);
    }
  }
}
