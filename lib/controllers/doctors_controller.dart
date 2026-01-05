import 'dart:collection';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../models/doctor_model.dart';
import '../services/doctor_service.dart';

/// Doctors list controller
class DoctorsController extends ChangeNotifier {
  final DoctorService _doctorService = DoctorService();

  // State - SplayTreeSet for automatic deduplication and sorting
  final Set<DoctorModel> _doctors = SplayTreeSet((a, b) {
    // Default sort: available first, then by name
    if (a.isCurrentlyAvailable != b.isCurrentlyAvailable) {
      return a.isCurrentlyAvailable ? -1 : 1;
    }
    return a.fullName.compareTo(b.fullName);
  });
  bool _isLoading = false;
  bool _hasPrimed = false;

  // Pagination state
  DocumentSnapshot? _lastDocument;
  bool _hasMore = true;

  // Filters
  Set<String> _selectedSpecialties = {};
  Set<String> _selectedSubspecialties = {};
  Set<String> _selectedLanguages = {};
  Set<String> _selectedExperienceRanges = {};
  bool _availableOnly = false;
  String _selectedSort = 'availability';
  String _searchQuery = '';

  // Getters - return List for UI compatibility
  List<DoctorModel> get doctors => List.from(_doctors);
  bool get isLoading => _isLoading;
  bool get hasPrimed => _hasPrimed;
  bool get hasMore => _hasMore;
  Set<String> get selectedSpecialties => _selectedSpecialties;
  Set<String> get selectedSubspecialties => _selectedSubspecialties;
  Set<String> get selectedLanguages => _selectedLanguages;
  Set<String> get selectedExperienceRanges => _selectedExperienceRanges;
  bool get availableOnly => _availableOnly;
  String get selectedSort => _selectedSort;
  String get searchQuery => _searchQuery;

  bool get hasActiveFilters =>
      _selectedSpecialties.isNotEmpty ||
      _selectedSubspecialties.isNotEmpty ||
      _selectedLanguages.isNotEmpty ||
      _selectedExperienceRanges.isNotEmpty ||
      _availableOnly;

  int get activeFilterCount {
    int count = 0;
    if (_selectedSpecialties.isNotEmpty) count++;
    if (_selectedSubspecialties.isNotEmpty) count++;
    if (_selectedLanguages.isNotEmpty) count++;
    if (_selectedExperienceRanges.isNotEmpty) count++;
    if (_availableOnly) count++;
    return count;
  }

  List<String> get availableSpecialties {
    final specialties =
        _doctors
            .map((d) => d.specialty.toString().split('.').last)
            .toSet()
            .toList()
          ..sort();
    return ['all', ...specialties];
  }

  List<String> getSubspecialtiesFor(Set<String> specialtyKeys) {
    if (specialtyKeys.isEmpty || specialtyKeys.contains('all')) {
      return [];
    }

    final subspecialties =
        _doctors
            .where(
              (d) => specialtyKeys.contains(
                d.specialty.toString().split('.').last,
              ),
            )
            .expand((d) => d.subspecialties)
            .toSet()
            .toList()
          ..sort();
    return subspecialties;
  }

  List<String> get availableSubspecialties {
    final subspecialties =
        _doctors.expand((d) => d.subspecialties).toSet().toList()..sort();
    return subspecialties;
  }

  List<String> get availableLanguages {
    final languages = _doctors.expand((d) => d.languages).toSet().toList()
      ..sort();
    return languages;
  }

  // Filtered and sorted doctors
  List<DoctorModel> get filteredDoctors {
    var result = _doctors.where((doctor) {
      // Only show doctors with complete profiles to patients
      if (!doctor.isProfileComplete) {
        return false;
      }

      final specialtyKey = doctor.specialty.toString().split('.').last;

      // Search filter (name only - specialty filtering via filter chips)
      if (_searchQuery.isNotEmpty) {
        final query = _searchQuery.toLowerCase();
        if (!doctor.fullName.toLowerCase().contains(query)) {
          return false;
        }
      }

      // Specialty filter
      if (_selectedSpecialties.isNotEmpty &&
          !_selectedSpecialties.contains(specialtyKey)) {
        return false;
      }

      // Subspecialty filter
      if (_selectedSubspecialties.isNotEmpty) {
        final matches = _selectedSubspecialties.any(
          (sub) => doctor.subspecialties.contains(sub),
        );
        if (!matches) return false;
      }

      // Language filter
      if (_selectedLanguages.isNotEmpty) {
        final matches = _selectedLanguages.any(
          (lang) => doctor.languages.contains(lang),
        );
        if (!matches) return false;
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

    // Apply sorting (SplayTreeSet has default sort, but user can change it)
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
          (a, b) => a.consultationPrice.compareTo(b.consultationPrice),
        );
      case 'price_desc':
        result.sort(
          (a, b) => b.consultationPrice.compareTo(a.consultationPrice),
        );
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

  /// Fetch initial page of doctors (resets pagination).
  /// Throws exceptions on failure - UI should catch and display.
  Future<void> fetchDoctors() async {
    _isLoading = true;
    _doctors.clear();
    _lastDocument = null;
    _hasMore = true;
    notifyListeners();

    try {
      final result = await _doctorService.fetchDoctorsPage();
      _doctors.addAll(result.doctors);
      _lastDocument = result.lastDoc;
      _hasMore = result.doctors.length >= DoctorService.defaultPageSize;
      _hasPrimed = true;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Fetch more doctors (next page).
  /// Does nothing if already loading or no more data.
  Future<void> fetchMore() async {
    if (_isLoading || !_hasMore) return;

    _isLoading = true;
    notifyListeners();

    try {
      final result = await _doctorService.fetchDoctorsPage(
        startAfterDoc: _lastDocument,
      );
      _doctors.addAll(result.doctors);
      _lastDocument = result.lastDoc;
      _hasMore = result.doctors.length >= DoctorService.defaultPageSize;
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

  void toggleSubspecialty(String sub) {
    if (_selectedSubspecialties.contains(sub)) {
      _selectedSubspecialties.remove(sub);
    } else {
      _selectedSubspecialties.add(sub);
    }
    notifyListeners();
  }

  void toggleLanguage(String lang) {
    if (_selectedLanguages.contains(lang)) {
      _selectedLanguages.remove(lang);
    } else {
      _selectedLanguages.add(lang);
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
    _selectedSubspecialties.clear();
    _selectedLanguages.clear();
    _selectedExperienceRanges.clear();
    _availableOnly = false;
    notifyListeners();
  }

  void applyFilters({
    required Set<String> specialties,
    required Set<String> subspecialties,
    required Set<String> languages,
    required Set<String> experienceRanges,
    required bool availableOnly,
  }) {
    _selectedSpecialties = specialties;
    _selectedSubspecialties = subspecialties;
    _selectedLanguages = languages;
    _selectedExperienceRanges = experienceRanges;
    _availableOnly = availableOnly;
    notifyListeners();
  }

  /// Refresh doctors list.
  Future<void> refresh() async {
    await fetchDoctors();
  }

  /// Clear data (e.g., on logout).
  void clear() {
    _doctors.clear();
    _isLoading = false;
    _hasPrimed = false;
    _lastDocument = null;
    _hasMore = true;
    _selectedSpecialties = {};
    _selectedExperienceRanges = {};
    _availableOnly = false;
    _selectedSort = 'availability';
    _searchQuery = '';
    notifyListeners();
  }
}
