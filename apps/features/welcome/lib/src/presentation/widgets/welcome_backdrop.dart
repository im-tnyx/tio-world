import 'package:flutter/material.dart';
import 'package:tio_core/core.dart';

class WelcomeBackdrop extends StatelessWidget {
  const WelcomeBackdrop({super.key});

  static const _bottomCoverageFactor = 0.50;
  static const _topOverlayAlphas = <double>[
    TioOpacity.opacity18,
    TioOpacity.opacity08,
    TioOpacity.opacity0,
  ];
  static const _topOverlayStops = <double>[0.0, 0.35, 1.0];
  static const _bottomOverlayAlphas = <double>[
    TioOpacity.opacity0,
    TioOpacity.opacity30,
    TioOpacity.opacity100,
    TioOpacity.opacity100,
    TioOpacity.opacity100,
    TioOpacity.opacity100,
  ];
  static const _bottomOverlayStops = <double>[
    0.0,
    0.20,
    0.50,
    0.80,
    0.90,
    1.0,
  ];

  @override
  Widget build(BuildContext context) {
    final themeColor = Theme.of(context).scaffoldBackgroundColor;
    final topOverlayColors = _topOverlayAlphas
        .map((alpha) => themeColor.withValues(alpha: alpha))
        .toList(growable: false);
    final bottomOverlayColors = _bottomOverlayAlphas
        .map((alpha) => themeColor.withValues(alpha: alpha))
        .toList(growable: false);

    return Stack(
      children: [
        Positioned.fill(
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: topOverlayColors,
                stops: _topOverlayStops,
              ),
            ),
          ),
        ),
        Align(
          alignment: Alignment.bottomCenter,
          child: FractionallySizedBox(
            widthFactor: 1,
            heightFactor: _bottomCoverageFactor,
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: bottomOverlayColors,
                  stops: _bottomOverlayStops,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
