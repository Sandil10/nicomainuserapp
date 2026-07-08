import 'package:flutter/material.dart';
import './app_localization.dart';

class LegalSettings extends StatefulWidget {
  const LegalSettings({Key? key}) : super(key: key);

  @override
  State<LegalSettings> createState() => _LegalSettingsState();
}

class _LegalSettingsState extends State<LegalSettings> {
  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();
    _initializeComponent();
  }

  Future<void> _initializeComponent() async {
    await AppLocalization.initialize();
    if (mounted) {
      setState(() {
        _isInitialized = true;
      });
    }
  }

  void _showPrivacyPolicy() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => LegalDocumentPage(
          title: AppLocalization.getText('privacyPolicyTitle'),
          content: _privacyPolicyContent,
        ),
      ),
    );
  }

  void _showTermsAndConditions() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => LegalDocumentPage(
          title: AppLocalization.getText('termsConditionsTitle'),
          content: _termsAndConditionsContent,
        ),
      ),
    );
  }

  Widget _buildLegalItem({
    required String title,
    required String subtitle,
    required IconData icon,
    required Color iconColor,
    required VoidCallback onTap,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 1),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: iconColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(icon, color: iconColor, size: 20),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          fontSize: 13,
                          color: Color(0xFF1A1A1A),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        subtitle,
                        style: const TextStyle(
                          fontSize: 13,
                          color: Color(0xFF6B7280),
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                    ],
                  ),
                ),
                const Icon(Icons.arrow_forward_ios,
                    color: Color(0xFF6B7280), size: 14),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String get _privacyPolicyContent => '''
Last Updated: January 2026

Privacy Policy of Nico Mart

1. Introduction
Nico Mart ("we," "our," or "us") is a mobile grocery shopping application that allows users to browse products, place home delivery orders, and make secure payments using cash. Protecting your privacy is important to us. This Privacy Policy explains how we collect, use, and share your personal information when you use our app.

By using Nico Mart, you agree to the collection and use of information in accordance with this Privacy Policy.

2. Information We Collect
A. Information You Provide Directly
When you sign up, log in, or place an order, we may collect:
• Name
• Email address
• Phone number
• Password
• Delivery details: full name, phone number, street address, city, zip code, province, delivery instructions
• Gender (if updated in profile)

B. Information Collected Automatically (Derivative Data)
We automatically collect:
• Device information (device type, OS version, app version, device ID)
• Log and usage data (IP address, app usage, session info, errors)

C. Information from Google API Services and Apple Sign In
• If you use Continue with Google, we collect your Google account email and name.
• If you use Continue with Apple, we collect your Apple account email and name.

3. How We Use Your Information
We use your information to:
• Process and manage your orders
• Deliver groceries to your specified address
• Respond to user inquiries (messages to admin)
• Provide account management (login, profile updates, password reset)
• Secure and authenticate user accounts

Note: Users do not receive push notifications from Nico Mart.

4. Legal Bases for Processing
We process your personal information under the following lawful bases:
• Consent: When you agree to provide personal information during signup or order placement.
• Performance of a Contract: To fulfill your orders, deliver services, and manage payments.
• Legitimate Interests: To improve app functionality, prevent fraud, and ensure security.
• Legal Obligation: To comply with applicable laws.

5. Payments
Users can pay via cash upon delivery. All payments are made in cash when the order is delivered to your specified address.

6. Data Sharing
We do not sell, rent, or trade your personal information. We may share data with Firebase (for authentication, database storage, and analytics).

7. Data Retention
We retain your account and order information as long as your account exists or as necessary to fulfill legal obligations. You can delete your account at any time through the app.

8. User Rights
You can:
• Access and update your personal information in your profile
• Change your password
• Delete your account
• Request information about what data we have stored

9. Cookies and Tracking
We use Firebase for analytics and security. No tracking or location data is collected beyond what is needed for app functionality.

10. Children's Privacy
Nico Mart is not intended for children under 13. We do not knowingly collect personal information from children.

11. Language
This Privacy Policy is available in English.

12. Changes to This Privacy Policy
We may update this Privacy Policy from time to time. Updates will be posted on this page with the effective date.

13. Contact Us
If you have any questions about this Privacy Policy, contact us at:
Email: nicocrewmilano@gmail.com
Website: https://www.nicomart.it/
''';

  String get _termsAndConditionsContent => '''
TERMS AND CONDITIONS OF NICO MART

Last Updated: January 2026

Welcome to Nico Mart! By using our mobile application, you agree to these Terms and Conditions. Please read them carefully before using the app.

1. PURPOSE OF THE TERMS
These Terms govern your access and use of Nico Mart for browsing, ordering, and receiving groceries, fashion items, school supplies, and water bottles through registered accounts.

2. USER REGISTRATION AND ACCOUNT
To use the service, you must provide accurate information during account creation. You are responsible for maintaining the confidentiality of your account credentials.

3. USING THE SERVICE
Nico Mart allows users to:
• Browse product categories
• Add products to a cart
• Provide delivery details
• Pay via cash on delivery

4. PRICES AND PAYMENTS
• All prices are in Rupees (Rs)
• All payments are made in CASH upon delivery
• Delivery fees, if any, are shown before order confirmation

5. REFUNDS AND ISSUES
• For missing or damaged items, contact customer support within 24 hours
• Perishable food products are excluded from the right of withdrawal

6. RESPONSIBILITIES
Nico Mart is not responsible for technical malfunctions outside our control or incorrect user-provided information.

7. CONTACT INFORMATION
For questions regarding these Terms:
Email: nicocrewmilano@gmail.com
Website: https://www.nicomart.it/

8. APPLICABLE LAW
These Terms are governed by Sri Lankan law.
''';

  @override
  Widget build(BuildContext context) {
    if (!_isInitialized) {
      return Scaffold(
        backgroundColor: const Color(0xFFF8FAFC),
        body: const Center(
            child: CircularProgressIndicator(color: Color(0xFF4A22A8))),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: const Icon(Icons.arrow_back_ios,
              color: Color(0xFF4A22A8), size: 20),
        ),
        title: ValueListenableBuilder<String>(
          valueListenable: AppLocalization.currentLanguage,
          builder: (context, languageCode, child) {
            return Text(
              AppLocalization.getText('legalTitle'),
              style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF1A1A1A)),
            );
          },
        ),
        centerTitle: false,
      ),
      body: SafeArea(
        child: ValueListenableBuilder<String>(
          valueListenable: AppLocalization.currentLanguage,
          builder: (context, languageCode, child) {
            return SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 16),
                  Container(
                    margin: const EdgeInsets.symmetric(horizontal: 20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                            color: Colors.black.withOpacity(0.06),
                            blurRadius: 15,
                            offset: const Offset(0, 6)),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
                          child: Row(
                            children: [
                              Container(
                                width: 28,
                                height: 28,
                                decoration: BoxDecoration(
                                  color:
                                      const Color(0xFF4A22A8).withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: const Icon(Icons.gavel_outlined,
                                    color: Color(0xFF4A22A8), size: 16),
                              ),
                              const SizedBox(width: 10),
                              Text(
                                AppLocalization.getText('legalDocuments'),
                                style: const TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    color: Color(0xFF1A1A1A)),
                              ),
                            ],
                          ),
                        ),
                        _buildLegalItem(
                          title: AppLocalization.getText('privacyPolicyTitle'),
                          subtitle:
                              AppLocalization.getText('privacyPolicySubtitle'),
                          icon: Icons.privacy_tip_outlined,
                          iconColor: const Color(0xFF4A22A8),
                          onTap: _showPrivacyPolicy,
                        ),
                        _buildLegalItem(
                          title:
                              AppLocalization.getText('termsConditionsTitle'),
                          subtitle: AppLocalization.getText(
                              'termsConditionsSubtitle'),
                          icon: Icons.description_outlined,
                          iconColor: const Color(0xFFEA580C),
                          onTap: _showTermsAndConditions,
                        ),
                        const SizedBox(height: 4),
                      ],
                    ),
                  ),
                  const SizedBox(height: 32),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

class LegalDocumentPage extends StatelessWidget {
  final String title;
  final String content;

  const LegalDocumentPage(
      {Key? key, required this.title, required this.content})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: const Icon(Icons.arrow_back_ios,
              color: Color(0xFF4A22A8), size: 20),
        ),
        title: Text(
          title,
          style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Color(0xFF1A1A1A)),
        ),
        centerTitle: false,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Container(
            margin: const EdgeInsets.all(20),
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                    color: Colors.black.withOpacity(0.06),
                    blurRadius: 15,
                    offset: const Offset(0, 6))
              ],
            ),
            child: SelectableText(
              content,
              style: const TextStyle(
                  fontSize: 14,
                  height: 1.6,
                  color: Color(0xFF374151),
                  fontWeight: FontWeight.w400),
            ),
          ),
        ),
      ),
    );
  }
}
