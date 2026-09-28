import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/theme/theme_provider.dart';
import '../../../core/widgets/custom_button.dart';
import '../../../core/widgets/offline_banner.dart';
import '../../../core/widgets/company_support_modal.dart';
import '../../auth/providers/auth_provider.dart';
import '../../products/screens/brands_list_screen.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  void _showServerConfigDialog(BuildContext context, bool isDark) {
    final auth = Provider.of<AuthProvider>(context, listen: false);
    final urlController = TextEditingController(text: auth.currentServerUrl);
    final surface = AppColors.getSurface(isDark);
    final textPrimary = AppColors.getTextPrimary(isDark);
    final textSecondary = AppColors.getTextSecondary(isDark);
    final bg = AppColors.getBackground(isDark);

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: surface,
        title: Row(
          children: [
            const Icon(Icons.dns_rounded, color: AppColors.accent),
            const SizedBox(width: 8),
            Text("تعديل عنوان السيرفر", style: TextStyle(color: textPrimary, fontSize: 16)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "أدخل رابط الـ Cloud API أو IP الخادم:",
              style: TextStyle(color: textSecondary, fontSize: 13),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: urlController,
              style: TextStyle(color: textPrimary),
              decoration: InputDecoration(
                hintText: "http://192.168.1.100:5100",
                hintStyle: const TextStyle(color: AppColors.textMuted),
                filled: true,
                fillColor: bg,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text("إلغاء", style: TextStyle(color: textSecondary)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
            onPressed: () async {
              await auth.setServerUrl(urlController.text.trim());
              if (ctx.mounted) Navigator.pop(ctx);
            },
            child: const Text("حفظ", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _confirmLogout(BuildContext context, bool isDark) {
    final auth = Provider.of<AuthProvider>(context, listen: false);
    final surface = AppColors.getSurface(isDark);
    final textPrimary = AppColors.getTextPrimary(isDark);
    final textSecondary = AppColors.getTextSecondary(isDark);

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            const Icon(Icons.logout_rounded, color: AppColors.syncFailed),
            const SizedBox(width: 8),
            Text("تسجيل الخروج", style: TextStyle(color: textPrimary, fontSize: 16, fontWeight: FontWeight.bold)),
          ],
        ),
        content: Text(
          "هل أنت متأكد من رغبتك في تسجيل الخروج من التطبيق؟",
          style: TextStyle(color: textSecondary, fontSize: 14),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text("إلغاء", style: TextStyle(color: textSecondary)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.syncFailed),
            onPressed: () async {
              Navigator.pop(ctx);
              await auth.logout();
            },
            child: const Text("تسجيل الخروج", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context);
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDark = themeProvider.isDarkMode;
    final user = auth.userData;

    final bg = AppColors.getBackground(isDark);
    final surface = AppColors.getSurface(isDark);
    final border = AppColors.getBorder(isDark);
    final textPrimary = AppColors.getTextPrimary(isDark);
    final textSecondary = AppColors.getTextSecondary(isDark);
    final textMuted = AppColors.getTextMuted(isDark);

    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        backgroundColor: surface,
        elevation: 0,
        title: Text("الإعدادات والحساب", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: textPrimary)),
      ),
      body: Column(
        children: [
          const OfflineBanner(),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Profile Card
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: surface,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: border),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 52,
                          height: 52,
                          decoration: const BoxDecoration(
                            gradient: LinearGradient(
                              colors: [AppColors.primary, AppColors.primaryLight],
                            ),
                            shape: BoxShape.circle,
                          ),
                          child: Center(
                            child: Text(
                              auth.userName.isNotEmpty ? auth.userName[0] : "م",
                              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 22),
                            ),
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                auth.userName,
                                style: TextStyle(color: textPrimary, fontWeight: FontWeight.bold, fontSize: 16),
                              ),
                              const SizedBox(height: 3),
                              Row(
                                children: [
                                  const Icon(Icons.storefront_rounded, color: AppColors.accent, size: 16),
                                  const SizedBox(width: 4),
                                  Expanded(
                                    child: Text(
                                      auth.shopName,
                                      style: const TextStyle(color: AppColors.accent, fontSize: 14, fontWeight: FontWeight.bold),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                              if (auth.shopAddress.isNotEmpty || auth.shopPhone.isNotEmpty) ...[
                                const SizedBox(height: 4),
                                Row(
                                  children: [
                                    if (auth.shopPhone.isNotEmpty) ...[
                                      Icon(Icons.phone_rounded, size: 12, color: textMuted),
                                      const SizedBox(width: 3),
                                      Text(auth.shopPhone, style: TextStyle(color: textMuted, fontSize: 11)),
                                      const SizedBox(width: 8),
                                    ],
                                    if (auth.shopAddress.isNotEmpty) ...[
                                      Icon(Icons.location_on_rounded, size: 12, color: textMuted),
                                      const SizedBox(width: 3),
                                      Expanded(
                                        child: Text(auth.shopAddress, style: TextStyle(color: textMuted, fontSize: 11), maxLines: 1, overflow: TextOverflow.ellipsis),
                                      ),
                                    ],
                                  ],
                                ),
                              ],
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: AppColors.primary.withOpacity(0.12),
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: Text(
                                      "كود الفرع: ${user['tenantCode'] ?? 'SHOP01'}",
                                      style: const TextStyle(color: AppColors.primaryLight, fontSize: 11, fontWeight: FontWeight.w600),
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: AppColors.success.withOpacity(0.12),
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: Text(
                                      "العملة: ${auth.shopCurrency}",
                                      style: const TextStyle(color: AppColors.success, fontSize: 11, fontWeight: FontWeight.w600),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.refresh_rounded, size: 20, color: AppColors.primaryLight),
                          tooltip: "تحديث بيانات المحل من السحابة",
                          onPressed: () async {
                            await auth.fetchStoreSettings();
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text("تم تحديث بيانات المحل من كاشير الديسك توب بنجاح!"),
                                  backgroundColor: AppColors.success,
                                  duration: Duration(seconds: 2),
                                ),
                              );
                            }
                          },
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Brands Management Card (Home Appliances)
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: surface,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: border),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              "الماركات التجارية للأجهزة (Brands)",
                              style: TextStyle(color: textPrimary, fontWeight: FontWeight.bold, fontSize: 14),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                              decoration: BoxDecoration(
                                color: AppColors.accent.withOpacity(0.12),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: const Text(
                                "الأجهزة المنزلية",
                                style: TextStyle(color: AppColors.accent, fontSize: 10, fontWeight: FontWeight.bold),
                              ),
                            ),
                          ],
                        ),
                        const Divider(color: AppColors.border, height: 20),
                        Text(
                          "إدارة الماركات التجارية والتوكيلات المعتمدة، وتحديد بلد المنشأ وأرقام مراكز الصيانة وخدمة العملاء.",
                          style: TextStyle(color: textSecondary, fontSize: 12.5, height: 1.4),
                        ),
                        const SizedBox(height: 12),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.accent.withOpacity(0.12),
                              foregroundColor: AppColors.accent,
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                                side: BorderSide(color: AppColors.accent.withOpacity(0.35)),
                              ),
                              padding: const EdgeInsets.symmetric(vertical: 10),
                            ),
                            icon: const Icon(Icons.verified_rounded, size: 18),
                            label: const Text("فتح إدارة الماركات والتوكيلات", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(builder: (_) => const BrandsListScreen()),
                              );
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Theme Mode Card
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: surface,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: border),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "المظهر والعرض",
                          style: TextStyle(color: textPrimary, fontWeight: FontWeight.bold, fontSize: 14),
                        ),
                        const Divider(color: AppColors.border, height: 20),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                Icon(
                                  isDark ? Icons.dark_mode_rounded : Icons.light_mode_rounded,
                                  color: isDark ? AppColors.accent : Colors.amber.shade700,
                                  size: 22,
                                ),
                                const SizedBox(width: 10),
                                Text(
                                  isDark ? "الوضع الليلي (Dark Mode)" : "الوضع الفاتح (Light Mode)",
                                  style: TextStyle(color: textPrimary, fontSize: 14, fontWeight: FontWeight.w600),
                                ),
                              ],
                            ),
                            Switch(
                              value: isDark,
                              activeColor: AppColors.primary,
                              onChanged: (_) => themeProvider.toggleTheme(),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Server Settings Card
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: surface,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: border),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "إعدادات السيرفر السحابي والمزامنة",
                          style: TextStyle(color: textPrimary, fontWeight: FontWeight.bold, fontSize: 14),
                        ),
                        const Divider(color: AppColors.border, height: 20),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text("عنوان السيرفر (API):", style: TextStyle(color: textSecondary, fontSize: 13)),
                            TextButton.icon(
                              onPressed: () => _showServerConfigDialog(context, isDark),
                              icon: const Icon(Icons.edit, size: 14, color: AppColors.accent),
                              label: const Text("تعديل", style: TextStyle(color: AppColors.accent, fontSize: 12)),
                            ),
                          ],
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                          decoration: BoxDecoration(
                            color: bg,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            auth.currentServerUrl,
                            style: TextStyle(color: textPrimary, fontSize: 13, fontFamily: 'monospace'),
                          ),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          "المزامنة الذكية: يتم حفظ فواتير المشتريات على السحابة وتنزيلها تلقائياً على قاعدة بيانات الكاشير المحلي في المحل وتحديث أرصدة المنتجات والموردين فورياً.",
                          style: TextStyle(color: textMuted, fontSize: 12, height: 1.4),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // 3A Tech Customer Support Card
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: surface,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.cyan.withOpacity(0.35)),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.cyan.withOpacity(0.06),
                          blurRadius: 10,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: AppColors.cyan.withOpacity(0.12),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Image.asset(
                                'assets/images/3a-tech-logo.png',
                                height: 24,
                                width: 24,
                                errorBuilder: (_, __, ___) => const Icon(Icons.headset_mic_rounded, size: 22, color: AppColors.cyan),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    "الدعم الفني وخدمة العملاء (3A Tech)",
                                    style: TextStyle(color: textPrimary, fontWeight: FontWeight.bold, fontSize: 14),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    "فريق الدعم الفني متواجد لمساعدتك هاتفياً وعبر واتساب",
                                    style: TextStyle(color: textMuted, fontSize: 11.5),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const Divider(color: AppColors.border, height: 20),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.cyan.withOpacity(0.15),
                              foregroundColor: AppColors.cyan,
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                                side: BorderSide(color: AppColors.cyan.withOpacity(0.4)),
                              ),
                              padding: const EdgeInsets.symmetric(vertical: 12),
                            ),
                            icon: const Icon(Icons.support_agent_rounded, size: 20),
                            label: const Text(
                              "التواصل مع الدعم الفني وخدمة العملاء",
                              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                            ),
                            onPressed: () => CompanySupportModal.show(context, isDark),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Logout Button
                  CustomButton(
                    text: "تسجيل الخروج من الحساب",
                    icon: Icons.logout_rounded,
                    backgroundColor: AppColors.syncFailed,
                    isOutlined: true,
                    onPressed: () => _confirmLogout(context, isDark),
                  ),
                  const SizedBox(height: 20),

                  Center(
                    child: Text(
                      "نظام الكاشير والمشتريات السحابي • الإصدار 2.0.0",
                      style: TextStyle(color: textMuted, fontSize: 11),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
