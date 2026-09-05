import 'package:flutter/material.dart';
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

  late double _selectedCm;
  late int _selectedUnitIndex; // 0: cm, 1: in (ft/in)

  @override
  void initState() {
    super.initState();
    _selectedCm = widget.valueCm ?? _defaultCm;

    _selectedUnitIndex = (widget.unit == 'in' || widget.unit == 'ft') ? 1 : 0;
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
    }
  }

  void _syncToCm(double cm, {bool notify = true}) {
    setState(() => _selectedCm = cm);
    if (notify) widget.onChanged(cm);
  }

  int get _cmWholeIndex =>
      _selectedCm.truncate().clamp(_minCm, _maxCm) - _minCm;

  int get _cmDecimal =>
      ((_selectedCm - _selectedCm.truncate()) * 10).round().clamp(0, 9);

  int get _totalInches => (_selectedCm / 2.54).round();

  int get _feetIndex => (_totalInches ~/ 12).clamp(3, 8) - 3;

  int get _inches => (_totalInches % 12).clamp(0, 11);

  void _onCmWheelChanged({int? wholeIndex, int? decimalIndex}) {
    final nextWholeIndex = wholeIndex ?? _cmWholeIndex;
    final nextDecimalIndex = decimalIndex ?? _cmDecimal;
    final whole = _minCm + nextWholeIndex;
    final newCm = whole + (nextDecimalIndex / 10.0);
    setState(() => _selectedCm = newCm);
    widget.onChanged(newCm);
  }

  void _onFtInChanged({int? feetIndex, int? inches}) {
    final nextFeetIndex = feetIndex ?? _feetIndex;
    final nextInches = inches ?? _inches;
    final feet = nextFeetIndex + 3;
    final totalInches = (feet * 12) + nextInches;
    final newCm =
        (totalInches * 2.54).clamp(_minCm.toDouble(), _maxCm.toDouble());
    setState(() => _selectedCm = newCm);
    widget.onChanged(newCm);
  }

  void _onUnitIndexChanged(TioWheelSelectionChange change) {
    final index = change.index;
    if (_selectedUnitIndex == index) return;
    setState(() => _selectedUnitIndex = index);
    final newUnit = index == 0 ? 'cm' : 'in';
    widget.onUnitChanged?.call(newUnit);
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.tioColors;

    return TioWheelPickerFrame(
      selectionPillKey:
          const ValueKey('onboarding-height-wheel-selection-pill'),
      child: _selectedUnitIndex == 0
          ? _buildCmWheelRow(colors)
          : _buildFtInWheelRow(colors),
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
            child: TioWheelPickerColumn(
              selectedIndex: _cmWholeIndex,
              itemCount: _maxCm - _minCm + 1,
              onSelectedItemChanged: (change) =>
                  _onCmWheelChanged(wholeIndex: change.index),
              itemBuilder: (context, index, isSelected) {
                  final cm = _minCm + index;
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
            child: TioWheelPickerColumn(
              selectedIndex: _cmDecimal,
              itemCount: 10,
              onSelectedItemChanged: (change) =>
                  _onCmWheelChanged(decimalIndex: change.index),
              itemBuilder: (context, index, isSelected) {
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
            child: TioWheelPickerColumn(
              selectedIndex: _feetIndex,
              itemCount: 6,
              onSelectedItemChanged: (change) =>
                  _onFtInChanged(feetIndex: change.index),
              itemBuilder: (context, index, isSelected) {
                  final ft = 3 + index;
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

          // Inches Column (0"..11")
          Expanded(
            flex: 2,
            child: TioWheelPickerColumn(
              selectedIndex: _inches,
              itemCount: 12,
              onSelectedItemChanged: (change) =>
                  _onFtInChanged(inches: change.index),
              itemBuilder: (context, index, isSelected) {
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
    return TioWheelPickerColumn(
      selectedIndex: _selectedUnitIndex,
      itemCount: 2,
      onSelectedItemChanged: _onUnitIndexChanged,
      itemBuilder: (context, index, isSelected) {
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
    );
  }
}
