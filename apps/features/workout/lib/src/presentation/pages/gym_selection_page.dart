import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:geolocator/geolocator.dart';
import 'package:tio_core/core.dart';

import '../../domain/models/gym_location.dart';
import '../../domain/repositories/gym_location_repository.dart';

export '../../domain/models/gym_location.dart';
export '../../domain/repositories/gym_location_repository.dart';

/// Screen allowing the user to search and select a gym location.
class GymSelectionPage extends StatefulWidget {
  const GymSelectionPage({
    this.currentGymName,
    this.repository,
    this.positionProvider,
    super.key,
  });

  final String? currentGymName;
  final GymLocationRepository? repository;
  final Future<Position?> Function()? positionProvider;

  @override
  State<GymSelectionPage> createState() => _GymSelectionPageState();
}

enum _GymLocationAccess {
  resolving,
  granted,
  denied,
  deniedForever,
  serviceDisabled,
  unavailable,
}

class _GymSelectionPageState extends State<GymSelectionPage> {
  final TextEditingController _searchController = TextEditingController();
  GymLocationRepository? get _repository => widget.repository;

  String _query = '';
  bool _isLoading = false;
  double? _currentLat;
  double? _currentLng;
  Timer? _debounceTimer;
  var _requestGeneration = 0;
  _GymLocationAccess _locationAccess = _GymLocationAccess.resolving;

  static const homeGym = GymLocation(
    id: 'home_gym',
    name: 'Home gym',
    address: 'Private location',
  );

  List<GymLocation> _gyms = const [];

  bool get _showsLocationPermissionOption =>
      widget.positionProvider == null &&
      (_locationAccess == _GymLocationAccess.denied ||
          _locationAccess == _GymLocationAccess.deniedForever ||
          _locationAccess == _GymLocationAccess.serviceDisabled);

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_onSearchInputChanged);
    _loadInitialGyms();
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    _requestGeneration++;
    _searchController.removeListener(_onSearchInputChanged);
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchInputChanged() {
    final text = _searchController.text.trim();
    if (text == _query) return;
    setState(() => _query = text);

    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: TioDuration.ms310), () {
      _executeSearch(text);
    });
  }

  Future<Position?> _resolveDevicePosition({required bool promptIfDenied}) async {
    final serviceEnabled = await Geolocator.isLocationServiceEnabled()
        .timeout(const Duration(seconds: 1));
    if (!serviceEnabled) {
      _locationAccess = _GymLocationAccess.serviceDisabled;
      return null;
    }

    var permission = await Geolocator.checkPermission()
        .timeout(const Duration(seconds: 1));
    if (permission == LocationPermission.denied && promptIfDenied) {
      permission = await Geolocator.requestPermission();
    }

    if (permission == LocationPermission.denied) {
      _locationAccess = _GymLocationAccess.denied;
      return null;
    }
    if (permission == LocationPermission.deniedForever) {
      _locationAccess = _GymLocationAccess.deniedForever;
      return null;
    }
    if (permission != LocationPermission.always &&
        permission != LocationPermission.whileInUse) {
      _locationAccess = _GymLocationAccess.unavailable;
      return null;
    }

    final pos = await Geolocator.getCurrentPosition(
      locationSettings: const LocationSettings(
        timeLimit: Duration(seconds: 4),
      ),
    ).timeout(const Duration(seconds: 4));
    _locationAccess = _GymLocationAccess.granted;
    return pos;
  }

  Future<void> _offerLocationPermission() async {
    unawaited(HapticFeedback.selectionClick());
    switch (_locationAccess) {
      case _GymLocationAccess.serviceDisabled:
        await Geolocator.openLocationSettings();
        if (!mounted) return;
        await _loadInitialGyms(promptIfDenied: false);
        return;
      case _GymLocationAccess.deniedForever:
        await Geolocator.openAppSettings();
        if (!mounted) return;
        await _loadInitialGyms(promptIfDenied: false);
        return;
      case _GymLocationAccess.denied:
        await _loadInitialGyms(promptIfDenied: true);
        return;
      case _GymLocationAccess.resolving:
      case _GymLocationAccess.granted:
      case _GymLocationAccess.unavailable:
        return;
    }
  }

  Future<void> _loadInitialGyms({bool promptIfDenied = true}) async {
    final requestGeneration = ++_requestGeneration;
    setState(() {
      _isLoading = true;
      if (widget.positionProvider == null) {
        _locationAccess = _GymLocationAccess.resolving;
      }
    });

    final repository = _repository;
    if (repository == null) {
      if (mounted && requestGeneration == _requestGeneration) {
        setState(() {
          _gyms = const [];
          _isLoading = false;
          _locationAccess = _GymLocationAccess.unavailable;
        });
      }
      return;
    }

    Position? pos;
    try {
      if (widget.positionProvider != null) {
        pos = await widget.positionProvider!();
        _locationAccess = pos != null
            ? _GymLocationAccess.granted
            : _GymLocationAccess.unavailable;
      } else {
        pos = await _resolveDevicePosition(promptIfDenied: promptIfDenied);
      }
    } catch (_) {
      // Location unavailable / denied / test environment, fallback to query.
      if (widget.positionProvider != null) {
        _locationAccess = _GymLocationAccess.unavailable;
      } else if (_locationAccess == _GymLocationAccess.resolving) {
        _locationAccess = _GymLocationAccess.denied;
      }
    }

    if (pos != null) {
      _currentLat = pos.latitude;
      _currentLng = pos.longitude;
    } else {
      _currentLat = null;
      _currentLng = null;
    }

    try {
      final results = await repository
          .searchGyms(
            latitude: _currentLat,
            longitude: _currentLng,
          )
          .timeout(const Duration(seconds: 4));

      if (mounted &&
          requestGeneration == _requestGeneration &&
          _query.isEmpty) {
        setState(() {
          _gyms = results;
        });
      }
    } catch (_) {
      if (mounted &&
          requestGeneration == _requestGeneration &&
          _query.isEmpty) {
        setState(() => _gyms = const []);
      }
    } finally {
      if (mounted && requestGeneration == _requestGeneration) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _executeSearch(String query) async {
    if (query.isEmpty) {
      unawaited(_loadInitialGyms());
      return;
    }

    final requestGeneration = ++_requestGeneration;
    final repository = _repository;
    if (repository == null) {
      setState(() {
        _gyms = const [];
        _isLoading = false;
      });
      return;
    }

    setState(() => _isLoading = true);

    try {
      final results = await repository
          .searchGyms(
            query: query,
            latitude: _currentLat,
            longitude: _currentLng,
          )
          .timeout(const Duration(seconds: 4));

      if (mounted &&
          requestGeneration == _requestGeneration &&
          _query == query) {
        setState(() => _gyms = results);
      }
    } catch (_) {
      if (mounted &&
          requestGeneration == _requestGeneration &&
          _query == query) {
        setState(() => _gyms = const []);
      }
    } finally {
      if (mounted && requestGeneration == _requestGeneration) {
        setState(() => _isLoading = false);
      }
    }
  }

  bool get _matchesHomeGym {
    if (_query.isEmpty) return true;
    final lower = _query.toLowerCase();
    return homeGym.name.toLowerCase().contains(lower) ||
        homeGym.address.toLowerCase().contains(lower);
  }

  void _selectGym(GymLocation gym) {
    HapticFeedback.selectionClick();
    Navigator.of(context).pop(gym.name);
  }

  void _selectCustomLocation(String name) {
    HapticFeedback.selectionClick();
    Navigator.of(context).pop(name);
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.tioColors;
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      appBar: TioAppBar(
        automaticallyImplyLeading: false,
        leading: IconButton(
          key: const ValueKey('gym-selection-back-button'),
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text('Gym'),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Search Bar
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: TioSpacing.lg,
              vertical: TioSpacing.sm,
            ),
            child: Container(
              height: TioSize.dp44,
              decoration: BoxDecoration(
                color: colors.surfaceVariant,
                borderRadius: BorderRadius.circular(TioRadius.full),
              ),
              padding: const EdgeInsets.symmetric(horizontal: TioSpacing.md),
              child: Row(
                children: [
                  Icon(
                    Icons.search_rounded,
                    size: TioSize.dp20,
                    color: colors.textSecondary,
                  ),
                  const SizedBox(width: TioSpacing.sm),
                  Expanded(
                    child: TextField(
                      key: const ValueKey('gym-search-input'),
                      controller: _searchController,
                      style: textTheme.bodyMedium?.copyWith(
                        color: colors.textPrimary,
                      ),
                      decoration: InputDecoration(
                        border: InputBorder.none,
                        enabledBorder: InputBorder.none,
                        focusedBorder: InputBorder.none,
                        errorBorder: InputBorder.none,
                        focusedErrorBorder: InputBorder.none,
                        disabledBorder: InputBorder.none,
                        filled: false,
                        fillColor: TioPalette.transparent,
                        isDense: true,
                        contentPadding: EdgeInsets.zero,
                        hintText: 'Search gyms',
                        hintStyle: textTheme.bodyMedium?.copyWith(
                          color: colors.textSecondary,
                        ),
                      ),
                    ),
                  ),
                  if (_query.isNotEmpty)
                    GestureDetector(
                      key: const ValueKey('gym-search-clear'),
                      onTap: () => _searchController.clear(),
                      child: Icon(
                        Icons.close_rounded,
                        size: TioSize.dp18,
                        color: colors.textSecondary,
                      ),
                    ),
                ],
              ),
            ),
          ),

          if (_isLoading)
            LinearProgressIndicator(
              minHeight: 2,
              backgroundColor: TioPalette.transparent,
              valueColor: AlwaysStoppedAnimation<Color>(colors.primary),
            ),

          const SizedBox(height: TioSpacing.sm),

          // Gym list
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(
                horizontal: TioSpacing.lg,
                vertical: TioSpacing.xs,
              ),
              children: [
                // Suggestions Section
                if (_matchesHomeGym) ...[
                  Padding(
                    padding: const EdgeInsets.only(
                      top: TioSpacing.sm,
                      bottom: TioSpacing.sm,
                    ),
                    child: Text(
                      'Suggestions',
                      style: textTheme.titleSmall?.copyWith(
                        color: colors.textSecondary,
                        fontWeight: TioFontWeight.w600,
                      ),
                    ),
                  ),
                  _GymTile(
                    key: const ValueKey('gym-option-home-gym'),
                    gym: homeGym,
                    icon: Icons.home_outlined,
                    isSelected: widget.currentGymName == homeGym.name,
                    onTap: () => _selectGym(homeGym),
                  ),
                  if (_showsLocationPermissionOption) ...[
                    const SizedBox(height: TioSpacing.sm),
                    _LocationPermissionTile(
                      access: _locationAccess,
                      onTap: () => unawaited(_offerLocationPermission()),
                    ),
                  ],
                  const SizedBox(height: TioSpacing.md),
                ],

                // If user typed a search not in the list, offer to use it
                if (_query.isNotEmpty &&
                    !_gyms.any((g) =>
                        g.name.toLowerCase() == _query.toLowerCase())) ...[
                  _CustomSearchTile(
                    query: _query,
                    onTap: () => _selectCustomLocation(_query),
                  ),
                  const SizedBox(height: TioSpacing.md),
                ],

                // Popular / Nearby gyms Section
                if (_gyms.isNotEmpty) ...[
                  Padding(
                    padding: const EdgeInsets.only(
                      top: TioSpacing.sm,
                      bottom: TioSpacing.sm,
                    ),
                    child: Text(
                      _currentLat != null ? 'Nearby gyms' : 'Popular gyms',
                      style: textTheme.titleSmall?.copyWith(
                        color: colors.textSecondary,
                        fontWeight: TioFontWeight.w600,
                      ),
                    ),
                  ),
                  for (final gym in _gyms)
                    _GymTile(
                      key: ValueKey('gym-option-${gym.id}'),
                      gym: gym,
                      icon: Icons.location_on_outlined,
                      isSelected: widget.currentGymName == gym.name,
                      onTap: () => _selectGym(gym),
                    ),
                ] else if (!_matchesHomeGym && !_isLoading) ...[
                  Padding(
                    padding:
                        const EdgeInsets.symmetric(vertical: TioSpacing.xl),
                    child: Center(
                      child: Text(
                        'No gyms found',
                        style: textTheme.bodyMedium?.copyWith(
                          color: colors.textSecondary,
                        ),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _GymTile extends StatelessWidget {
  const _GymTile({
    required this.gym,
    required this.icon,
    required this.isSelected,
    required this.onTap,
    super.key,
  });

  final GymLocation gym;
  final IconData icon;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.tioColors;
    final textTheme = Theme.of(context).textTheme;

    final subtitleText = gym.distanceKm != null
        ? '${gym.distanceKm!.toStringAsFixed(2)} km - ${gym.address}'
        : gym.address;

    return InkWell(
      borderRadius: BorderRadius.circular(TioRadius.md),
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: TioSpacing.sm + 2),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: TioSize.dp40,
              height: TioSize.dp40,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isSelected
                    ? colors.primary.withValues(alpha: TioOpacity.opacity15)
                    : colors.surfaceVariant,
              ),
              child: Icon(
                icon,
                size: TioSize.dp20,
                color: isSelected ? colors.primary : colors.textPrimary,
              ),
            ),
            const SizedBox(width: TioSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    gym.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: textTheme.bodyLarge?.copyWith(
                      fontWeight:
                          isSelected ? TioFontWeight.w600 : TioFontWeight.w500,
                      color: colors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitleText,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: textTheme.bodySmall?.copyWith(
                      color: colors.textSecondary,
                      height: 1.25,
                    ),
                  ),
                ],
              ),
            ),
            if (isSelected)
              Padding(
                padding: const EdgeInsets.only(left: TioSpacing.sm, top: 4),
                child: Icon(
                  Icons.check_rounded,
                  size: TioSize.dp20,
                  color: colors.primary,
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _CustomSearchTile extends StatelessWidget {
  const _CustomSearchTile({
    required this.query,
    required this.onTap,
  });

  final String query;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.tioColors;
    final textTheme = Theme.of(context).textTheme;

    return InkWell(
      key: const ValueKey('gym-option-custom-search'),
      borderRadius: BorderRadius.circular(TioRadius.md),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(TioSpacing.md),
        decoration: BoxDecoration(
          color: colors.surfaceVariant.withValues(alpha: TioOpacity.opacity50),
          borderRadius: BorderRadius.circular(TioRadius.md),
          border: Border.all(
            color: colors.surfaceVariant,
          ),
        ),
        child: Row(
          children: [
            Icon(
              Icons.add_location_alt_outlined,
              size: TioSize.dp20,
              color: colors.primary,
            ),
            const SizedBox(width: TioSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Use "$query"',
                    style: textTheme.bodyMedium?.copyWith(
                      fontWeight: TioFontWeight.w600,
                      color: colors.textPrimary,
                    ),
                  ),
                  Text(
                    'Select this custom gym name',
                    style: textTheme.bodySmall?.copyWith(
                      color: colors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.chevron_right_rounded,
              size: TioSize.dp20,
              color: colors.textSecondary,
            ),
          ],
        ),
      ),
    );
  }
}

class _LocationPermissionTile extends StatelessWidget {
  const _LocationPermissionTile({
    required this.access,
    required this.onTap,
  });

  final _GymLocationAccess access;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.tioColors;
    final textTheme = Theme.of(context).textTheme;
    final (title, subtitle, icon) = switch (access) {
      _GymLocationAccess.serviceDisabled => (
          'Turn on location',
          'Enable location services to see nearby gyms',
          Icons.location_disabled_outlined,
        ),
      _GymLocationAccess.deniedForever => (
          'Open settings',
          'Allow location access to see nearby gyms',
          Icons.settings_outlined,
        ),
      _ => (
          'Allow location',
          'See nearby gyms around you',
          Icons.my_location_outlined,
        ),
    };

    return InkWell(
      key: const ValueKey('gym-location-permission-option'),
      borderRadius: BorderRadius.circular(TioRadius.md),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(TioSpacing.md),
        decoration: BoxDecoration(
          color: colors.surfaceVariant.withValues(alpha: TioOpacity.opacity50),
          borderRadius: BorderRadius.circular(TioRadius.md),
          border: Border.all(
            color: colors.surfaceVariant,
          ),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              size: TioSize.dp20,
              color: colors.primary,
            ),
            const SizedBox(width: TioSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: textTheme.bodyMedium?.copyWith(
                      fontWeight: TioFontWeight.w600,
                      color: colors.textPrimary,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: textTheme.bodySmall?.copyWith(
                      color: colors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.chevron_right_rounded,
              size: TioSize.dp20,
              color: colors.textSecondary,
            ),
          ],
        ),
      ),
    );
  }
}
