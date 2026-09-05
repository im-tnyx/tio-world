import 'package:flutter/material.dart';

import '../../../theme/theme.dart';
import '../../../units/units.dart';
import '../pickers/tio_wheel_picker.dart';

/// Reusable numeric weight drum-wheel picker.
///
/// Generic wheel mechanics (drum scrolling, decimal selection, haptics,
/// value synchronization, and configured bounds) live here; product/Body
/// business policy (which range applies, goal validation, persistence, etc.)
/// stays with the caller.
///
/// [unit] is the currently displayed unit and [onChanged] always reports the
/// resulting value in kg regardless of it, so canonical storage/business
/// logic never depends on which unit is on screen.
///
/// When [showUnitSwitcher] is true, a third drum lets the person switch
/// between kg and lb themselves, reporting the choice via [onUnitChanged]
/// (Product Onboarding's own weight steps use this). When false, the caller
/// supplies [unit] directly -- typically from an existing app-global unit
/// preference -- and no unit-switching drum renders, so this widget never
/// becomes a second owner of unit preferences.
class TioWeightWheel extends StatefulWidget {
  const TioWeightWheel({
    required this.valueKg,
    required this.onChanged,
    super.key,
    this.unit = WeightUnit.kg,
    this.onUnitChanged,
    this.showUnitSwitcher = true,
    this.minKg = 30.0,
    this.maxKg = 200.0,
    this.minLbs,
    this.maxLbs,
  });

  final double? valueKg;
  final ValueChanged<double> onChanged;
  final WeightUnit unit;
  final ValueChanged<WeightUnit>? onUnitChanged;
  final bool showUnitSwitcher;
  final double minKg;
  final double maxKg;
  final int? minLbs;
  final int? maxLbs;

  @override
  State<TioWeightWheel> createState() => _TioWeightWheelState();
}

class _TioWeightWheelState extends State<TioWeightWheel> {
  static const double _kgToLbsFactor = 2.20462;

  late int _minKg;
  late int _maxKg;
  late int _minLbs;
  late int _maxLbs;

  late double _selectedKg;
  late bool _isLbs;

  void _applyBounds() {
    _minKg = widget.minKg.round();
    _maxKg = widget.maxKg.round();
    _minLbs = widget.minLbs ?? (widget.minKg * _kgToLbsFactor).round();
    _maxLbs = widget.maxLbs ?? (widget.maxKg * _kgToLbsFactor).round();
  }

  @override
  void initState() {
    super.initState();
    _applyBounds();
    _selectedKg = widget.valueKg ?? ((_minKg + _maxKg) / 2).roundToDouble();
    _isLbs = widget.unit == WeightUnit.lb;

  }

  @override
  void didUpdateWidget(covariant TioWeightWheel oldWidget) {
    super.didUpdateWidget(oldWidget);
    _applyBounds();
    if (widget.valueKg != null && widget.valueKg != oldWidget.valueKg) {
      final newKg = widget.valueKg!.clamp(_minKg.toDouble(), _maxKg.toDouble());
      if (newKg != _selectedKg) {
        _syncToKg(newKg, notify: false);
      }
    }
    final newIsLbs = widget.unit == WeightUnit.lb;
    if (newIsLbs != _isLbs) {
      setState(() => _isLbs = newIsLbs);
    }
  }

  void _syncToKg(double kg, {bool notify = true}) {
    setState(() => _selectedKg = kg);
    if (notify) widget.onChanged(kg);
  }

  void _onWholeChanged(TioWheelSelectionChange change) {
    final decimalIndex = _displayDecimal;
    if (!_isLbs) {
      final whole = _minKg + change.index;
      final newKg = whole + (decimalIndex / 10.0);
      setState(() => _selectedKg = newKg);
      widget.onChanged(newKg);
    } else {
      final wholeLbs = _minLbs + change.index;
      final totalLbs = wholeLbs + (decimalIndex / 10.0);
      final newKg = (totalLbs / _kgToLbsFactor)
          .clamp(_minKg.toDouble(), _maxKg.toDouble());
      setState(() => _selectedKg = newKg);
      widget.onChanged(newKg);
    }
  }

  void _onDecimalChanged(TioWheelSelectionChange change) {
    if (!_isLbs) {
      final whole = _selectedKg.truncate().clamp(_minKg, _maxKg);
      final newKg = whole + (change.index / 10.0);
      setState(() => _selectedKg = newKg);
      widget.onChanged(newKg);
      return;
    }

    final lbs = _selectedKg * _kgToLbsFactor;
    final wholeLbs = lbs.truncate().clamp(_minLbs, _maxLbs);
    final newKg = ((wholeLbs + (change.index / 10.0)) / _kgToLbsFactor)
        .clamp(_minKg.toDouble(), _maxKg.toDouble());
    setState(() => _selectedKg = newKg);
    widget.onChanged(newKg);
  }

  int get _displayDecimal {
    final displayValue =
        _isLbs ? _selectedKg * _kgToLbsFactor : _selectedKg;
    return ((displayValue - displayValue.truncate()) * 10)
        .round()
        .clamp(0, 9);
  }

  void _onUnitIndexChanged(TioWheelSelectionChange change) {
    final index = change.index;
    final newIsLbs = index == 1;
    if (newIsLbs == _isLbs) return;

    setState(() => _isLbs = newIsLbs);
    widget.onUnitChanged?.call(newIsLbs ? WeightUnit.lb : WeightUnit.kg);
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.tioColors;

    final drums = <Widget>[
      Expanded(
        flex: 3,
        child: TioWheelPickerColumn(
          selectedIndex: !_isLbs
              ? _selectedKg.truncate().clamp(_minKg, _maxKg) - _minKg
              : (_selectedKg * _kgToLbsFactor)
                      .truncate()
                      .clamp(_minLbs, _maxLbs) -
                  _minLbs,
          itemCount:
              !_isLbs ? (_maxKg - _minKg + 1) : (_maxLbs - _minLbs + 1),
          onSelectedItemChanged: _onWholeChanged,
          itemBuilder: (context, index, isSelected) {
              final whole = !_isLbs ? (_minKg + index) : (_minLbs + index);
              return Center(
                child: Text(
                  '$whole',
                  style: TextStyle(
                    fontSize: isSelected
                        ? TioWheelPickerTokens.selectedFontSize
                        : TioFontSize.size16,
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
      ),
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
      Expanded(
        flex: 2,
        child: TioWheelPickerColumn(
          selectedIndex: _displayDecimal,
          itemCount: 10,
          onSelectedItemChanged: _onDecimalChanged,
          itemBuilder: (context, index, isSelected) {
              return Center(
                child: Text(
                  '$index',
                  style: TextStyle(
                    fontSize: isSelected
                        ? TioWheelPickerTokens.selectedFontSize
                        : TioFontSize.size16,
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
      ),
    ];

    if (widget.showUnitSwitcher) {
      drums.add(
        Expanded(
          flex: 2,
          child: TioWheelPickerColumn(
            selectedIndex: _isLbs ? 1 : 0,
          itemCount: 2,
          onSelectedItemChanged: _onUnitIndexChanged,
          itemBuilder: (context, index, isSelected) {
                final unitText = index == 0 ? 'kg' : 'lbs';
                return Center(
                  child: Text(
                    unitText,
                    style: TextStyle(
                      fontSize:
                          isSelected ? TioFontSize.size18 : TioFontSize.size15,
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
        ),
      );
    }

    return TioWheelPickerFrame(
      selectionPillKey: const ValueKey('tio-weight-wheel-selection-pill'),
      contentPadding: const EdgeInsets.symmetric(horizontal: TioSize.dp28),
      child: Row(children: drums),
    );
  }
}
