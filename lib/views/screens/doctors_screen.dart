import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import '../../models/doctor_model.dart';
import '../../models/medical_specialty.dart';
import '../../services/doctor_service.dart';
import '../../utils/app_theme.dart';
import '../widgets/doctor_card.dart';

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
        .map((d) => d.specialty.name)
        .toSet()
        .toList()
      ..sort();
    return ['all', ...specialties];
  }

  List<DoctorModel> get _filteredDoctors {
    final searchQuery = _searchController.text.toLowerCase();
    return _allDoctors.where((doctor) {
      final matchesSearch = searchQuery.isEmpty ||
          doctor.fullName.toLowerCase().contains(searchQuery) ||
          doctor.specialty.name.toLowerCase().contains(searchQuery);
      final matchesSpecialty =
          _selectedSpecialty == 'all' || doctor.specialty.name == _selectedSpecialty;
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
      backgroundColor: AppTheme.backgroundLight,
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
      child: CircularProgressIndicator(
        valueColor: AlwaysStoppedAnimation<Color>(AppTheme.primaryBlue),
      ),
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
                color: AppTheme.errorRed.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(AppTheme.radiusCircular),
              ),
              child: const Icon(
                Icons.error_outline,
                size: 36,
                color: AppTheme.errorRed,
              ),
            ),
            const SizedBox(height: AppTheme.spacing16),
            Text(
              'doctors.error_loading_title'.tr(),
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: AppTheme.textPrimary,
                    fontWeight: FontWeight.w600,
                  ),
            ),
            const SizedBox(height: AppTheme.spacing8),
            Text(
              'doctors.error_loading_subtitle'.tr(),
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppTheme.textSecondary,
                  ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppTheme.spacing24),
            ElevatedButton.icon(
              onPressed: _loadDoctors,
              icon: const Icon(Icons.refresh),
              label: Text('doctors.retry_button'.tr()),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryBlue,
                foregroundColor: AppTheme.textOnPrimary,
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
      color: AppTheme.primaryBlue,
      child: ListView(
        padding: AppTheme.screenPadding,
        children: [
          _buildHeader(context),
          const SizedBox(height: AppTheme.sectionSpacing),
          _buildSearchField(context),
          const SizedBox(height: AppTheme.sectionSpacing),
          _buildFilters(context),
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
              final availabilityDescription = doctor.isCurrentlyAvailable
                  ? 'doctors.availability_description.available'.tr()
                  : 'doctors.availability_description.unavailable'.tr();

              return Padding(
                padding: const EdgeInsets.only(bottom: AppTheme.spacing20),
                child: DoctorCard(
                  doctor: doctor,
                  availabilityLabel: availabilityLabel,
                  availabilityDescription: availabilityDescription,
                  availabilityColor: doctor.isCurrentlyAvailable
                      ? AppTheme.secondaryGreen
                      : AppTheme.textTertiary,
                  viewProfileLabel: 'doctors.view_profile'.tr(),
                  onTap: () {
                    // TODO: Navigate to DoctorProfileScreen once implemented
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
                color: AppTheme.textPrimary,
                fontWeight: FontWeight.w700,
              ),
        ),
        const SizedBox(height: AppTheme.spacing12),
        Text(
          'doctors.subtitle'.tr(),
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: AppTheme.textSecondary,
              ),
        ),
      ],
    );
  }

  Widget _buildSearchField(BuildContext context) {
    return TextField(
      controller: _searchController,
      onChanged: (_) => setState(() {}),
      decoration: InputDecoration(
        prefixIcon: const Icon(Icons.search_outlined),
        hintText: 'doctors.search_hint'.tr(),
        filled: true,
        fillColor: AppTheme.backgroundWhite,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
          borderSide: BorderSide(color: AppTheme.dividerColor),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
          borderSide: BorderSide(color: AppTheme.dividerColor),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
          borderSide: const BorderSide(color: AppTheme.primaryBlue, width: 2),
        ),
      ),
    );
  }

  Widget _buildFilters(BuildContext context) {
    return Container(
      padding: AppTheme.cardPadding,
      decoration: BoxDecoration(
        color: AppTheme.backgroundWhite,
        borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
        border: Border.all(color: AppTheme.dividerColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'doctors.filters.title'.tr(),
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      color: AppTheme.textPrimary,
                      fontWeight: FontWeight.w600,
                    ),
              ),
              TextButton(
                onPressed: _resetFilters,
                child: Text('doctors.filters.clear'.tr()),
              ),
            ],
          ),
          const SizedBox(height: AppTheme.spacing16),
          Text(
            'doctors.filters.specialty'.tr(),
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: AppTheme.textSecondary,
                  fontWeight: FontWeight.w600,
                ),
          ),
          const SizedBox(height: AppTheme.spacing12),
          Wrap(
            spacing: AppTheme.spacing12,
            runSpacing: AppTheme.spacing12,
            children: _specialtyOptions.map((specialty) {
              final isSelected = specialty == _selectedSpecialty;
              return ChoiceChip(
                label: Text(
                  specialty == 'all'
                      ? 'doctors.filters.all_specialties'.tr()
                      : specialty,
                ),
                selected: isSelected,
                onSelected: (_) {
                  setState(() => _selectedSpecialty = specialty);
                },
                labelStyle: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: isSelected ? AppTheme.textOnPrimary : AppTheme.textPrimary,
                      fontWeight: FontWeight.w600,
                    ),
                selectedColor: AppTheme.primaryBlue,
                backgroundColor: AppTheme.backgroundLight,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: AppTheme.spacing24),
          const SizedBox(height: AppTheme.spacing12),
          const SizedBox(height: AppTheme.spacing24),
          Text(
            'doctors.filters.availability'.tr(),
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: AppTheme.textSecondary,
                  fontWeight: FontWeight.w600,
                ),
          ),
          const SizedBox(height: AppTheme.spacing12),
          FilterChip(
            selected: _availableOnly,
            label: Text('doctors.filters.available_now'.tr()),
            onSelected: (_) => setState(() => _availableOnly = !_availableOnly),
            labelStyle: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: _availableOnly ? AppTheme.textOnPrimary : AppTheme.textPrimary,
                  fontWeight: FontWeight.w600,
                ),
            backgroundColor: AppTheme.backgroundLight,
            selectedColor: AppTheme.secondaryGreen,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildResultsHeader(BuildContext context, int count) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          'doctors.results_title'.tr(),
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                color: AppTheme.textPrimary,
                fontWeight: FontWeight.w600,
              ),
        ),
        Text(
          'doctors.results_count'.tr(namedArgs: {'count': count.toString()}),
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: AppTheme.textSecondary,
              ),
        ),
      ],
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Container(
      padding: AppTheme.cardPadding,
      decoration: BoxDecoration(
        color: AppTheme.backgroundWhite,
        borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
        border: Border.all(color: AppTheme.dividerColor),
      ),
      child: Column(
        children: [
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              color: AppTheme.primaryBlue.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(AppTheme.radiusCircular),
            ),
            child: const Icon(
              Icons.search_off_outlined,
              size: 36,
              color: AppTheme.primaryBlue,
            ),
          ),
          const SizedBox(height: AppTheme.spacing16),
          Text(
            'doctors.empty_state_title'.tr(),
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: AppTheme.textPrimary,
                  fontWeight: FontWeight.w600,
                ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppTheme.spacing8),
          Text(
            'doctors.empty_state_subtitle'.tr(),
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppTheme.textSecondary,
                ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  void _resetFilters() {
    setState(() {
      _selectedSpecialty = 'all';
      _availableOnly = false;
    });
  }

}
