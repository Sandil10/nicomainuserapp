import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'app_notification.dart';
import 'app_localization.dart';

class FAQs extends StatefulWidget {
  const FAQs({Key? key}) : super(key: key);

  @override
  State<FAQs> createState() => _FAQsState();
}

class _FAQsState extends State<FAQs> {
  int? expandedIndex;

  static const Color _primaryBlue = Color(0xFF1E40AF);
  static const Color _darkGray = Color(0xFF374151);
  static const Color _mediumGray = Color(0xFF6B7280);
  static const Color _backgroundColor = Color(0xFFFAFAFA);
  static const Color _softPurple = Color(0xFF4A22A8);

  List<Map<String, dynamic>> _getFaqData() => [
        {
          'question': AppLocalization.getText('faq1Question'),
          'answer': AppLocalization.getText('faq1Answer'),
          'hasWhatsApp': false,
        },
        {
          'question': AppLocalization.getText('faq2Question'),
          'answer': AppLocalization.getText('faq2Answer'),
          'hasWhatsApp': false,
        },
        {
          'question': AppLocalization.getText('faq3Question'),
          'answer': AppLocalization.getText('faq3Answer'),
          'hasWhatsApp': true,
        },
      ];

  void _copyToClipboard() {
    const phoneNumber = '+94 329 013 2841';
    Clipboard.setData(const ClipboardData(text: phoneNumber));

    // Show top notification using app_notification.dart style
    showAppNotification(
      title: AppLocalization.getText('copied'),
      message: AppLocalization.getText('phoneNumberCopied'),
      type: NotificationType.success,
    );
  }

  void _showContactDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: _softPurple,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          title: Row(
            children: [
              const Icon(Icons.chat_bubble_outline,
                  color: Colors.white, size: 22),
              const SizedBox(width: 12),
              Text(
                AppLocalization.getText('contactSupportDialog'),
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                  letterSpacing: -0.3,
                ),
              ),
            ],
          ),
          content: Text(
            AppLocalization.getText('contactSupportDialogMessage'),
            style: const TextStyle(
              fontSize: 14,
              color: Colors.white,
              height: 1.6,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              style: TextButton.styleFrom(
                foregroundColor: Colors.white70,
              ),
              child: Text(
                AppLocalization.getText('close'),
                style: const TextStyle(fontWeight: FontWeight.w500),
              ),
            ),
            Container(
              margin: const EdgeInsets.only(right: 8, bottom: 8, top: 8),
              child: ElevatedButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  _copyToClipboard();
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: _softPurple,
                  elevation: 0,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
                child: Text(
                  AppLocalization.getText('copyNumber'),
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<String>(
      valueListenable: AppLocalization.currentLanguage,
      builder: (context, currentLanguage, child) {
        return Scaffold(
          backgroundColor: _backgroundColor,
          body: CustomScrollView(
            slivers: [
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
                  title: Text(
                    AppLocalization.getText('faqsPageTitle'),
                    style: const TextStyle(
                        color: _darkGray,
                        fontSize: 22,
                        fontWeight: FontWeight.w600),
                  ),
                  background: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Color(0xFFF4F0FF), Color(0xFFF4F0FF)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      border: const Border(
                          bottom:
                              BorderSide(color: Color(0xFFE5E7EB), width: 0.5)),
                    ),
                  ),
                ),
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    children: [
                      ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: _getFaqData().length,
                        itemBuilder: (context, index) {
                          final faq = _getFaqData()[index];
                          final isExpanded = expandedIndex == index;

                          return Container(
                            margin: const EdgeInsets.only(bottom: 16),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(20),
                              boxShadow: const [
                                BoxShadow(
                                    color: Color(0x0A000000),
                                    blurRadius: 10,
                                    offset: Offset(0, 2)),
                              ],
                              border: isExpanded
                                  ? Border.all(
                                      color: _primaryBlue.withOpacity(0.3),
                                      width: 1.5)
                                  : null,
                            ),
                            child: Column(
                              children: [
                                GestureDetector(
                                  onTap: () => setState(() => expandedIndex =
                                      isExpanded ? null : index),
                                  child: Padding(
                                    padding: const EdgeInsets.all(20),
                                    child: Row(
                                      children: [
                                        Expanded(
                                          child: Text(
                                            faq['question']!,
                                            style: const TextStyle(
                                                fontSize: 16,
                                                fontWeight: FontWeight.w600,
                                                color: _darkGray),
                                          ),
                                        ),
                                        const SizedBox(width: 12),
                                        AnimatedRotation(
                                          turns: isExpanded ? 0.25 : 0,
                                          duration:
                                              const Duration(milliseconds: 300),
                                          child: Icon(
                                            Icons.add_circle_outline,
                                            color: isExpanded
                                                ? _primaryBlue
                                                : _mediumGray,
                                            size: 24,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                                AnimatedSize(
                                  duration: const Duration(milliseconds: 300),
                                  curve: Curves.easeInOut,
                                  child: Container(
                                    height: isExpanded ? null : 0,
                                    child: Padding(
                                      padding: const EdgeInsets.fromLTRB(
                                          20, 0, 20, 20),
                                      child: Column(
                                        children: [
                                          const Divider(
                                              height: 1,
                                              color: Color(0xFFE5E7EB)),
                                          const SizedBox(height: 16),
                                          Text(
                                            faq['answer']!,
                                            style: const TextStyle(
                                                fontSize: 14,
                                                height: 1.6,
                                                color: _mediumGray),
                                          ),
                                          if (faq['hasWhatsApp'] == true) ...[
                                            const SizedBox(height: 16),
                                            ElevatedButton.icon(
                                              onPressed: _showContactDialog,
                                              icon: const Icon(
                                                  Icons.chat_bubble_outline,
                                                  size: 18),
                                              label: Text(
                                                  AppLocalization.getText(
                                                      'contactOnWhatsApp')),
                                              style: ElevatedButton.styleFrom(
                                                backgroundColor: _softPurple,
                                                foregroundColor: Colors.white,
                                                shape: RoundedRectangleBorder(
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                            12)),
                                              ),
                                            ),
                                          ],
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
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
}
