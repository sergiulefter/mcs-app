import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:provider/provider.dart';
import 'package:mcs_app/controllers/doctors_controller.dart';
import 'package:mcs_app/utils/app_theme.dart';
import 'package:mcs_app/views/patient/widgets/cards/doctor_card.dart';
import 'package:mcs_app/views/patient/widgets/cards/doctor_card_skeleton.dart';
import 'package:mcs_app/views/patient/widgets/cards/surface_card.dart';
import 'package:mcs_app/views/patient/widgets/filters/themed_filter_chip.dart';
import 'package:mcs_app/views/patient/widgets/forms/app_search_bar.dart';
import 'package:mcs_app/views/patient/widgets/layout/app_empty_state.dart';
import 'package:mcs_app/views/patient/widgets/layout/section_header.dart';
import 'package:mcs_app/views/shared/widgets/modal_handle_bar.dart';
import 'doctor_profile_screen.dart';

class DoctorsScreen extends StatefulWidget {
  const DoctorsScreen({super.key});

  @override
  State<DoctorsScreen> createState() => _DoctorsScreenState();
}

class _DoctorsScreenState extends State<DoctorsScreen> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<DoctorsController>().prime();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<DoctorsController>();

    return Scaffold(
      body: SafeArea(
        child: controller.isLoading && !controller.hasPrimed
            ? _buildLoadingState(context, controller)
            : controller.error != null && !controller.hasPrimed
                ? _buildErrorState(context)
                : _buildContent(context, controller),
      ),
    );
  }

  Widget _buildLoadingState(
      BuildContext context, DoctorsController controller) {
    return ListView(
      padding: AppTheme.screenPadding,
      children: [
        _buildHeader(context),
        const SizedBox(height: AppTheme.sectionSpacing),
        _buildSearchField(context, controller),
        const SizedBox(height: AppTheme.spacing16),
        _buildSortAndFilterRow(context, controller),
        const SizedBox(height: AppTheme.sectionSpacing),
        // Skeleton cards
        ...List.generate(
          4,
          (index) => const Padding(
            padding: EdgeInsets.only(bottom: AppTheme.spacing20),
            child: DoctorCardSkeleton(),
          ),
        ),
      ],
    );
  }

  Widget _buildErrorState(BuildContext context) {
    return Center(
      child: Padding(
        padding: AppTheme.screenPadding,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SurfaceCard(
              padding: const EdgeInsets.all(AppTheme.spacing16),
              backgroundColor:
                  Theme.of(context).colorScheme.error.withValues(alpha: 0.1),
              borderColor:
                  Theme.of(context).colorScheme.error.withValues(alpha: 0.3),
              showShadow: false,
              child: Icon(
                Icons.error_outline,
                size: 36,
                color: Theme.of(context).colorScheme.error,
              ),
            ),
            const SizedBox(height: AppTheme.spacing16),
            Text(
              'doctors.error_loading_title'.tr(),
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
            ),
            const SizedBox(height: AppTheme.spacing8),
            Text(
              'doctors.error_loading_subtitle'.tr(),
              style: Theme.of(context).textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppTheme.spacing24),
            ElevatedButton.icon(
              onPressed: () => context.read<DoctorsController>().fetchDoctors(),
              icon: const Icon(Icons.refresh),
              label: Text('common.retry'.tr()),
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(200, 56),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContent(BuildContext context, DoctorsController controller) {
    final filteredDoctors = controller.filteredDoctors;

    return RefreshIndicator(
      onRefresh: () => context.read<DoctorsController>().refresh(),
      child: ListView(
        padding: AppTheme.screenPadding,
        children: [
          _buildHeader(context),
          const SizedBox(height: AppTheme.sectionSpacing),
          _buildSearchField(context, controller),
          const SizedBox(height: AppTheme.spacing16),
          _buildSortAndFilterRow(context, controller),
          const SizedBox(height: AppTheme.sectionSpacing),
          _buildResultsHeader(context, filteredDoctors.length),
          const SizedBox(height: AppTheme.spacing16),
          if (filteredDoctors.isEmpty)
            _buildEmptyState(context)
          else
            ...filteredDoctors.map((doctor) {
              return Padding(
                padding: const EdgeInsets.only(bottom: AppTheme.spacing20),
                child: DoctorCard(
                  doctor: doctor,
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) =>
                            DoctorProfileScreen(doctor: doctor),
                      ),
                    );
                  },
                ),
              );
            }),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'doctors.title'.tr(),
          style: Theme.of(context).textTheme.displaySmall?.copyWith(
                fontWeight: FontWeight.w700,
              ),
        ),
        const SizedBox(height: AppTheme.spacing12),
        Text(
          'doctors.subtitle'.tr(),
          style: Theme.of(context).textTheme.bodyLarge,
        ),
      ],
    );
  }

  Widget _buildSearchField(
      BuildContext context, DoctorsController controller) {
    // Sync text controller with controller state if needed
    if (_searchController.text != controller.searchQuery) {
      _searchController.text = controller.searchQuery;
    }

    return AppSearchBar(
      controller: _searchController,
      hintText: 'doctors.search_hint'.tr(),
      onChanged: (value) =>
          context.read<DoctorsController>().setSearchQuery(value),
    );
  }

  Widget _buildSortAndFilterRow(
      BuildContext context, DoctorsController controller) {
    return Row(
      children: [
        // Sort dropdown
        Expanded(
          child: _SortDropdown(
            selectedSort: controller.selectedSort,
            onSortChanged: (sort) =>
                context.read<DoctorsController>().setSortOption(sort),
          ),
        ),
        const SizedBox(width: AppTheme.spacing12),
        // Filter button
        _FilterButton(
          activeCount: controller.activeFilterCount,
          onTap: () => _openFiltersSheet(context, controller),
        ),
        if (controller.hasActiveFilters) ...[
          const SizedBox(width: AppTheme.spacing8),
          IconButton(
            onPressed: () => context.read<DoctorsController>().clearFilters(),
            icon: const Icon(Icons.close, size: 20),
            tooltip: 'doctors.filters.clear'.tr(),
            style: IconButton.styleFrom(
              backgroundColor:
                  Theme.of(context).colorScheme.surfaceContainerHighest,
            ),
          ),
        ],
      ],
    );
  }

  Future<void> _openFiltersSheet(
      BuildContext context, DoctorsController controller) async {
    var tempSelectedSpecialties = {...controller.selectedSpecialties};
    var tempSelectedExperienceRanges = {...controller.selectedExperienceRanges};
    var tempAvailableOnly = controller.availableOnly;

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(AppTheme.radiusLarge),
        ),
      ),
      builder: (sheetContext) {
        final bottomInset = MediaQuery.of(sheetContext).viewInsets.bottom;
        return DraggableScrollableSheet(
          expand: false,
          initialChildSize: 0.65,
          minChildSize: 0.5,
          maxChildSize: 0.95,
          builder: (context, scrollController) {
            return StatefulBuilder(
              builder: (context, setModalState) {
                return SafeArea(
                  child: Padding(
                    padding: AppTheme.cardPadding.add(
                      EdgeInsets.only(bottom: bottomInset),
                    ),
                    child: ListView(
                      controller: scrollController,
                      children: [
                        // Handle bar
                        const ModalHandleBar(),
                        const SizedBox(height: AppTheme.spacing20),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Text(
                                'doctors.filters.title'.tr(),
                                style: Theme.of(context)
                                    .textTheme
                                    .titleLarge
                                    ?.copyWith(fontWeight: FontWeight.w700),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.close),
                              onPressed: () => Navigator.of(sheetContext).pop(),
                            ),
                          ],
                        ),
                        const SizedBox(height: AppTheme.spacing16),
                        _buildFiltersContent(
                          context,
                          controller: controller,
                          selectedSpecialties: tempSelectedSpecialties,
                          selectedExperienceRanges: tempSelectedExperienceRanges,
                          availableOnly: tempAvailableOnly,
                          onSpecialtyChanged: (value) {
                            setModalState(() {
                              if (value == 'all') {
                                tempSelectedSpecialties.clear();
                              } else if (tempSelectedSpecialties
                                  .contains(value)) {
                                tempSelectedSpecialties.remove(value);
                              } else {
                                tempSelectedSpecialties.add(value);
                              }
                            });
                          },
                          onExperienceChanged: (value) {
                            setModalState(() {
                              if (tempSelectedExperienceRanges.contains(value)) {
                                tempSelectedExperienceRanges.remove(value);
                              } else {
                                tempSelectedExperienceRanges.add(value);
                              }
                            });
                          },
                          onAvailabilityChanged: (value) {
                            setModalState(() {
                              tempAvailableOnly = value;
                            });
                          },
                        ),
                        const SizedBox(height: AppTheme.spacing16),
                        Row(
                          children: [
                            Expanded(
                              child: OutlinedButton(
                                onPressed: () {
                                  setModalState(() {
                                    tempSelectedSpecialties.clear();
                                    tempSelectedExperienceRanges.clear();
                                    tempAvailableOnly = false;
                                  });
                                  this
                                      .context
                                      .read<DoctorsController>()
                                      .clearFilters();
                                  Navigator.of(sheetContext).pop();
                                },
                                child: FittedBox(
                                  fit: BoxFit.scaleDown,
                                  child: Text('doctors.filters.clear'.tr()),
                                ),
                              ),
                            ),
                            const SizedBox(width: AppTheme.spacing12),
                            Expanded(
                              child: ElevatedButton(
                                onPressed: () {
                                  this
                                      .context
                                      .read<DoctorsController>()
                                      .applyFilters(
                                        specialties: tempSelectedSpecialties,
                                        experienceRanges:
                                            tempSelectedExperienceRanges,
                                        availableOnly: tempAvailableOnly,
                                      );
                                  Navigator.of(sheetContext).pop();
                                },
                                child: Text('common.apply'.tr()),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              },
            );
          },
        );
      },
    );
  }

  Widget _buildFiltersContent(
    BuildContext context, {
    required DoctorsController controller,
    required Set<String> selectedSpecialties,
    required Set<String> selectedExperienceRanges,
    required bool availableOnly,
    required ValueChanged<String> onSpecialtyChanged,
    required ValueChanged<String> onExperienceChanged,
    required ValueChanged<bool> onAvailabilityChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionHeader(title: 'doctors.filters.specialty'.tr()),
        const SizedBox(height: AppTheme.spacing12),
        Wrap(
          spacing: AppTheme.spacing12,
          runSpacing: AppTheme.spacing12,
          children: controller.availableSpecialties.map((specialty) {
            final isAll = specialty == 'all';
            final isSelected = isAll
                ? selectedSpecialties.isEmpty
                : selectedSpecialties.contains(specialty);
            final label = isAll
                ? 'doctors.filters.all_specialties'.tr()
                : 'specialties.$specialty'.tr();
            return ThemedFilterChip(
              label: label,
              selected: isSelected,
              onSelected: (_) => onSpecialtyChanged(specialty),
              hideIconWhenSelected: true,
            );
          }).toList(),
        ),
        const SizedBox(height: AppTheme.spacing24),
        SectionHeader(title: 'doctors.filters.experience'.tr()),
        const SizedBox(height: AppTheme.spacing12),
        Wrap(
          spacing: AppTheme.spacing12,
          runSpacing: AppTheme.spacing12,
          children: [
            {'key': '0_5', 'label': 'doctors.filters.experience_0_5'.tr()},
            {'key': '5_10', 'label': 'doctors.filters.experience_5_10'.tr()},
            {'key': '10_15', 'label': 'doctors.filters.experience_10_15'.tr()},
            {
              'key': '15_plus',
              'label': 'doctors.filters.experience_15_plus'.tr()
            },
          ].map((range) {
            final key = range['key']!;
            final isSelected = selectedExperienceRanges.contains(key);
            return ThemedFilterChip(
              label: range['label']!,
              selected: isSelected,
              onSelected: (_) => onExperienceChanged(key),
              hideIconWhenSelected: true,
            );
          }).toList(),
        ),
        const SizedBox(height: AppTheme.spacing24),
        SectionHeader(title: 'doctors.filters.availability'.tr()),
        const SizedBox(height: AppTheme.spacing12),
        ThemedFilterChip(
          label: 'doctors.filters.available_now'.tr(),
          selected: availableOnly,
          onSelected: (_) => onAvailabilityChanged(!availableOnly),
          icon: Icons.schedule,
          hideIconWhenSelected: true,
        ),
      ],
    );
  }

  Widget _buildResultsHeader(BuildContext context, int count) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              'doctors.results_title'.tr(),
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
            ),
          ),
        ),
        Flexible(
          child: Text(
            'doctors.results_count'.tr(namedArgs: {'count': count.toString()}),
            style: Theme.of(context).textTheme.bodyMedium,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return AppEmptyState(
      icon: Icons.search_off_outlined,
      title: 'doctors.empty_state_title'.tr(),
      subtitle: 'doctors.empty_state_subtitle'.tr(),
      iconColor: Theme.of(context).colorScheme.primary,
    );
  }
}

class _SortDropdown extends StatefulWidget {
  const _SortDropdown({
    required this.selectedSort,
    required this.onSortChanged,
  });

  final String selectedSort;
  final ValueChanged<String> onSortChanged;

  @override
  State<_SortDropdown> createState() => _SortDropdownState();
}

class _SortDropdownState extends State<_SortDropdown> {
  bool _isOpen = false;
  final MenuController _menuController = MenuController();

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final borderColor = Theme.of(context).dividerColor;
    final backgroundColor = colorScheme.surfaceContainerLow;

    final sortOptions = [
      {'key': 'availability', 'label': 'doctors.sort.availability'.tr()},
      {'key': 'experience', 'label': 'doctors.sort.experience'.tr()},
      {'key': 'price_asc', 'label': 'doctors.sort.price_asc'.tr()},
      {'key': 'price_desc', 'label': 'doctors.sort.price_desc'.tr()},
      {'key': 'name', 'label': 'doctors.sort.name'.tr()},
    ];

    final selectedLabel =
        sortOptions.firstWhere((o) => o['key'] == widget.selectedSort)['label']!;

    return MenuAnchor(
      controller: _menuController,
      onOpen: () => setState(() => _isOpen = true),
      onClose: () => setState(() => _isOpen = false),
      style: MenuStyle(
        shape: WidgetStatePropertyAll(
          RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
          ),
        ),
      ),
      menuChildren: sortOptions.map((option) {
        final isSelected = option['key'] == widget.selectedSort;
        return MenuItemButton(
          onPressed: () {
            widget.onSortChanged(option['key']!);
            _menuController.close();
          },
          child: Row(
            children: [
              Expanded(
                child: Text(
                  option['label']!,
                  style: TextStyle(
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                    color: isSelected ? colorScheme.primary : null,
                  ),
                ),
              ),
              if (isSelected)
                Icon(
                  Icons.check,
                  size: 18,
                  color: colorScheme.primary,
                ),
            ],
          ),
        );
      }).toList(),
      child: InkWell(
        onTap: () {
          if (_menuController.isOpen) {
            _menuController.close();
          } else {
            _menuController.open();
          }
        },
        borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
        overlayColor: WidgetStateProperty.resolveWith(
          (states) {
            if (states.contains(WidgetState.pressed)) {
              return colorScheme.onSurface.withValues(alpha: 0.06);
            }
            if (states.contains(WidgetState.hovered) ||
                states.contains(WidgetState.focused)) {
              return colorScheme.onSurface.withValues(alpha: 0.03);
            }
            return null;
          },
        ),
        child: Ink(
          padding: const EdgeInsets.symmetric(
            horizontal: AppTheme.spacing16,
            vertical: AppTheme.spacing12,
          ),
          decoration: BoxDecoration(
            color: backgroundColor,
            border: Border.all(color: borderColor),
            borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
          ),
          child: Row(
            children: [
              Icon(
                Icons.sort,
                size: 20,
                color: colorScheme.onSurfaceVariant,
              ),
              const SizedBox(width: AppTheme.spacing8),
              Expanded(
                child: Text(
                  selectedLabel,
                  style: Theme.of(context).textTheme.bodyMedium,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              AnimatedRotation(
                turns: _isOpen ? 0.5 : 0,
                duration: const Duration(milliseconds: 250),
                curve: Curves.easeOutCubic,
                child: Icon(
                  Icons.keyboard_arrow_down,
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _FilterButton extends StatefulWidget {
  const _FilterButton({
    required this.activeCount,
    required this.onTap,
  });

  final int activeCount;
  final VoidCallback onTap;

  @override
  State<_FilterButton> createState() => _FilterButtonState();
}

class _FilterButtonState extends State<_FilterButton> {
  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final borderColor = widget.activeCount > 0
        ? colorScheme.primary
        : Theme.of(context).dividerColor;
    final backgroundColor = widget.activeCount > 0
        ? colorScheme.primary.withValues(alpha: 0.08)
        : colorScheme.surfaceContainerLow;

    return InkWell(
      onTap: widget.onTap,
      borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
      overlayColor: WidgetStateProperty.resolveWith(
        (states) {
          if (states.contains(WidgetState.pressed)) {
            return colorScheme.onSurface.withValues(alpha: 0.06);
          }
          if (states.contains(WidgetState.hovered) ||
              states.contains(WidgetState.focused)) {
            return colorScheme.onSurface.withValues(alpha: 0.03);
          }
          return null;
        },
      ),
      child: Ink(
        decoration: BoxDecoration(
          border: Border.all(color: borderColor),
          borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
          color: backgroundColor,
        ),
        padding: const EdgeInsets.all(AppTheme.spacing12),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.tune,
              size: 20,
              color: widget.activeCount > 0
                  ? colorScheme.primary
                  : colorScheme.onSurfaceVariant,
            ),
            if (widget.activeCount > 0) ...[
              const SizedBox(width: AppTheme.spacing4),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 6,
                  vertical: 2,
                ),
                decoration: BoxDecoration(
                  color: colorScheme.primary,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  widget.activeCount.toString(),
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: colorScheme.onPrimary,
                        fontWeight: FontWeight.w600,
                      ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
