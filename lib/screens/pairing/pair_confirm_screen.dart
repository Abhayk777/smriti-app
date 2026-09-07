import 'package:flutter/material.dart';

import '../../app_colors.dart';
import '../../core/auth/pairing_service.dart';

/// Last step of the caregiver-login path: confirm which patient this tablet
/// becomes, then pair.
///
/// Pops `true` on success. Whatever happens — confirm, cancel, or error — the
/// caregiver session is signed out by [PairingService] before this screen goes
/// away, so the tablet never keeps caregiver credentials (AGENTS.md #8).
class PairConfirmScreen extends StatefulWidget {
  const PairConfirmScreen({
    super.key,
    required this.pairingService,
    required this.patient,
  });

  final PairingService pairingService;
  final CaregiverPatient patient;

  @override
  State<PairConfirmScreen> createState() => _PairConfirmScreenState();
}

class _PairConfirmScreenState extends State<PairConfirmScreen> {
  bool _isPairing = false;
  String? _error;

  /// True once pairing has run, success or failure: the caregiver session is
  /// gone, so cancelling no longer needs to sign anything out.
  bool _sessionSpent = false;

  Future<void> _confirm() async {
    setState(() {
      _isPairing = true;
      _error = null;
    });

    try {
      await widget.pairingService
          .completeCaregiverPairing(widget.patient.id);
      _sessionSpent = true;
      if (!mounted) return;
      Navigator.of(context).pop(true);
    } on PairingException catch (e) {
      _sessionSpent = true;
      _failed(e.message);
    } catch (_) {
      _sessionSpent = true;
      _failed('Could not reach the server. Check the connection and retry.');
    }
  }

  void _failed(String message) {
    if (!mounted) return;
    setState(() {
      _isPairing = false;
      _error = message;
    });
  }

  /// Backing out still signs the caregiver out.
  Future<void> _cancel() async {
    if (!_sessionSpent) {
      await widget.pairingService.cancelCaregiverLogin();
    }
    if (!mounted) return;
    Navigator.of(context).pop(false);
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop && !_isPairing) _cancel();
      },
      child: Scaffold(
        backgroundColor: AppColors.pageBackground,
        appBar: AppBar(
          backgroundColor: AppColors.pageBackground,
          foregroundColor: AppColors.primaryText,
          elevation: 0,
          title: const Text('Confirm pairing'),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: _isPairing ? null : _cancel,
          ),
        ),
        body: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(28, 24, 28, 28),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'This tablet will be set up for',
                  style: TextStyle(
                    fontSize: 16,
                    color: AppColors.secondaryText,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  widget.patient.displayName,
                  key: const Key('confirm_patient_name'),
                  style: const TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.w700,
                    color: AppColors.primaryText,
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  'You will be signed out on this tablet as soon as pairing '
                  'finishes. Any tablet previously paired to this patient '
                  'stops syncing.',
                  style: TextStyle(
                    fontSize: 15,
                    height: 1.4,
                    color: AppColors.secondaryText,
                  ),
                ),
                const SizedBox(height: 24),
                if (_error != null) ...[
                  Text(
                    _error!,
                    key: const Key('confirm_error'),
                    style: const TextStyle(
                      fontSize: 15,
                      color: AppColors.terracottaDark,
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
                SizedBox(
                  width: double.infinity,
                  height: 60,
                  child: ElevatedButton(
                    key: const Key('confirm_pair_button'),
                    onPressed: _isPairing ? null : _confirm,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.terracotta,
                      foregroundColor: AppColors.onColor,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(18),
                      ),
                    ),
                    child: _isPairing
                        ? const SizedBox(
                            width: 26,
                            height: 26,
                            child: CircularProgressIndicator(strokeWidth: 3),
                          )
                        : const Text(
                            'Pair this tablet',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
