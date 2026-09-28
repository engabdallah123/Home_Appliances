import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';
import '../constants/app_colors.dart';

class CompanySupportModal {
  static void show(BuildContext context, bool isDark) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _SupportModalContent(isDark: isDark),
    );
  }
}

class _SupportModalContent extends StatefulWidget {
  final bool isDark;
  const _SupportModalContent({required this.isDark});

  @override
  State<_SupportModalContent> createState() => _SupportModalContentState();
}

class _SupportModalContentState extends State<_SupportModalContent> {
  String? _copiedNumber;


  Future<void> _openWhatsApp(String phoneNumber) async {
    // International format: remove leading 0, prepend 2
    final clean = phoneNumber.replaceAll(RegExp(r'\D'), '');
    final intlPhone = clean.startsWith('0') ? '2$clean' : clean;
    final message = Uri.encodeComponent("السلام عليكم، أحتاج دعم فني بخصوص تطبيق كاشير 3A Tech.");
    final uri = Uri.parse("https://wa.me/$intlPhone?text=$message");
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  void _copyToClipboard(String number) {
    Clipboard.setData(ClipboardData(text: number));
    setState(() {
      _copiedNumber = number;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text("تم نسخ الرقم $number بنجاح"),
        backgroundColor: AppColors.success,
        duration: const Duration(seconds: 2),
      ),
    );
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) setState(() => _copiedNumber = null);
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = widget.isDark;

    return Container(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
      decoration: BoxDecoration(
        color: AppColors.getSurface(isDark),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        border: Border.all(color: AppColors.getBorder(isDark)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Handle pill
              Container(
                width: 44,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.getTextMuted(isDark).withOpacity(0.4),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 16),

              // Header with 3A Tech Logo
              Row(
                children: [
                  Container(
                    width: 56,
                    height: 56,
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppColors.cyan.withOpacity(0.3)),
                    ),
                    child: Image.asset(
                      'assets/images/3a-tech-logo.png',
                      fit: BoxFit.contain,
                      errorBuilder: (_, __, ___) => const Icon(
                        Icons.business_rounded,
                        color: AppColors.cyan,
                        size: 30,
                      ),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Wrap(
                          crossAxisAlignment: WrapCrossAlignment.center,
                          spacing: 6,
                          runSpacing: 4,
                          children: [
                            Text(
                              "الدعم الفني وخدمة العملاء",
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.bold,
                                color: AppColors.getTextPrimary(isDark),
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: AppColors.primary.withOpacity(0.15),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: const Text(
                                "3A Tech",
                                style: TextStyle(
                                  color: AppColors.primaryLight,
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          "تطوير وتشغيل شركة 3A Tech للحلول البرمجية",
                          style: TextStyle(
                            fontSize: 11.5,
                            color: AppColors.getTextSecondary(isDark),
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: Icon(Icons.close_rounded, color: AppColors.getTextMuted(isDark)),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Banner
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.primaryLight.withOpacity(0.25)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.headset_mic_rounded, color: AppColors.primaryLight, size: 24),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        "فريق 3A Tech جاهز لتقديم الدعم الفني، الصيانة الدورية، التدريب والإجابة على أي استفسار طوال أيام الأسبوع.",
                        style: TextStyle(
                          fontSize: 11.5,
                          color: AppColors.getTextPrimary(isDark),
                          height: 1.4,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Number 1
              _buildContactCard(
                isDark,
                title: "الدعم الفني والخدمات (1)",
                number: "01062592321",
                icon: Icons.phone_in_talk_rounded,
                color: AppColors.primaryLight,
              ),
              const SizedBox(height: 10),

              // Number 2
              _buildContactCard(
                isDark,
                title: "خدمة العملاء والمبيعات (2)",
                number: "01063301965",
                icon: Icons.phone_forwarded_rounded,
                color: AppColors.cyan,
              ),
              const SizedBox(height: 10),

              // Number 3
              _buildContactCard(
                isDark,
                title: "المتابعة الفنية والتطوير (3)",
                number: "01095997875",
                icon: Icons.laptop_chromebook_rounded,
                color: Colors.amber,
              ),
              const SizedBox(height: 16),

              // Footer Copyright
              Text(
                "© 2026 3A Tech For Software Developments. All Rights Reserved.",
                style: TextStyle(fontSize: 10, color: AppColors.getTextMuted(isDark)),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildContactCard(
    bool isDark, {
    required String title,
    required String number,
    required IconData icon,
    required Color color,
  }) {
    final isCopied = _copiedNumber == number;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.getBorder(isDark)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 11,
                    color: AppColors.getTextSecondary(isDark),
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  number,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.8,
                    color: AppColors.getTextPrimary(isDark),
                    fontFamily: 'monospace',
                  ),
                ),
              ],
            ),
          ),
          // Action buttons: WhatsApp & Copy only
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              // 1. WhatsApp Button
              InkWell(
                onTap: () => _openWhatsApp(number),
                borderRadius: BorderRadius.circular(10),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: const Color(0xFF25D366).withOpacity(0.15),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: const Color(0xFF25D366).withOpacity(0.35)),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.chat_bubble_outline_rounded, color: Color(0xFF25D366), size: 15),
                      SizedBox(width: 4),
                      Text(
                        "واتساب",
                        style: TextStyle(
                          color: Color(0xFF25D366),
                          fontSize: 11.5,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 6),

              // 2. Copy Button
              InkWell(
                onTap: () => _copyToClipboard(number),
                borderRadius: BorderRadius.circular(10),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: isCopied
                        ? AppColors.success.withOpacity(0.15)
                        : (isDark ? const Color(0xFF334155) : const Color(0xFFF1F5F9)),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: isCopied
                          ? AppColors.success.withOpacity(0.5)
                          : AppColors.getBorder(isDark),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        isCopied ? Icons.check_rounded : Icons.copy_rounded,
                        color: isCopied ? AppColors.success : AppColors.getTextSecondary(isDark),
                        size: 15,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        isCopied ? "تم النسخ" : "نسخ",
                        style: TextStyle(
                          color: isCopied ? AppColors.success : AppColors.getTextSecondary(isDark),
                          fontSize: 11.5,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
