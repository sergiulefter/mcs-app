import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:mcs_app/controllers/doctors_controller.dart';

import 'package:mcs_app/views/patient/widgets/cards/doctor_card.dart';
import 'package:mcs_app/views/patient/widgets/cards/doctor_card_skeleton.dart';
import 'package:mcs_app/views/patient/widgets/layout/app_empty_state.dart';
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
    // Sync text controller if needed (though usually avoiding loop is good)
    if (_searchController.text != controller.searchQuery) {
      _searchController.text = controller.searchQuery;
    }

    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            _buildHeader(context, controller),
            _buildCategoryPills(context, controller),
            Expanded(
              child: controller.isLoading && !controller.hasPrimed
                  ? _buildLoadingList()
                  : _buildDoctorList(context, controller),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, DoctorsController controller) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor.withValues(alpha: 0.9),
      ),
      child: Column(
        children: [
          // Search Row
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _searchController,
                  onChanged: (value) => controller.setSearchQuery(value),
                  decoration: InputDecoration(
                    hintText: 'doctors.search_hint'.tr(),
                    hintStyle: TextStyle(
                      color: Theme.of(context).hintColor,
                      fontSize: 14,
                    ),
                    prefixIcon: Icon(
                      Icons.search,
                      color: Theme.of(context).hintColor,
                    ),
                    filled: true,
                    fillColor: Theme.of(context).cardColor,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(
                        color: Theme.of(context).dividerColor,
                      ),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(
                        color: Theme.of(context).dividerColor,
                      ),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(
                        color: Theme.of(context).primaryColor,
                        width: 1.5,
                      ),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      vertical: 0, // Icons ensure height
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Tools Row: Sort + Filter
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(child: _AnimatedSortDropdown(controller: controller)),
              const SizedBox(width: 8),
              _buildFilterButton(context, controller),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFilterButton(
    BuildContext context,
    DoctorsController controller,
  ) {
    final activeCount = controller.activeFilterCount;
    final colorScheme = Theme.of(context).colorScheme;
    final isActive = activeCount > 0;

    final backgroundColor = isActive
        ? colorScheme.primary
        : Theme.of(context).cardColor;
    final iconColor = isActive
        ? colorScheme.onPrimary
        : Theme.of(context).disabledColor;

    return InkWell(
      onTap: () => _openFiltersSheet(context, controller),
      borderRadius: BorderRadius.circular(16),
      child: Container(
        width: 46,
        height: 46,
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: isActive
                  ? colorScheme.primary.withValues(alpha: 0.3)
                  : Colors.black.withValues(alpha: 0.03),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Center(
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Icon(Icons.tune, color: iconColor),
              if (isActive)
                Positioned(
                  top: -8,
                  right: -8,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: colorScheme.onPrimary,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: backgroundColor,
                        width: 2,
                      ), // Add border to separate from bg
                    ),
                    child: Text(
                      activeCount.toString(),
                      style: TextStyle(
                        color: colorScheme.primary,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCategoryPills(
    BuildContext context,
    DoctorsController controller,
  ) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      height: 50,
      margin: const EdgeInsets.only(bottom: 8),
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        scrollDirection: Axis.horizontal,
        itemCount: controller.availableSpecialties.length,
        separatorBuilder: (context, index) => const SizedBox(width: 12),
        itemBuilder: (context, index) {
          final specialty = controller.availableSpecialties[index];
          final isSelected = specialty == 'all'
              ? controller.selectedSpecialties.isEmpty
              : controller.selectedSpecialties.contains(specialty);

          final label = specialty == 'all'
              ? 'doctors.filters.all_specialties'
                    .tr() // Or just "All"
              : 'specialties.$specialty'.tr();

          final backgroundColor = isSelected
              ? colorScheme.primary
              : Theme.of(context).cardColor;
          final foregroundColor = isSelected
              ? colorScheme.onPrimary
              : Theme.of(context).textTheme.bodyMedium?.color;

          return InkWell(
            onTap: () => controller.toggleSpecialty(specialty),
            borderRadius: BorderRadius.circular(24),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: backgroundColor,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                  color: isSelected
                      ? Colors.transparent
                      : Theme.of(context).dividerColor,
                ),
                boxShadow: isSelected
                    ? [
                        BoxShadow(
                          color: colorScheme.primary.withValues(alpha: 0.3),
                          blurRadius: 8,
                          offset: const Offset(0, 4),
                        ),
                      ]
                    : [],
              ),
              child: Row(
                children: [
                  Text(
                    label,
                    style: TextStyle(
                      color: foregroundColor,
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildLoadingList() {
    return ListView.builder(
      padding: const EdgeInsets.all(20),
      itemCount: 4,
      itemBuilder: (context, index) => const Padding(
        padding: EdgeInsets.only(bottom: 20),
        child: DoctorCardSkeleton(),
      ),
    );
  }

  Widget _buildDoctorList(BuildContext context, DoctorsController controller) {
    final filteredDoctors = controller.filteredDoctors;

    return NotificationListener<ScrollNotification>(
      onNotification: (scrollInfo) {
        if (scrollInfo.metrics.pixels >=
            scrollInfo.metrics.maxScrollExtent - 200) {
          controller.fetchMore();
        }
        return false;
      },
      child: RefreshIndicator(
        onRefresh: () => controller.refresh(),
        child: filteredDoctors.isEmpty
            ? _buildEmptyState(context)
            : ListView.builder(
                padding: const EdgeInsets.fromLTRB(
                  20,
                  0,
                  20,
                  80,
                ), // Bottom padding for FAB/Nav
                itemCount:
                    filteredDoctors.length + (controller.hasMore ? 1 : 0),
                itemBuilder: (context, index) {
                  if (index == filteredDoctors.length) {
                    return const Center(
                      child: Padding(
                        padding: EdgeInsets.all(16.0),
                        child: CircularProgressIndicator(),
                      ),
                    );
                  }
                  final doctor = filteredDoctors[index];
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 16),
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
                },
              ),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return AppEmptyState(
      icon: Icons.search_off_outlined,
      title: 'doctors.empty_state_title'.tr(),
      subtitle: 'doctors.empty_state_subtitle'.tr(),
      iconColor: Theme.of(context).primaryColor,
    );
  }

  Future<void> _openFiltersSheet(
    BuildContext context,
    DoctorsController controller,
  ) async {
    // Reuse existing filter sheet logic, preserving context
    final tempSelectedSpecialties = {...controller.selectedSpecialties};
    final tempSelectedSubspecialties = {...controller.selectedSubspecialties};
    final tempSelectedLanguages = {...controller.selectedLanguages};
    final tempSelectedExperienceRanges = {...controller.selectedExperienceRanges};
    var tempAvailableOnly = controller.availableOnly;

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (sheetContext) {
        return DraggableScrollableSheet(
          expand: false,
          initialChildSize: 0.7,
          minChildSize: 0.5,
          maxChildSize: 0.95,
          builder: (context, scrollController) {
            return StatefulBuilder(
              builder: (context, setModalState) {
                // Determine valid subspecialties based on current selection
                final availableSubspecialties = controller.getSubspecialtiesFor(
                  tempSelectedSpecialties,
                );

                return Padding(
                  padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'doctors.filters.title'.tr(),
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          TextButton(
                            onPressed: () {
                              setModalState(() {
                                tempSelectedSpecialties.clear();
                                tempSelectedSubspecialties.clear();
                                tempSelectedLanguages.clear();
                                tempSelectedExperienceRanges.clear();
                                tempAvailableOnly = false;
                              });
                            },
                            child: Text('doctors.filters.clear'.tr()),
                          ),
                        ],
                      ),
                      Expanded(
                        child: ListView(
                          controller: scrollController,
                          children: [
                            // Specialty Section
                            if (controller.availableSpecialties.length > 1) ...[
                              _buildFilterSection(
                                context,
                                'doctors.filters.specialty'.tr(),
                                controller.availableSpecialties.map((
                                  specialty,
                                ) {
                                  final isSelected = tempSelectedSpecialties
                                      .contains(specialty);
                                  return FilterChip(
                                    label: Text(
                                      specialty == 'all'
                                          ? 'common.all'.tr()
                                          : 'specialties.$specialty'.tr(),
                                      style: TextStyle(
                                        color: isSelected
                                            ? Theme.of(
                                                context,
                                              ).colorScheme.primary
                                            : Theme.of(
                                                context,
                                              ).colorScheme.onSurface,
                                        fontWeight: isSelected
                                            ? FontWeight.w600
                                            : FontWeight.w400,
                                      ),
                                    ),
                                    selected: isSelected,
                                    selectedColor: Theme.of(context)
                                        .colorScheme
                                        .primaryContainer
                                        .withValues(alpha: 0.2),
                                    checkmarkColor: Theme.of(
                                      context,
                                    ).colorScheme.primary,
                                    backgroundColor: Theme.of(
                                      context,
                                    ).colorScheme.surface,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(20),
                                      side: BorderSide(
                                        color: isSelected
                                            ? Colors.transparent
                                            : Theme.of(context).dividerColor,
                                      ),
                                    ),
                                    onSelected: (val) {
                                      setModalState(() {
                                        if (specialty == 'all') {
                                          tempSelectedSpecialties.clear();
                                        } else if (isSelected) {
                                          tempSelectedSpecialties.remove(
                                            specialty,
                                          );
                                        } else {
                                          tempSelectedSpecialties.add(
                                            specialty,
                                          );
                                        }
                                        // Clear subspecialties if parent specialty removed could be done here,
                                        // but filtering on apply is safer and easier.
                                      });
                                    },
                                  );
                                }).toList(),
                              ),
                              const SizedBox(height: 24),
                            ],

                            // Subspecialty Section - ONLY SHOW IF VALID OPTIONS EXIST
                            if (availableSubspecialties.isNotEmpty) ...[
                              _buildFilterSection(
                                context,
                                'doctors.filters.subspecialty'.tr(),
                                availableSubspecialties.map((sub) {
                                  final isSelected = tempSelectedSubspecialties
                                      .contains(sub);
                                  return FilterChip(
                                    label: Text(
                                      sub,
                                      style: TextStyle(
                                        color: isSelected
                                            ? Theme.of(
                                                context,
                                              ).colorScheme.primary
                                            : Theme.of(
                                                context,
                                              ).colorScheme.onSurface,
                                        fontWeight: isSelected
                                            ? FontWeight.w600
                                            : FontWeight.w400,
                                      ),
                                    ),
                                    selected: isSelected,
                                    selectedColor: Theme.of(context)
                                        .colorScheme
                                        .primaryContainer
                                        .withValues(alpha: 0.2),
                                    checkmarkColor: Theme.of(
                                      context,
                                    ).colorScheme.primary,
                                    backgroundColor: Theme.of(
                                      context,
                                    ).colorScheme.surface,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(20),
                                      side: BorderSide(
                                        color: isSelected
                                            ? Colors.transparent
                                            : Theme.of(context).dividerColor,
                                      ),
                                    ),
                                    onSelected: (val) {
                                      setModalState(() {
                                        if (isSelected) {
                                          tempSelectedSubspecialties.remove(
                                            sub,
                                          );
                                        } else {
                                          tempSelectedSubspecialties.add(sub);
                                        }
                                      });
                                    },
                                  );
                                }).toList(),
                              ),
                              const SizedBox(height: 24),
                            ],

                            // Language Section
                            if (controller.availableLanguages.isNotEmpty) ...[
                              _buildFilterSection(
                                context,
                                'doctors.filters.language'.tr(),
                                controller.availableLanguages.map((lang) {
                                  final isSelected = tempSelectedLanguages
                                      .contains(lang);
                                  return FilterChip(
                                    label: Text(
                                      lang,
                                      style: TextStyle(
                                        color: isSelected
                                            ? Theme.of(
                                                context,
                                              ).colorScheme.primary
                                            : Theme.of(
                                                context,
                                              ).colorScheme.onSurface,
                                        fontWeight: isSelected
                                            ? FontWeight.w600
                                            : FontWeight.w400,
                                      ),
                                    ),
                                    selected: isSelected,
                                    selectedColor: Theme.of(context)
                                        .colorScheme
                                        .primaryContainer
                                        .withValues(alpha: 0.2),
                                    checkmarkColor: Theme.of(
                                      context,
                                    ).colorScheme.primary,
                                    backgroundColor: Theme.of(
                                      context,
                                    ).colorScheme.surface,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(20),
                                      side: BorderSide(
                                        color: isSelected
                                            ? Colors.transparent
                                            : Theme.of(context).dividerColor,
                                      ),
                                    ),
                                    onSelected: (val) {
                                      setModalState(() {
                                        if (isSelected) {
                                          tempSelectedLanguages.remove(lang);
                                        } else {
                                          tempSelectedLanguages.add(lang);
                                        }
                                      });
                                    },
                                  );
                                }).toList(),
                              ),
                              const SizedBox(height: 24),
                            ],

                            _buildFilterSection(
                              context,
                              'doctors.filters.availability'.tr(),
                              [
                                FilterChip(
                                  label: Text(
                                    'doctors.filters.available_now'.tr(),
                                    style: TextStyle(
                                      color: tempAvailableOnly
                                          ? Theme.of(
                                              context,
                                            ).colorScheme.primary
                                          : Theme.of(
                                              context,
                                            ).colorScheme.onSurface,
                                      fontWeight: tempAvailableOnly
                                          ? FontWeight.w600
                                          : FontWeight.w400,
                                    ),
                                  ),
                                  selected: tempAvailableOnly,
                                  selectedColor: Theme.of(context)
                                      .colorScheme
                                      .primaryContainer
                                      .withValues(alpha: 0.2),
                                  checkmarkColor: Theme.of(
                                    context,
                                  ).colorScheme.primary,
                                  backgroundColor: Theme.of(
                                    context,
                                  ).colorScheme.surface,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(20),
                                    side: BorderSide(
                                      color: tempAvailableOnly
                                          ? Colors.transparent
                                          : Theme.of(context).dividerColor,
                                    ),
                                  ),
                                  onSelected: (val) => setModalState(
                                    () => tempAvailableOnly = val,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      SizedBox(
                        width: double.infinity,
                        height: 56,
                        child: FilledButton(
                          onPressed: () {
                            // Ensure we only apply subspecialties that are valid for selected specialties
                            final validSubspecialties = availableSubspecialties
                                .toSet();
                            final finalSubspecialties =
                                tempSelectedSubspecialties.intersection(
                                  validSubspecialties,
                                );

                            controller.applyFilters(
                              specialties: tempSelectedSpecialties,
                              subspecialties: finalSubspecialties,
                              languages: tempSelectedLanguages,
                              experienceRanges: tempSelectedExperienceRanges,
                              availableOnly: tempAvailableOnly,
                            );
                            Navigator.pop(sheetContext);
                          },
                          child: Text('common.apply'.tr()),
                        ),
                      ),
                    ],
                  ),
                );
              },
            );
          },
        );
      },
    );
  }

  Widget _buildFilterSection(
    BuildContext context,
    String title,
    List<Widget> children,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 12),
        Wrap(spacing: 8, runSpacing: 8, children: children),
      ],
    );
  }
}

class _AnimatedSortDropdown extends StatefulWidget {
  final DoctorsController controller;

  const _AnimatedSortDropdown({required this.controller});

  @override
  State<_AnimatedSortDropdown> createState() => _AnimatedSortDropdownState();
}

class _AnimatedSortDropdownState extends State<_AnimatedSortDropdown>
    with SingleTickerProviderStateMixin {
  final LayerLink _layerLink = LayerLink();
  OverlayEntry? _overlayEntry;
  bool _isExpanded = false;
  late AnimationController _animationController;
  late Animation<double> _expandAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
    );
    _expandAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    );
  }

  void _toggleDropdown() {
    if (_isExpanded) {
      _animationController.reverse().then((_) {
        _overlayEntry?.remove();
        _overlayEntry = null;
        if (mounted) {
          setState(() {
            _isExpanded = false;
          });
        }
      });
    } else {
      _overlayEntry = _createOverlayEntry();
      Overlay.of(context).insert(_overlayEntry!);
      _animationController.forward();
      setState(() {
        _isExpanded = true;
      });
    }
  }

  OverlayEntry _createOverlayEntry() {
    final RenderBox renderBox = context.findRenderObject() as RenderBox;
    final size = renderBox.size;

    // Sort labels map (same as in build)
    final sortLabels = {
      'availability': 'doctors.sort.availability'.tr(),
      'price_asc': 'doctors.sort.price_asc'.tr(),
      'price_desc': 'doctors.sort.price_desc'.tr(),
      'name': 'doctors.sort.name'.tr(),
      'experience': 'doctors.sort.experience'.tr(),
    };

    return OverlayEntry(
      builder: (context) => Stack(
        children: [
          // Transparent barrier to close dropdown on outside tap
          Positioned.fill(
            child: GestureDetector(
              onTap: _toggleDropdown,
              behavior: HitTestBehavior.translucent,
              child: Container(color: Colors.transparent),
            ),
          ),
          Positioned(
            width: size.width,
            child: CompositedTransformFollower(
              link: _layerLink,
              showWhenUnlinked: false,
              offset: Offset(0, size.height + 8),
              child: Material(
                color: Colors.transparent,
                child: FadeTransition(
                  opacity: _expandAnimation,
                  child: SizeTransition(
                    sizeFactor: _expandAnimation,
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      decoration: BoxDecoration(
                        color: Theme.of(context).cardColor,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: Theme.of(context).dividerColor,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.1),
                            blurRadius: 16,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: sortLabels.entries.map((entry) {
                          final isSelected =
                              widget.controller.selectedSort == entry.key;
                          return InkWell(
                            onTap: () {
                              widget.controller.setSortOption(entry.key);
                              _toggleDropdown();
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 12,
                              ),
                              color: isSelected
                                  ? Theme.of(context)
                                        .colorScheme
                                        .primaryContainer
                                        .withValues(alpha: 0.1)
                                  : Colors.transparent,
                              child: Text(
                                entry.value,
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: isSelected
                                      ? FontWeight.w600
                                      : FontWeight.w400,
                                  color: isSelected
                                      ? Theme.of(context).colorScheme.primary
                                      : Theme.of(
                                          context,
                                        ).textTheme.bodyMedium?.color,
                                ),
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    if (_isExpanded && _overlayEntry != null) {
      _overlayEntry?.remove();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Mapping internal sort key to translated label
    final sortLabels = {
      'availability': 'doctors.sort.availability'.tr(),
      'price_asc': 'doctors.sort.price_asc'.tr(),
      'price_desc': 'doctors.sort.price_desc'.tr(),
      'name': 'doctors.sort.name'.tr(),
      'experience': 'doctors.sort.experience'.tr(),
    };

    final currentLabel =
        sortLabels[widget.controller.selectedSort] ?? 'doctors.sort.label'.tr();

    return CompositedTransformTarget(
      link: _layerLink,
      child: InkWell(
        onTap: _toggleDropdown,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          height: 48,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: _isExpanded
                  ? Theme.of(context).primaryColor
                  : Theme.of(context).dividerColor,
              width: _isExpanded ? 1.5 : 1.0,
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  currentLabel,
                  style: TextStyle(
                    fontSize: 14,
                    color: Theme.of(context).textTheme.bodyMedium?.color,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              RotationTransition(
                turns: Tween(begin: 0.0, end: 0.5).animate(_expandAnimation),
                child: Icon(
                  Icons.keyboard_arrow_down,
                  size: 20,
                  color: Theme.of(context).hintColor,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
