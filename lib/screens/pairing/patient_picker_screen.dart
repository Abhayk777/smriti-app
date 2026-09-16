import 'package:flutter/material.dart';

import '../../app_colors.dart';
import '../../core/auth/pairing_service.dart';
import '../../ui/smriti_ui.dart';

/// Shown only when a caregiver manages more than one patient. With exactly one,
/// the flow goes straight to the confirmation screen.
///
/// Caregiver-facing setup screen: normal density, not elder styling.
class PatientPickerScreen extends StatelessWidget {
  const PatientPickerScreen({super.key, required this.patients});

  final List<CaregiverPatient> patients;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.pageBackground,
      appBar: AppBar(
        backgroundColor: AppColors.pageBackground,
        foregroundColor: AppColors.primaryText,
        elevation: 0,
        title: const Text('Choose a patient'),
      ),
      body: SafeArea(
        child: MaxWidth(
          maxWidth: 640,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(28, 16, 28, 8),
                child: const Text(
                  'Which patient will use this device?',
                  style: TextStyle(
                    fontSize: 17,
                    color: AppColors.secondaryText,
                  ),
                ),
              ),
              Expanded(
                child: ListView.separated(
                  padding: const EdgeInsets.fromLTRB(28, 8, 28, 28),
                  itemCount: patients.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final patient = patients[index];
                    return Material(
                      color: AppColors.raisedSurface,
                      borderRadius: BorderRadius.circular(18),
                      child: InkWell(
                        key: Key('patient_${patient.id}'),
                        borderRadius: BorderRadius.circular(18),
                        onTap: () => Navigator.of(context).pop(patient),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 18,
                          ),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(18),
                            border: Border.all(
                              color: AppColors.border,
                              width: 1.5,
                            ),
                          ),
                          child: Row(
                            children: [
                              const IconMedallion(
                                icon: Icons.person_rounded,
                                color: AppColors.indigo,
                                size: 52,
                                background: AppColors.pageBackground,
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      patient.displayName,
                                      style: const TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.w700,
                                        color: AppColors.primaryText,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      patient.langCode.toUpperCase(),
                                      style: TextStyle(
                                        fontSize: 13,
                                        color: AppColors.secondaryText,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const Icon(
                                Icons.chevron_right_rounded,
                                color: AppColors.secondaryText,
                                size: 32,
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
