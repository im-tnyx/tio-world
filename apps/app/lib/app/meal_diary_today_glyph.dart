import 'package:flutter/material.dart';
import 'package:tio_core/core.dart';

/// Calendar glyph for the Meal Diary "Today" action, with the current day
/// drawn inside it.
///
/// `ic_calendar.svg` draws the body between the header divider (y 9.5) and the
/// bottom stroke (y 21.5) of the 24dp box, so the date is placed on that body
/// centre instead of the icon centre.
class MealDiaryTodayGlyph extends StatelessWidget {
  const MealDiaryTodayGlyph({required this.localToday, super.key});

  final DateTime localToday;

  @override
  Widget build(BuildContext context) {
    final outline = Theme.of(context).colorScheme.onSurface;

    return ExcludeSemantics(
      child: SizedBox(
        key: const ValueKey('meal-diary-today-glyph'),
        width: TioSize.dp24,
        height: TioSize.dp24,
        child: Stack(
          fit: StackFit.expand,
          children: [
            SvgPicture.asset(
              'assets/svg_icon/ic_calendar.svg',
              package: 'tio_core',
              colorFilter: ColorFilter.mode(outline, BlendMode.srcIn),
            ),
            // This slot is the drawn body: its centre is the body centre, and
            // its sides stop at the body's side strokes, so the date can never
            // sit on a stroke however wide the digits are.
            Positioned(
              left: TioSize.dp3,
              top: TioSize.dp10,
              right: TioSize.dp3,
              bottom: TioSize.dp3,
              child: Center(
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    localToday.day.toString(),
                    key: const ValueKey('meal-diary-today-day-label'),
                    maxLines: 1,
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: context.tioColors.info,
                          // Sized for the body slot rather than inherited from
                          // the label scale, so two digits still fit and the
                          // line box stays inside the calendar.
                          fontSize: TioFontSize.size9_5,
                          height: TioLineHeight.height110,
                          fontWeight: TioFontWeight.w700,
                        ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
