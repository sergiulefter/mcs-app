import 'package:easy_localization/easy_localization.dart';
import 'medical_specialty.dart';

/// Central registry for medical subspecialties with translation support.
/// Single source of truth for all specialty-subspecialty definitions.
///
/// Usage:
/// - Get subspecialties: `SpecialtyRegistry.getSubspecialties(specialty)`
/// - Translate: `SpecialtyRegistry.translateSubspecialty(key)`
/// - Normalize legacy: `SpecialtyRegistry.normalizeLegacy(oldString)`
class SpecialtyRegistry {
  SpecialtyRegistry._();

  /// All subspecialties grouped by their parent specialty.
  /// Keys are translation keys matching the pattern 'subspecialties.{key}'.
  static const Map<MedicalSpecialty, List<String>> subspecialtiesBySpecialty = {
    // Cardiology
    MedicalSpecialty.cardiology: [
      'interventional',
      'heartFailure',
      'arrhythmia',
      'pediatricCardiology',
      'cardiacImaging',
      'preventiveCardiology',
    ],

    // Oncology
    MedicalSpecialty.oncology: [
      'solidTumors',
      'hematologicOncology',
      'immunotherapy',
      'pediatricOncology',
      'radiationOncology',
      'palliativeCare',
    ],

    // Neurology
    MedicalSpecialty.neurology: [
      'epilepsy',
      'movementDisorders',
      'neuroimmunology',
      'strokeNeurology',
      'headacheMedicine',
      'neuromuscular',
    ],

    // Orthopedics
    MedicalSpecialty.orthopedics: [
      'sportsMedicine',
      'jointReplacement',
      'spinalSurgery',
      'traumaOrthopedics',
      'pediatricOrthopedics',
      'handSurgery',
    ],

    // Endocrinology
    MedicalSpecialty.endocrinology: [
      'diabetesManagement',
      'thyroidDisorders',
      'metabolicDisorders',
      'reproductiveEndocrinology',
      'adrenalDisorders',
      'osteoporosis',
    ],

    // Dermatology
    MedicalSpecialty.dermatology: [
      'medicalDermatology',
      'cosmeticDermatology',
      'dermatopathology',
      'pediatricDermatology',
      'mohs',
      'skinCancer',
    ],

    // Gastroenterology
    MedicalSpecialty.gastroenterology: [
      'hepatology',
      'inflammatoryBowelDisease',
      'motilityDisorders',
      'pancreaticDisorders',
      'endoscopy',
      'nutrition',
    ],

    // Pulmonology
    MedicalSpecialty.pulmonology: [
      'asthma',
      'copd',
      'interstitialLungDisease',
      'sleepMedicine',
      'lungCancer',
      'pulmonaryHypertension',
    ],

    // Nephrology
    MedicalSpecialty.nephrology: [
      'dialysis',
      'kidneyTransplant',
      'glomerularDisease',
      'hypertensionNephrology',
      'pediatricNephrology',
      'electrolytes',
    ],

    // Rheumatology
    MedicalSpecialty.rheumatology: [
      'rheumatoidArthritis',
      'lupus',
      'vasculitis',
      'osteoarthritis',
      'spondyloarthritis',
      'autoimmune',
    ],

    // Hematology
    MedicalSpecialty.hematology: [
      'coagulationDisorders',
      'anemias',
      'leukemia',
      'lymphoma',
      'transfusionMedicine',
      'stemCellTransplant',
    ],

    // Infectious Diseases
    MedicalSpecialty.infectious: [
      'bacterialInfections',
      'viralInfections',
      'fungalInfections',
      'parasitic',
      'hivAids',
      'travelMedicine',
    ],

    // Pediatrics
    MedicalSpecialty.pediatrics: [
      'neonatology',
      'pediatricCardiologyPeds',
      'pediatricNeurologyPeds',
      'pediatricGastroenterology',
      'developmentalPediatrics',
      'adolescentMedicine',
    ],

    // Psychiatry
    MedicalSpecialty.psychiatry: [
      'adultPsychiatry',
      'childPsychiatry',
      'addictionPsychiatry',
      'geriatricPsychiatry',
      'forensicPsychiatry',
      'psychosomatic',
    ],

    // Radiology
    MedicalSpecialty.radiology: [
      'diagnosticRadiology',
      'interventionalRadiology',
      'neuroradiology',
      'musculoskeletalRadiology',
      'pediatricRadiology',
      'breastImaging',
    ],

    // Surgery
    MedicalSpecialty.surgery: [
      'generalSurgery',
      'colorectalSurgery',
      'bariatricSurgery',
      'traumaSurgery',
      'oncologicSurgery',
      'minimallyInvasive',
    ],

    // Urology
    MedicalSpecialty.urology: [
      'oncologicUrology',
      'pediatricUrology',
      'femaleUrology',
      'maleInfertility',
      'urolithiasis',
      'neurourology',
    ],

    // Gynecology
    MedicalSpecialty.gynecology: [
      'reproductiveMedicine',
      'gynecologicOncology',
      'urogynecology',
      'minimallyInvasiveGyn',
      'menopause',
      'endometriosis',
    ],

    // Ophthalmology
    MedicalSpecialty.ophthalmology: [
      'retina',
      'glaucoma',
      'cornea',
      'pediatricOphthalmology',
      'oculoplastics',
      'neuroOphthalmology',
    ],

    // Otolaryngology (ENT)
    MedicalSpecialty.otolaryngology: [
      'otology',
      'rhinology',
      'laryngology',
      'headNeckOncology',
      'pediatricENT',
      'sleepSurgery',
    ],

    // Anesthesiology
    MedicalSpecialty.anesthesiology: [
      'cardiacAnesthesia',
      'pediatricAnesthesia',
      'painMedicine',
      'criticalCareAnesthesia',
      'obstetricAnesthesia',
      'regionalAnesthesia',
    ],

    // Pathology
    MedicalSpecialty.pathology: [
      'surgicalPathology',
      'cytopathology',
      'hematopathology',
      'dermatopathologyPath',
      'molecularPathology',
      'forensicPathology',
    ],

    // Family Medicine
    MedicalSpecialty.familyMedicine: [
      'preventiveMedicine',
      'geriatrics',
      'sportsFamily',
      'palliativeFamilyCare',
      'obesityMedicine',
      'adolescentCare',
    ],

    // Internal Medicine
    MedicalSpecialty.internalMedicine: [
      'hospitalMedicine',
      'geriatricMedicine',
      'preventiveInternal',
      'complexCare',
      'diagnosticMedicine',
      'palliativeInternal',
    ],

    // Emergency Medicine
    MedicalSpecialty.emergency: [
      'traumaCare',
      'pediatricEmergency',
      'toxicology',
      'disasterMedicine',
      'ultrasoundEmergency',
      'criticalCareEM',
    ],
  };

  /// Get subspecialties for a given specialty.
  /// Returns an empty list if specialty has no defined subspecialties.
  static List<String> getSubspecialties(MedicalSpecialty specialty) {
    return subspecialtiesBySpecialty[specialty] ?? [];
  }

  /// Get all unique subspecialties across all specialties.
  static List<String> get allSubspecialties {
    final all = <String>{};
    for (final list in subspecialtiesBySpecialty.values) {
      all.addAll(list);
    }
    return all.toList()..sort();
  }

  /// Translate a subspecialty key to its display text.
  /// Uses the current locale from easy_localization.
  static String translateSubspecialty(String key) {
    return 'subspecialties.$key'.tr();
  }

  /// Check if a subspecialty is valid for a given specialty.
  static bool isValidSubspecialty(MedicalSpecialty specialty, String subspecialty) {
    return getSubspecialties(specialty).contains(subspecialty);
  }
}
