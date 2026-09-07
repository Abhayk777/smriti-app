import 'package:flutter/material.dart';
import 'package:smriti/app_colors.dart';
import 'package:smriti/core/auth/pairing_service.dart';
import 'package:smriti/core/db/app_database.dart';
import 'package:smriti/core/repo/ability_repo.dart';
import 'package:smriti/screens/pairing/pair_confirm_screen.dart';
import 'package:smriti/screens/pairing/patient_picker_screen.dart';
import 'package:smriti/screens/pairing/scan_screen.dart';

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
  /// patient if there is more than one, confirms, then pairs — and the service
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
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Tablet paired.')),
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
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Tablet paired.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.pageBackground,
      body: SafeArea(
        child: Stack(
          children: [

            // Bottom leaves and wave decoration
            Positioned(left: 0,right: 0,bottom: 0,height: 150,
              child: IgnorePointer(child: CustomPaint(painter: BottomDecorationPainter())),
            ),

            // Main screen content
            SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(28,30,28,160),
              child: Column(
                children: [
                  Image.asset('assets/images/smriti_login_logo.png',
                    width: 260,height: 160, fit: BoxFit.contain,
                  ),
                  const SizedBox(height: 5),
                  Text('Memories for a brighter tomorrow',
                    textAlign: TextAlign.center,style: TextStyle(fontSize: 15,color: AppColors.secondaryText),
                  ),

                  const SizedBox(height: 35),

                  // LOGIN
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.fromLTRB(24,30,24,28),
                    decoration: BoxDecoration(color: AppColors.raisedSurface,
                      borderRadius: BorderRadius.circular(28),
                      border: Border.all(color: AppColors.border,width: 1.5),
                    ),
                    child: Column(
                      children: [

                        // EMAIL
                        TextField(
                          controller: emailController,
                          keyboardType: TextInputType.emailAddress,
                          style: const TextStyle(fontSize: 18,color: AppColors.primaryText),
                          decoration: InputDecoration(
                            hintText: 'Email address',
                            hintStyle: const TextStyle(fontSize: 18,color: AppColors.secondaryText),
                            prefixIcon: const Icon(Icons.email_outlined,size: 28,color: AppColors.secondaryText),
                            filled: true,fillColor: AppColors.raisedSurface,
                            contentPadding:const EdgeInsets.symmetric(horizontal: 18,vertical: 20),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(18),
                              borderSide: const BorderSide(color: AppColors.border,width: 1.5),
                            ),
                            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(18),
                              borderSide: const BorderSide(color: AppColors.border,width: 1.5),
                            ),
                            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(18),
                              borderSide: const BorderSide(color: AppColors.terracotta,width: 2),
                            ),
                          ),
                        ),

                        const SizedBox(height: 18),

                        // PASSWORD
                        TextField(
                          controller: passwordController,
                          obscureText: !isPasswordVisible,
                          style: const TextStyle(fontSize: 18,color: AppColors.primaryText),
                          decoration: InputDecoration(
                            hintText: 'Password',
                            hintStyle: const TextStyle(fontSize: 18,color: AppColors.secondaryText),
                            prefixIcon: const Icon(Icons.lock_outline,size: 29,color: AppColors.secondaryText),
                            suffixIcon: IconButton(
                              onPressed: () {
                                setState(() {
                                  isPasswordVisible =!isPasswordVisible;
                                });
                              },
                              icon: Icon(
                                isPasswordVisible
                                    ? Icons.visibility_outlined
                                    : Icons.visibility_off_outlined,
                                size: 28,color: AppColors.secondaryText,
                              ),
                            ),
                            filled: true,fillColor: AppColors.raisedSurface,
                            contentPadding:const EdgeInsets.symmetric(horizontal: 18,vertical: 20),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(18),
                              borderSide: const BorderSide(color: AppColors.border,width: 1.5),
                            ),
                            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(18),
                              borderSide: const BorderSide(color: AppColors.border,width: 1.5),
                            ),
                            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(18),
                              borderSide: const BorderSide(color: AppColors.terracotta,width: 2),
                            ),
                          ),
                        ),

                        const SizedBox(height: 24),

                        // SIGN IN BUTTON
                        SizedBox(
                          width: double.infinity,height: 60,
                          child: ElevatedButton(
                            key: const Key('sign_in_button'),
                            onPressed: _signInAsCaregiver,
                            style: ElevatedButton.styleFrom(
                              backgroundColor:AppColors.terracotta,
                              foregroundColor: AppColors.onColor,elevation: 0,
                              shape: RoundedRectangleBorder(borderRadius:BorderRadius.circular(18)),
                            ),
                            child: const Row(
                              mainAxisAlignment:MainAxisAlignment.center,
                              children: [
                                Text('Sign In',
                                  style: TextStyle(fontSize: 20,fontWeight: FontWeight.w700),
                                ),
                                SizedBox(width: 12),
                                Icon(Icons.arrow_forward,size: 30),
                              ],
                            ),
                          ),
                        ),

                        const SizedBox(height: 15),

                        // OR DIVIDER
                        Row(
                          children: [
                            Expanded(
                              child: Container(
                                height: 1.5,color: AppColors.secondaryText,
                              ),
                            ),
                            Padding(
                              padding:const EdgeInsets.symmetric(horizontal: 18),
                              child: Text('OR',
                                style: TextStyle(
                                  fontSize: 17,fontWeight: FontWeight.w600,color:AppColors.secondaryText,
                                ),
                              ),
                            ),
                            Expanded(
                              child: Container(
                                height: 1.5,color: AppColors.secondaryText,
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 15),

                        // QR SCANNER BUTTON
                        SizedBox(
                          width: double.infinity,height: 110,
                          child: OutlinedButton(
                            key: const Key('scan_qr_button'),
                            onPressed: _openPairingScanner,
                            style: OutlinedButton.styleFrom(
                              side: const BorderSide(color: AppColors.terracottaDark,width: 1.5),
                              shape: RoundedRectangleBorder(borderRadius:BorderRadius.circular(20)),
                              padding:const EdgeInsets.symmetric(horizontal: 18),
                            ),
                            child: Row(
                              children: [

                                // QR icon
                                Container(
                                  width: 65,height: 65,
                                  decoration: BoxDecoration(
                                    color:AppColors.raisedSurface,borderRadius:BorderRadius.circular(12),
                                  ),
                                  child: const Icon(
                                    Icons.qr_code_scanner,size: 48,color: AppColors.leafGreen,
                                  ),
                                ),

                                const SizedBox(width: 18),

                                // QR text
                                Expanded(
                                  child: Column(
                                    mainAxisAlignment:MainAxisAlignment.center,
                                    crossAxisAlignment:CrossAxisAlignment.start,
                                    children: [
                                      Text('Scan QR Code',
                                        style: TextStyle(fontSize: 17,fontWeight:FontWeight.w700,
                                         color:AppColors.primaryText
                                        ),
                                      ),
                                      const SizedBox(height: 5),
                                      Text('Load patient data from web app',
                                        style: TextStyle(fontSize: 13,color: AppColors.secondaryText),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// BOTTOM WAVE + LEAVES
class BottomDecorationPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    
    // WAVE
    final wavePaint = Paint()
      ..color = AppColors.wovenMat
      ..style = PaintingStyle.fill;
    final wavePath = Path();
    wavePath.moveTo(0, size.height * 0.45);

    wavePath.quadraticBezierTo(
      size.width * 0.25,
      size.height * 0.10,
      size.width * 0.50,
      size.height * 0.45,
    );

    wavePath.quadraticBezierTo(
      size.width * 0.75,
      size.height * 0.80,
      size.width,
      size.height * 0.30,
    );

    wavePath.lineTo(size.width, size.height);
    wavePath.lineTo(0, size.height);
    wavePath.close();

    canvas.drawPath(wavePath, wavePaint);

    // LEAVES
    final leafPaint = Paint()
      ..color = AppColors.leafGreen
      ..style = PaintingStyle.fill;

    final stemPaint = Paint()
      ..color = AppColors.leafGreenDark
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    // Main stem
    final stem = Path();
    stem.moveTo(55, size.height);

    stem.quadraticBezierTo(
      55,size.height * 0.55,110,size.height * 0.10,
    );

    canvas.drawPath(stem, stemPaint);

    // Left leaf
    final leftLeaf = Path();
    leftLeaf.moveTo(55, size.height * 0.68);

    leftLeaf.quadraticBezierTo(
      10,size.height * 0.48,10,size.height * 0.20,
    );

    leftLeaf.quadraticBezierTo(
      55,size.height * 0.28,55,size.height * 0.68,
    );

    leftLeaf.close();

    canvas.drawPath(leftLeaf, leafPaint);

    // Tall leaf
    final tallLeaf = Path();
    tallLeaf.moveTo(78, size.height * 0.52);

    tallLeaf.quadraticBezierTo(
      70,size.height * 0.10,110,0,
    );

    tallLeaf.quadraticBezierTo(
      125,size.height * 0.30,78,size.height * 0.52,
    );

    tallLeaf.close();

    canvas.drawPath(tallLeaf, leafPaint);

    // Right leaf
    final rightLeaf = Path();
    rightLeaf.moveTo(88, size.height * 0.75);

    rightLeaf.quadraticBezierTo(
      125,size.height * 0.38,160,size.height * 0.40,
    );

    rightLeaf.quadraticBezierTo(
      150,size.height * 0.70,88,size.height * 0.75,
    );

    rightLeaf.close();

    canvas.drawPath(rightLeaf, leafPaint);

    // LEAF VEINS
    final veinPaint = Paint()
      ..color = AppColors.leafGreenDark
      ..strokeWidth = 2.5
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    canvas.drawLine(
      Offset(55, size.height * 0.65),
      Offset(25, size.height * 0.35),
      veinPaint,
    );

    canvas.drawLine(
      Offset(82, size.height * 0.48),
      Offset(103, size.height * 0.18),
      veinPaint,
    );

    canvas.drawLine(
      Offset(94, size.height * 0.70),
      Offset(140, size.height * 0.48),
      veinPaint,
    );
  }

  @override
  bool shouldRepaint(
    covariant CustomPainter oldDelegate,
  ) {
    return false;
  }
}