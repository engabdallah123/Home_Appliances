import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/api_endpoints.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/network/api_client.dart';
import '../../../core/theme/theme_provider.dart';
import '../../../core/widgets/offline_banner.dart';
import '../models/category_model.dart';
import '../providers/products_provider.dart';

class CategoriesListScreen extends StatefulWidget {
  const CategoriesListScreen({super.key});

  @override
  State<CategoriesListScreen> createState() => _CategoriesListScreenState();
}

class _CategoriesListScreenState extends State<CategoriesListScreen> {
  final ApiClient _apiClient = ApiClient();
  final TextEditingController _searchCtrl = TextEditingController();

  bool _isLoading = false;
  String? _errorMessage;
  List<CategoryModel> _categories = [];

  @override
  void initState() {
    super.initState();
    _fetchCategories();
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _fetchCategories() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final res = await _apiClient.get(ApiEndpoints.categories);
      List<CategoryModel> loaded = [];
      if (res != null && res is List) {
        loaded = res.map((i) => CategoryModel.fromJson(i)).toList();
      }
      setState(() {
        _categories = loaded;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
        _isLoading = false;
      });
    }
  }

  List<CategoryModel> get _filteredCategories {
    final query = _searchCtrl.text.trim().toLowerCase();
    if (query.isEmpty) return _categories;
    return _categories.where((c) {
      return c.nameAr.toLowerCase().contains(query) || (c.nameEn != null && c.nameEn!.toLowerCase().contains(query));
    }).toList();
  }

  void _openAddCategoryModal(bool isDark) {
    final nameArCtrl = TextEditingController();
    final nameEnCtrl = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.getSurface(isDark),
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 16,
            left: 16,
            right: 16,
            top: 16,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(color: AppColors.primary.withOpacity(0.12), shape: BoxShape.circle),
                    child: const Icon(Icons.category_rounded, color: AppColors.primaryLight, size: 22),
                  ),
                  const SizedBox(width: 10),
                  Text("إضافة قسم / تصنيف جديد", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppColors.getTextPrimary(isDark))),
                ],
              ),
              const Divider(height: 24),
              Text("اسم القسم بالعربية *", style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.getTextSecondary(isDark))),
              const SizedBox(height: 6),
              TextField(
                controller: nameArCtrl,
                style: TextStyle(color: AppColors.getTextPrimary(isDark), fontSize: 14),
                decoration: InputDecoration(
                  hintText: "مثال: ثلاجات وديب فريزر، غسالات، شاشات...",
                  prefixIcon: const Icon(Icons.folder_outlined, color: AppColors.primaryLight),
                  filled: true,
                  fillColor: AppColors.getInputBackground(isDark),
                ),
              ),
              const SizedBox(height: 12),
              Text("الاسم بالإنجليزية (اختياري)", style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.getTextSecondary(isDark))),
              const SizedBox(height: 6),
              TextField(
                controller: nameEnCtrl,
                style: TextStyle(color: AppColors.getTextPrimary(isDark), fontSize: 14),
                decoration: InputDecoration(
                  hintText: "Example: Refrigerators, Washers...",
                  prefixIcon: const Icon(Icons.language_rounded, color: AppColors.cyan),
                  filled: true,
                  fillColor: AppColors.getInputBackground(isDark),
                ),
              ),
              const SizedBox(height: 18),
              SizedBox(
                width: double.infinity,
                height: 46,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  icon: const Icon(Icons.add_circle_outline_rounded, color: Colors.white),
                  label: const Text("حفظ القسم ومزامنته مع الكاشير", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
                  onPressed: () async {
                    final nameAr = nameArCtrl.text.trim();
                    if (nameAr.isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("يرجى إدخال اسم القسم بالعربية.")));
                      return;
                    }
                    Navigator.pop(ctx);
                    await _submitAddCategory(nameAr, nameEnCtrl.text.trim());
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _submitAddCategory(String nameAr, String nameEn) async {
    setState(() => _isLoading = true);
    try {
      await _apiClient.post(
        ApiEndpoints.categories,
        body: {
          'nameAr': nameAr,
          'nameEn': nameEn.isNotEmpty ? nameEn : null,
        },
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("تمت إضافة قسم '$nameAr' بنجاح ومزامنته."),
            backgroundColor: AppColors.success,
          ),
        );
      }
      await _fetchCategories();
      // Also update products provider
      if (mounted) {
        Provider.of<ProductsProvider>(context, listen: false).fetchCategories();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("فشل إضافة القسم: $e"), backgroundColor: AppColors.danger),
        );
      }
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Provider.of<ThemeProvider>(context).isDarkMode;
    final filtered = _filteredCategories;

    return Scaffold(
      backgroundColor: AppColors.getBackground(isDark),
      appBar: AppBar(
        backgroundColor: AppColors.getSurface(isDark),
        elevation: 0,
        title: Text(
          "أقسام وتصنيفات الأجهزة",
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppColors.getTextPrimary(isDark)),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.refresh_rounded, color: AppColors.getTextPrimary(isDark)),
            tooltip: "تحديث",
            onPressed: _fetchCategories,
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: AppColors.primary,
        icon: const Icon(Icons.add_rounded, color: Colors.white),
        label: const Text("إضافة قسم جديد", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        onPressed: () => _openAddCategoryModal(isDark),
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
                  hintText: "بحث عن قسم...",
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

          // Content
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
                            ElevatedButton(onPressed: _fetchCategories, child: const Text("إعادة المحاولة")),
                          ],
                        ),
                      )
                    : filtered.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.folder_open_rounded, size: 56, color: AppColors.getTextMuted(isDark)),
                                const SizedBox(height: 12),
                                Text("لا توجد أقسام مسجلة", style: TextStyle(color: AppColors.getTextMuted(isDark), fontSize: 14)),
                              ],
                            ),
                          )
                        : RefreshIndicator(
                            onRefresh: _fetchCategories,
                            child: ListView.separated(
                              padding: const EdgeInsets.fromLTRB(16, 8, 16, 80),
                              itemCount: filtered.length,
                              separatorBuilder: (_, __) => const SizedBox(height: 10),
                              itemBuilder: (ctx, idx) {
                                final c = filtered[idx];
                                return Container(
                                  padding: const EdgeInsets.all(14),
                                  decoration: BoxDecoration(
                                    color: AppColors.getSurface(isDark),
                                    borderRadius: BorderRadius.circular(14),
                                    border: Border.all(color: AppColors.getBorder(isDark)),
                                  ),
                                  child: Row(
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.all(10),
                                        decoration: BoxDecoration(
                                          color: AppColors.primary.withOpacity(0.12),
                                          shape: BoxShape.circle,
                                        ),
                                        child: const Icon(Icons.category_rounded, color: AppColors.primaryLight, size: 20),
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              c.nameAr,
                                              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppColors.getTextPrimary(isDark)),
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                            if (c.nameEn != null && c.nameEn!.isNotEmpty)
                                              Text(
                                                c.nameEn!,
                                                style: TextStyle(fontSize: 11.5, color: AppColors.getTextMuted(isDark)),
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                          ],
                                        ),
                                      ),
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                        decoration: BoxDecoration(
                                          color: c.isActive ? AppColors.success.withOpacity(0.15) : AppColors.danger.withOpacity(0.15),
                                          borderRadius: BorderRadius.circular(6),
                                        ),
                                        child: Text(
                                          c.isActive ? "نشط ✓" : "معطل",
                                          style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: c.isActive ? AppColors.success : AppColors.danger),
                                        ),
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
