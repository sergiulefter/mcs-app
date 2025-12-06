import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../models/consultation_model.dart';
import '../models/doctor_model.dart';
import '../models/medical_specialty.dart';
import '../services/doctor_service.dart';

/// Seeder script for bulk doctors + consultations (dev/testing only).
/// This will WIPE existing doctors/consultations collections before inserting new data.

class DevDataSeeder {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final DoctorService _doctorService = DoctorService();
  final _rand = Random();

  Future<void> run({
    required int doctorCount,
    required int consultationsPerUser,
    required String patientId,
  }) async {
    debugPrint('Dev seeder will DELETE doctors & consultations collections...');
    await _clearCollection('doctors');
    await _clearCollection('consultations');

    final doctors = await _seedDoctors(doctorCount);
    await _seedConsultations(
      patientId: patientId,
      doctors: doctors,
      count: consultationsPerUser,
    );

    debugPrint('Seeding complete: ${doctors.length} doctors, $consultationsPerUser consultations for patient $patientId');
  }

  Future<void> _clearCollection(String collection) async {
    const batchSize = 300;
    while (true) {
      final snap = await _firestore.collection(collection).limit(batchSize).get();
      if (snap.docs.isEmpty) break;
      final batch = _firestore.batch();
      for (final doc in snap.docs) {
        batch.delete(doc.reference);
      }
      await batch.commit();
      if (snap.docs.length < batchSize) break;
    }
  }

  Future<List<DoctorModel>> _seedDoctors(int count) async {
    final doctors = <DoctorModel>[];
    for (int i = 0; i < count; i++) {
      final fullName = _randomFullName();
      final specialty = _randomSpecialty();
      final isAvailable = _rand.nextBool();
      final vacationPeriods = isAvailable ? <DateRange>[] : _randomVacationPeriods();
      final doctor = DoctorModel(
        uid: 'doctor_${i + 1}_${_rand.nextInt(999999)}',
        email: _emailFromName(fullName, i),
        fullName: fullName,
        photoUrl: null,
        specialty: specialty,
        subspecialties: _subspecialtiesForSpecialty(specialty),
        experienceYears: _rand.nextInt(25) + 5,
        bio: _bioForSpecialty(specialty),
        education: [
          EducationEntry(
            institution: 'Universitatea de Medicină București',
            degree: 'Doctor of Medicine',
            year: 2000 + _rand.nextInt(20),
          ),
          EducationEntry(
            institution: 'European Fellowship',
            degree: 'Fellowship in ${specialty.name}',
            year: 2010 + _rand.nextInt(10),
          ),
        ],
        consultationPrice: 250 + _rand.nextInt(200).toDouble(),
        languages: _randomLanguages(),
        isAvailable: isAvailable,
        vacationPeriods: vacationPeriods,
        createdAt: DateTime.now(),
        lastActive: DateTime.now().subtract(Duration(days: _rand.nextInt(10))),
      );
      doctors.add(doctor);
      await _doctorService.createDoctorProfile(doctor);
    }
    return doctors;
  }

  Future<void> _seedConsultations({
    required String patientId,
    required List<DoctorModel> doctors,
    required int count,
  }) async {
    // Status distribution: pending 15%, in_review 25%, info_requested 25%, completed 25%, cancelled 10%
    final statusWeights = [
      ('pending', 15),
      ('in_review', 25),
      ('info_requested', 25),
      ('completed', 25),
      ('cancelled', 10),
    ];

    for (int i = 0; i < count; i++) {
      final doctor = doctors[_rand.nextInt(doctors.length)];
      final status = _weightedRandomStatus(statusWeights);
      final urgency = _rand.nextInt(100) < 80 ? 'normal' : 'priority'; // 80% normal, 20% priority
      final createdAt = DateTime.now().subtract(Duration(days: _rand.nextInt(60) + 1));
      final updatedAt = createdAt.add(Duration(days: _rand.nextInt(14) + 1));

      // Generate infoRequests based on status
      final infoRequests = _generateInfoRequests(
        status: status,
        doctorId: doctor.uid,
        consultationCreatedAt: createdAt,
      );

      // Generate doctor response for completed consultations
      final completedAt = status == 'completed'
          ? updatedAt.add(Duration(days: _rand.nextInt(5) + 1))
          : null;
      final doctorResponse = status == 'completed'
          ? _generateDoctorResponse(completedAt ?? updatedAt)
          : null;

      final consultation = ConsultationModel(
        id: 'consult_${i + 1}_${_rand.nextInt(999999)}',
        patientId: patientId,
        doctorId: status == 'pending' && _rand.nextBool() ? null : doctor.uid,
        status: status,
        urgency: urgency,
        title: _consultationTitles[_rand.nextInt(_consultationTitles.length)],
        description: _consultationDescriptions[_rand.nextInt(_consultationDescriptions.length)],
        attachments: const [], // Placeholder URLs not useful for dev
        doctorResponse: doctorResponse,
        infoRequests: infoRequests,
        createdAt: createdAt,
        updatedAt: updatedAt,
        completedAt: completedAt,
        termsAcceptedAt: createdAt.subtract(const Duration(minutes: 5)),
        doctorName: doctor.fullName,
        doctorSpecialty: doctor.specialty.name,
      );

      await _firestore
          .collection('consultations')
          .doc(consultation.id)
          .set(consultation.toFirestore());
    }
  }

  String _weightedRandomStatus(List<(String, int)> weights) {
    final totalWeight = weights.fold(0, (sum, w) => sum + w.$2);
    var random = _rand.nextInt(totalWeight);
    for (final (status, weight) in weights) {
      random -= weight;
      if (random < 0) return status;
    }
    return weights.last.$1;
  }

  List<InfoRequestModel> _generateInfoRequests({
    required String status,
    required String doctorId,
    required DateTime consultationCreatedAt,
  }) {
    // Pending consultations typically don't have info requests yet
    if (status == 'pending') return [];

    // Cancelled consultations might have 0-1 info requests
    if (status == 'cancelled') {
      if (_rand.nextInt(100) < 70) return []; // 70% have no info requests
      return [_createInfoRequest(doctorId, consultationCreatedAt, answered: false)];
    }

    // info_requested status MUST have at least one unanswered info request
    if (status == 'info_requested') {
      final requestCount = 1 + _rand.nextInt(2); // 1-2 requests
      final requests = <InfoRequestModel>[];
      for (int i = 0; i < requestCount; i++) {
        // Last one should be unanswered, previous ones can be answered
        final isLastRequest = i == requestCount - 1;
        requests.add(_createInfoRequest(
          doctorId,
          consultationCreatedAt.add(Duration(days: i + 1)),
          answered: !isLastRequest && _rand.nextBool(),
        ));
      }
      return requests;
    }

    // in_review: may have 0-2 answered info requests
    if (status == 'in_review') {
      final chance = _rand.nextInt(100);
      if (chance < 40) return []; // 40% no info requests
      if (chance < 75) {
        // 35% have 1 answered info request
        return [_createInfoRequest(doctorId, consultationCreatedAt, answered: true)];
      }
      // 25% have 2 answered info requests
      return [
        _createInfoRequest(doctorId, consultationCreatedAt, answered: true),
        _createInfoRequest(doctorId, consultationCreatedAt.add(const Duration(days: 3)), answered: true),
      ];
    }

    // completed: usually has 0-2 answered info requests
    if (status == 'completed') {
      final chance = _rand.nextInt(100);
      if (chance < 50) return []; // 50% no info requests needed
      if (chance < 80) {
        // 30% have 1 answered info request
        return [_createInfoRequest(doctorId, consultationCreatedAt, answered: true)];
      }
      // 20% have 2 answered info requests
      return [
        _createInfoRequest(doctorId, consultationCreatedAt, answered: true),
        _createInfoRequest(doctorId, consultationCreatedAt.add(const Duration(days: 2)), answered: true),
      ];
    }

    return [];
  }

  InfoRequestModel _createInfoRequest(String doctorId, DateTime baseDate, {required bool answered}) {
    final requestedAt = baseDate.add(Duration(days: _rand.nextInt(3) + 1));
    final questionCount = 1 + _rand.nextInt(3); // 1-3 questions

    // Select random questions
    final shuffledQuestions = List<String>.from(_infoRequestQuestions)..shuffle(_rand);
    final questions = shuffledQuestions.take(questionCount).toList();

    // Generate answers if answered
    List<String>? answers;
    String? additionalInfo;
    DateTime? respondedAt;

    if (answered) {
      final shuffledAnswers = List<String>.from(_patientAnswers)..shuffle(_rand);
      answers = shuffledAnswers.take(questionCount).toList();
      additionalInfo = _additionalInfoPool[_rand.nextInt(_additionalInfoPool.length)];
      respondedAt = requestedAt.add(Duration(days: _rand.nextInt(3) + 1));
    }

    return InfoRequestModel(
      id: 'inforeq_${_rand.nextInt(999999)}',
      message: _infoRequestMessages[_rand.nextInt(_infoRequestMessages.length)],
      questions: questions,
      doctorId: doctorId,
      requestedAt: requestedAt,
      answers: answers,
      additionalInfo: additionalInfo,
      respondedAt: respondedAt,
    );
  }

  DoctorResponseModel _generateDoctorResponse(DateTime respondedAt) {
    final text = _doctorResponseTexts[_rand.nextInt(_doctorResponseTexts.length)];
    final recommendations = _doctorRecommendations[_rand.nextInt(_doctorRecommendations.length)];

    return DoctorResponseModel(
      text: text,
      recommendations: recommendations,
      respondedAt: respondedAt,
      followUpNeeded: _rand.nextInt(100) < 30, // 30% need follow-up
      responseAttachments: const [], // Placeholder URLs not useful for dev
    );
  }

  String _randomFullName() {
    final first = _firstNames[_rand.nextInt(_firstNames.length)];
    final last = _lastNames[_rand.nextInt(_lastNames.length)];
    return '$first $last';
  }

  MedicalSpecialty _randomSpecialty() {
    final values = MedicalSpecialty.values;
    return values[_rand.nextInt(values.length)];
  }

  String _emailFromName(String fullName, int index) {
    final slug = fullName.toLowerCase().replaceAll(' ', '.');
    return '$slug.$index@medicalmcs.ro';
  }

  List<String> _subspecialtiesForSpecialty(MedicalSpecialty specialty) {
    return _subspecialtyPool[specialty] ??
        [
          'General practice',
          'Second opinions',
        ];
  }

  String _bioForSpecialty(MedicalSpecialty specialty) {
    return _bioPool[specialty] ??
        'Experienced specialist providing evidence-based second opinions.';
  }

  List<String> _randomLanguages() {
    final langs = List<String>.of(_languagePool);
    langs.shuffle(_rand);
    return langs.take(2 + _rand.nextInt(2)).toList();
  }

  List<DateRange> _randomVacationPeriods() {
    final today = DateTime.now();
    final startOffset = _rand.nextInt(7); // within a week from now
    final length = 3 + _rand.nextInt(5); // 3-7 days
    final start = DateTime(today.year, today.month, today.day)
        .add(Duration(days: startOffset));
    final end =
        DateTime(today.year, today.month, today.day).add(Duration(days: startOffset + length));
    return [
      DateRange(
        startDate: start,
        endDate: end,
        reason: 'Not available (auto-seeded)',
      ),
    ];
  }
}

const _firstNames = [
  // Romanian names (40)
  'Andreea', 'Victor', 'Alexandra', 'Mihai', 'Iulia', 'Radu', 'Maria', 'Ciprian',
  'Elena', 'Bogdan', 'Cristina', 'Adrian', 'Bianca', 'Florin', 'Raluca', 'Sorin',
  'Diana', 'Gabriel', 'Oana', 'Daniel', 'Ioana', 'Alexandru', 'Simona', 'Andrei',
  'Lavinia', 'Vlad', 'Monica', 'Stefan', 'Ana', 'Cosmin', 'Alina', 'Marius',
  'Roxana', 'Lucian', 'Carmen', 'Catalin', 'Laura', 'Dragos', 'Irina', 'Paul',
  // International names (15)
  'Sophie', 'Thomas', 'Emma', 'Lucas', 'Isabella', 'Oliver', 'Natalia', 'Erik',
  'Clara', 'Maxim', 'Helena', 'Sebastian', 'Eva', 'Nikolai', 'Olivia',
];

const _lastNames = [
  // Romanian surnames (45)
  'Popescu', 'Ionescu', 'Marinescu', 'Dima', 'Cernat', 'Andreescu', 'Petrescu',
  'Stoica', 'Munteanu', 'Tudor', 'Gheorghiu', 'Stancu', 'Voicu', 'Rusu', 'Badea',
  'Lazar', 'Enache', 'Moldovan', 'Costache', 'Matei', 'Popa', 'Dumitru', 'Stan',
  'Barbu', 'Nicolae', 'Constantin', 'Dragomir', 'Mihalache', 'Neagu', 'Dobre',
  'Marin', 'Florea', 'Cristea', 'Radu', 'Vasile', 'Ilie', 'Nistor', 'Anghel',
  'Mocanu', 'Tanase', 'Mihai', 'Stefanescu', 'Manole', 'Oprea', 'Zaharia',
  // International surnames (10)
  'Weber', 'Novak', 'Bergmann', 'Lindberg', 'Kowalski', 'Petrov', 'Horvat',
  'Bauer', 'Schmidt', 'Andersson',
];

// Using subspecialties from SpecialtyRegistry - these match the official translation keys
final Map<MedicalSpecialty, List<String>> _subspecialtyPool = {
  MedicalSpecialty.cardiology: ['interventional', 'heartFailure', 'arrhythmia', 'pediatricCardiology', 'cardiacImaging', 'preventiveCardiology'],
  MedicalSpecialty.oncology: ['solidTumors', 'hematologicOncology', 'immunotherapy', 'pediatricOncology', 'radiationOncology', 'palliativeCare'],
  MedicalSpecialty.neurology: ['epilepsy', 'movementDisorders', 'neuroimmunology', 'strokeNeurology', 'headacheMedicine', 'neuromuscular'],
  MedicalSpecialty.orthopedics: ['sportsMedicine', 'jointReplacement', 'spinalSurgery', 'traumaOrthopedics', 'pediatricOrthopedics', 'handSurgery'],
  MedicalSpecialty.endocrinology: ['diabetesManagement', 'thyroidDisorders', 'metabolicDisorders', 'reproductiveEndocrinology', 'adrenalDisorders', 'osteoporosis'],
  MedicalSpecialty.dermatology: ['medicalDermatology', 'cosmeticDermatology', 'dermatopathology', 'pediatricDermatology', 'mohs', 'skinCancer'],
  MedicalSpecialty.gastroenterology: ['hepatology', 'inflammatoryBowelDisease', 'motilityDisorders', 'pancreaticDisorders', 'endoscopy', 'nutrition'],
  MedicalSpecialty.pulmonology: ['asthma', 'copd', 'interstitialLungDisease', 'sleepMedicine', 'lungCancer', 'pulmonaryHypertension'],
  MedicalSpecialty.nephrology: ['dialysis', 'kidneyTransplant', 'glomerularDisease', 'hypertensionNephrology', 'pediatricNephrology', 'electrolytes'],
  MedicalSpecialty.rheumatology: ['rheumatoidArthritis', 'lupus', 'vasculitis', 'osteoarthritis', 'spondyloarthritis', 'autoimmune'],
  MedicalSpecialty.hematology: ['coagulationDisorders', 'anemias', 'leukemia', 'lymphoma', 'transfusionMedicine', 'stemCellTransplant'],
  MedicalSpecialty.infectious: ['bacterialInfections', 'viralInfections', 'fungalInfections', 'parasitic', 'hivAids', 'travelMedicine'],
  MedicalSpecialty.pediatrics: ['neonatology', 'pediatricCardiologyPeds', 'pediatricNeurologyPeds', 'pediatricGastroenterology', 'developmentalPediatrics', 'adolescentMedicine'],
  MedicalSpecialty.psychiatry: ['adultPsychiatry', 'childPsychiatry', 'addictionPsychiatry', 'geriatricPsychiatry', 'forensicPsychiatry', 'psychosomatic'],
  MedicalSpecialty.radiology: ['diagnosticRadiology', 'interventionalRadiology', 'neuroradiology', 'musculoskeletalRadiology', 'pediatricRadiology', 'breastImaging'],
  MedicalSpecialty.surgery: ['generalSurgery', 'colorectalSurgery', 'bariatricSurgery', 'traumaSurgery', 'oncologicSurgery', 'minimallyInvasive'],
  MedicalSpecialty.urology: ['oncologicUrology', 'pediatricUrology', 'femaleUrology', 'maleInfertility', 'urolithiasis', 'neurourology'],
  MedicalSpecialty.gynecology: ['reproductiveMedicine', 'gynecologicOncology', 'urogynecology', 'minimallyInvasiveGyn', 'menopause', 'endometriosis'],
  MedicalSpecialty.ophthalmology: ['retina', 'glaucoma', 'cornea', 'pediatricOphthalmology', 'oculoplastics', 'neuroOphthalmology'],
  MedicalSpecialty.otolaryngology: ['otology', 'rhinology', 'laryngology', 'headNeckOncology', 'pediatricENT', 'sleepSurgery'],
  MedicalSpecialty.anesthesiology: ['cardiacAnesthesia', 'pediatricAnesthesia', 'painMedicine', 'criticalCareAnesthesia', 'obstetricAnesthesia', 'regionalAnesthesia'],
  MedicalSpecialty.pathology: ['surgicalPathology', 'cytopathology', 'hematopathology', 'dermatopathologyPath', 'molecularPathology', 'forensicPathology'],
  MedicalSpecialty.familyMedicine: ['preventiveMedicine', 'geriatrics', 'sportsFamily', 'palliativeFamilyCare', 'obesityMedicine', 'adolescentCare'],
  MedicalSpecialty.internalMedicine: ['hospitalMedicine', 'geriatricMedicine', 'preventiveInternal', 'complexCare', 'diagnosticMedicine', 'palliativeInternal'],
  MedicalSpecialty.emergency: ['traumaCare', 'pediatricEmergency', 'toxicology', 'disasterMedicine', 'ultrasoundEmergency', 'criticalCareEM'],
};

final Map<MedicalSpecialty, String> _bioPool = {
  MedicalSpecialty.cardiology:
      'Cardiologist focused on interventional procedures, heart failure management, and arrhythmia treatment with over a decade of clinical experience.',
  MedicalSpecialty.oncology:
      'Medical oncologist with extensive experience in chemotherapy protocols, targeted therapies, and immunotherapy for solid tumors and hematologic malignancies.',
  MedicalSpecialty.neurology:
      'Neurologist specializing in movement disorders, epilepsy management, and neurodegenerative diseases including Parkinson\'s and multiple sclerosis.',
  MedicalSpecialty.orthopedics:
      'Orthopedic surgeon focused on sports injuries, arthroscopic procedures, and joint replacement surgery using minimally invasive techniques.',
  MedicalSpecialty.dermatology:
      'Dermatologist experienced in medical dermatology, skin cancer screening, Mohs surgery, and treatment of chronic skin conditions.',
  MedicalSpecialty.endocrinology:
      'Endocrinologist focusing on diabetes care, thyroid disorders, metabolic health, and hormonal imbalances with a patient-centered approach.',
  MedicalSpecialty.gastroenterology:
      'Gastroenterologist with expertise in inflammatory bowel disease, hepatology, and advanced therapeutic endoscopy procedures.',
  MedicalSpecialty.pulmonology:
      'Pulmonologist specializing in asthma, COPD, sleep disorders, and interstitial lung diseases with expertise in pulmonary function testing.',
  MedicalSpecialty.nephrology:
      'Nephrologist with experience in chronic kidney disease management, dialysis care, and kidney transplant evaluation and follow-up.',
  MedicalSpecialty.rheumatology:
      'Rheumatologist focused on autoimmune diseases, inflammatory arthritis, and connective tissue disorders using evidence-based treatment protocols.',
  MedicalSpecialty.hematology:
      'Hematologist specializing in blood disorders, coagulation abnormalities, and hematologic malignancies including leukemia and lymphoma.',
  MedicalSpecialty.infectious:
      'Infectious disease specialist with expertise in complex infections, HIV/AIDS management, and antimicrobial stewardship programs.',
  MedicalSpecialty.pediatrics:
      'Pediatrician dedicated to child health from newborn to adolescence, with special interest in developmental pediatrics and preventive care.',
  MedicalSpecialty.psychiatry:
      'Psychiatrist experienced in mood disorders, anxiety, PTSD, and addiction medicine with integrated psychotherapy and pharmacological approaches.',
  MedicalSpecialty.radiology:
      'Radiologist with expertise in diagnostic imaging, interventional procedures, and advanced modalities including MRI and CT interpretation.',
  MedicalSpecialty.surgery:
      'General surgeon skilled in laparoscopic and open surgical procedures, with focus on minimally invasive techniques and rapid recovery protocols.',
  MedicalSpecialty.urology:
      'Urologist specializing in urologic oncology, men\'s health, kidney stones, and minimally invasive urological surgery.',
  MedicalSpecialty.gynecology:
      'Gynecologist with expertise in reproductive health, gynecologic oncology, and minimally invasive surgical techniques.',
  MedicalSpecialty.ophthalmology:
      'Ophthalmologist focused on retinal diseases, glaucoma management, and cataract surgery with advanced diagnostic capabilities.',
  MedicalSpecialty.otolaryngology:
      'ENT specialist with expertise in head and neck surgery, rhinology, and treatment of hearing and balance disorders.',
  MedicalSpecialty.anesthesiology:
      'Anesthesiologist experienced in perioperative care, pain management, and critical care medicine with patient safety focus.',
  MedicalSpecialty.pathology:
      'Pathologist with expertise in surgical pathology, cytopathology, and molecular diagnostics for accurate disease diagnosis.',
  MedicalSpecialty.familyMedicine:
      'Family physician providing comprehensive primary care across all ages, with focus on preventive medicine and chronic disease management.',
  MedicalSpecialty.internalMedicine:
      'Internist specializing in complex medical conditions, hospital medicine, and coordinated care for patients with multiple comorbidities.',
  MedicalSpecialty.emergency:
      'Emergency medicine physician experienced in acute care, trauma management, and critical decision-making in time-sensitive situations.',
};

const _languagePool = ['RO', 'EN', 'FR', 'DE', 'ES', 'IT', 'HU', 'RU'];

// Consultation titles pool
const _consultationTitles = [
  'Follow-up on chest pain',
  'Review MRI results',
  'Second opinion on diagnosis',
  'Clarify treatment plan',
  'Medication side effects',
  'Post-surgery recovery advice',
  'Chronic symptoms evaluation',
  'Lab results interpretation',
  'Specialist recommendation',
  'Persistent headaches assessment',
  'Unusual fatigue concerns',
  'Skin condition evaluation',
  'Joint pain management',
  'Blood pressure monitoring',
  'Thyroid function review',
  'Digestive issues consultation',
  'Sleep disorder assessment',
  'Anxiety symptoms evaluation',
  'Weight management guidance',
  'Allergy symptoms review',
  'Back pain treatment options',
  'Heart palpitations concern',
  'Diabetes management review',
  'Post-treatment follow-up',
  'Pre-operative consultation',
  'Pediatric growth concerns',
  'Neurological symptoms review',
  'Respiratory issues assessment',
  'Vision changes evaluation',
  'Hearing concerns consultation',
];

// Consultation descriptions pool
const _consultationDescriptions = [
  'I have been experiencing these symptoms for the past few weeks and would like a specialist\'s opinion on the best course of action.',
  'My primary care physician recommended getting a second opinion before proceeding with the suggested treatment plan.',
  'Recent test results have raised some concerns, and I would appreciate an expert review of the findings and their implications.',
  'I am looking for clarity on my current diagnosis and would like to explore alternative treatment options if available.',
  'The prescribed medication has been causing some side effects, and I need advice on whether to continue or adjust the treatment.',
  'Following my recent procedure, I have some questions about the recovery process and what symptoms are normal versus concerning.',
  'These symptoms have been persistent despite initial treatment, and I would like a specialist to evaluate if there\'s an underlying issue.',
  'I need help understanding my lab results and what lifestyle changes might improve my health markers.',
  'I\'m seeking a specialist\'s recommendation on whether my condition warrants further investigation or immediate intervention.',
  'My symptoms have been getting progressively worse, and I\'m concerned about potential complications if left untreated.',
  'I would like an expert opinion on the proposed surgery and whether there are less invasive alternatives to consider.',
  'The initial treatment plan hasn\'t been as effective as hoped, and I\'m looking for alternative approaches.',
  'I have a family history of this condition and would like guidance on preventive measures and early detection.',
  'My current medications seem to be interacting poorly, and I need advice on managing my prescriptions.',
  'I\'ve been dealing with these chronic symptoms for years and am hoping for a fresh perspective on management.',
  'Recent changes in my health have been alarming, and I want to make sure nothing serious is being overlooked.',
  'I need professional guidance on interpreting my imaging results and understanding the next steps.',
  'My symptoms don\'t fit the typical pattern, and I\'d like a specialist to evaluate for less common conditions.',
  'I\'m preparing for a major life change and want to ensure my current health status is thoroughly evaluated.',
  'The inconsistency in my symptoms has made diagnosis challenging, and I\'m seeking a comprehensive evaluation.',
];

// InfoRequest messages pool
const _infoRequestMessages = [
  'I need some additional information to provide a comprehensive opinion on your case.',
  'Before I can finalize my assessment, please clarify the following details.',
  'To better understand your condition and provide accurate recommendations, I have a few questions.',
  'Additional details would help me give you more precise and personalized recommendations.',
  'Please provide the following information for a complete evaluation of your situation.',
  'To ensure my recommendations are tailored to your specific needs, please answer these questions.',
  'Some clarification would be helpful in forming my professional opinion.',
  'Your answers to these questions will help me understand the full picture of your health concern.',
];

// InfoRequest questions pool
const _infoRequestQuestions = [
  'When did you first notice these symptoms?',
  'Have you experienced this before? If so, when and how was it treated?',
  'Are you currently taking any medications? If so, please list them.',
  'Do you have any known allergies to medications or other substances?',
  'Has anyone in your family had similar issues or related conditions?',
  'How would you rate the severity of your symptoms on a scale of 1-10?',
  'Have you noticed any specific triggers that worsen the symptoms?',
  'What treatments or remedies have you already tried for this issue?',
  'Do you have any other chronic conditions or ongoing health concerns?',
  'Have you had any recent blood work or imaging done? If so, what were the results?',
  'How has this condition affected your daily activities and quality of life?',
  'Are your symptoms constant or do they come and go?',
  'Have you noticed any changes in your sleep, appetite, or weight?',
  'Do your symptoms worsen at any particular time of day?',
  'Have you recently traveled or been exposed to any unusual environments?',
  'Are you experiencing any additional symptoms that might be related?',
  'What is your typical diet and exercise routine?',
  'Do you consume alcohol, tobacco, or recreational substances?',
  'Have you had any recent injuries, surgeries, or major life stressors?',
  'What are your primary concerns about this condition?',
];

// Patient answers pool (for answered info requests)
const _patientAnswers = [
  'The symptoms started approximately 3 weeks ago, gradually becoming more noticeable.',
  'I experienced something similar about 2 years ago, but it resolved on its own.',
  'Currently taking blood pressure medication and a daily multivitamin.',
  'No known allergies to medications. I do have seasonal allergies to pollen.',
  'My mother had similar issues in her 50s. No other family history that I know of.',
  'I would rate it around 6-7, it\'s manageable but definitely affects my daily routine.',
  'Symptoms seem to worsen with stress and lack of sleep.',
  'I\'ve tried over-the-counter pain relievers with limited success.',
  'I have mild hypertension, controlled with medication.',
  'Had blood work done last month, everything came back within normal ranges.',
  'It has significantly impacted my ability to work and exercise regularly.',
  'The symptoms are fairly constant, though they do fluctuate in intensity.',
  'Sleep has been disrupted, and I\'ve lost about 3 kg over the past month.',
  'Symptoms tend to be worse in the morning and improve somewhat throughout the day.',
  'No recent travel. I work in an office environment with typical conditions.',
  'I\'ve also noticed increased fatigue and occasional dizziness.',
  'I try to eat balanced meals and exercise 3 times per week.',
  'Occasional social drinking, no tobacco or other substances.',
  'No recent injuries. I did experience significant work stress recently.',
  'My main concern is whether this could be something serious that needs immediate attention.',
];

// Additional info pool
const _additionalInfoPool = [
  'I also wanted to mention that I have upcoming travel plans and would like to know if this affects my ability to fly.',
  'I forgot to mention that I recently changed jobs and the stress levels have been quite high.',
  'My partner has also been experiencing similar symptoms, though milder.',
  'I have attached some additional photos of the affected area for your reference.',
  'I\'ve been keeping a symptom diary which I can share if it would be helpful.',
  null, // No additional info in some cases
  null,
  null,
];

// Doctor response texts pool
const _doctorResponseTexts = [
  'Based on my review of your case, I believe your symptoms are consistent with a common presentation of this condition. The proposed treatment plan appears appropriate, though I would suggest monitoring closely for any changes.',
  'After carefully reviewing your medical history and symptoms, I recommend proceeding with the current treatment while making some adjustments to optimize outcomes. Please see my detailed recommendations below.',
  'Your case presents some interesting findings that warrant further investigation. I recommend additional testing to rule out certain conditions before finalizing the treatment approach.',
  'Having reviewed all the information provided, I concur with your primary physician\'s assessment. The treatment plan is evidence-based and appropriate for your condition.',
  'Your symptoms suggest multiple possible causes, and I\'ve outlined a systematic approach to narrow down the diagnosis. This may require some additional tests.',
  'The test results you\'ve shared indicate that the condition is being well-managed. I recommend continuing the current approach with minor modifications.',
  'Based on my evaluation, there are alternative treatment options that may be more suitable for your specific situation. I\'ve detailed these options with their respective benefits and considerations.',
  'Your case has been thoroughly reviewed, and I believe the prognosis is favorable. Adherence to the treatment plan and lifestyle modifications will be key to recovery.',
  'The findings suggest this may be a self-limiting condition that will improve with time. However, I recommend certain supportive measures to manage symptoms.',
  'After reviewing your imaging and lab results, I\'ve identified some areas that require attention. My recommendations focus on addressing these specific findings.',
  'Your symptoms appear to be well-controlled with current management. I suggest maintaining the current regimen while scheduling regular follow-ups.',
  'Based on the clinical picture, I recommend a referral to a subspecialist for more targeted evaluation and treatment of this specific aspect of your condition.',
];

// Doctor recommendations pool
const _doctorRecommendations = [
  'Continue current medication as prescribed. Schedule a follow-up appointment in 4-6 weeks to assess progress.',
  'Consider lifestyle modifications including reduced sodium intake, regular exercise, and stress management techniques.',
  'Proceed with the recommended imaging studies to obtain more detailed information before making final treatment decisions.',
  'Maintain a symptom diary for the next 2 weeks and note any triggers or patterns that emerge.',
  'Increase water intake and ensure adequate rest. Avoid strenuous activities until symptoms improve.',
  'Consider consulting with a physical therapist for targeted exercises to address the musculoskeletal component.',
  'Blood work should be repeated in 3 months to monitor the effectiveness of the current treatment.',
  'Medication adjustment may be beneficial. Discuss with your primary care physician about alternative options.',
  'Ensure consistent sleep schedule and consider sleep hygiene improvements as discussed.',
  'Dietary modifications as outlined may help alleviate some symptoms. Consider consultation with a nutritionist.',
  null, // Some responses don't have separate recommendations
  null,
  null,
];

/// Convenience entry point for in-app/debug seeding.
Future<void> runDevSeeder({
  required String patientId,
  int doctorCount = 300,
  int consultationsPerUser = 25,
}) async {
  final seeder = DevDataSeeder();
  await seeder.run(
    doctorCount: doctorCount,
    consultationsPerUser: consultationsPerUser,
    patientId: patientId,
  );
}
