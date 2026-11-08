import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:tio_core/core.dart';

/// Represents a gym location option.
class GymLocation {
  const GymLocation({
    required this.id,
    required this.name,
    required this.address,
    this.distanceKm,
    this.isPrivate = false,
  });

  final String id;
  final String name;
  final String address;
  final double? distanceKm;
  final bool isPrivate;

  static const homeGym = GymLocation(
    id: 'home_gym',
    name: 'Home gym',
    address: 'Private location',
    isPrivate: true,
  );

  static const List<GymLocation> defaultPopularGyms = [
    GymLocation(
      id: 'sky_mangyawas',
      name: 'Sky Fitness - Best Gym in Mangyawas, Mansarover',
      address: 'Maharani Garden Road, Mansarover, Rajat Path, Jaipur, Rajasthan',
      distanceKm: 1.86,
    ),
    GymLocation(
      id: 'sky_ajmer_road',
      name: 'Sky Fitness - Best Gym In Ajmer Road, Jaipur',
      address:
          '1st Floor, ML Tower, Metro Pillar No-01, Teja Circle, Gopalpura Bypass Rd, Jaipur',
      distanceKm: 2.68,
    ),
    GymLocation(
      id: 'm_fit_studio',
      name: 'M-Fit Studio',
      address:
          '9/216, Chitrakoot Marg, Akruti Apartments, Vaishali Nagar, Jaipur, Rajasthan',
      distanceKm: 4.88,
    ),
    GymLocation(
      id: 'golds_gym',
      name: "Gold's Gym",
      address: 'Malviya Nagar, Jaipur, Rajasthan',
      distanceKm: 6.20,
    ),
    GymLocation(
      id: 'anytime_fitness',
      name: 'Anytime Fitness',
      address: 'C-Scheme, Ashok Nagar, Jaipur, Rajasthan',
      distanceKm: 7.50,
    ),
  ];
}

/// Screen allowing the user to search and select a gym location.
class GymSelectionPage extends StatefulWidget {
  const GymSelectionPage({
    this.currentGymName,
    super.key,
  });

  final String? currentGymName;

  @override
  State<GymSelectionPage> createState() => _GymSelectionPageState();
}

class _GymSelectionPageState extends State<GymSelectionPage> {
  final TextEditingController _searchController = TextEditingController();
  String _query = '';

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() {
      final text = _searchController.text.trim();
      if (text != _query) {
        setState(() => _query = text);
      }
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<GymLocation> get _filteredPopularGyms {
    if (_query.isEmpty) return GymLocation.defaultPopularGyms;
    final lower = _query.toLowerCase();
    return GymLocation.defaultPopularGyms.where((g) {
      return g.name.toLowerCase().contains(lower) ||
          g.address.toLowerCase().contains(lower);
    }).toList();
  }

  bool get _matchesHomeGym {
    if (_query.isEmpty) return true;
    final lower = _query.toLowerCase();
    return GymLocation.homeGym.name.toLowerCase().contains(lower) ||
        GymLocation.homeGym.address.toLowerCase().contains(lower);
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
    final filtered = _filteredPopularGyms;

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
                        fillColor: Colors.transparent,
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
                    gym: GymLocation.homeGym,
                    icon: Icons.home_outlined,
                    isSelected: widget.currentGymName == GymLocation.homeGym.name,
                    onTap: () => _selectGym(GymLocation.homeGym),
                  ),
                  const SizedBox(height: TioSpacing.md),
                ],

                // If user typed a search not in the list, offer to use it
                if (_query.isNotEmpty &&
                    !filtered.any((g) =>
                        g.name.toLowerCase() == _query.toLowerCase())) ...[
                  _CustomSearchTile(
                    query: _query,
                    onTap: () => _selectCustomLocation(_query),
                  ),
                  const SizedBox(height: TioSpacing.md),
                ],

                // Popular gyms Section
                if (filtered.isNotEmpty) ...[
                  Padding(
                    padding: const EdgeInsets.only(
                      top: TioSpacing.sm,
                      bottom: TioSpacing.sm,
                    ),
                    child: Text(
                      'Popular gyms',
                      style: textTheme.titleSmall?.copyWith(
                        color: colors.textSecondary,
                        fontWeight: TioFontWeight.w600,
                      ),
                    ),
                  ),
                  for (final gym in filtered)
                    _GymTile(
                      key: ValueKey('gym-option-${gym.id}'),
                      gym: gym,
                      icon: Icons.location_on_outlined,
                      isSelected: widget.currentGymName == gym.name,
                      onTap: () => _selectGym(gym),
                    ),
                ] else if (!_matchesHomeGym && _query.isEmpty) ...[
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: TioSpacing.xl),
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
                    ? colors.primary.withValues(alpha: 0.15)
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
      borderRadius: BorderRadius.circular(TioRadius.md),
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: TioSpacing.sm),
        child: Row(
          children: [
            Container(
              width: TioSize.dp40,
              height: TioSize.dp40,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: colors.primary.withValues(alpha: 0.15),
              ),
              child: Icon(
                Icons.add_location_alt_outlined,
                size: TioSize.dp20,
                color: colors.primary,
              ),
            ),
            const SizedBox(width: TioSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Use "$query"',
                    style: textTheme.bodyLarge?.copyWith(
                      fontWeight: TioFontWeight.w600,
                      color: colors.primary,
                    ),
                  ),
                  Text(
                    'Set as custom gym location',
                    style: textTheme.bodySmall?.copyWith(
                      color: colors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
