import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'tio_button.dart';

enum TioSocialButtonType { google, truecaller, email, phone }

/// Reusable, unified social authentication and provider button component.
///
/// Built on top of core [TioButton] to ensure 100% identical styling,
/// height, corner radius, touch feedback, and token consistency across
/// all screens in the app using official SVG brand assets.
class TioSocialButton extends StatelessWidget {
  const TioSocialButton({
    required this.label,
    required this.onPressed,
    required this.type,
    super.key,
    this.enabled = true,
    this.loading = false,
    this.expand = true,
  });

  const TioSocialButton.google({
    required this.onPressed,
    this.label = 'Continue with Google',
    super.key,
    this.enabled = true,
    this.loading = false,
    this.expand = true,
  }) : type = TioSocialButtonType.google;

  const TioSocialButton.truecaller({
    required this.onPressed,
    this.label = 'Continue with Truecaller',
    super.key,
    this.enabled = true,
    this.loading = false,
    this.expand = true,
  }) : type = TioSocialButtonType.truecaller;

  const TioSocialButton.email({
    required this.onPressed,
    this.label = 'Continue with Email',
    super.key,
    this.enabled = true,
    this.loading = false,
    this.expand = true,
  }) : type = TioSocialButtonType.email;

  const TioSocialButton.phone({
    required this.onPressed,
    this.label = 'Continue with Phone',
    super.key,
    this.enabled = true,
    this.loading = false,
    this.expand = true,
  }) : type = TioSocialButtonType.phone;

  final String label;
  final VoidCallback? onPressed;
  final TioSocialButtonType type;
  final bool enabled;
  final bool loading;
  final bool expand;

  @override
  Widget build(BuildContext context) {
    switch (type) {
      case TioSocialButtonType.truecaller:
        return TioButton.secondary(
          label: label,
          onPressed: onPressed,
          enabled: enabled,
          loading: loading,
          expand: expand,
          leading: Padding(
            padding: const EdgeInsets.only(right: 8),
            child: SvgPicture.asset(
              'assets/svg_icon/ic_trucaller.svg',
              package: 'tio_core',
              width: 20,
              height: 20,
            ),
          ),
        );

      case TioSocialButtonType.google:
        return TioButton.secondary(
          label: label,
          onPressed: onPressed,
          enabled: enabled,
          loading: loading,
          expand: expand,
          leading: Padding(
            padding: const EdgeInsets.only(right: 8),
            child: SvgPicture.asset(
              'assets/svg_icon/ic_google.svg',
              package: 'tio_core',
              width: 20,
              height: 20,
            ),
          ),
        );

      case TioSocialButtonType.email:
        return TioButton.secondary(
          label: label,
          onPressed: onPressed,
          enabled: enabled,
          loading: loading,
          expand: expand,
          leading: const Padding(
            padding: EdgeInsets.only(right: 8),
            child: Icon(Icons.mail_outline, size: 20),
          ),
        );

      case TioSocialButtonType.phone:
        return TioButton.secondary(
          label: label,
          onPressed: onPressed,
          enabled: enabled,
          loading: loading,
          expand: expand,
          leading: const Padding(
            padding: EdgeInsets.only(right: 8),
            child: Icon(Icons.phone_outlined, size: 20),
          ),
        );
    }
  }
}
