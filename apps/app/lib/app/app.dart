import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tio_core/core.dart';
import 'package:tio_feature_auth/auth.dart';

import 'app_theme.dart';
import 'auth_phone_otp_providers.dart';
import 'router.dart';

class TioApp extends ConsumerWidget {
  const TioApp({super.key, this.themeConfig});

  final TioThemeConfig? themeConfig;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(goRouterProvider);
    final resolvedThemeConfig =
        themeConfig ?? ref.watch(appThemeControllerProvider).themeConfig;
    final requestPhoneOtpUseCase = ref.watch(requestPhoneOtpUseCaseProvider);
    final resendPhoneOtpUseCase = ref.watch(resendPhoneOtpUseCaseProvider);
    final verifyPhoneOtpUseCase = ref.watch(verifyPhoneOtpUseCaseProvider);

    return MaterialApp.router(
      title: 'Tio',
      routerConfig: router,
      debugShowCheckedModeBanner: false,
      builder: (context, child) {
        return TioTheme(
          config: resolvedThemeConfig,
          child: Builder(
            builder: (context) {
              final brightness = Theme.of(context).brightness;
              final iconBrightness = brightness == Brightness.light
                  ? Brightness.dark
                  : Brightness.light;

              return PhoneOtpAuthScope(
                requestPhoneOtpUseCase: requestPhoneOtpUseCase,
                resendPhoneOtpUseCase: resendPhoneOtpUseCase,
                verifyPhoneOtpUseCase: verifyPhoneOtpUseCase,
                child: AnnotatedRegion<SystemUiOverlayStyle>(
                  value: SystemUiOverlayStyle(
                    systemNavigationBarColor: Colors.transparent,
                    systemNavigationBarDividerColor: Colors.transparent,
                    systemNavigationBarIconBrightness: iconBrightness,
                    systemNavigationBarContrastEnforced: false,
                    statusBarColor: Colors.transparent,
                    statusBarIconBrightness: iconBrightness,
                    statusBarBrightness: brightness,
                  ),
                  child: child ?? const SizedBox.shrink(),
                ),
              );
            },
          ),
        );
      },
    );
  }
}
