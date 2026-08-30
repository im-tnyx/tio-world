import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../theme/theme.dart';
import '../../../units/units.dart';

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
  static const double _perspective = 0.003;
  static const double _diameterRatio = 1.6;
  static const double _kgToLbsFactor = 2.20462;

  late int _minKg;
  late int _maxKg;
  late int _minLbs;
  late int _maxLbs;

  late double _selectedKg;
  late bool _isLbs;
  bool _isProgrammaticSync = false;

  late FixedExtentScrollController _wholeController;
  late FixedExtentScrollController _decimalController;
  FixedExtentScrollController? _unitController;

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

    final whole = _selectedKg.truncate().clamp(_minKg, _maxKg);
    final decimal = ((_selectedKg - whole) * 10).round().clamp(0, 9);

    _wholeController = FixedExtentScrollController(initialItem: whole - _minKg);
    _decimalController = FixedExtentScrollController(initialItem: decimal);
    if (widget.showUnitSwitcher) {
      _unitController =
          FixedExtentScrollController(initialItem: _isLbs ? 1 : 0);
    }
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
      if (_unitController?.hasClients ?? false) {
        _runProgrammaticSync(
          () => _unitController!.jumpToItem(newIsLbs ? 1 : 0),
        );
      }
    }
  }

  @override
  void dispose() {
    _wholeController.dispose();
    _decimalController.dispose();
    _unitController?.dispose();
    super.dispose();
  }

  void _runProgrammaticSync(VoidCallback action) {
    _isProgrammaticSync = true;
    try {
      action();
    } finally {
      _isProgrammaticSync = false;
    }
  }

  void _syncToKg(double kg, {bool notify = true}) {
    setState(() => _selectedKg = kg);
    final whole = kg.truncate().clamp(_minKg, _maxKg);
    final decimal = ((kg - whole) * 10).round().clamp(0, 9);

    _runProgrammaticSync(() {
      if (!_isLbs) {
        final wholeIndex = whole - _minKg;
        if (_wholeController.hasClients &&
            _wholeController.selectedItem != wholeIndex) {
          _wholeController.jumpToItem(wholeIndex);
        }
        if (_decimalController.hasClients &&
            _decimalController.selectedItem != decimal) {
          _decimalController.jumpToItem(decimal);
        }
      } else {
        final lbs = kg * _kgToLbsFactor;
        final wholeLbs = lbs.truncate().clamp(_minLbs, _maxLbs);
        final decimalLbs = ((lbs - wholeLbs) * 10).round().clamp(0, 9);

        final wholeIndex = wholeLbs - _minLbs;
        if (_wholeController.hasClients &&
            _wholeController.selectedItem != wholeIndex) {
          _wholeController.jumpToItem(wholeIndex);
        }
        if (_decimalController.hasClients &&
            _decimalController.selectedItem != decimalLbs) {
          _decimalController.jumpToItem(decimalLbs);
        }
      }
    });

    if (notify) widget.onChanged(kg);
  }

  void _onWheelChanged() {
    if (_isProgrammaticSync) return;

    HapticFeedback.selectionClick();
    final wholeIndex =
        _wholeController.hasClients ? _wholeController.selectedItem : 0;
    final decimalIndex =
        _decimalController.hasClients ? _decimalController.selectedItem : 0;

    if (!_isLbs) {
      final whole = _minKg + wholeIndex;
      final newKg = whole + (decimalIndex / 10.0);
      setState(() => _selectedKg = newKg);
      widget.onChanged(newKg);
    } else {
      final wholeLbs = _minLbs + wholeIndex;
      final totalLbs = wholeLbs + (decimalIndex / 10.0);
      final newKg = (totalLbs / _kgToLbsFactor)
          .clamp(_minKg.toDouble(), _maxKg.toDouble());
      setState(() => _selectedKg = newKg);
      widget.onChanged(newKg);
    }
  }

  void _onUnitIndexChanged(int index) {
    if (_isProgrammaticSync) return;
    final newIsLbs = index == 1;
    if (newIsLbs == _isLbs) return;

    HapticFeedback.selectionClick();
    setState(() => _isLbs = newIsLbs);
    widget.onUnitChanged?.call(newIsLbs ? WeightUnit.lb : WeightUnit.kg);

    _runProgrammaticSync(() {
      if (!newIsLbs) {
        final whole = _selectedKg.truncate().clamp(_minKg, _maxKg);
        final decimal = ((_selectedKg - whole) * 10).round().clamp(0, 9);
        _wholeController.jumpToItem(whole - _minKg);
        _decimalController.jumpToItem(decimal);
      } else {
        final lbs = _selectedKg * _kgToLbsFactor;
        final wholeLbs = lbs.truncate().clamp(_minLbs, _maxLbs);
        final decimalLbs = ((lbs - wholeLbs) * 10).round().clamp(0, 9);
        _wholeController.jumpToItem(wholeLbs - _minLbs);
        _decimalController.jumpToItem(decimalLbs);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.tioColors;

    final drums = <Widget>[
      Expanded(
        flex: 3,
        child: ListWheelScrollView.useDelegate(
          controller: _wholeController,
          itemExtent: TioWheelPickerTokens.itemExtent,
          perspective: _perspective,
          diameterRatio: _diameterRatio,
          physics: const FixedExtentScrollPhysics(),
          onSelectedItemChanged: (_) => _onWheelChanged(),
          childDelegate: ListWheelChildBuilderDelegate(
            childCount:
                !_isLbs ? (_maxKg - _minKg + 1) : (_maxLbs - _minLbs + 1),
            builder: (context, index) {
              final whole = !_isLbs ? (_minKg + index) : (_minLbs + index);
              final currentWhole = !_isLbs
                  ? _selectedKg.truncate()
                  : (_selectedKg * _kgToLbsFactor).truncate();
              final isSelected = whole == currentWhole;
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
        child: ListWheelScrollView.useDelegate(
          controller: _decimalController,
          itemExtent: TioWheelPickerTokens.itemExtent,
          perspective: _perspective,
          diameterRatio: _diameterRatio,
          physics: const FixedExtentScrollPhysics(),
          onSelectedItemChanged: (_) => _onWheelChanged(),
          childDelegate: ListWheelChildBuilderDelegate(
            childCount: 10,
            builder: (context, index) {
              final currentDecimal = !_isLbs
                  ? ((_selectedKg - _selectedKg.truncate()) * 10).round()
                  : (((_selectedKg * _kgToLbsFactor) -
                              (_selectedKg * _kgToLbsFactor).truncate()) *
                          10)
                      .round();
              final isSelected = index == currentDecimal;
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
      ),
    ];

    if (widget.showUnitSwitcher) {
      drums.add(
        Expanded(
          flex: 2,
          child: ListWheelScrollView.useDelegate(
            controller: _unitController!,
            itemExtent: TioWheelPickerTokens.itemExtent,
            perspective: _perspective,
            diameterRatio: _diameterRatio,
            physics: const FixedExtentScrollPhysics(),
            onSelectedItemChanged: _onUnitIndexChanged,
            childDelegate: ListWheelChildBuilderDelegate(
              childCount: 2,
              builder: (context, index) {
                final isSelected = index == (_isLbs ? 1 : 0);
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
        ),
      );
    }

    return SizedBox(
      height: TioWheelPickerTokens.viewportHeight,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Container(
            key: const ValueKey('tio-weight-wheel-selection-pill'),
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
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: TioSize.dp28),
            child: Row(children: drums),
          ),
        ],
      ),
    );
  }
}
