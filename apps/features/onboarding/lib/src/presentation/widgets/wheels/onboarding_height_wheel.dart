import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:tio_core/core.dart';

class OnboardingHeightWheel extends StatefulWidget {
  const OnboardingHeightWheel({
    required this.valueCm,
    required this.onChanged,
    this.unit = 'cm',
    this.onUnitChanged,
    super.key,
  });

  final double? valueCm;
  final ValueChanged<double> onChanged;
  final String unit;
  final ValueChanged<String>? onUnitChanged;

  @override
  State<OnboardingHeightWheel> createState() => _OnboardingHeightWheelState();
}

class _OnboardingHeightWheelState extends State<OnboardingHeightWheel> {
  static const int _minCm = 100;
  static const int _maxCm = 250;
  static const double _defaultCm = 170.0;
  static const double _perspective = TioWheelPickerTokens.perspective;
  static const double _diameterRatio = TioWheelPickerTokens.diameterRatio;

  late double _selectedCm;
  late int _selectedUnitIndex; // 0: cm, 1: in (ft/in)

  late FixedExtentScrollController _cmWholeController;
  late FixedExtentScrollController _cmDecimalController;
  late FixedExtentScrollController _feetController;
  late FixedExtentScrollController _inchesController;
  late FixedExtentScrollController _unitController;

  @override
  void initState() {
    super.initState();
    _selectedCm = widget.valueCm ?? _defaultCm;

    final wholeCm = _selectedCm.truncate().clamp(_minCm, _maxCm);
    final decimalCm = ((_selectedCm - wholeCm) * 10).round().clamp(0, 9);

    _cmWholeController = FixedExtentScrollController(
      initialItem: wholeCm - _minCm,
    );
    _cmDecimalController = FixedExtentScrollController(
      initialItem: decimalCm,
    );

    final totalInches = (_selectedCm / 2.54).round();
    final feet = (totalInches ~/ 12).clamp(3, 8);
    final inches = (totalInches % 12).clamp(0, 11);

    _feetController = FixedExtentScrollController(
      initialItem: feet - 3,
    );
    _inchesController = FixedExtentScrollController(
      initialItem: inches,
    );

    _selectedUnitIndex = (widget.unit == 'in' || widget.unit == 'ft') ? 1 : 0;
    _unitController = FixedExtentScrollController(
      initialItem: _selectedUnitIndex,
    );
  }

  @override
  void didUpdateWidget(covariant OnboardingHeightWheel oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.valueCm != null && widget.valueCm != oldWidget.valueCm) {
      final newCm = widget.valueCm!.clamp(_minCm.toDouble(), _maxCm.toDouble());
      if (newCm != _selectedCm) {
        _syncToCm(newCm, notify: false);
      }
    }
    final newUnitIndex = (widget.unit == 'in' || widget.unit == 'ft') ? 1 : 0;
    if (newUnitIndex != _selectedUnitIndex) {
      setState(() => _selectedUnitIndex = newUnitIndex);
      if (_unitController.hasClients) _unitController.jumpToItem(newUnitIndex);
    }
  }

  @override
  void dispose() {
    _cmWholeController.dispose();
    _cmDecimalController.dispose();
    _feetController.dispose();
    _inchesController.dispose();
    _unitController.dispose();
    super.dispose();
  }

  void _syncToCm(double cm, {bool notify = true}) {
    setState(() => _selectedCm = cm);

    final whole = cm.truncate().clamp(_minCm, _maxCm);
    final decimal = ((cm - whole) * 10).round().clamp(0, 9);

    if (_cmWholeController.hasClients &&
        _cmWholeController.selectedItem != (whole - _minCm)) {
      _cmWholeController.jumpToItem(whole - _minCm);
    }
    if (_cmDecimalController.hasClients &&
        _cmDecimalController.selectedItem != decimal) {
      _cmDecimalController.jumpToItem(decimal);
    }

    final totalInches = (cm / 2.54).round();
    final feet = (totalInches ~/ 12).clamp(3, 8);
    final inches = (totalInches % 12).clamp(0, 11);

    if (_feetController.hasClients &&
        _feetController.selectedItem != (feet - 3)) {
      _feetController.jumpToItem(feet - 3);
    }
    if (_inchesController.hasClients &&
        _inchesController.selectedItem != inches) {
      _inchesController.jumpToItem(inches);
    }

    if (notify) widget.onChanged(cm);
  }

  void _onCmWheelChanged() {
    HapticFeedback.selectionClick();
    final wholeIndex =
        _cmWholeController.hasClients ? _cmWholeController.selectedItem : 0;
    final decimalIndex =
        _cmDecimalController.hasClients ? _cmDecimalController.selectedItem : 0;
    final whole = _minCm + wholeIndex;
    final newCm = whole + (decimalIndex / 10.0);
    setState(() => _selectedCm = newCm);
    widget.onChanged(newCm);
  }

  void _onFtInChanged() {
    HapticFeedback.selectionClick();
    final feet =
        (_feetController.hasClients ? _feetController.selectedItem : 0) + 3;
    final inches =
        _inchesController.hasClients ? _inchesController.selectedItem : 0;
    final totalInches = (feet * 12) + inches;
    final newCm =
        (totalInches * 2.54).clamp(_minCm.toDouble(), _maxCm.toDouble());
    setState(() => _selectedCm = newCm);
    widget.onChanged(newCm);
  }

  void _onUnitIndexChanged(int index) {
    if (_selectedUnitIndex == index) return;
    HapticFeedback.selectionClick();
    setState(() => _selectedUnitIndex = index);
    final newUnit = index == 0 ? 'cm' : 'in';
    widget.onUnitChanged?.call(newUnit);

    if (index == 0) {
      final whole = _selectedCm.truncate().clamp(_minCm, _maxCm);
      final decimal = ((_selectedCm - whole) * 10).round().clamp(0, 9);
      _cmWholeController.jumpToItem(whole - _minCm);
      _cmDecimalController.jumpToItem(decimal);
    } else {
      final totalInches = (_selectedCm / 2.54).round();
      final feet = (totalInches ~/ 12).clamp(3, 8);
      final inches = (totalInches % 12).clamp(0, 11);
      _feetController.jumpToItem(feet - 3);
      _inchesController.jumpToItem(inches);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.tioColors;

    return SizedBox(
      height: TioWheelPickerTokens.viewportHeight,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Center Horizontal Highlight Pill
          Container(
            key: const ValueKey('onboarding-height-wheel-selection-pill'),
            height: TioWheelPickerTokens.selectionHeight,
            margin: const EdgeInsets.symmetric(
              horizontal: TioWheelPickerTokens.selectionHorizontalMargin,
            ),
            decoration: BoxDecoration(
              // `surface` and `surfaceRaised` are both white in light mode.
              // `surfaceVariant` remains distinct from the raised sheet across
              // every supported theme, so the selected row stays visible.
              color: colors.surfaceVariant.withAlpha(
                TioWheelPickerTokens.selectionSurfaceAlpha,
              ),
              borderRadius: BorderRadius.circular(TioRadius.md),
            ),
          ),

          // Active Wheel Content
          if (_selectedUnitIndex == 0)
            _buildCmWheelRow(colors)
          else
            _buildFtInWheelRow(colors),
        ],
      ),
    );
  }

  Widget _buildCmWheelRow(TioColors colors) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: TioSize.dp28),
      child: Row(
        children: [
          // Whole Number Drum (100..250)
          Expanded(
            flex: 3,
            child: ListWheelScrollView.useDelegate(
              controller: _cmWholeController,
              itemExtent: TioWheelPickerTokens.itemExtent,
              perspective: _perspective,
              diameterRatio: _diameterRatio,
              physics: const FixedExtentScrollPhysics(),
              onSelectedItemChanged: (_) => _onCmWheelChanged(),
              childDelegate: ListWheelChildBuilderDelegate(
                childCount: _maxCm - _minCm + 1,
                builder: (context, index) {
                  final cm = _minCm + index;
                  final isSelected = cm == _selectedCm.truncate();
                  return Center(
                    child: Text(
                      '$cm',
                      style: TextStyle(
                        fontSize: isSelected
                            ? TioWheelPickerTokens.selectedFontSize
                            : TioFontSize.size16,
                        fontWeight: isSelected
                            ? TioFontWeight.w800
                            : TioFontWeight.w500,
                        color: isSelected
                            ? colors.textPrimary
                            : colors.textSecondary.withAlpha(TioAlpha.alpha90),
                      ),
                    ),
                  );
                },
              ),
            ),
          ),

          // Dot Decimal separator .
          Center(
            child: Text(
              '.',
              style: TextStyle(
                fontSize: TioFontSize.size28,
                fontWeight: TioFontWeight.w900,
                color: colors.textPrimary,
              ),
            ),
          ),

          // Decimal Drum (0..9)
          Expanded(
            flex: 2,
            child: ListWheelScrollView.useDelegate(
              controller: _cmDecimalController,
              itemExtent: TioWheelPickerTokens.itemExtent,
              perspective: _perspective,
              diameterRatio: _diameterRatio,
              physics: const FixedExtentScrollPhysics(),
              onSelectedItemChanged: (_) => _onCmWheelChanged(),
              childDelegate: ListWheelChildBuilderDelegate(
                childCount: 10,
                builder: (context, index) {
                  final currentDecimal =
                      ((_selectedCm - _selectedCm.truncate()) * 10).round();
                  final isSelected = index == currentDecimal;
                  return Center(
                    child: Text(
                      '$index',
                      style: TextStyle(
                        fontSize: isSelected
                            ? TioWheelPickerTokens.selectedFontSize
                            : TioFontSize.size16,
                        fontWeight: isSelected
                            ? TioFontWeight.w800
                            : TioFontWeight.w500,
                        color: isSelected
                            ? colors.textPrimary
                            : colors.textSecondary.withAlpha(TioAlpha.alpha90),
                      ),
                    ),
                  );
                },
              ),
            ),
          ),

          // Unit Picker (cm / in)
          Expanded(
            flex: 2,
            child: _buildUnitPicker(colors),
          ),
        ],
      ),
    );
  }

  Widget _buildFtInWheelRow(TioColors colors) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: TioSize.dp36),
      child: Row(
        children: [
          // Feet Column (3'..8')
          Expanded(
            flex: 2,
            child: ListWheelScrollView.useDelegate(
              controller: _feetController,
              itemExtent: TioWheelPickerTokens.itemExtent,
              perspective: _perspective,
              diameterRatio: _diameterRatio,
              physics: const FixedExtentScrollPhysics(),
              onSelectedItemChanged: (_) => _onFtInChanged(),
              childDelegate: ListWheelChildBuilderDelegate(
                childCount: 6, // 3 to 8
                builder: (context, index) {
                  final ft = 3 + index;
                  final totalInches = (_selectedCm / 2.54).round();
                  final currentFt = totalInches ~/ 12;
                  final isSelected = ft == currentFt;
                  return Center(
                    child: Text(
                      "$ft'",
                      style: TextStyle(
                        fontSize: isSelected
                            ? TioWheelPickerTokens.selectedFontSize
                            : TioFontSize.size16,
                        fontWeight: isSelected
                            ? TioFontWeight.w800
                            : TioFontWeight.w500,
                        color: isSelected
                            ? colors.textPrimary
                            : colors.textSecondary.withAlpha(TioAlpha.alpha90),
                      ),
                    ),
                  );
                },
              ),
            ),
          ),

          // Inches Column (0"..11")
          Expanded(
            flex: 2,
            child: ListWheelScrollView.useDelegate(
              controller: _inchesController,
              itemExtent: TioWheelPickerTokens.itemExtent,
              perspective: _perspective,
              diameterRatio: _diameterRatio,
              physics: const FixedExtentScrollPhysics(),
              onSelectedItemChanged: (_) => _onFtInChanged(),
              childDelegate: ListWheelChildBuilderDelegate(
                childCount: 12, // 0 to 11
                builder: (context, index) {
                  final totalInches = (_selectedCm / 2.54).round();
                  final currentInches = totalInches % 12;
                  final isSelected = index == currentInches;
                  return Center(
                    child: Text(
                      '$index"',
                      style: TextStyle(
                        fontSize: isSelected
                            ? TioWheelPickerTokens.selectedFontSize
                            : TioFontSize.size16,
                        fontWeight: isSelected
                            ? TioFontWeight.w800
                            : TioFontWeight.w500,
                        color: isSelected
                            ? colors.textPrimary
                            : colors.textSecondary.withAlpha(TioAlpha.alpha90),
                      ),
                    ),
                  );
                },
              ),
            ),
          ),

          // Unit Switcher (cm / in)
          Expanded(
            flex: 2,
            child: _buildUnitPicker(colors),
          ),
        ],
      ),
    );
  }

  Widget _buildUnitPicker(TioColors colors) {
    return ListWheelScrollView.useDelegate(
      controller: _unitController,
      itemExtent: TioWheelPickerTokens.itemExtent,
      perspective: _perspective,
      diameterRatio: _diameterRatio,
      physics: const FixedExtentScrollPhysics(),
      onSelectedItemChanged: _onUnitIndexChanged,
      childDelegate: ListWheelChildBuilderDelegate(
        childCount: 2, // 0: cm, 1: in
        builder: (context, index) {
          final isSelected = index == _selectedUnitIndex;
          final unitText = index == 0 ? 'cm' : 'in';
          return Center(
            child: Text(
              unitText,
              style: TextStyle(
                fontSize: isSelected ? TioFontSize.size18 : TioFontSize.size15,
                fontWeight:
                    isSelected ? TioFontWeight.w800 : TioFontWeight.w500,
                color: isSelected
                    ? colors.textPrimary
                    : colors.textSecondary.withAlpha(TioAlpha.alpha90),
              ),
            ),
          );
        },
      ),
    );
  }
}
