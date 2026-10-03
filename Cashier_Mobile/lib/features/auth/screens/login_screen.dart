import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/widgets/custom_button.dart';
import '../../../core/widgets/custom_text_field.dart';
import '../../../core/widgets/offline_banner.dart';
import '../../../core/widgets/company_support_modal.dart';
import '../providers/auth_provider.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController(text: "admin");
  final _passwordController = TextEditingController(text: "123456");
  bool _obscurePassword = true;

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _submitLogin() async {
    if (!_formKey.currentState!.validate()) return;

    final auth = Provider.of<AuthProvider>(context, listen: false);
    final success = await auth.login(
      _usernameController.text.trim(),
      _passwordController.text.trim(),
    );

    if (!success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: AppColors.syncFailed,
          content: Text(
            auth.errorMessage ?? "فشل تسجيل الدخول",
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
        ),
      );
    }
  }

  void _showServerConfigDialog() {
    final auth = Provider.of<AuthProvider>(context, listen: false);
    final urlController = TextEditingController(text: auth.currentServerUrl);

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: const Row(
          children: [
            Icon(Icons.dns_rounded, color: AppColors.accent),
            SizedBox(width: 8),
            Text("عنوان الخادم السحابي", style: TextStyle(color: AppColors.textPrimary, fontSize: 16)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "أدخل رابط الـ Cloud API أو IP الخادم:",
              style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: urlController,
              style: const TextStyle(color: AppColors.textPrimary),
              decoration: InputDecoration(
                hintText: "http://192.168.1.100:5100",
                hintStyle: const TextStyle(color: AppColors.textMuted),
                filled: true,
                fillColor: AppColors.background,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              "ملاحظة: للمحاكي (Emulator) استخدم: http://10.0.2.2:5100\nوللشبكة المحلية استخدم IP جهاز السيرفر.",
              style: TextStyle(color: AppColors.textMuted, fontSize: 11),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text("إلغاء", style: TextStyle(color: AppColors.textSecondary)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
            onPressed: () async {
              await auth.setServerUrl(urlController.text.trim());
              if (mounted) Navigator.pop(ctx);
            },
            child: const Text("حفظ العنوان", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            const OfflineBanner(),
            Expanded(
              child: Center(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        // App Logo / Store Icon
                        Container(
                          width: 88,
                          height: 88,
                          decoration: BoxDecoration(
                            color: Colors.transparent,
                            borderRadius: BorderRadius.circular(24),
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.primary.withOpacity(0.25),
                                blurRadius: 20,
                                offset: const Offset(0, 8),
                              ),
                            ],
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(24),
                            child: Image.asset(
                              'assets/images/app_logo.png',
                              fit: BoxFit.contain,
                              errorBuilder: (_, __, ___) => Container(
                                decoration: BoxDecoration(
                                  gradient: const LinearGradient(
                                    colors: [AppColors.primary, AppColors.primaryLight],
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                  ),
                                  borderRadius: BorderRadius.circular(24),
                                ),
                                child: const Icon(
                                  Icons.tv_rounded,
                                  size: 46,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 18),

                        const Text(
                          "إلكترو كاشير",
                          style: TextStyle(
                            fontSize: 26,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 6),
                        const Text(
                          "إدارة معارض ومخازن الأجهزة المنزلية والكهربائية",
                          style: TextStyle(
                            fontSize: 13,
                            color: AppColors.textSecondary,
                          ),
                        ),
                        const SizedBox(height: 32),

                        // Login Card
                        Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: AppColors.surface,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: AppColors.border),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              CustomTextField(
                                controller: _usernameController,
                                label: "اسم المستخدم",
                                hint: "أدخل اسم المستخدم",
                                prefixIcon: Icons.person_rounded,
                                validator: (val) => (val == null || val.trim().isEmpty) ? "اسم المستخدم مطلوب" : null,
                              ),
                              const SizedBox(height: 16),
                              CustomTextField(
                                controller: _passwordController,
                                label: "كلمة المرور",
                                hint: "أدخل كلمة المرور",
                                prefixIcon: Icons.lock_rounded,
                                obscureText: _obscurePassword,
                                suffixIcon: IconButton(
                                  icon: Icon(
                                    _obscurePassword ? Icons.visibility_rounded : Icons.visibility_off_rounded,
                                    color: AppColors.textSecondary,
                                    size: 20,
                                  ),
                                  onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                                ),
                                validator: (val) => (val == null || val.trim().isEmpty) ? "كلمة المرور مطلوبة" : null,
                              ),
                              const SizedBox(height: 24),
                              CustomButton(
                                text: "تسجيل الدخول",
                                icon: Icons.login_rounded,
                                isLoading: auth.isLoading,
                                onPressed: _submitLogin,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 20),

                        // Server URL settings button
                        TextButton.icon(
                          onPressed: _showServerConfigDialog,
                          icon: const Icon(Icons.settings_input_component_rounded, size: 16, color: AppColors.accent),
                          label: Text(
                            "ضبط عنوان السيرفر (${auth.currentServerUrl})",
                            style: const TextStyle(color: AppColors.accent, fontSize: 12),
                          ),
                        ),
                        const SizedBox(height: 8),

                        // 3A Tech Branding & Direct Support Footer
                        InkWell(
                          onTap: () => CompanySupportModal.show(context, true),
                          borderRadius: BorderRadius.circular(12),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.06),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: Colors.white.withOpacity(0.12)),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Image.asset(
                                  'assets/images/3a-tech-logo.png',
                                  height: 22,
                                  width: 22,
                                  errorBuilder: (_, __, ___) => const Icon(Icons.business_rounded, size: 20, color: AppColors.cyan),
                                ),
                                const SizedBox(width: 8),
                                const Text(
                                  "تطوير 3A Tech — الدعم الفني وخدمة العملاء 🎧",
                                  style: TextStyle(color: Colors.white70, fontSize: 11, fontWeight: FontWeight.bold),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
