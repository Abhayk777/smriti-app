import 'package:flutter/material.dart';

import '../app_colors.dart';
import '../core/reminders/native_reminder_bridge.dart';
import '../core/reminders/reminder_isolate.dart';
import '../core/reminders/reminder_permissions.dart';
import '../ui/smriti_ui.dart';

/// Checklist the caregiver completes after pairing so medicine reminders can
/// take over the full screen: over the lock screen, on the home screen and
/// inside other apps. Shown again on app start whenever something critical
/// has been switched off.
class ReminderSetupScreen extends StatefulWidget {
  const ReminderSetupScreen({super.key, required this.onDone});

  final VoidCallback onDone;

  @override
  State<ReminderSetupScreen> createState() => _ReminderSetupScreenState();
}

class _ReminderSetupScreenState extends State<ReminderSetupScreen>
    with WidgetsBindingObserver {
  Map<ReminderSetupItem, bool> _status = const {};
  OemVendor? _oem;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _refresh();
    ReminderPermissions.oemVendor().then((oem) {
      if (mounted) setState(() => _oem = oem);
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Coming back from a system settings page.
    if (state == AppLifecycleState.resumed) _refresh();
  }

  Future<void> _refresh() async {
    final status = await ReminderPermissions.check();
    if (mounted) setState(() => _status = status);
  }

  Future<void> _turnOn(ReminderSetupItem item) async {
    await ReminderPermissions.request(item);
    await _refresh();
  }

  Future<void> _sendTestReminder() async {
    try {
      await scheduleTestReminder(delay: const Duration(seconds: 15));
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          duration: Duration(seconds: 8),
          content: Text(
            'Test reminder in 15 seconds. Lock the phone, or go to the home '
            'screen or another app, and check that it fills the screen.',
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not schedule test reminder: $e')),
      );
    }
  }

  bool get _allGranted =>
      _status.isNotEmpty && _status.values.every((granted) => granted);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.pageBackground,
      body: SafeArea(
        child: MaxWidth(
          maxWidth: 820,
          child: ListView(
            padding: EdgeInsets.symmetric(
              horizontal: Screen.gutter(context),
              vertical: 20,
            ),
            children: [
              const Row(
                children: [
                  IconMedallion(
                    icon: Icons.notifications_active_rounded,
                    color: AppColors.terracotta,
                    size: 56,
                    background: AppColors.medicineBlush,
                  ),
                  SizedBox(width: 14),
                  Expanded(
                    child: Text(
                      'Set up medicine reminders',
                      style: TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.w800,
                        color: AppColors.primaryText,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              const Text(
                'Turn these on so reminders fill the whole screen, even when '
                'the phone is locked or another app is open.',
                style: TextStyle(
                  fontSize: 17,
                  color: AppColors.secondaryText,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 16),
              const Hairline(color: AppColors.terracotta),
              const SizedBox(height: 20),
              _row(
                ReminderSetupItem.overlay,
                Icons.layers_rounded,
                'Display over other apps',
                'Lets the reminder cover the screen on the home screen or inside '
                    'another app. On the next screen, find Smriti in the list and '
                    'turn it on.',
              ),
              _row(
                ReminderSetupItem.notifications,
                Icons.notifications_active_rounded,
                'Notifications',
                'Needed to show any reminder.',
              ),
              _row(
                ReminderSetupItem.fullScreen,
                Icons.screen_lock_portrait_rounded,
                'Full-screen notifications',
                'Lets the reminder appear over the lock screen.',
              ),
              _row(
                ReminderSetupItem.exactAlarm,
                Icons.alarm_rounded,
                'Alarms & reminders',
                'Makes reminders ring at exactly the right time.',
              ),
              _row(
                ReminderSetupItem.battery,
                Icons.battery_charging_full_rounded,
                'Battery: no restrictions',
                'Stops the phone from putting Smriti to sleep and missing '
                    'reminders.',
              ),
              if (_oem != null) _oemCard(_oem!),
              const SizedBox(height: 8),
              _testCard(),
              const SizedBox(height: 20),
              SizedBox(
                height: 60,
                child: ElevatedButton(
                  onPressed: widget.onDone,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _allGranted
                        ? AppColors.leafGreen
                        : AppColors.terracotta,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: Text(
                    _allGranted ? 'Done' : 'Continue for now',
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _row(ReminderSetupItem item, IconData icon, String title, String why) {
    final granted = _status[item];
    return _card(
      icon: icon,
      title: title,
      body: why,
      trailing: granted == null
          ? const SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          : granted
          ? const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.check_circle_rounded,
                  color: AppColors.leafGreen,
                  size: 28,
                ),
                SizedBox(width: 6),
                Text(
                  'On',
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                    color: AppColors.leafGreen,
                  ),
                ),
              ],
            )
          : _actionButton('Turn on', () => _turnOn(item)),
    );
  }

  Widget _oemCard(OemVendor oem) {
    final (brand, toggles) = switch (oem) {
      OemVendor.xiaomi => (
        'Xiaomi / Redmi / POCO',
        'Under "Other permissions", allow: Show on lock screen, Display '
            'pop-up windows while running in the background, and Display '
            'pop-up windows. Then turn on Autostart in the app settings.',
      ),
      OemVendor.vivo => (
        'Vivo / iQOO',
        'Allow: Display on lock screen, Background pop-ups (display pop-up '
            'windows), and Autostart.',
      ),
      OemVendor.oppo => (
        'Oppo / Realme / OnePlus',
        'Allow: Display over other apps / floating windows, Auto launch, '
            'and Allow background activity.',
      ),
      OemVendor.samsung => (
        'Samsung',
        'Set Battery to "Unrestricted" and make sure Smriti is not in '
            '"Sleeping apps" or "Deep sleeping apps".',
      ),
      OemVendor.other => (
        'this',
        'Some phones add their own switches. In the app settings, allow '
            'anything like: Show on lock screen, Pop-up or floating '
            'windows, Autostart or background activity, and set Battery '
            'to "Unrestricted".',
      ),
    };
    return _card(
      icon: Icons.phone_android_rounded,
      title:
          'Extra settings on $brand phone${oem == OemVendor.other ? '' : 's'}',
      body:
          '$toggles\nThese can\'t be checked automatically. Please confirm '
          'with the test reminder below.',
      trailing: _actionButton(
        'Open',
        NativeReminderBridge.openOemPermissionSettings,
      ),
    );
  }

  Widget _testCard() {
    return _card(
      icon: Icons.play_circle_fill_rounded,
      title: 'Try it',
      body:
          'Sends a test reminder in 15 seconds. Lock the phone or open '
          'another app and check that it fills the screen and the voice '
          'plays.',
      trailing: _actionButton('Send test', _sendTestReminder),
    );
  }

  Widget _actionButton(String label, VoidCallback onPressed) {
    return ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.terracotta,
        foregroundColor: AppColors.onColor,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      ),
      child: Text(
        label,
        style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700),
      ),
    );
  }

  Widget _card({
    required IconData icon,
    required String title,
    required String body,
    required Widget trailing,
  }) {
    final text = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 19,
            fontWeight: FontWeight.w700,
            color: AppColors.primaryText,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          body,
          style: const TextStyle(
            fontSize: 15,
            color: AppColors.secondaryText,
            height: 1.35,
          ),
        ),
      ],
    );
    final medallion = IconMedallion(
      icon: icon,
      color: AppColors.terracotta,
      size: 52,
      background: AppColors.medicineBlush,
    );

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.raisedSurface,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: AppColors.terracottaDeep.withValues(alpha: 0.07), blurRadius: 10, offset: const Offset(0, 3))],
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          // Narrow phones: action goes under the explanation.
          if (constraints.maxWidth < 480) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    medallion,
                    const SizedBox(width: 14),
                    Expanded(child: text),
                  ],
                ),
                const SizedBox(height: 12),
                Align(alignment: Alignment.centerRight, child: trailing),
              ],
            );
          }
          return Row(
            children: [
              medallion,
              const SizedBox(width: 16),
              Expanded(child: text),
              const SizedBox(width: 12),
              trailing,
            ],
          );
        },
      ),
    );
  }
}
