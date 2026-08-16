import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:tio_core/core.dart';

class OnboardingWeightWheel extends StatefulWidget {
  const OnboardingWeightWheel({
    required this.valueKg,
    required this.onChanged,
    this.unit = 'kg',
    this.onUnitChanged,
    super.key,
  });

  final double? valueKg;
  final ValueChanged<double> onChanged;
  final String unit;
  final ValueChanged<String>? onUnitChanged;

  @override
  State<OnboardingWeightWheel> createState() => _OnboardingWeightWheelState();
}

class _OnboardingWeightWheelState extends State<OnboardingWeightWheel> {
  static const int _minKg = 30;
  static const int _maxKg = 220;
  static const int _defaultKg = 75;

  static const int _minLbs = 66;
  static const int _maxLbs = 485;

  late double _selectedKg;
  late int _selectedUnitIndex; // 0: kg, 1: lbs

  late FixedExtentScrollController _wholeController;
  late FixedExtentScrollController _decimalController;
  late FixedExtentScrollController _unitController;

  @override
  void initState() {
    super.initState();
    _selectedKg = widget.valueKg ?? _defaultKg.toDouble();

    final whole = _selectedKg.truncate().clamp(_minKg, _maxKg);
    final decimal = ((_selectedKg - whole) * 10).round().clamp(0, 9);

    _wholeController = FixedExtentScrollController(
      initialItem: whole - _minKg,
    );
    _decimalController = FixedExtentScrollController(
      initialItem: decimal,
    );
    _selectedUnitIndex = widget.unit == 'lbs' ? 1 : 0;
    _unitController = FixedExtentScrollController(
      initialItem: _selectedUnitIndex,
    );
  }

  @override
  void didUpdateWidget(covariant OnboardingWeightWheel oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.valueKg != null && widget.valueKg != oldWidget.valueKg) {
      final newKg = widget.valueKg!.clamp(_minKg.toDouble(), _maxKg.toDouble());
      if (newKg != _selectedKg) {
        _syncToKg(newKg, notify: false);
      }
    }
    final newUnitIndex = widget.unit == 'lbs' ? 1 : 0;
    if (newUnitIndex != _selectedUnitIndex) {
      setState(() => _selectedUnitIndex = newUnitIndex);
      if (_unitController.hasClients) _unitController.jumpToItem(newUnitIndex);
    }
  }

  @override
  void dispose() {
    _wholeController.dispose();
    _decimalController.dispose();
    _unitController.dispose();
    super.dispose();
  }

  void _syncToKg(double kg, {bool notify = true}) {
    setState(() => _selectedKg = kg);
    final whole = kg.truncate().clamp(_minKg, _maxKg);
    final decimal = ((kg - whole) * 10).round().clamp(0, 9);

    if (_selectedUnitIndex == 0) {
      final wholeIndex = whole - _minKg;
      if (_wholeController.hasClients && _wholeController.selectedItem != wholeIndex) {
        _wholeController.jumpToItem(wholeIndex);
      }
      if (_decimalController.hasClients && _decimalController.selectedItem != decimal) {
        _decimalController.jumpToItem(decimal);
      }
    } else {
      final lbs = kg * 2.20462;
      final wholeLbs = lbs.truncate().clamp(_minLbs, _maxLbs);
      final decimalLbs = ((lbs - wholeLbs) * 10).round().clamp(0, 9);

      final wholeIndex = wholeLbs - _minLbs;
      if (_wholeController.hasClients && _wholeController.selectedItem != wholeIndex) {
        _wholeController.jumpToItem(wholeIndex);
      }
      if (_decimalController.hasClients && _decimalController.selectedItem != decimalLbs) {
        _decimalController.jumpToItem(decimalLbs);
      }
    }

    if (notify) widget.onChanged(kg);
  }

  void _onWheelChanged() {
    HapticFeedback.selectionClick();
    final wholeIndex = _wholeController.hasClients ? _wholeController.selectedItem : 0;
    final decimalIndex = _decimalController.hasClients ? _decimalController.selectedItem : 0;

    if (_selectedUnitIndex == 0) {
      final whole = _minKg + wholeIndex;
      final newKg = whole + (decimalIndex / 10.0);
      setState(() => _selectedKg = newKg);
      widget.onChanged(newKg);
    } else {
      final wholeLbs = _minLbs + wholeIndex;
      final totalLbs = wholeLbs + (decimalIndex / 10.0);
      final newKg = (totalLbs / 2.20462).clamp(_minKg.toDouble(), _maxKg.toDouble());
      setState(() => _selectedKg = newKg);
      widget.onChanged(newKg);
    }
  }

  void _onUnitIndexChanged(int index) {
    if (_selectedUnitIndex == index) return;
    HapticFeedback.selectionClick();
    setState(() => _selectedUnitIndex = index);
    final newUnit = index == 0 ? 'kg' : 'lbs';
    widget.onUnitChanged?.call(newUnit);

    if (index == 0) {
      final whole = _selectedKg.truncate().clamp(_minKg, _maxKg);
      final decimal = ((_selectedKg - whole) * 10).round().clamp(0, 9);
      _wholeController.jumpToItem(whole - _minKg);
      _decimalController.jumpToItem(decimal);
    } else {
      final lbs = _selectedKg * 2.20462;
      final wholeLbs = lbs.truncate().clamp(_minLbs, _maxLbs);
      final decimalLbs = ((lbs - wholeLbs) * 10).round().clamp(0, 9);
      _wholeController.jumpToItem(wholeLbs - _minLbs);
      _decimalController.jumpToItem(decimalLbs);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = TioTheme.colors(context);

    return SizedBox(
      height: 200,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Center Horizontal Highlight Pill
          Container(
            height: 48,
            margin: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              color: colors.surface.withAlpha(200),
              borderRadius: BorderRadius.circular(TioRadius.medium),
            ),
          ),

          // Drum Wheels Row
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 28),
            child: Row(
              children: [
                // Whole Number Drum
                Expanded(
                  flex: 3,
                  child: ListWheelScrollView.useDelegate(
                    controller: _wholeController,
                    itemExtent: 44,
                    perspective: 0.003,
                    diameterRatio: 1.6,
                    physics: const FixedExtentScrollPhysics(),
                    onSelectedItemChanged: (_) => _onWheelChanged(),
                    childDelegate: ListWheelChildBuilderDelegate(
                      childCount: _selectedUnitIndex == 0
                          ? (_maxKg - _minKg + 1)
                          : (_maxLbs - _minLbs + 1),
                      builder: (context, index) {
                        final whole = _selectedUnitIndex == 0
                            ? (_minKg + index)
                            : (_minLbs + index);
                        final currentWhole = _selectedUnitIndex == 0
                            ? _selectedKg.truncate()
                            : (_selectedKg * 2.20462).truncate();
                        final isSelected = whole == currentWhole;
                        return Center(
                          child: Text(
                            '$whole',
                            style: TextStyle(
                              fontSize: isSelected ? 22 : 16,
                              fontWeight: isSelected ? FontWeight.w800 : FontWeight.w500,
                              color: isSelected
                                  ? colors.textPrimary
                                  : colors.textSecondary.withAlpha(90),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),

                // Dot Decimal Separator .
                Center(
                  child: Text(
                    '.',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.w900,
                      color: colors.textPrimary,
                    ),
                  ),
                ),

                // Decimal Drum (0..9)
                Expanded(
                  flex: 2,
                  child: ListWheelScrollView.useDelegate(
                    controller: _decimalController,
                    itemExtent: 44,
                    perspective: 0.003,
                    diameterRatio: 1.6,
                    physics: const FixedExtentScrollPhysics(),
                    onSelectedItemChanged: (_) => _onWheelChanged(),
                    childDelegate: ListWheelChildBuilderDelegate(
                      childCount: 10,
                      builder: (context, index) {
                        final currentDecimal = _selectedUnitIndex == 0
                            ? ((_selectedKg - _selectedKg.truncate()) * 10).round()
                            : (((_selectedKg * 2.20462) - (_selectedKg * 2.20462).truncate()) * 10).round();
                        final isSelected = index == currentDecimal;
                        return Center(
                          child: Text(
                            '$index',
                            style: TextStyle(
                              fontSize: isSelected ? 22 : 16,
                              fontWeight: isSelected ? FontWeight.w800 : FontWeight.w500,
                              color: isSelected
                                  ? colors.textPrimary
                                  : colors.textSecondary.withAlpha(90),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),

                // Unit Switcher (kg / lbs)
                Expanded(
                  flex: 2,
                  child: ListWheelScrollView.useDelegate(
                    controller: _unitController,
                    itemExtent: 44,
                    perspective: 0.003,
                    diameterRatio: 1.6,
                    physics: const FixedExtentScrollPhysics(),
                    onSelectedItemChanged: _onUnitIndexChanged,
                    childDelegate: ListWheelChildBuilderDelegate(
                      childCount: 2,
                      builder: (context, index) {
                        final isSelected = index == _selectedUnitIndex;
                        final unitText = index == 0 ? 'kg' : 'lbs';
                        return Center(
                          child: Text(
                            unitText,
                            style: TextStyle(
                              fontSize: isSelected ? 18 : 15,
                              fontWeight: isSelected ? FontWeight.w800 : FontWeight.w500,
                              color: isSelected
                                  ? colors.textPrimary
                                  : colors.textSecondary.withAlpha(90),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
