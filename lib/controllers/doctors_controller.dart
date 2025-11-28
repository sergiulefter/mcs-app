import 'package:flutter/material.dart';
import '../models/doctor_model.dart';
import '../services/doctor_service.dart';

class DoctorsController extends ChangeNotifier {
  final DoctorService _doctorService = DoctorService();

  // State
  List<DoctorModel> _doctors = [];
  bool _isLoading = false;
  String? _error;
  bool _hasPrimed = false;

  // Filters
  Set<String> _selectedSpecialties = {};
  Set<String> _selectedExperienceRanges = {};
  bool _availableOnly = false;
  String _selectedSort = 'availability';
  String _searchQuery = '';

  // Getters
  List<DoctorModel> get doctors => _doctors;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get hasPrimed => _hasPrimed;
  Set<String> get selectedSpecialties => _selectedSpecialties;
  Set<String> get selectedExperienceRanges => _selectedExperienceRanges;
  bool get availableOnly => _availableOnly;
  String get selectedSort => _selectedSort;
  String get searchQuery => _searchQuery;

  bool get hasActiveFilters =>
      _selectedSpecialties.isNotEmpty ||
      _selectedExperienceRanges.isNotEmpty ||
      _availableOnly;

  int get activeFilterCount {
    int count = 0;
    if (_selectedSpecialties.isNotEmpty) count++;
    if (_selectedExperienceRanges.isNotEmpty) count++;
    if (_availableOnly) count++;
    return count;
  }

  List<String> get availableSpecialties {
    final specialties = _doctors
        .map((d) => d.specialty.toString().split('.').last)
        .toSet()
        .toList()
      ..sort();
    return ['all', ...specialties];
  }

  // Filtered and sorted doctors
  List<DoctorModel> get filteredDoctors {
    var result = _doctors.where((doctor) {
      final specialtyKey = doctor.specialty.toString().split('.').last;

      // Search filter
      if (_searchQuery.isNotEmpty) {
        final query = _searchQuery.toLowerCase();
        if (!doctor.fullName.toLowerCase().contains(query) &&
            !specialtyKey.toLowerCase().contains(query)) {
          return false;
        }
      }

      // Specialty filter
      if (_selectedSpecialties.isNotEmpty &&
          !_selectedSpecialties.contains(specialtyKey)) {
        return false;
      }

      // Experience filter
      if (_selectedExperienceRanges.isNotEmpty) {
        final matches = _selectedExperienceRanges.any(
          (range) => _experienceMatchesRange(doctor.experienceYears, range),
        );
        if (!matches) return false;
      }

      // Availability filter
      if (_availableOnly && !doctor.isCurrentlyAvailable) {
        return false;
      }

      return true;
    }).toList();

    // Apply sorting
    switch (_selectedSort) {
      case 'availability':
        result.sort((a, b) {
          if (a.isCurrentlyAvailable == b.isCurrentlyAvailable) {
            return a.fullName.compareTo(b.fullName);
          }
          return a.isCurrentlyAvailable ? -1 : 1;
        });
      case 'experience':
        result.sort((a, b) => b.experienceYears.compareTo(a.experienceYears));
      case 'price_asc':
        result.sort(
            (a, b) => a.consultationPrice.compareTo(b.consultationPrice));
      case 'price_desc':
        result.sort(
            (a, b) => b.consultationPrice.compareTo(a.consultationPrice));
      case 'name':
        result.sort((a, b) => a.fullName.compareTo(b.fullName));
    }

    return result;
  }

  bool _experienceMatchesRange(int years, String rangeKey) {
    switch (rangeKey) {
      case '0_5':
        return years < 5;
      case '5_10':
        return years >= 5 && years < 10;
      case '10_15':
        return years >= 10 && years < 15;
      case '15_plus':
        return years >= 15;
      default:
        return true;
    }
  }

  // Actions
  Future<void> fetchDoctors() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _doctors = await _doctorService.fetchAllDoctors();
      _error = null;
      _hasPrimed = true;
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Prime data if not already loaded. Skips fetch if already primed unless forced.
  Future<void> prime({bool force = false}) async {
    if (!force && _hasPrimed) {
      return;
    }
    await fetchDoctors();
  }

  void setSearchQuery(String query) {
    _searchQuery = query;
    notifyListeners();
  }

  void setSortOption(String sort) {
    _selectedSort = sort;
    notifyListeners();
  }

  void toggleSpecialty(String specialty) {
    if (specialty == 'all') {
      _selectedSpecialties.clear();
    } else if (_selectedSpecialties.contains(specialty)) {
      _selectedSpecialties.remove(specialty);
    } else {
      _selectedSpecialties.add(specialty);
    }
    notifyListeners();
  }

  void toggleExperienceRange(String range) {
    if (_selectedExperienceRanges.contains(range)) {
      _selectedExperienceRanges.remove(range);
    } else {
      _selectedExperienceRanges.add(range);
    }
    notifyListeners();
  }

  void setAvailableOnly(bool value) {
    _availableOnly = value;
    notifyListeners();
  }

  void clearFilters() {
    _selectedSpecialties.clear();
    _selectedExperienceRanges.clear();
    _availableOnly = false;
    notifyListeners();
  }

  void applyFilters({
    required Set<String> specialties,
    required Set<String> experienceRanges,
    required bool availableOnly,
  }) {
    _selectedSpecialties = specialties;
    _selectedExperienceRanges = experienceRanges;
    _availableOnly = availableOnly;
    notifyListeners();
  }

  /// Refresh doctors list
  Future<void> refresh() async {
    await fetchDoctors();
  }

  /// Clear data (e.g., on logout)
  void clear() {
    _doctors = [];
    _isLoading = false;
    _hasPrimed = false;
    _error = null;
    _selectedSpecialties = {};
    _selectedExperienceRanges = {};
    _availableOnly = false;
    _selectedSort = 'availability';
    _searchQuery = '';
    notifyListeners();
  }
}
