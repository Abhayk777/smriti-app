import 'dart:async';

import 'package:flutter/material.dart';
import 'package:smriti/app_colors.dart';
import 'package:smriti/core/auth/pairing_service.dart';
import 'package:smriti/core/db/app_database.dart';
import 'package:smriti/core/repo/ability_repo.dart';
import 'package:smriti/core/sync/sync_engine.dart';
import 'package:smriti/screens/main_screen.dart';
import 'package:smriti/screens/pairing/pair_confirm_screen.dart';
import 'package:smriti/screens/pairing/patient_picker_screen.dart';
import 'package:smriti/screens/pairing/scan_screen.dart';
import 'package:smriti/ui/smriti_ui.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key, this.pairingService});

  /// Injectable for tests; production builds it from the shared database.
  final PairingService? pairingService;

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();

  bool isPasswordVisible = false;

  late final PairingService _pairingService = widget.pairingService ??
      PairingService(
        configs: appDatabase.appConfigsDao,
        abilityRepo: AbilityRepo(appDatabase),
      );

  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  bool _isSigningIn = false;

  /// Caregiver-login pairing path (APP-BUILD-SPEC.md §8). Signs in, picks a
  /// patient if there is more than one, confirms, then pairs, and the service
  /// signs the caregiver out before any device session exists.
  Future<void> _signInAsCaregiver() async {
    if (_isSigningIn) return;
    _isSigningIn = true;

    try {
      final patients = await _pairingService.signInCaregiver(
        email: emailController.text,
        password: passwordController.text,
      );

      if (!mounted) return;

      // One patient needs no picker.
      var patient = patients.first;
      if (patients.length > 1) {
        final chosen = await Navigator.of(context).push<CaregiverPatient>(
          MaterialPageRoute(
            builder: (_) => PatientPickerScreen(patients: patients),
          ),
        );
        if (chosen == null) {
          await _pairingService.cancelCaregiverLogin();
          return;
        }
        patient = chosen;
      }

      if (!mounted) return;
      final paired = await Navigator.of(context).push<bool>(
        MaterialPageRoute(
          builder: (_) => PairConfirmScreen(
            pairingService: _pairingService,
            patient: patient,
          ),
        ),
      );

      if (paired == true && mounted) {
        passwordController.clear();
        unawaited(SyncEngine.defaultInstance.run(trigger: SyncTrigger.manual));
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const MainScreen()),
          (route) => false,
        );
      }
    } on PairingException catch (e) {
      _showError(e.message);
    } catch (_) {
      _showError('Could not sign in. Check the connection and retry.');
    } finally {
      _isSigningIn = false;
    }
  }

  void _showError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  /// Opens the QR scanner. The code-entry fallback lives inside that screen, so
  /// this screen's layout is unchanged.
  Future<void> _openPairingScanner() async {
    final paired = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => ScanScreen(pairingService: _pairingService),
      ),
    );

    if (paired == true && mounted) {
      unawaited(SyncEngine.defaultInstance.run(trigger: SyncTrigger.manual));
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const MainScreen()),
        (route) => false,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.pageBackground,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final wide = constraints.maxWidth >= 760 &&
                constraints.maxWidth > constraints.maxHeight;
            if (wide) {
              return Row(
                children: [
                  Expanded(child: _buildBrandPanel(large: true)),
                  Expanded(
                    child: Center(
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.fromLTRB(16, 24, 40, 24),
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 520),
                          child: _buildForm(),
                        ),
                      ),
                    ),
                  ),
                ],
              );
            }
            final gutter = constraints.maxWidth >= 600 ? 40.0 : 20.0;
            return SingleChildScrollView(
              padding: EdgeInsets.fromLTRB(gutter, 20, gutter, 24),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 560),
                  child: Column(
                    children: [
                      _buildBrandPanel(large: false),
                      const SizedBox(height: 20),
                      _buildForm(),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildBrandPanel({required bool large}) {
    // The logo artwork has its own sand background, so it sits on a badge
    // of the same colour.
    final logo = ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: Image.asset(
        'assets/images/smriti_login_logo.png',
        width: large ? 340 : 260,
        height: large ? 146 : 112,
        fit: BoxFit.cover,
      ),
    );
    const tagline = Text(
      'Memories for a brighter tomorrow',
      textAlign: TextAlign.center,
      style: TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.w500,
        color: AppColors.secondaryText,
      ),
    );

    if (!large) {
      return Column(
        children: [
          logo,
          const SizedBox(height: 4),
          tagline,
        ],
      );
    }

    return Container(
      margin: const EdgeInsets.fromLTRB(40, 24, 16, 24),
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: AppColors.raisedSurface,
        borderRadius: BorderRadius.circular(32),
        border: Border.all(color: AppColors.border, width: 1.5),
      ),
      child: Column(
        children: [
          const GamosaBand(height: 14),
          Expanded(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Column(
                  children: [logo, const SizedBox(height: 8), tagline],
                ),
              ),
            ),
          ),
          const SizedBox(
            height: 160,
            width: double.infinity,
            child: HillsScene(),
          ),
        ],
      ),
    );
  }

  InputDecoration _fieldDecoration({
    required String hint,
    required IconData icon,
    Widget? suffix,
  }) {
    return InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(fontSize: 18, color: AppColors.secondaryText),
      prefixIcon: Icon(icon, size: 26, color: AppColors.secondaryText),
      suffixIcon: suffix,
      filled: true,
      fillColor: AppColors.pageBackground,
      contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 20),
    );
  }

  Widget _buildForm() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(22, 26, 22, 24),
      decoration: BoxDecoration(
        color: AppColors.raisedSurface,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: AppColors.border, width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            'Caregiver sign in',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w800,
              color: AppColors.primaryText,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'Set up this device for your family member.',
            style: TextStyle(fontSize: 16, color: AppColors.secondaryText),
          ),
          const SizedBox(height: 20),

          // EMAIL
          TextField(
            controller: emailController,
            keyboardType: TextInputType.emailAddress,
            style: const TextStyle(fontSize: 18, color: AppColors.primaryText),
            decoration: _fieldDecoration(
              hint: 'Email address',
              icon: Icons.mail_outline_rounded,
            ),
          ),

          const SizedBox(height: 14),

          // PASSWORD
          TextField(
            controller: passwordController,
            obscureText: !isPasswordVisible,
            style: const TextStyle(fontSize: 18, color: AppColors.primaryText),
            decoration: _fieldDecoration(
              hint: 'Password',
              icon: Icons.lock_outline_rounded,
              suffix: IconButton(
                tooltip: isPasswordVisible ? 'Hide password' : 'Show password',
                onPressed: () {
                  setState(() {
                    isPasswordVisible = !isPasswordVisible;
                  });
                },
                icon: Icon(
                  isPasswordVisible
                      ? Icons.visibility_outlined
                      : Icons.visibility_off_outlined,
                  size: 26,
                  color: AppColors.secondaryText,
                ),
              ),
            ),
          ),

          const SizedBox(height: 20),

          // SIGN IN BUTTON
          SizedBox(
            height: 62,
            child: ElevatedButton(
              key: const Key('sign_in_button'),
              onPressed: _signInAsCaregiver,
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'Sign In',
                    style: TextStyle(fontSize: 21, fontWeight: FontWeight.w800),
                  ),
                  SizedBox(width: 12),
                  Icon(Icons.arrow_forward_rounded, size: 28),
                ],
              ),
            ),
          ),

          const SizedBox(height: 18),

          // OR DIVIDER
          const Row(
            children: [
              Expanded(child: Divider(thickness: 1.5)),
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 16),
                child: Text(
                  'OR',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: AppColors.secondaryText,
                  ),
                ),
              ),
              Expanded(child: Divider(thickness: 1.5)),
            ],
          ),

          const SizedBox(height: 18),

          // QR SCANNER BUTTON
          PressableCard(
            key: const Key('scan_qr_button'),
            onTap: _openPairingScanner,
            color: AppColors.pageBackground,
            borderColor: AppColors.border,
            radius: 20,
            semanticLabel: 'Scan QR Code',
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            child: const Row(
              children: [
                IconMedallion(
                  icon: Icons.qr_code_scanner_rounded,
                  color: AppColors.leafGreen,
                  size: 64,
                  background: AppColors.raisedSurface,
                ),
                SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Scan QR Code',
                        style: TextStyle(
                          fontSize: 19,
                          fontWeight: FontWeight.w700,
                          color: AppColors.primaryText,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        'Load patient data from web app',
                        style: TextStyle(
                          fontSize: 15,
                          color: AppColors.secondaryText,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.chevron_right_rounded,
                  color: AppColors.secondaryText,
                  size: 32,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
