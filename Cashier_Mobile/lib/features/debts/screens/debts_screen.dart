import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/theme/theme_provider.dart';
import '../../../core/widgets/offline_banner.dart';
import '../models/debt_model.dart';
import '../providers/debts_provider.dart';
import 'entity_debts_detail_screen.dart';

class DebtsScreen extends StatefulWidget {
  const DebtsScreen({super.key});

  @override
  State<DebtsScreen> createState() => _DebtsScreenState();
}

class _DebtsScreenState extends State<DebtsScreen> {
  final TextEditingController _searchCtrl = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<DebtsProvider>(context, listen: false).fetchDebts();
    });
  }

  void _onScroll() {
    if (_scrollController.hasClients &&
        _scrollController.position.pixels >= _scrollController.position.maxScrollExtent - 250) {
      final prov = Provider.of<DebtsProvider>(context, listen: false);
      if (prov.hasMore && !prov.isLoadingMore && !prov.isLoading) {
        prov.fetchMoreDebts();
      }
    }
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Provider.of<ThemeProvider>(context).isDarkMode;
    final prov = Provider.of<DebtsProvider>(context);
    final currencyFormatter = NumberFormat("#,##0.00", "en_US");

    return Scaffold(
      backgroundColor: AppColors.getBackground(isDark),
      appBar: AppBar(
        backgroundColor: AppColors.getSurface(isDark),
        elevation: 0,
        title: Text(
          "إدارة الديون والمستحقات",
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: AppColors.getTextPrimary(isDark)),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.refresh_rounded, color: AppColors.getTextPrimary(isDark)),
            onPressed: () => prov.fetchDebts(search: _searchCtrl.text),
          ),
        ],
      ),
      body: Column(
        children: [
          const OfflineBanner(),

          // KPI Summary Cards
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(
                  child: _buildSummaryCard(
                    isDark,
                    title: "ديون العملاء (لنا)",
                    amount: prov.totalCustomerDebts,
                    icon: Icons.call_received_rounded,
                    color: AppColors.success,
                    currencyFormatter: currencyFormatter,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _buildSummaryCard(
                    isDark,
                    title: "مستحقات الموردين (علينا)",
                    amount: prov.totalSupplierDebts,
                    icon: Icons.call_made_rounded,
                    color: AppColors.danger,
                    currencyFormatter: currencyFormatter,
                  ),
                ),
              ],
            ),
          ),

          // Tabs Switcher
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: AppColors.getSurface(isDark),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.getBorder(isDark)),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: _buildTabButton(
                      isDark,
                      title: "ديون العملاء",
                      icon: Icons.people_alt_rounded,
                      isActive: prov.activeTab == 'Customer',
                      onTap: () => prov.setActiveTab('Customer'),
                    ),
                  ),
                  Expanded(
                    child: _buildTabButton(
                      isDark,
                      title: "مستحقات الموردين",
                      icon: Icons.local_shipping_rounded,
                      isActive: prov.activeTab == 'Supplier',
                      onTap: () => prov.setActiveTab('Supplier'),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Search Field
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: Container(
              decoration: BoxDecoration(
                color: AppColors.getSurface(isDark),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.getBorder(isDark)),
              ),
              child: TextField(
                controller: _searchCtrl,
                style: TextStyle(color: AppColors.getTextPrimary(isDark), fontSize: 13),
                decoration: InputDecoration(
                  hintText: "بحث باسم العميل أو المورد أو رقم الهاتف...",
                  hintStyle: TextStyle(color: AppColors.getTextMuted(isDark), fontSize: 13),
                  prefixIcon: const Icon(Icons.search_rounded, color: AppColors.primaryLight),
                  suffixIcon: _searchCtrl.text.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear_rounded, size: 18),
                          onPressed: () {
                            _searchCtrl.clear();
                            prov.fetchDebts();
                          },
                        )
                      : null,
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(vertical: 12),
                ),
                onSubmitted: (val) => prov.fetchDebts(search: val),
              ),
            ),
          ),

          // Debts List
          Expanded(
            child: prov.isLoading
                ? const Center(child: CircularProgressIndicator(color: AppColors.primaryLight))
                : prov.debts.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.check_circle_outline_rounded, size: 54, color: AppColors.success.withOpacity(0.7)),
                            const SizedBox(height: 12),
                            Text(
                              prov.activeTab == 'Customer'
                                  ? "لا توجد أي ديون متأخرة على العملاء حالياً 🎉"
                                  : "لا توجد مستحقات متبقية للموردين حالياً 🎉",
                              style: TextStyle(color: AppColors.getTextMuted(isDark), fontSize: 14),
                            ),
                          ],
                        ),
                      )
                    : Builder(
                        builder: (context) {
                          // Group debts by entityName
                          final Map<String, List<DebtItemModel>> groups = {};
                          for (final d in prov.debts) {
                            final key = d.entityName.trim().isEmpty ? "غير محدد" : d.entityName.trim();
                            groups.putIfAbsent(key, () => []).add(d);
                          }
                          final groupedList = groups.entries.map((e) {
                            final first = e.value.first;
                            return GroupedDebtEntity(
                              entityName: e.key,
                              phone: first.phone,
                              type: first.type,
                              invoices: e.value,
                            );
                          }).toList();

                          return RefreshIndicator(
                            onRefresh: () => prov.fetchDebts(search: _searchCtrl.text),
                            child: ListView.separated(
                              controller: _scrollController,
                              physics: const AlwaysScrollableScrollPhysics(),
                              padding: const EdgeInsets.all(16),
                              itemCount: groupedList.length + (prov.isLoadingMore ? 1 : 0),
                              separatorBuilder: (_, __) => const SizedBox(height: 10),
                              itemBuilder: (ctx, idx) {
                                if (idx == groupedList.length) {
                                  return const Padding(
                                    padding: EdgeInsets.symmetric(vertical: 16),
                                    child: Center(
                                      child: SizedBox(
                                        width: 24,
                                        height: 24,
                                        child: CircularProgressIndicator(strokeWidth: 2.5, color: AppColors.primaryLight),
                                      ),
                                    ),
                                  );
                                }
                                final item = groupedList[idx];
                                return _buildGroupedDebtCard(context, isDark, item, currencyFormatter);
                              },
                            ),
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryCard(bool isDark, {required String title, required double amount, required IconData icon, required Color color, required NumberFormat currencyFormatter}) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.getSurface(isDark),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.getBorder(isDark)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 16),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(fontSize: 11, color: AppColors.getTextMuted(isDark)),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              "${currencyFormatter.format(amount)} ج.م",
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: color),
              maxLines: 1,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabButton(bool isDark, {required String title, required IconData icon, required bool isActive, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color: isActive ? AppColors.primary : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
        ),
        alignment: Alignment.center,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 16, color: isActive ? Colors.white : AppColors.getTextMuted(isDark)),
            const SizedBox(width: 6),
            Text(
              title,
              style: TextStyle(
                color: isActive ? Colors.white : AppColors.getTextSecondary(isDark),
                fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
                fontSize: 13,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGroupedDebtCard(
    BuildContext context,
    bool isDark,
    GroupedDebtEntity entity,
    NumberFormat currencyFormatter,
  ) {
    final isCustomer = entity.type == 'Customer';
    final count = entity.invoicesCount;

    return InkWell(
      borderRadius: BorderRadius.circular(14),
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => EntityDebtsDetailScreen(entity: entity),
          ),
        ).then((_) {
          if (!mounted) return;
          Provider.of<DebtsProvider>(context, listen: false).fetchDebts(search: _searchCtrl.text);
        });
      },
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.getSurface(isDark),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.getBorder(isDark)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 20,
                        backgroundColor: (isCustomer ? AppColors.success : AppColors.primary).withOpacity(0.12),
                        child: Icon(
                          isCustomer ? Icons.person_rounded : Icons.store_rounded,
                          size: 22,
                          color: isCustomer ? AppColors.success : AppColors.primaryLight,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              entity.entityName,
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 15,
                                color: AppColors.getTextPrimary(isDark),
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            if (entity.phone != null && entity.phone!.isNotEmpty) ...[
                              const SizedBox(height: 2),
                              Text(
                                entity.phone!,
                                style: TextStyle(
                                  fontSize: 12,
                                  color: AppColors.getTextMuted(isDark),
                                  fontFamily: 'monospace',
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Flexible(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: (isCustomer ? AppColors.success : AppColors.danger).withOpacity(0.12),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          isCustomer ? "المحصلة المطلوبة" : "المستحق للمورد",
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            color: isCustomer ? AppColors.success : AppColors.danger,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          "${currencyFormatter.format(entity.totalRemaining)} ج.م",
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: isCustomer ? AppColors.success : AppColors.danger,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            const Divider(height: 18),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Flexible(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: AppColors.primaryLight.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.receipt_long_rounded, size: 13, color: AppColors.primaryLight),
                        const SizedBox(width: 4),
                        Flexible(
                          child: Text(
                            count == 1 ? "فاتورة واحدة معلقة" : "$count فواتير معلقة",
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: AppColors.primaryLight,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      "عرض الفواتير والسداد",
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: isCustomer ? AppColors.success : AppColors.primaryLight,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Icon(
                      Icons.arrow_forward_ios_rounded,
                      size: 12,
                      color: isCustomer ? AppColors.success : AppColors.primaryLight,
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
