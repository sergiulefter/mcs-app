import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import '../../models/doctor_model.dart';
import '../../services/doctor_service.dart';
import '../../utils/app_theme.dart';
import '../widgets/app_empty_state.dart';
import '../widgets/app_search_bar.dart';
import '../widgets/doctor_card.dart';
import 'doctor_profile_screen.dart';

class DoctorsScreen extends StatefulWidget {
  const DoctorsScreen({super.key});

  @override
  State<DoctorsScreen> createState() => _DoctorsScreenState();
}

class _DoctorsScreenState extends State<DoctorsScreen> {
  final TextEditingController _searchController = TextEditingController();
  final DoctorService _doctorService = DoctorService();

  List<DoctorModel> _allDoctors = [];
  bool _isLoading = true;
  String? _errorMessage;

  String _selectedSpecialty = 'all';
  bool _availableOnly = false;

  bool get _hasActiveFilters =>
      _selectedSpecialty != 'all' || _availableOnly;

  @override
  void initState() {
    super.initState();
    _loadDoctors();
  }

  Future<void> _loadDoctors() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final doctors = await _doctorService.fetchAllDoctors();
      setState(() {
        _allDoctors = doctors;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
        _isLoading = false;
      });
    }
  }

  List<String> get _specialtyOptions {
    final specialties = _allDoctors
        .map((d) => d.specialty.toString().split('.').last)
        .toSet()
        .toList()
      ..sort();
    return ['all', ...specialties];
  }

  List<DoctorModel> get _filteredDoctors {
    final searchQuery = _searchController.text.toLowerCase();
    return _allDoctors.where((doctor) {
      final specialtyKey = doctor.specialty.toString().split('.').last;
      final matchesSearch = searchQuery.isEmpty ||
          doctor.fullName.toLowerCase().contains(searchQuery) ||
          specialtyKey.toLowerCase().contains(searchQuery);
      final matchesSpecialty =
          _selectedSpecialty == 'all' || specialtyKey == _selectedSpecialty;
      final matchesAvailability = !_availableOnly || doctor.isCurrentlyAvailable;
      return matchesSearch && matchesSpecialty && matchesAvailability;
    }).toList();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: _isLoading
            ? _buildLoadingState(context)
            : _errorMessage != null
                ? _buildErrorState(context)
                : _buildContent(context),
      ),
    );
  }

  Widget _buildLoadingState(BuildContext context) {
    return const Center(
      child: CircularProgressIndicator(),
    );
  }

  Widget _buildErrorState(BuildContext context) {
    return Center(
      child: Padding(
        padding: AppTheme.screenPadding,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.error.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(AppTheme.radiusCircular),
              ),
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
              onPressed: _loadDoctors,
              icon: const Icon(Icons.refresh),
              label: Text('doctors.retry_button'.tr()),
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(200, 56),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContent(BuildContext context) {
    final filteredDoctors = _filteredDoctors;

    return RefreshIndicator(
      onRefresh: _loadDoctors,
      child: ListView(
        padding: AppTheme.screenPadding,
        children: [
          _buildHeader(context),
          const SizedBox(height: AppTheme.sectionSpacing),
          _buildSearchField(context),
          const SizedBox(height: AppTheme.spacing16),
          _buildFilterActions(context),
          const SizedBox(height: AppTheme.sectionSpacing),
          _buildResultsHeader(context, filteredDoctors.length),
          const SizedBox(height: AppTheme.spacing16),
          if (filteredDoctors.isEmpty)
            _buildEmptyState(context)
          else
            ...filteredDoctors.map((doctor) {
              final availabilityLabel = doctor.isCurrentlyAvailable
                  ? 'doctors.availability_badge.available'.tr()
                  : 'doctors.availability_badge.unavailable'.tr();

              return Padding(
                padding: const EdgeInsets.only(bottom: AppTheme.spacing20),
                child: DoctorCard(
                  doctor: doctor,
                  availabilityLabel: availabilityLabel,
                  availabilityColor: doctor.isCurrentlyAvailable
                      ? Theme.of(context).colorScheme.secondary
                      : Theme.of(context).colorScheme.onSurfaceVariant,
                  viewProfileLabel: 'doctors.view_profile'.tr(),
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) => DoctorProfileScreen(doctor: doctor),
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

  Widget _buildSearchField(BuildContext context) {
    return AppSearchBar(
      controller: _searchController,
      hintText: 'doctors.search_hint'.tr(),
      onChanged: (_) => setState(() {}),
    );
  }

  Widget _buildFilterActions(BuildContext context) {
    final activeCount = [
      if (_selectedSpecialty != 'all') 1,
      if (_availableOnly) 1,
    ].length;

    return Row(
      children: [
        Expanded(
          child: OutlinedButton.icon(
            onPressed: () => _openFiltersSheet(context),
            icon: const Icon(Icons.filter_alt_outlined),
            label: Text(
              activeCount > 0
                  ? 'doctors.filters.active_count'
                      .tr(namedArgs: {'count': activeCount.toString()})
                  : 'doctors.filters.title'.tr(),
            ),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(
                vertical: AppTheme.spacing16,
                horizontal: AppTheme.spacing16,
              ),
            ),
          ),
        ),
        if (_hasActiveFilters) ...[
          const SizedBox(width: AppTheme.spacing12),
          TextButton(
            onPressed: _resetFilters,
            child: Text('doctors.filters.clear'.tr()),
          ),
        ],
      ],
    );
  }

  Future<void> _openFiltersSheet(BuildContext context) async {
    var tempSelectedSpecialty = _selectedSpecialty;
    var tempAvailableOnly = _availableOnly;

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
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'doctors.filters.title'.tr(),
                              style: Theme.of(context)
                                  .textTheme
                                  .titleLarge
                                  ?.copyWith(fontWeight: FontWeight.w700),
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
                          selectedSpecialty: tempSelectedSpecialty,
                          availableOnly: tempAvailableOnly,
                          onSpecialtyChanged: (value) {
                            setModalState(() {
                              tempSelectedSpecialty = value;
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
                                    tempSelectedSpecialty = 'all';
                                    tempAvailableOnly = false;
                                  });
                                  setState(() {
                                    _selectedSpecialty = 'all';
                                    _availableOnly = false;
                                  });
                                  Navigator.of(sheetContext).pop();
                                },
                                child: Text('doctors.filters.clear'.tr()),
                              ),
                            ),
                            const SizedBox(width: AppTheme.spacing12),
                            Expanded(
                              child: ElevatedButton(
                                onPressed: () {
                                  setState(() {
                                    _selectedSpecialty = tempSelectedSpecialty;
                                    _availableOnly = tempAvailableOnly;
                                  });
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
    required String selectedSpecialty,
    required bool availableOnly,
    required ValueChanged<String> onSpecialtyChanged,
    required ValueChanged<bool> onAvailabilityChanged,
  }) {
    final colorScheme = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'doctors.filters.specialty'.tr(),
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
        ),
        const SizedBox(height: AppTheme.spacing12),
        Wrap(
          spacing: AppTheme.spacing12,
          runSpacing: AppTheme.spacing12,
          children: _specialtyOptions.map((specialty) {
            final isSelected = specialty == selectedSpecialty;
            return ChoiceChip(
              label: Text(
                specialty == 'all'
                    ? 'doctors.filters.all_specialties'.tr()
                    : 'specialties.$specialty'.tr(),
              ),
              selected: isSelected,
                onSelected: (_) {
                  onSpecialtyChanged(specialty);
                },
                labelStyle: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: colorScheme.onSurface,
                    ),
                selectedColor: colorScheme.primaryContainer,
                backgroundColor: colorScheme.surfaceContainerHighest,
                checkmarkColor: colorScheme.onPrimaryContainer,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
                  side: BorderSide(
                    color: isSelected
                        ? colorScheme.primary.withValues(alpha: 0.5)
                        : Theme.of(context).dividerColor,
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: AppTheme.spacing24),
        Text(
          'doctors.filters.availability'.tr(),
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
        ),
        const SizedBox(height: AppTheme.spacing12),
        FilterChip(
            selected: availableOnly,
            label: Text('doctors.filters.available_now'.tr()),
            onSelected: (_) => onAvailabilityChanged(!availableOnly),
            labelStyle: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: colorScheme.onSurface,
                ),
            selectedColor: colorScheme.secondaryContainer,
            checkmarkColor: colorScheme.onSecondaryContainer,
            backgroundColor: colorScheme.surfaceContainerHighest,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
              side: BorderSide(
                color: availableOnly
                    ? colorScheme.secondary.withValues(alpha: 0.5)
                    : Theme.of(context).dividerColor,
              ),
            ),
          ),
        ],
      );
    }

  Widget _buildResultsHeader(BuildContext context, int count) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          'doctors.results_title'.tr(),
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w600,
              ),
        ),
        Text(
          'doctors.results_count'.tr(namedArgs: {'count': count.toString()}),
          style: Theme.of(context).textTheme.bodyMedium,
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

  void _resetFilters() {
    setState(() {
      _selectedSpecialty = 'all';
      _availableOnly = false;
    });
  }

}

