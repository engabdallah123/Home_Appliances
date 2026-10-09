import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/widgets/custom_button.dart';
import '../../../core/widgets/custom_text_field.dart';
import '../../../core/widgets/offline_banner.dart';
import '../../../core/widgets/company_support_modal.dart';
import '../providers/auth_provider.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;

  @override
  void dispose() {
    _nameController.dispose();
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _submitRegister() async {
    if (!_formKey.currentState!.validate()) return;

    final auth = Provider.of<AuthProvider>(context, listen: false);
    final username = _usernameController.text.trim();

    final success = await auth.register(
      fullName: _nameController.text.trim(),
      username: username,
      password: _passwordController.text.trim(),
    );

    if (mounted) {
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            backgroundColor: AppColors.success,
            content: Text(
              "تم إنشاء الحساب بنجاح! يرجى تسجيل الدخول باسم المستخدم وكلمة المرور.",
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
        );
        Navigator.pop(context, username);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: AppColors.syncFailed,
            content: Text(
              auth.errorMessage ?? "فشل إنشاء الحساب، يرجى المحاولة مرة أخرى.",
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
        );
      }
    }
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
                          width: 80,
                          height: 80,
                          decoration: BoxDecoration(
                            color: Colors.transparent,
                            borderRadius: BorderRadius.circular(22),
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.primary.withOpacity(0.25),
                                blurRadius: 20,
                                offset: const Offset(0, 8),
                              ),
                            ],
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(22),
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
                                  borderRadius: BorderRadius.circular(22),
                                ),
                                child: const Icon(
                                  Icons.person_add_alt_1_rounded,
                                  size: 42,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),

                        const Text(
                          "إنشاء حساب جديد",
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 6),
                        const Text(
                          "أدخل بياناتك لإنشاء حساب كاشير / مندوب مبيعات",
                          style: TextStyle(
                            fontSize: 13,
                            color: AppColors.textSecondary,
                          ),
                        ),
                        const SizedBox(height: 28),

                        // Register Card
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
                              // 1. الاسم (Full Name)
                              CustomTextField(
                                controller: _nameController,
                                label: "الاسم (الاسم الكامل)",
                                hint: "أدخل اسمك كما سيظهر في الفواتير",
                                prefixIcon: Icons.badge_rounded,
                                validator: (val) {
                                  if (val == null || val.trim().isEmpty) {
                                    return "الاسم مطلوب";
                                  }
                                  if (val.trim().length < 2) {
                                    return "الاسم يجب ألا يقل عن حرفين";
                                  }
                                  return null;
                                },
                              ),
                              const SizedBox(height: 16),

                              // 2. username
                              CustomTextField(
                                controller: _usernameController,
                                label: "اسم المستخدم (Username)",
                                hint: "أدخل اسم المستخدم لتسجيل الدخول",
                                prefixIcon: Icons.person_rounded,
                                validator: (val) {
                                  if (val == null || val.trim().isEmpty) {
                                    return "اسم المستخدم مطلوب";
                                  }
                                  if (val.trim().length < 3) {
                                    return "اسم المستخدم يجب ألا يقل عن 3 أحرف";
                                  }
                                  if (val.trim().contains(" ")) {
                                    return "اسم المستخدم يجب ألا يحتوي على مسافات";
                                  }
                                  return null;
                                },
                              ),
                              const SizedBox(height: 16),

                              // 3. password
                              CustomTextField(
                                controller: _passwordController,
                                label: "كلمة المرور (Password)",
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
                                validator: (val) {
                                  if (val == null || val.trim().isEmpty) {
                                    return "كلمة المرور مطلوبة";
                                  }
                                  if (val.trim().length < 4) {
                                    return "كلمة المرور يجب ألا تقل عن 4 خانات";
                                  }
                                  return null;
                                },
                              ),
                              const SizedBox(height: 24),

                              // Submit Button
                              CustomButton(
                                text: "إنشاء الحساب",
                                icon: Icons.how_to_reg_rounded,
                                isLoading: auth.isLoading,
                                onPressed: _submitRegister,
                              ),

                              const SizedBox(height: 14),

                              // Back to Login Link
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Text(
                                    "لديك حساب بالفعل؟",
                                    style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
                                  ),
                                  TextButton(
                                    onPressed: () => Navigator.pop(context),
                                    child: const Text(
                                      "تسجيل الدخول",
                                      style: TextStyle(
                                        color: AppColors.primaryLight,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 13,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 20),

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
