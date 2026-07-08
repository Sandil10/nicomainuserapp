// lib/contact.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'app_notification.dart';
import 'app_localization.dart';

class ContactSupport extends StatelessWidget {
  const ContactSupport({Key? key}) : super(key: key);

  static const Color _primaryPurple = Color(0xFF4A22A8);
  static const Color _darkGray = Color(0xFF374151);
  static const Color _mediumGray = Color(0xFF6B7280);
  static const Color _lightGray = Color(0xFF9CA3AF);
  static const Color _backgroundColor = Color(0xFFFAFAFA);

  void _copy(BuildContext ctx, String text) {
    Clipboard.setData(ClipboardData(text: text));

    // Show top notification using app_notification.dart style
    showAppNotification(
      title: AppLocalization.getText('copied'),
      message: AppLocalization.getText('textCopiedToClipboard'),
      type: NotificationType.success,
    );
  }

  Widget _contactItem({
    required BuildContext context,
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) =>
      GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(14),
          margin: const EdgeInsets.only(bottom: 10),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: _primaryPurple.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: _primaryPurple, size: 20),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: _darkGray,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        fontSize: 12,
                        color: _mediumGray,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.copy_outlined, color: _lightGray, size: 18),
            ],
          ),
        ),
      );

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<String>(
      valueListenable: AppLocalization.currentLanguage,
      builder: (context, currentLanguage, child) {
        return Scaffold(
          backgroundColor: _backgroundColor,
          appBar: AppBar(
            backgroundColor: Colors.white,
            elevation: 0,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_ios_rounded,
                  color: _darkGray, size: 18),
              onPressed: () => Navigator.pop(context),
            ),
            title: Text(
              AppLocalization.getText('contactPageTitle'),
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: _darkGray,
              ),
            ),
            centerTitle: false,
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header Card
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        _primaryPurple.withOpacity(0.1),
                        _primaryPurple.withOpacity(0.05),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(
                      color: _primaryPurple.withOpacity(0.2),
                      width: 1,
                    ),
                  ),
                  child: Column(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: _primaryPurple.withOpacity(0.2),
                              blurRadius: 12,
                              offset: const Offset(0, 3),
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.support_agent,
                          color: _primaryPurple,
                          size: 32,
                        ),
                      ),
                      const SizedBox(height: 14),
                      Text(
                        AppLocalization.getText('customerSupport'),
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: _darkGray,
                          letterSpacing: -0.3,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        AppLocalization.getText('customerSupportSubtitle'),
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 13,
                          color: _mediumGray,
                          height: 1.5,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 28),

                // Contact Methods Title
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(7),
                      decoration: BoxDecoration(
                        color: _primaryPurple.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(9),
                      ),
                      child: const Icon(
                        Icons.contact_mail_outlined,
                        color: _primaryPurple,
                        size: 18,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Text(
                      AppLocalization.getText('contactUsSection'),
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: _darkGray,
                        letterSpacing: -0.3,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),

                // Website
                _contactItem(
                  context: context,
                  icon: Icons.language_outlined,
                  title: 'www.nicomart.it',
                  subtitle: AppLocalization.getText('visitOurWebsite'),
                  onTap: () => _copy(context, 'www.nicomart.it'),
                ),

                const SizedBox(height: 20),

                // Phone Numbers Section
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(7),
                      decoration: BoxDecoration(
                        color: _primaryPurple.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(9),
                      ),
                      child: const Icon(
                        Icons.phone_outlined,
                        color: _primaryPurple,
                        size: 18,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Text(
                      AppLocalization.getText('hotlineSection'),
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: _darkGray,
                        letterSpacing: -0.3,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),

                // Phone Number 1
                _contactItem(
                  context: context,
                  icon: Icons.phone_outlined,
                  title: '+94 76 921 9530',
                  subtitle: AppLocalization.getText('tapToCopy'),
                  onTap: () => _copy(context, '+94769219530'),
                ),

                // Phone Number 2
                _contactItem(
                  context: context,
                  icon: Icons.phone_outlined,
                  title: '+94 76 829 3948',
                  subtitle: AppLocalization.getText('tapToCopy'),
                  onTap: () => _copy(context, '+94768293948'),
                ),

                const SizedBox(height: 28),

                // Additional Info Card
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Color(0xFFF4F0FF),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: Color(0xFFE8DFFF),
                      width: 1,
                    ),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(
                        Icons.info_outline,
                        color: Color(0xFF4A22A8),
                        size: 20,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          AppLocalization.getText('supportTeamAvailable'),
                          style: TextStyle(
                            fontSize: 12,
                            color: Color(0xFF2F176F),
                            height: 1.5,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 32),
              ],
            ),
          ),
        );
      },
    );
  }
}
