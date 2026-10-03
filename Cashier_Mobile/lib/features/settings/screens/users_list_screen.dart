import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/api_endpoints.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/network/api_client.dart';
import '../../../core/theme/theme_provider.dart';
import '../../../core/widgets/offline_banner.dart';

class UsersListScreen extends StatefulWidget {
  const UsersListScreen({super.key});

  @override
  State<UsersListScreen> createState() => _UsersListScreenState();
}

class _UsersListScreenState extends State<UsersListScreen> {
  final ApiClient _apiClient = ApiClient();
  final TextEditingController _searchCtrl = TextEditingController();

  bool _isLoading = false;
  String? _errorMessage;
  List<dynamic> _users = [];

  @override
  void initState() {
    super.initState();
    _fetchUsers();
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _fetchUsers() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final res = await _apiClient.get(ApiEndpoints.users);
      List<dynamic> loaded = [];
      if (res != null && res is List) {
        loaded = res;
      }
      setState(() {
        _users = loaded;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
        _isLoading = false;
      });
    }
  }

  List<dynamic> get _filteredUsers {
    final query = _searchCtrl.text.trim().toLowerCase();
    if (query.isEmpty) return _users;
    return _users.where((u) {
      final name = (u['fullName'] ?? '').toString().toLowerCase();
      final username = (u['username'] ?? '').toString().toLowerCase();
      final role = (u['role'] ?? '').toString().toLowerCase();
      return name.contains(query) || username.contains(query) || role.contains(query);
    }).toList();
  }

  String _translateRole(String? role) {
    switch (role?.toLowerCase()) {
      case 'admin':
      case 'administrator':
        return 'مدير النظام 👑';
      case 'manager':
        return 'مشرف فرع 🛡️';
      case 'cashier':
        return 'كاشير مبيعات 💳';
      case 'sales':
      case 'showroom':
        return 'مندوب صالة 📱';
      default:
        return role ?? 'مستخدم';
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Provider.of<ThemeProvider>(context).isDarkMode;
    final filtered = _filteredUsers;

    return Scaffold(
      backgroundColor: AppColors.getBackground(isDark),
      appBar: AppBar(
        backgroundColor: AppColors.getSurface(isDark),
        elevation: 0,
        title: Text(
          "المستخدمين وصلاحيات الموظفين",
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppColors.getTextPrimary(isDark)),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.refresh_rounded, color: AppColors.getTextPrimary(isDark)),
            tooltip: "تحديث",
            onPressed: _fetchUsers,
          ),
        ],
      ),
      body: Column(
        children: [
          const OfflineBanner(),

          // Search Field
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: Container(
              decoration: BoxDecoration(
                color: AppColors.getSurface(isDark),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppColors.getBorder(isDark)),
              ),
              child: TextField(
                controller: _searchCtrl,
                style: TextStyle(color: AppColors.getTextPrimary(isDark), fontSize: 14),
                decoration: InputDecoration(
                  hintText: "بحث بالاسم، اسم المستخدم، أو الصلاحية...",
                  hintStyle: TextStyle(color: AppColors.getTextMuted(isDark), fontSize: 13),
                  prefixIcon: const Icon(Icons.search_rounded, color: AppColors.primaryLight),
                  suffixIcon: _searchCtrl.text.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear_rounded, size: 18),
                          onPressed: () {
                            _searchCtrl.clear();
                            setState(() {});
                          },
                        )
                      : null,
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(vertical: 14),
                ),
                onChanged: (_) => setState(() {}),
              ),
            ),
          ),

          // Total count banner
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: Row(
              children: [
                const Icon(Icons.badge_rounded, size: 16, color: AppColors.primaryLight),
                const SizedBox(width: 6),
                Text(
                  "إجمالي فريق العمل المسجل: ${_users.length} موظف",
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.getTextSecondary(isDark)),
                ),
              ],
            ),
          ),

          const SizedBox(height: 8),

          // Users List
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator(color: AppColors.primaryLight))
                : _errorMessage != null
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.error_outline_rounded, color: AppColors.danger, size: 48),
                            const SizedBox(height: 8),
                            Text("خطأ: $_errorMessage", style: TextStyle(color: AppColors.getTextMuted(isDark))),
                            const SizedBox(height: 12),
                            ElevatedButton(onPressed: _fetchUsers, child: const Text("إعادة المحاولة")),
                          ],
                        ),
                      )
                    : filtered.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.people_outline_rounded, size: 56, color: AppColors.getTextMuted(isDark)),
                                const SizedBox(height: 12),
                                Text("لا يوجد مستخدمين مطابقين", style: TextStyle(color: AppColors.getTextMuted(isDark), fontSize: 14)),
                              ],
                            ),
                          )
                        : RefreshIndicator(
                            onRefresh: _fetchUsers,
                            child: ListView.separated(
                              padding: const EdgeInsets.fromLTRB(16, 4, 16, 40),
                              itemCount: filtered.length,
                              separatorBuilder: (_, __) => const SizedBox(height: 10),
                              itemBuilder: (ctx, idx) {
                                final u = filtered[idx];
                                final fullName = u['fullName'] ?? 'موظف';
                                final username = u['username'] ?? '';
                                final role = u['role'] ?? 'Cashier';
                                final phone = u['phone']?.toString();
                                final isActive = u['isActive'] ?? true;

                                return Container(
                                  padding: const EdgeInsets.all(14),
                                  decoration: BoxDecoration(
                                    color: AppColors.getSurface(isDark),
                                    borderRadius: BorderRadius.circular(14),
                                    border: Border.all(color: AppColors.getBorder(isDark)),
                                  ),
                                  child: Row(
                                    children: [
                                      CircleAvatar(
                                        radius: 22,
                                        backgroundColor: AppColors.primary.withOpacity(0.15),
                                        child: Text(
                                          fullName.isNotEmpty ? fullName[0] : 'U',
                                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppColors.primaryLight),
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              fullName,
                                              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppColors.getTextPrimary(isDark)),
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                            const SizedBox(height: 3),
                                            Row(
                                              children: [
                                                Icon(Icons.alternate_email_rounded, size: 12, color: AppColors.getTextMuted(isDark)),
                                                const SizedBox(width: 3),
                                                Expanded(
                                                  child: Text(
                                                    username,
                                                    style: TextStyle(fontSize: 11.5, color: AppColors.getTextMuted(isDark), fontFamily: 'monospace'),
                                                    overflow: TextOverflow.ellipsis,
                                                  ),
                                                ),
                                              ],
                                            ),
                                            if (phone != null && phone.isNotEmpty) ...[
                                              const SizedBox(height: 2),
                                              Row(
                                                children: [
                                                  Icon(Icons.phone_outlined, size: 12, color: AppColors.cyan),
                                                  const SizedBox(width: 3),
                                                  Text(
                                                    phone,
                                                    style: TextStyle(fontSize: 11, color: AppColors.getTextMuted(isDark)),
                                                  ),
                                                ],
                                              ),
                                            ],
                                          ],
                                        ),
                                      ),
                                      Column(
                                        crossAxisAlignment: CrossAxisAlignment.end,
                                        children: [
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                            decoration: BoxDecoration(
                                              color: AppColors.primary.withOpacity(0.12),
                                              borderRadius: BorderRadius.circular(6),
                                            ),
                                            child: Text(
                                              _translateRole(role),
                                              style: const TextStyle(fontSize: 10.5, fontWeight: FontWeight.bold, color: AppColors.primaryLight),
                                            ),
                                          ),
                                          const SizedBox(height: 4),
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                            decoration: BoxDecoration(
                                              color: isActive ? AppColors.success.withOpacity(0.12) : AppColors.danger.withOpacity(0.12),
                                              borderRadius: BorderRadius.circular(4),
                                            ),
                                            child: Text(
                                              isActive ? "نشط" : "معطل",
                                              style: TextStyle(fontSize: 9.5, fontWeight: FontWeight.bold, color: isActive ? AppColors.success : AppColors.danger),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                );
                              },
                            ),
                          ),
          ),
        ],
      ),
    );
  }
}
