import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:tio_core/core.dart';

/// Profile Settings Page structured with modern capsule input containers and
/// segmented unit toggles (cm/ft for Height, kg/lbs for Weight).
class ProfileSettingsPage extends StatefulWidget {
  const ProfileSettingsPage({
    this.name = '',
    this.username = '',
    this.gender = 'Male',
    this.dateOfBirth,
    this.heightCm = 170.0,
    this.currentWeightKg = 70.0,
    this.avatarUrl,
    this.avatarFrame = TioAvatarFrame.none,
    this.plan = 'free',
    this.onAvatarPressed,
    this.onPickImage,
    this.onDeleteImage,
    this.onSave,
    super.key,
  });

  final String name;
  final String username;
  final String gender;
  final DateTime? dateOfBirth;
  final double heightCm;
  final double currentWeightKg;
  final String? avatarUrl;
  final TioAvatarFrame avatarFrame;
  final String plan;
  final VoidCallback? onAvatarPressed;
  final Future<void> Function(TioImageSource source)? onPickImage;
  final Future<void> Function()? onDeleteImage;
  final Future<void> Function({
    required String name,
    required String username,
    required String gender,
    required DateTime dateOfBirth,
    required double heightCm,
    required double currentWeightKg,
  })? onSave;

  @override
  State<ProfileSettingsPage> createState() => _ProfileSettingsPageState();
}

class _ProfileSettingsPageState extends State<ProfileSettingsPage> {
  late TextEditingController _nameController;
  late TextEditingController _usernameController;
  late String _gender;
  late DateTime _dob;
  late double _heightCm;
  late double _weightKg;

  String _heightUnit = 'ft'; // 'cm' or 'ft'
  String _weightUnit = 'kg'; // 'kg' or 'lbs'

  bool _isSaving = false;
  String? _errorMessage;

  static const List<String> _genderOptions = ['Male', 'Female', 'Other'];

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.name);
    _usernameController = TextEditingController(text: widget.username);
    _gender = widget.gender.isNotEmpty ? widget.gender : 'Male';
    _dob = widget.dateOfBirth ?? DateTime(1995, 6, 5);
    _heightCm = widget.heightCm > 0 ? widget.heightCm : 170.0;
    _weightKg = widget.currentWeightKg > 0 ? widget.currentWeightKg : 70.0;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _usernameController.dispose();
    super.dispose();
  }

  String _formattedHeight() {
    if (_heightUnit == 'cm') {
      return '${_heightCm.toStringAsFixed(0)} cm';
    } else {
      final totalInches = _heightCm / 2.54;
      final feet = (totalInches / 12).floor();
      final inches = (totalInches % 12).round();
      return "$feet' $inches\"";
    }
  }

  String _formattedWeight() {
    if (_weightUnit == 'kg') {
      return '${_weightKg.toStringAsFixed(1)} kg';
    } else {
      final lbs = _weightKg * 2.20462;
      return '${lbs.toStringAsFixed(1)} lbs';
    }
  }

  Future<void> _triggerAvatarActionSheet(
    BuildContext context, {
    required bool hasPhoto,
  }) async {
    final action = await showTioAvatarActionBottomSheet(
      context: context,
      hasPhoto: hasPhoto,
    );

    if (action == null || !mounted) return;

    switch (action) {
      case TioAvatarAction.gallery:
        await widget.onPickImage?.call(TioImageSource.gallery);
        break;
      case TioAvatarAction.camera:
        await widget.onPickImage?.call(TioImageSource.camera);
        break;
      case TioAvatarAction.delete:
        if (!mounted) return;
        final confirmed = await showTioRemoveImageConfirmationBottomSheet(this.context);
        if (confirmed == true) {
          await widget.onDeleteImage?.call();
        }
        break;
    }
  }

  Future<void> _pickDateOfBirth() async {
    final picked = await showTioDobPickerBottomSheet(
      context: context,
      initialDate: _dob,
    );

    if (picked != null && mounted) {
      setState(() => _dob = picked);
    }
  }

  void _showGenderPicker() {
    final colors = TioTheme.colors(context);

    showModalBottomSheet<void>(
      context: context,
      backgroundColor: colors.surfaceRaised,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(TioRadius.large)),
      ),
      builder: (modalContext) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: TioSpacing.large,
              vertical: TioSpacing.medium,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 36,
                    height: 4,
                    decoration: BoxDecoration(
                      color: colors.outlineStrong.withAlpha(50),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: TioSpacing.medium),
                Text(
                  'Select Biological Sex',
                  style: TextStyle(
                    color: colors.textPrimary,
                    fontWeight: FontWeight.w700,
                    fontSize: 18,
                  ),
                ),
                const SizedBox(height: TioSpacing.small),
                for (final g in _genderOptions)
                  ListTile(
                    title: Text(
                      g,
                      style: TextStyle(
                        color: _gender == g ? colors.primary : colors.textPrimary,
                        fontWeight: _gender == g ? FontWeight.w700 : FontWeight.w500,
                      ),
                    ),
                    trailing: _gender == g
                        ? Icon(Icons.check_circle_rounded, color: colors.primary)
                        : null,
                    onTap: () {
                      setState(() => _gender = g);
                      Navigator.of(modalContext).pop();
                    },
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _pickHeight() async {
    final picked = await showTioHeightPickerBottomSheet(
      context: context,
      initialHeightCm: _heightCm,
      unit: _heightUnit,
    );

    if (picked != null && mounted) {
      setState(() => _heightCm = picked);
    }
  }

  Future<void> _pickWeight() async {
    final picked = await showTioWeightPickerBottomSheet(
      context: context,
      initialWeightKg: _weightKg,
      unit: _weightUnit,
    );

    if (picked != null && mounted) {
      setState(() => _weightKg = picked);
    }
  }

  Future<void> _handleSave() async {
    if (_isSaving) return;

    final name = _nameController.text.trim();
    final username = _usernameController.text.trim();

    if (name.isEmpty) {
      setState(() => _errorMessage = 'Please enter your full name');
      return;
    }

    setState(() {
      _isSaving = true;
      _errorMessage = null;
    });

    try {
      await widget.onSave?.call(
        name: name,
        username: username,
        gender: _gender,
        dateOfBirth: _dob,
        heightCm: _heightCm,
        currentWeightKg: _weightKg,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Profile updated successfully!')),
        );
        Navigator.of(context).pop();
      }
    } catch (_) {
      if (mounted) {
        setState(() => _errorMessage = 'Could not update profile. Please try again.');
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = TioTheme.colors(context);

    final normalizedPlan = widget.plan.toLowerCase();
    final isPro = normalizedPlan == 'pro' || normalizedPlan == 'premium';
    final isPlus = normalizedPlan == 'plus';

    final avatarUrl = widget.avatarUrl?.trim();
    final hasValidPhoto = avatarUrl != null && 
                         avatarUrl.isNotEmpty && 
                         avatarUrl.startsWith('http');

    return Scaffold(
      backgroundColor: colors.background,
      appBar: AppBar(
        backgroundColor: colors.background,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: BackButton(color: colors.textPrimary),
        title: Text(
          'Profile Settings',
          style: TextStyle(
            color: colors.textPrimary,
            fontWeight: FontWeight.w800,
            fontSize: 20,
          ),
        ),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(
            TioSpacing.large,
            TioSpacing.small,
            TioSpacing.large,
            TioSpacing.extraLarge + 50,
          ),
          children: [
            // ── Dynamic Avatar Edit Header ──
            Center(
              child: SizedBox(
                width: TioAvatarSize.large.dimension ,
                height: TioAvatarSize.large.dimension ,
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    // Main Avatar Click
                    Center(
                      child: InkWell(
                        customBorder: const CircleBorder(),
                        onTap: () {
                          if (hasValidPhoto) {
                            widget.onAvatarPressed?.call();
                          } else {
                            _triggerAvatarActionSheet(
                              context,
                              hasPhoto: false,
                            );
                          }
                        },
                        child: TioAvatar(
                          size: TioAvatarSize.large,
                          frame: widget.avatarFrame,
                          displayName: _nameController.text.isNotEmpty
                              ? _nameController.text
                              : _usernameController.text,
                          imageUrl: avatarUrl,
                        ),
                      ),
                    ),

                    // Bottom-Right Dynamic Plan Tier / Edit Badge: ALWAYS opens Bottom Sheet
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: GestureDetector(
                        behavior: HitTestBehavior.opaque,
                        onTap: () {
                          _triggerAvatarActionSheet(
                            context,
                            hasPhoto: hasValidPhoto,
                          );
                        },
                        child: Container(
                          width: 26,
                          height: 26,
                          decoration: BoxDecoration(
                            color: isPro
                                ? const Color(0xFF0F172A)
                                : isPlus
                                    ? const Color(0xFF1E1B4B)
                                    : const Color(0xFF0F172A),
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: colors.background,
                              width: 2.5,
                            ),
                          ),
                          alignment: Alignment.center,
                          child: isPro
                              ? SvgPicture.asset(
                                  'assets/svg_icon/ic_pro_outline.svg',
                                  package: 'tio_core',
                                  width: 16,
                                  height: 16,
                                  colorFilter: const ColorFilter.mode(
                                    Color(0xFF5EEAD4),
                                    BlendMode.srcIn,
                                  ),
                                )
                              : isPlus
                                  ? const Icon(
                                      Icons.star_rounded,
                                      size: 16,
                                      color: Color(0xFFF59E0B),
                                    )
                                  : const Icon(
                                      Icons.edit,
                                      size: 14,
                                      color: Colors.white,
                                    ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: TioSpacing.extraLarge),

            // ── Field 1: FULL NAME ──
            _CapsuleInputField(
              label: 'FULL NAME',
              icon: Icons.person_outline_rounded,
              controller: _nameController,
              hintText: 'Your name',
              colors: colors,
            ),

            const SizedBox(height: TioSpacing.large),

            // ── Field 2: DATE OF BIRTH ──
            _CapsuleActionField(
              label: 'DATE OF BIRTH',
              icon: Icons.calendar_today_outlined,
              value: '${_dob.month}/${_dob.day}/${_dob.year}',
              onTap: _pickDateOfBirth,
              colors: colors,
            ),

            const SizedBox(height: TioSpacing.large),

            // ── Field 4: BIOLOGICAL SEX ──
            _CapsuleActionField(
              label: 'BIOLOGICAL SEX',
              icon: _gender == 'Female'
                  ? Icons.female_rounded
                  : _gender == 'Male'
                      ? Icons.male_rounded
                      : Icons.transgender_rounded,
              value: _gender,
              trailingIcon: Icons.keyboard_arrow_down_rounded,
              onTap: _showGenderPicker,
              colors: colors,
            ),

            const SizedBox(height: TioSpacing.large),

            // ── Field 5: HEIGHT (with cm / ft unit switch) ──
            _CapsuleWithUnitField(
              label: 'HEIGHT',
              value: _formattedHeight(),
              onTapValue: _pickHeight,
              units: const ['cm', 'ft'],
              selectedUnit: _heightUnit,
              onUnitChanged: (u) => setState(() => _heightUnit = u),
              colors: colors,
            ),

            const SizedBox(height: TioSpacing.large),

            // ── Field 6: CURRENT WEIGHT (with kg / lbs unit switch) ──
            _CapsuleWithUnitField(
              label: 'CURRENT WEIGHT',
              value: _formattedWeight(),
              onTapValue: _pickWeight,
              units: const ['kg', 'lbs'],
              selectedUnit: _weightUnit,
              onUnitChanged: (u) => setState(() => _weightUnit = u),
              colors: colors,
            ),

            if (_errorMessage case final err?) ...[
              const SizedBox(height: TioSpacing.large),
              Text(
                err,
                style: TextStyle(
                  color: colors.danger,
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ],
        ),
      ),
      // ── Fixed Bottom Save Action Bar ──
      bottomNavigationBar: ClipRect(
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                stops: const [0.0, 0.45, 1.0],
                colors: [
                  colors.background.withValues(alpha: 0.0),
                  colors.background.withValues(alpha: 0.75),
                  colors.background.withValues(alpha: 0.98),
                ],
              ),
            ),
            child: SafeArea(
              top: false,
              minimum: const EdgeInsets.all(TioSpacing.large),
              child: TioButton.primary(
                label: 'Save Changes',
                loading: _isSaving,
                loadingLabel: 'Saving',
                expand: true,
                onPressed: _handleSave,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Capsule Input Field (for Name, Username)
class _CapsuleInputField extends StatelessWidget {
  const _CapsuleInputField({
    required this.label,
    required this.icon,
    required this.controller,
    required this.hintText,
    required this.colors,
  });

  final String label;
  final IconData icon;
  final TextEditingController controller;
  final String hintText;
  final TioColors colors;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            color: colors.textPrimary,
            fontWeight: FontWeight.w700,
            fontSize: 13,
            letterSpacing: 0.8,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          height: 56,
          decoration: BoxDecoration(
            color: colors.surfaceRaised,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: colors.outlineStrong.withAlpha(40),
            ),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 16),
          alignment: Alignment.center,
          child: Row(
            children: [
              Icon(icon, size: 22, color: colors.textPrimary),
              const SizedBox(width: 14),
              Expanded(
                child: TextField(
                  controller: controller,
                  cursorColor: colors.primary,
                  style: TextStyle(
                    color: colors.textPrimary,
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                  decoration: InputDecoration(
                    border: InputBorder.none,
                    enabledBorder: InputBorder.none,
                    focusedBorder: InputBorder.none,
                    errorBorder: InputBorder.none,
                    disabledBorder: InputBorder.none,
                    focusedErrorBorder: InputBorder.none,
                    filled: false,
                    fillColor: Colors.transparent,
                    isDense: true,
                    contentPadding: EdgeInsets.zero,
                    hintText: hintText,
                    hintStyle: TextStyle(
                      color: colors.textMuted,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// Capsule Action Field (for DOB, Sex)
class _CapsuleActionField extends StatelessWidget {
  const _CapsuleActionField({
    required this.label,
    required this.icon,
    required this.value,
    required this.onTap,
    required this.colors,
    this.trailingIcon,
  });

  final String label;
  final IconData icon;
  final String value;
  final VoidCallback onTap;
  final TioColors colors;
  final IconData? trailingIcon;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            color: colors.textPrimary,
            fontWeight: FontWeight.w700,
            fontSize: 13,
            letterSpacing: 0.8,
          ),
        ),
        const SizedBox(height: 8),
        InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Container(
            height: 56,
            decoration: BoxDecoration(
              color: colors.surfaceRaised,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: colors.outlineStrong.withAlpha(40),
              ),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                Icon(icon, size: 22, color: colors.textPrimary),
                const SizedBox(width: 14),
                Expanded(
                  child: Text(
                    value,
                    style: TextStyle(
                      color: colors.textPrimary,
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                if (trailingIcon != null)
                  Icon(
                    trailingIcon,
                    size: 22,
                    color: colors.textPrimary,
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

/// Capsule with Unit Segmented Switch (for Height cm/ft & Weight kg/lbs)
class _CapsuleWithUnitField extends StatelessWidget {
  const _CapsuleWithUnitField({
    required this.label,
    required this.value,
    required this.onTapValue,
    required this.units,
    required this.selectedUnit,
    required this.onUnitChanged,
    required this.colors,
  });

  final String label;
  final String value;
  final VoidCallback onTapValue;
  final List<String> units;
  final String selectedUnit;
  final ValueChanged<String> onUnitChanged;
  final TioColors colors;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            color: colors.textPrimary,
            fontWeight: FontWeight.w700,
            fontSize: 13,
            letterSpacing: 0.8,
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            // ── Left Value Box ──
            Expanded(
              child: InkWell(
                onTap: onTapValue,
                borderRadius: BorderRadius.circular(16),
                child: Container(
                  height: 56,
                  decoration: BoxDecoration(
                    color: colors.surfaceRaised,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: colors.outlineStrong.withAlpha(40),
                    ),
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  alignment: Alignment.centerLeft,
                  child: Text(
                    value,
                    style: TextStyle(
                      color: colors.textPrimary,
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),

            // ── Right Segmented Unit Toggle ──
            Container(
              height: 56,
              decoration: BoxDecoration(
                color: colors.surfaceRaised,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: colors.outlineStrong.withAlpha(40),
                ),
              ),
              padding: const EdgeInsets.all(5),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: units.map((u) {
                  final isSelected = u == selectedUnit;

                  return GestureDetector(
                    onTap: () => onUnitChanged(u),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 150),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 10,
                      ),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? colors.outlineStrong.withAlpha(80)
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Center(
                        child: Text(
                          u,
                          style: TextStyle(
                            color: isSelected
                                ? colors.textPrimary
                                : colors.textMuted,
                            fontWeight: isSelected
                                ? FontWeight.w700
                                : FontWeight.w500,
                            fontSize: 15,
                          ),
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
