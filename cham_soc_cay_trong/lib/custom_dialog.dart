import 'dart:ui';
import 'package:flutter/material.dart';

class PremiumDialog extends StatelessWidget {
  final String title;
  final String message;
  final String? confirmText;
  final String? cancelText;
  final bool isDanger;
  final bool isWarning;
  final bool isSuccess;
  final bool isConfirm; // true for confirm dialog (binary choices), false for alert (single button)

  const PremiumDialog({
    super.key,
    required this.title,
    required this.message,
    this.confirmText,
    this.cancelText,
    this.isDanger = false,
    this.isWarning = false,
    this.isSuccess = false,
    this.isConfirm = true,
  });

  static Future<bool> showPremiumConfirmDialog({
    required BuildContext context,
    required String title,
    required String message,
    String? confirmText,
    String? cancelText,
    bool isDanger = false,
    bool isWarning = false,
  }) async {
    final result = await showGeneralDialog<bool>(
      context: context,
      barrierDismissible: true,
      barrierLabel: '',
      barrierColor: Colors.black.withValues(alpha: 0.4),
      transitionDuration: const Duration(milliseconds: 320),
      pageBuilder: (context, anim1, anim2) {
        return const SizedBox.shrink();
      },
      transitionBuilder: (context, anim1, anim2, child) {
        final curve = CurvedAnimation(parent: anim1, curve: Curves.easeOutBack);
        return BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 5.0, sigmaY: 5.0),
          child: ScaleTransition(
            scale: curve,
            child: FadeTransition(
              opacity: anim1,
              child: Dialog(
                backgroundColor: Colors.transparent,
                elevation: 0,
                insetPadding: const EdgeInsets.symmetric(horizontal: 24),
                child: PremiumDialog(
                  title: title,
                  message: message,
                  confirmText: confirmText,
                  cancelText: cancelText,
                  isDanger: isDanger,
                  isWarning: isWarning,
                  isConfirm: true,
                ),
              ),
            ),
          ),
        );
      },
    );
    return result ?? false;
  }

  static Future<void> showPremiumAlertDialog({
    required BuildContext context,
    required String title,
    required String message,
    String? buttonText,
    bool isSuccess = true,
  }) async {
    await showGeneralDialog<void>(
      context: context,
      barrierDismissible: true,
      barrierLabel: '',
      barrierColor: Colors.black.withValues(alpha: 0.4),
      transitionDuration: const Duration(milliseconds: 320),
      pageBuilder: (context, anim1, anim2) {
        return const SizedBox.shrink();
      },
      transitionBuilder: (context, anim1, anim2, child) {
        final curve = CurvedAnimation(parent: anim1, curve: Curves.easeOutBack);
        return BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 5.0, sigmaY: 5.0),
          child: ScaleTransition(
            scale: curve,
            child: FadeTransition(
              opacity: anim1,
              child: Dialog(
                backgroundColor: Colors.transparent,
                elevation: 0,
                insetPadding: const EdgeInsets.symmetric(horizontal: 24),
                child: PremiumDialog(
                  title: title,
                  message: message,
                  confirmText: buttonText,
                  isSuccess: isSuccess,
                  isConfirm: false,
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    // Style settings based on type
    Color primaryColor = const Color(0xFF2E7D32); // Emerald Green default
    IconData iconData = Icons.info_outline_rounded;
    Color iconBgColor = const Color(0xFFE3F2FD); // Soft Blue default
    Color iconColor = const Color(0xFF1E88E5);

    if (isDanger) {
      primaryColor = const Color(0xFFE53935); // Vibrant Red
      iconData = Icons.delete_outline_rounded;
      iconBgColor = const Color(0xFFFFEBEE);
      iconColor = const Color(0xFFE53935);
    } else if (isWarning) {
      primaryColor = const Color(0xFFFB8C00); // Amber/Orange
      iconData = Icons.logout_rounded;
      iconBgColor = const Color(0xFFFFF3E0);
      iconColor = const Color(0xFFFB8C00);
    } else if (isSuccess) {
      primaryColor = const Color(0xFF2E7D32);
      iconData = Icons.check_circle_outline_rounded;
      iconBgColor = const Color(0xFFE8F5E9);
      iconColor = const Color(0xFF2E7D32);
    }

    return Container(
      constraints: const BoxConstraints(maxWidth: 380),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 24,
            offset: const Offset(0, 12),
          ),
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Icon Circle Header
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              color: iconBgColor,
              shape: BoxShape.circle,
            ),
            child: Icon(
              iconData,
              color: iconColor,
              size: 36,
            ),
          ),
          const SizedBox(height: 20),
          // Title
          Text(
            title,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w900,
              color: Color(0xFF1B2A22),
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),
          // Message
          Text(
            message,
            style: const TextStyle(
              fontSize: 14,
              height: 1.5,
              color: Color(0xFF5A6862),
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 28),
          // Actions Buttons Row or Single
          if (isConfirm)
            Row(
              children: [
                // Cancel
                Expanded(
                  child: TextButton(
                    onPressed: () => Navigator.pop(context, false),
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                        side: const BorderSide(color: Color(0xFFE5EDE9)),
                      ),
                      backgroundColor: const Color(0xFFF7FAF8),
                      foregroundColor: const Color(0xFF5A6862),
                    ),
                    child: Text(
                      cancelText ?? 'Hủy',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                // Confirm
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(context, true),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primaryColor,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      shadowColor: primaryColor.withValues(alpha: 0.3),
                    ),
                    child: Text(
                      confirmText ?? 'Xác nhận',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
              ],
            )
          else
            // Single Button for Alert
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryColor,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child: Text(
                  confirmText ?? 'OK',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
