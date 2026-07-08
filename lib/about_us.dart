// lib/about_us.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'app_notification.dart';
import 'app_localization.dart';

class AboutUs extends StatelessWidget {
  const AboutUs({Key? key}) : super(key: key);

  // Color palette - professional and subdued
  static const Color _primaryBlue = Color(0xFF1E40AF);
  static const Color _darkGray = Color(0xFF374151);
  static const Color _mediumGray = Color(0xFF6B7280);
  static const Color _lightGray = Color(0xFF9CA3AF);
  static const Color _softPurple = Color(0xFF4A22A8);
  static const Color _backgroundColor = Color(0xFFFAFAFA);

  /* ──────────────────  helpers  ────────────────── */

  void _copy(BuildContext ctx, String text) {
    Clipboard.setData(ClipboardData(text: text));

    // Show top notification using app_notification.dart style
    showAppNotification(
      title: AppLocalization.getText('copied'),
      message: AppLocalization.getText('textCopiedToClipboard'),
      type: NotificationType.success,
    );
  }

  Widget _infoChip(String label) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: _primaryBlue.withOpacity(0.08),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: _primaryBlue.withOpacity(0.2), width: 0.5),
        ),
        child: Text(
          label,
          style: const TextStyle(
            color: _primaryBlue,
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
        ),
      );

  Widget _bullet(String text) => Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              margin: const EdgeInsets.only(top: 2),
              width: 6,
              height: 6,
              decoration: const BoxDecoration(
                color: _softPurple,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                text,
                style: const TextStyle(
                  color: _darkGray,
                  fontSize: 14,
                  height: 1.5,
                ),
              ),
            ),
          ],
        ),
      );

  Widget _directorCard({
    required String imagePath,
    required String name,
    required String title,
  }) =>
      Container(
        padding: const EdgeInsets.all(20),
        margin: const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: const [
            BoxShadow(
              color: Color(0x0A000000),
              blurRadius: 10,
              offset: Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                image: DecorationImage(
                  image: AssetImage(imagePath),
                  fit: BoxFit.cover,
                ),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x15000000),
                    blurRadius: 8,
                    offset: Offset(0, 2),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: _softPurple,
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    name,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: _darkGray,
                      letterSpacing: -0.3,
                    ),
                  ),
                  const SizedBox(height: 8),
                ],
              ),
            ),
          ],
        ),
      );

  /* ──────────────────  build  ────────────────── */

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<String>(
      valueListenable: AppLocalization.currentLanguage,
      builder: (context, currentLanguage, child) {
        return Scaffold(
          backgroundColor: _backgroundColor,
          body: CustomScrollView(
            slivers: [
              /* ---------- Clean Header ---------- */
              SliverAppBar(
                automaticallyImplyLeading: false,
                pinned: true,
                expandedHeight: 160,
                backgroundColor: Colors.white,
                elevation: 0,
                leading: IconButton(
                  icon: const Icon(Icons.arrow_back_ios_rounded,
                      color: _darkGray, size: 20),
                  onPressed: () => Navigator.pop(context),
                ),
                flexibleSpace: FlexibleSpaceBar(
                  titlePadding: const EdgeInsets.only(left: 56, bottom: 16),
                  title: ValueListenableBuilder<String>(
                    valueListenable: AppLocalization.currentLanguage,
                    builder: (context, language, child) => Text(
                      AppLocalization.getText('aboutUsPageTitle'),
                      style: const TextStyle(
                        color: _darkGray,
                        fontSize: 22,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  background: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Color(0xFFF4F0FF),
                          Color(0xFFF4F0FF),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      border: const Border(
                        bottom:
                            BorderSide(color: Color(0xFFE5E7EB), width: 0.5),
                      ),
                    ),
                    child: Stack(
                      children: [
                        const Align(
                          alignment: Alignment.centerRight,
                          child: Padding(
                            padding: EdgeInsets.only(right: 24),
                            child: Icon(
                              Icons.water_drop_outlined,
                              size: 60,
                              color: Color(0x40039BE5),
                            ),
                          ),
                        ),
                        const Align(
                          alignment: Alignment.bottomRight,
                          child: Padding(
                            padding: EdgeInsets.only(right: 80, bottom: 20),
                            child: Icon(
                              Icons.restaurant_outlined,
                              size: 40,
                              color: Color(0x40FF9800),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              /* ---------- Body ---------- */
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      /* --- Company Intro Card --- */
                      _card(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              AppLocalization.getText('whatIsNicoOnlineMart'),
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w600,
                                color: _darkGray,
                                letterSpacing: -0.3,
                              ),
                            ),
                            const SizedBox(height: 16),
                            Text(
                              AppLocalization.getText(
                                  'nicoOnlineMartDescription'),
                              style: const TextStyle(
                                color: _mediumGray,
                                fontSize: 14,
                                height: 1.6,
                              ),
                            ),
                            const SizedBox(height: 20),
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: [
                                _infoChip(AppLocalization.getText('waterChip')),
                                _infoChip(AppLocalization.getText(
                                    'sriLankanGroceriesChip')),
                                _infoChip(AppLocalization.getText(
                                    'fastDeliveryChip')),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),

                      /* --- Simple Banner --- */
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          color: _primaryBlue.withOpacity(0.05),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                              color: _primaryBlue.withOpacity(0.1), width: 0.5),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: _primaryBlue.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: const Icon(
                                    Icons.local_shipping_outlined,
                                    color: _primaryBlue,
                                    size: 20,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    AppLocalization.getText(
                                        'nicoOnlineMartBanner'),
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                      color: _darkGray,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Text(
                              AppLocalization.getText(
                                  'nicoOnlineMartBannerSubtitle'),
                              style: const TextStyle(
                                color: _mediumGray,
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),

                      /* --- Solution Banner --- */
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: Color(0xFFF4F0FF),
                          borderRadius: BorderRadius.circular(20),
                          border:
                              Border.all(color: Color(0xFFE8DFFF), width: 0.5),
                        ),
                        child: Text(
                          AppLocalization.getText('solutionBanner'),
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            color: _darkGray,
                            fontSize: 14,
                            height: 1.5,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                      const SizedBox(height: 32),

                      /* --- Directors Section --- */
                      Text(
                        AppLocalization.getText('ourDirectors'),
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: _darkGray,
                          letterSpacing: -0.3,
                        ),
                      ),
                      const SizedBox(height: 16),
                      _directorCard(
                        imagePath: 'assets/images/100.jpg',
                        name: 'Maduranga Promod Rathnayaka',
                        title: AppLocalization.getText('director'),
                      ),
                      const SizedBox(height: 32),

                      /* --- Water Section --- */
                      Text(
                        AppLocalization.getText('drinkingWaterTitle'),
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: _darkGray,
                          letterSpacing: -0.3,
                        ),
                      ),
                      const SizedBox(height: 16),
                      _card(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _bullet(
                                AppLocalization.getText('orderAnyQuantity')),
                            _bullet(AppLocalization.getText(
                                'noMoreHeavyTransport')),
                            _bullet(
                                AppLocalization.getText('homeOfficeDelivery')),
                            _bullet(AppLocalization.getText('easyAppUse')),
                            const SizedBox(height: 10),
                            _bullet(AppLocalization.getText(
                                'simpleIntuitiveInterface')),
                            _bullet(
                                AppLocalization.getText('realtimeTracking')),
                            _bullet(AppLocalization.getText(
                                'paymentOnDeliveryOrOnline')),
                          ],
                        ),
                      ),
                      const SizedBox(height: 32),

                      /* --- Values Section --- */
                      Text(
                        AppLocalization.getText('speedReliabilityPunctuality'),
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: _darkGray,
                          letterSpacing: -0.3,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: _valueCard(
                              icon: Icons.schedule_outlined,
                              title: AppLocalization.getText(
                                  'alwaysPunctualDeliveries'),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _valueCard(
                              icon: Icons.verified_user_outlined,
                              title: AppLocalization.getText(
                                  'guaranteedCustomerSatisfaction'),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),

                      /* --- Order Now Section --- */
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: Color(0xFFF4F0FF),
                          borderRadius: BorderRadius.circular(20),
                          border:
                              Border.all(color: Color(0xFFE8DFFF), width: 0.5),
                        ),
                        child: Column(
                          children: [
                            Text(
                              AppLocalization.getText('orderNow'),
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w600,
                                color: _darkGray,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              AppLocalization.getText('downloadApp'),
                              style: const TextStyle(
                                color: _mediumGray,
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 32),

                      /* --- Contact Section --- */
                      Text(
                        AppLocalization.getText('contactUs'),
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: _darkGray,
                          letterSpacing: -0.3,
                        ),
                      ),
                      const SizedBox(height: 16),
                      _card(
                        child: Column(
                          children: [
                            _contactItem(
                              icon: Icons.language_outlined,
                              title: 'www.nicomart.it',
                              subtitle:
                                  AppLocalization.getText('visitOurWebsite'),
                              onTap: () => _copy(context, 'www.nicomart.it'),
                            ),
                            const Divider(height: 32, color: Color(0xFFE5E7EB)),
                            Align(
                              alignment: Alignment.centerLeft,
                              child: Text(
                                AppLocalization.getText('hotline'),
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                  color: _darkGray,
                                ),
                              ),
                            ),
                            const SizedBox(height: 16),
                            ...[
                              '+94 76 921 9530',
                              '+94 76 829 3948',
                            ].map((phone) => Padding(
                                  padding: const EdgeInsets.only(bottom: 8),
                                  child: _contactItem(
                                    icon: Icons.phone_outlined,
                                    title: phone,
                                    subtitle:
                                        AppLocalization.getText('tapToCopy'),
                                    onTap: () => _copy(context, phone),
                                  ),
                                )),
                          ],
                        ),
                      ),
                      const SizedBox(height: 40),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  /* ──────────────────  small reusable widgets  ────────────────── */

  Widget _card({required Widget child}) => Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: const [
            BoxShadow(
              color: Color(0x0A000000),
              blurRadius: 10,
              offset: Offset(0, 2),
            ),
          ],
        ),
        child: child,
      );

  Widget _valueCard({
    required IconData icon,
    required String title,
  }) =>
      Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: const [
            BoxShadow(
              color: Color(0x05000000),
              blurRadius: 8,
              offset: Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: _softPurple.withOpacity(0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Icon(icon, color: _softPurple, size: 20),
            ),
            const SizedBox(height: 12),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: _darkGray,
              ),
            ),
          ],
        ),
      );

  Widget _contactItem({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) =>
      GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.transparent,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: _lightGray.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Icon(icon, color: _mediumGray, size: 18),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: _darkGray,
                      ),
                    ),
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
              const Icon(Icons.copy_outlined, color: _lightGray, size: 16),
            ],
          ),
        ),
      );
}
