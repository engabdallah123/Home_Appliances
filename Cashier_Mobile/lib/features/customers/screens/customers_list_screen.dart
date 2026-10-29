import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/services/whatsapp_helper.dart';
import '../../debts/models/debt_model.dart';
import '../../sales/models/sale_model.dart';
import '../models/customer_model.dart';
import '../providers/customers_provider.dart';

class CustomersListScreen extends StatefulWidget {
  const CustomersListScreen({super.key});

  @override
  State<CustomersListScreen> createState() => _CustomersListScreenState();
}

class _CustomersListScreenState extends State<CustomersListScreen> {
  final TextEditingController _searchCtrl = TextEditingController();
  String _filterType = "all"; // all, debt, clear
  final currencyFmt = NumberFormat("#,##0.00", "ar_EG");
  final dateFmt = DateFormat("yyyy/MM/dd");

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<CustomersProvider>(context, listen: false).fetchCustomers();
    });
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  void _onSearch(String val) {
    Provider.of<CustomersProvider>(context, listen: false).fetchCustomers(search: val);
  }

  List<CustomerModel> _getFilteredCustomers(List<CustomerModel> list) {
    if (_filterType == "debt") {
      return list.where((c) => c.hasDebt || c.totalDebt > 0).toList();
    } else if (_filterType == "clear") {
      return list.where((c) => !c.hasDebt && c.totalDebt <= 0).toList();
    }
    return list;
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final customersProv = Provider.of<CustomersProvider>(context);
    final filtered = _getFilteredCustomers(customersProv.customers);

    return Scaffold(
      backgroundColor: AppColors.getBackground(isDark),
      appBar: AppBar(
        title: const Text(
          "دليل وسجلات العملاء",
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            tooltip: "تحديث",
            onPressed: () => customersProv.fetchCustomers(refresh: true, search: _searchCtrl.text),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: const Color(0xFF4F46E5),
        foregroundColor: Colors.white,
        icon: const Icon(Icons.person_add_rounded),
        label: const Text("إضافة عميل جديد", style: TextStyle(fontWeight: FontWeight.bold)),
        onPressed: () => _showAddCustomerDialog(context, customersProv, isDark),
      ),
      body: Column(
        children: [
          // 1. KPI Stats Summary Bar (Wrap-safe & responsive)
          _buildStatsSummary(context, customersProv, isDark),

          // 2. Search & Filter Bar
          _buildSearchBar(context, isDark),

          // 3. Customers List
          Expanded(
            child: RefreshIndicator(
              onRefresh: () => customersProv.fetchCustomers(refresh: true, search: _searchCtrl.text),
              child: customersProv.isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : customersProv.errorMessage != null
                      ? Center(
                          child: Padding(
                            padding: const EdgeInsets.all(20),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(Icons.error_outline_rounded, color: AppColors.danger, size: 48),
                                const SizedBox(height: 12),
                                Text(
                                  customersProv.errorMessage!,
                                  style: TextStyle(color: AppColors.getTextSecondary(isDark)),
                                  textAlign: TextAlign.center,
                                ),
                                const SizedBox(height: 16),
                                ElevatedButton.icon(
                                  onPressed: () => customersProv.fetchCustomers(refresh: true),
                                  icon: const Icon(Icons.refresh),
                                  label: const Text("إعادة المحاولة"),
                                ),
                              ],
                            ),
                          ),
                        )
                      : filtered.isEmpty
                          ? Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.person_search_rounded, size: 64, color: AppColors.getTextMuted(isDark).withOpacity(0.5)),
                                  const SizedBox(height: 12),
                                  Text(
                                    "لا يوجد عملاء مطابقين للبحث",
                                    style: TextStyle(color: AppColors.getTextSecondary(isDark), fontSize: 14),
                                  ),
                                ],
                              ),
                            )
                          : ListView.builder(
                              padding: const EdgeInsets.fromLTRB(14, 4, 14, 20),
                              itemCount: filtered.length,
                              itemBuilder: (ctx, idx) => _buildCustomerCard(ctx, filtered[idx], isDark),
                            ),
            ),
          ),
        ],
      ),
    );
  }

  // 1. Top Summary Cards (Safe Row with Expanded to prevent right overflow)
  Widget _buildStatsSummary(BuildContext context, CustomersProvider prov, bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      margin: const EdgeInsets.fromLTRB(14, 10, 14, 6),
      decoration: BoxDecoration(
        color: AppColors.getSurface(isDark),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.getBorder(isDark)),
      ),
      child: Row(
        children: [
          // Total Customers
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  "إجمالي العملاء",
                  style: TextStyle(fontSize: 10.5, color: AppColors.getTextMuted(isDark)),
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  "${prov.customers.length}",
                  style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppColors.primaryLight),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          Container(width: 1, height: 28, color: AppColors.getBorder(isDark)),
          const SizedBox(width: 10),
          // Outstanding Debts
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  "ديون العملاء (لنا)",
                  style: TextStyle(fontSize: 10.5, color: AppColors.getTextMuted(isDark)),
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  currencyFmt.format(prov.totalDebts),
                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.danger),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          Container(width: 1, height: 28, color: AppColors.getBorder(isDark)),
          const SizedBox(width: 10),
          // Total Purchases
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  "إجمالي المشتريات",
                  style: TextStyle(fontSize: 10.5, color: AppColors.getTextMuted(isDark)),
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  currencyFmt.format(prov.totalSpent),
                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.success),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // 2. Search & Filter Bar (Overflow-safe)
  Widget _buildSearchBar(BuildContext context, bool isDark) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: _searchCtrl,
            onChanged: _onSearch,
            decoration: InputDecoration(
              hintText: "بحث باسم العميل أو رقم الهاتف...",
              hintStyle: TextStyle(fontSize: 12.5, color: AppColors.getTextMuted(isDark)),
              prefixIcon: const Icon(Icons.search_rounded, size: 20),
              suffixIcon: _searchCtrl.text.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear, size: 18),
                      onPressed: () {
                        _searchCtrl.clear();
                        _onSearch('');
                      },
                    )
                  : null,
              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              filled: true,
              fillColor: AppColors.getSurface(isDark),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: AppColors.getBorder(isDark)),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: AppColors.getBorder(isDark)),
              ),
            ),
          ),
          const SizedBox(height: 8),
          // Filter Chips Row
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _buildFilterChip("all", "الكل", isDark),
                const SizedBox(width: 6),
                _buildFilterChip("debt", "عليهم ديون", isDark, icon: Icons.handshake_rounded),
                const SizedBox(width: 6),
                _buildFilterChip("clear", "خالص الحساب", isDark, icon: Icons.check_circle_outline_rounded),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String type, String label, bool isDark, {IconData? icon}) {
    final isSelected = _filterType == type;
    return InkWell(
      onTap: () => setState(() => _filterType = type),
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.primary.withOpacity(0.2)
              : AppColors.getSurface(isDark),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? AppColors.primaryLight : AppColors.getBorder(isDark),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(icon, size: 14, color: isSelected ? AppColors.primaryLight : AppColors.getTextMuted(isDark)),
              const SizedBox(width: 4),
            ],
            Text(
              label,
              style: TextStyle(
                fontSize: 11.5,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                color: isSelected ? AppColors.primaryLight : AppColors.getTextPrimary(isDark),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // 3. Customer Card (Completely wrapped & safe against right overflow)
  Widget _buildCustomerCard(BuildContext context, CustomerModel customer, bool isDark) {
    final hasDebt = customer.hasDebt || customer.totalDebt > 0;
    final initial = customer.name.isNotEmpty ? customer.name[0] : 'ع';

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.getSurface(isDark),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: hasDebt ? AppColors.danger.withOpacity(0.35) : AppColors.getBorder(isDark),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.2 : 0.04),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Header Row: Avatar, Name, Phone & WhatsApp Chat Icon
          Row(
            children: [
              // Avatar
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.15),
                  shape: BoxShape.circle,
                  border: Border.all(color: AppColors.primaryLight.withOpacity(0.3)),
                ),
                alignment: Alignment.center,
                child: Text(
                  initial,
                  style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.primaryLight, fontSize: 16),
                ),
              ),
              const SizedBox(width: 10),
              // Customer Name & Phone (Expanded to prevent overflow)
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      customer.name,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: AppColors.getTextPrimary(isDark),
                      ),
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                    ),
                    const SizedBox(height: 2),
                    if (customer.phone != null && customer.phone!.isNotEmpty)
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.phone_iphone_rounded, size: 12, color: AppColors.getTextMuted(isDark)),
                          const SizedBox(width: 4),
                          Flexible(
                            child: Text(
                              customer.phone!,
                              style: TextStyle(fontSize: 11, color: AppColors.getTextSecondary(isDark), fontFamily: 'monospace'),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      )
                    else
                      Text(
                        "لا يوجد رقم هاتف",
                        style: TextStyle(fontSize: 10.5, color: AppColors.getTextMuted(isDark)),
                      ),
                  ],
                ),
              ),
              // WhatsApp Quick Chat Button
              if (customer.phone != null && customer.phone!.isNotEmpty)
                IconButton(
                  icon: const Icon(Icons.chat_bubble_outline_rounded, color: Color(0xFF10B981), size: 22),
                  tooltip: "محادثة واتساب",
                  onPressed: () => WhatsAppHelper.openDirectChat(customer.phone),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
                ),
            ],
          ),

          const SizedBox(height: 10),
          const Divider(height: 1),
          const SizedBox(height: 8),

          // Financial Indicators Row
          Row(
            children: [
              // Invoices Count
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text("العمليات", style: TextStyle(fontSize: 10, color: AppColors.getTextMuted(isDark))),
                    Text(
                      "${customer.invoicesCount} فاتورة",
                      style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold, color: AppColors.getTextPrimary(isDark)),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              // Total Purchases
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text("المشتريات", style: TextStyle(fontSize: 10, color: AppColors.getTextMuted(isDark))),
                    Text(
                      "${currencyFmt.format(customer.totalSpent)} ج.م",
                      style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold, color: AppColors.primaryLight),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              // Balance / Debt
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text("المديونية", style: TextStyle(fontSize: 10, color: AppColors.getTextMuted(isDark))),
                    Text(
                      hasDebt ? "${currencyFmt.format(customer.totalDebt)} ج.م" : "خالص (0.00)",
                      style: TextStyle(
                        fontSize: 11.5,
                        fontWeight: FontWeight.bold,
                        color: hasDebt ? AppColors.danger : AppColors.success,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 10),

          // Action Buttons: كشف الحساب + إرسال فاتورة واتساب
          Row(
            children: [
              // 1. View Dossier
              Expanded(
                child: OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    side: BorderSide(color: AppColors.getBorder(isDark)),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  icon: const Icon(Icons.folder_open_rounded, size: 16, color: AppColors.primaryLight),
                  label: Text(
                    "كشف الحساب",
                    style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold, color: AppColors.getTextPrimary(isDark)),
                    overflow: TextOverflow.ellipsis,
                  ),
                  onPressed: () => _openCustomerDossierSheet(context, customer, isDark),
                ),
              ),
              const SizedBox(width: 8),
              // 2. Send Invoice WhatsApp
              Expanded(
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF059669),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    elevation: 0,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  icon: const Icon(Icons.send_rounded, size: 15),
                  label: const Text(
                    "فاتورة واتساب",
                    style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold),
                    overflow: TextOverflow.ellipsis,
                  ),
                  onPressed: () => _openSendInvoiceWhatsAppModal(context, customer, isDark),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // 4. Customer Dossier Bottom Sheet (Full history of sales & debts)
  void _openCustomerDossierSheet(BuildContext context, CustomerModel customer, bool isDark) {
    final prov = Provider.of<CustomersProvider>(context, listen: false);
    prov.fetchCustomerDossier(customer.name, customer.phone);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return Consumer<CustomersProvider>(
          builder: (_, prov, __) {
            final dossier = prov.currentDossier;

            return Container(
              height: MediaQuery.of(context).size.height * 0.85,
              decoration: BoxDecoration(
                color: AppColors.getSurface(isDark),
                borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
                border: Border(top: BorderSide(color: AppColors.getBorder(isDark))),
              ),
              child: SafeArea(
                child: Column(
                  children: [
                    // Handle
                    const SizedBox(height: 10),
                    Container(
                      width: 42,
                      height: 4,
                      decoration: BoxDecoration(color: AppColors.getBorder(isDark), borderRadius: BorderRadius.circular(10)),
                    ),
                    const SizedBox(height: 12),

                    // Sheet Header
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  "ملف العميل: ${customer.name}",
                                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.getTextPrimary(isDark)),
                                  overflow: TextOverflow.ellipsis,
                                ),
                                if (customer.phone != null && customer.phone!.isNotEmpty)
                                  Text(
                                    customer.phone!,
                                    style: TextStyle(fontSize: 11.5, color: AppColors.getTextMuted(isDark), fontFamily: 'monospace'),
                                  ),
                              ],
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.close_rounded),
                            onPressed: () => Navigator.pop(ctx),
                          ),
                        ],
                      ),
                    ),
                    const Divider(height: 16),

                    // Content
                    Expanded(
                      child: prov.isLoadingDossier
                          ? const Center(child: CircularProgressIndicator())
                          : prov.dossierError != null
                              ? Center(
                                  child: Text(prov.dossierError!, style: const TextStyle(color: AppColors.danger)),
                                )
                              : dossier == null
                                  ? const Center(child: Text("لا توجد بيانات لهذا العميل"))
                                  : DefaultTabController(
                                      length: 2,
                                      child: Column(
                                        children: [
                                          TabBar(
                                            indicatorColor: AppColors.primaryLight,
                                            labelColor: AppColors.primaryLight,
                                            unselectedLabelColor: AppColors.getTextMuted(isDark),
                                            tabs: [
                                              Tab(text: "فواتير المبيعات (${dossier.sales.length})"),
                                              Tab(text: "الديون والمديونيات (${dossier.debts.length})"),
                                            ],
                                          ),
                                          Expanded(
                                            child: TabBarView(
                                              children: [
                                                // 1. Sales Tab
                                                _buildSalesTab(context, dossier.sales, customer, isDark),
                                                // 2. Debts Tab
                                                _buildDebtsTab(context, dossier.debts, isDark),
                                              ],
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildSalesTab(BuildContext context, List<SaleSummaryModel> sales, CustomerModel customer, bool isDark) {
    if (sales.isEmpty) {
      return Center(
        child: Text("لا توجد فواتير مبيعات مسجلة لهذا العميل", style: TextStyle(color: AppColors.getTextMuted(isDark))),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(12),
      itemCount: sales.length,
      itemBuilder: (ctx, idx) {
        final s = sales[idx];
        return Card(
          margin: const EdgeInsets.only(bottom: 8),
          color: AppColors.getBackground(isDark),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10), side: BorderSide(color: AppColors.getBorder(isDark))),
          child: Padding(
            padding: const EdgeInsets.all(10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        "فاتورة #${s.invoiceNumber}",
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.primaryLight),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Text(
                      dateFmt.format(s.saleDate),
                      style: TextStyle(fontSize: 10.5, color: AppColors.getTextMuted(isDark)),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        "الإجمالي: ${currencyFmt.format(s.totalAmount)} ج.م",
                        style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold, color: AppColors.getTextPrimary(isDark)),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Expanded(
                      child: Text(
                        s.remainingAmount > 0 ? "متبقي: ${currencyFmt.format(s.remainingAmount)}" : "مسددة بالكامل",
                        style: TextStyle(
                          fontSize: 11.5,
                          fontWeight: FontWeight.bold,
                          color: s.remainingAmount > 0 ? AppColors.danger : AppColors.success,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Align(
                  alignment: Alignment.centerLeft,
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF059669),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                      minimumSize: const Size(0, 30),
                    ),
                    icon: const Icon(Icons.send_rounded, size: 13),
                    label: const Text("إرسال هذه الفاتورة بالواتساب", style: TextStyle(fontSize: 11)),
                    onPressed: () {
                      final msg = WhatsAppHelper.buildInvoiceReceiptMessage(
                        invoiceNumber: s.invoiceNumber,
                        customerName: s.customerName ?? customer.name,
                        customerPhone: s.customerPhone ?? customer.phone,
                        date: s.saleDate,
                        totalAmount: s.totalAmount,
                        paidAmount: s.paidAmount,
                        remainingAmount: s.remainingAmount,
                        paymentMethod: s.paymentMethod,
                        isInstallment: s.isInstallment,
                        numberOfMonths: s.numberOfMonths,
                        monthlyInstallmentAmount: s.calculatedMonthlyAmount,
                        guarantorName: s.guarantorName,
                        guarantorPhone: s.guarantorPhone,
                        isDelivery: s.isDelivery,
                        isReserved: s.isReserved,
                      );
                      WhatsAppHelper.openWhatsApp(phone: s.customerPhone ?? customer.phone, message: msg);
                    },
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildDebtsTab(BuildContext context, List<DebtItemModel> debts, bool isDark) {
    if (debts.isEmpty) {
      return Center(
        child: Text("لا توجد مديونيات مسجلة على هذا العميل", style: TextStyle(color: AppColors.getTextMuted(isDark))),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(12),
      itemCount: debts.length,
      itemBuilder: (ctx, idx) {
        final d = debts[idx];
        return Card(
          margin: const EdgeInsets.only(bottom: 8),
          color: AppColors.getBackground(isDark),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10), side: BorderSide(color: AppColors.danger.withOpacity(0.3))),
          child: Padding(
            padding: const EdgeInsets.all(10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        "فاتورة #${d.invoiceNumber}",
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.danger),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Text(
                      dateFmt.format(d.date),
                      style: TextStyle(fontSize: 10.5, color: AppColors.getTextMuted(isDark)),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        "إجمالي: ${currencyFmt.format(d.totalAmount)}",
                        style: TextStyle(fontSize: 11, color: AppColors.getTextSecondary(isDark)),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Expanded(
                      child: Text(
                        "المدفوع: ${currencyFmt.format(d.paidAmount)}",
                        style: const TextStyle(fontSize: 11, color: AppColors.success),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Expanded(
                      child: Text(
                        "المتبقي: ${currencyFmt.format(d.remainingAmount)}",
                        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.danger),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // 5. Send Invoice WhatsApp Dialog (Pick Invoice or Send Latest)
  void _openSendInvoiceWhatsAppModal(BuildContext context, CustomerModel customer, bool isDark) {
    final prov = Provider.of<CustomersProvider>(context, listen: false);
    prov.fetchCustomerDossier(customer.name, customer.phone);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (dialogCtx) {
        String phoneInput = customer.phone ?? '';
        SaleSummaryModel? selectedSale;

        return StatefulBuilder(
          builder: (ctx, setModalState) {
            return Consumer<CustomersProvider>(
              builder: (_, prov, __) {
                final sales = prov.currentDossier?.sales ?? [];
                if (selectedSale == null && sales.isNotEmpty) {
                  selectedSale = sales.first;
                }

                final previewMsg = selectedSale != null
                    ? WhatsAppHelper.buildInvoiceReceiptMessage(
                        invoiceNumber: selectedSale!.invoiceNumber,
                        customerName: selectedSale!.customerName ?? customer.name,
                        customerPhone: phoneInput,
                        date: selectedSale!.saleDate,
                        totalAmount: selectedSale!.totalAmount,
                        paidAmount: selectedSale!.paidAmount,
                        remainingAmount: selectedSale!.remainingAmount,
                        paymentMethod: selectedSale!.paymentMethod,
                        isInstallment: selectedSale!.isInstallment,
                        numberOfMonths: selectedSale!.numberOfMonths,
                        monthlyInstallmentAmount: selectedSale!.calculatedMonthlyAmount,
                        guarantorName: selectedSale!.guarantorName,
                        guarantorPhone: selectedSale!.guarantorPhone,
                        isDelivery: selectedSale!.isDelivery,
                        isReserved: selectedSale!.isReserved,
                      )
                    : "لا توجد فواتير مبيعات سابقة لهذا العميل.";

                return Container(
                  padding: EdgeInsets.fromLTRB(16, 12, 16, MediaQuery.of(context).viewInsets.bottom + 20),
                  decoration: BoxDecoration(
                    color: AppColors.getSurface(isDark),
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
                    border: Border(top: BorderSide(color: AppColors.getBorder(isDark))),
                  ),
                  child: SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Center(
                          child: Container(width: 40, height: 4, decoration: BoxDecoration(color: AppColors.getBorder(isDark), borderRadius: BorderRadius.circular(10))),
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            const Icon(Icons.send_rounded, color: Color(0xFF10B981), size: 22),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                "إرسال فاتورة مبيعات عبر واتساب",
                                style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppColors.getTextPrimary(isDark)),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(dialogCtx)),
                          ],
                        ),
                        const Divider(height: 16),

                        // Phone Number Field
                        Text("رقم هاتف الواتساب:", style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.getTextSecondary(isDark))),
                        const SizedBox(height: 4),
                        TextFormField(
                          initialValue: phoneInput,
                          keyboardType: TextInputType.phone,
                          onChanged: (val) => setModalState(() => phoneInput = val),
                          decoration: InputDecoration(
                            hintText: "010xxxxxxxx",
                            prefixIcon: const Icon(Icons.phone_iphone_rounded, size: 18),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                          ),
                        ),
                        const SizedBox(height: 12),

                        // Select Invoice Dropdown
                        Text("اختر الفاتورة المراد إرسالها:", style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.getTextSecondary(isDark))),
                        const SizedBox(height: 4),
                        if (prov.isLoadingDossier)
                          const Center(child: Padding(padding: EdgeInsets.all(8.0), child: CircularProgressIndicator()))
                        else if (sales.isEmpty)
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(color: AppColors.getBackground(isDark), borderRadius: BorderRadius.circular(8)),
                            child: const Text("لا توجد فواتير مسجلة لهذا العميل", style: TextStyle(fontSize: 12, color: AppColors.danger)),
                          )
                        else
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10),
                            decoration: BoxDecoration(
                              color: AppColors.getBackground(isDark),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: AppColors.getBorder(isDark)),
                            ),
                            child: DropdownButtonHideUnderline(
                              child: DropdownButton<SaleSummaryModel>(
                                isExpanded: true,
                                value: selectedSale,
                                items: sales.map((s) {
                                  return DropdownMenuItem<SaleSummaryModel>(
                                    value: s,
                                    child: Text(
                                      "فاتورة #${s.invoiceNumber} (${currencyFmt.format(s.totalAmount)} ج.م) - ${dateFmt.format(s.saleDate)}",
                                      style: TextStyle(fontSize: 12, color: AppColors.getTextPrimary(isDark)),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  );
                                }).toList(),
                                onChanged: (val) => setModalState(() => selectedSale = val),
                              ),
                            ),
                          ),

                        const SizedBox(height: 12),

                        // Preview box with Copy Button
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text("معاينة نص الرسالة:", style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.getTextMuted(isDark))),
                            InkWell(
                              onTap: () async {
                                await Clipboard.setData(ClipboardData(text: previewMsg));
                                if (context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(content: Text("تم نسخ نص الرسالة إلى الحافظة"), duration: Duration(seconds: 1)),
                                  );
                                }
                              },
                              borderRadius: BorderRadius.circular(6),
                              child: const Padding(
                                padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                child: Row(
                                  children: [
                                    Icon(Icons.copy_rounded, size: 14, color: AppColors.primaryLight),
                                    SizedBox(width: 4),
                                    Text("نسخ النص", style: TextStyle(fontSize: 11.5, color: AppColors.primaryLight, fontWeight: FontWeight.bold)),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Container(
                          padding: const EdgeInsets.all(12),
                          constraints: const BoxConstraints(minHeight: 140, maxHeight: 260),
                          width: double.infinity,
                          decoration: BoxDecoration(
                            color: AppColors.getBackground(isDark),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: AppColors.getBorder(isDark)),
                          ),
                          child: SingleChildScrollView(
                            physics: const ClampingScrollPhysics(),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  previewMsg,
                                  style: TextStyle(fontSize: 12, fontFamily: 'monospace', color: AppColors.getTextPrimary(isDark), height: 1.5),
                                ),
                                const SizedBox(height: 16), // bottom buffer so last line is never cut off
                              ],
                            ),
                          ),
                        ),

                        const SizedBox(height: 16),

                        // Send Button
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF059669),
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            ),
                            icon: const Icon(Icons.send_rounded),
                            label: const Text(
                              "فتح وإرسال عبر واتساب",
                              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                            ),
                            onPressed: (selectedSale == null || phoneInput.trim().isEmpty)
                                ? null
                                : () async {
                                    Navigator.pop(dialogCtx);
                                    final ok = await WhatsAppHelper.openWhatsApp(
                                      phone: phoneInput,
                                      message: previewMsg,
                                    );
                                    if (!ok && context.mounted) {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        const SnackBar(
                                          content: Text("تعذر فتح تطبيق الواتساب"),
                                          backgroundColor: AppColors.danger,
                                        ),
                                      );
                                    }
                                  },
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            );
          },
        );
      },
    );
  }

  Future<void> _showAddCustomerDialog(
    BuildContext context,
    CustomersProvider customersProv,
    bool isDark,
  ) async {
    final nameCtrl = TextEditingController();
    final phoneCtrl = TextEditingController();
    final addressCtrl = TextEditingController();
    final emailCtrl = TextEditingController();
    bool isSaving = false;

    await showDialog(
      context: context,
      builder: (dialogCtx) {
        return StatefulBuilder(
          builder: (ctx, setDialogState) {
            return AlertDialog(
              backgroundColor: AppColors.getSurface(isDark),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              title: const Row(
                children: [
                  Icon(Icons.person_add_rounded, color: Color(0xFF4F46E5)),
                  SizedBox(width: 8),
                  Text("إضافة عميل جديد", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                ],
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: nameCtrl,
                      decoration: const InputDecoration(
                        labelText: "اسم العميل *",
                        prefixIcon: Icon(Icons.person_outline),
                      ),
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: phoneCtrl,
                      keyboardType: TextInputType.phone,
                      decoration: const InputDecoration(
                        labelText: "رقم الهاتف",
                        prefixIcon: Icon(Icons.phone_outlined),
                      ),
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: addressCtrl,
                      decoration: const InputDecoration(
                        labelText: "العنوان",
                        prefixIcon: Icon(Icons.location_on_outlined),
                      ),
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: emailCtrl,
                      keyboardType: TextInputType.emailAddress,
                      decoration: const InputDecoration(
                        labelText: "البريد الإلكتروني (اختياري)",
                        prefixIcon: Icon(Icons.email_outlined),
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(dialogCtx),
                  child: const Text("إلغاء"),
                ),
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF4F46E5),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  icon: isSaving
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                        )
                      : const Icon(Icons.check_rounded, size: 18),
                  label: Text(isSaving ? "جاري الحفظ..." : "حفظ وتسجيل"),
                  onPressed: isSaving
                      ? null
                      : () async {
                          final name = nameCtrl.text.trim();
                          if (name.isEmpty) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text("يرجى كتابة اسم العميل")),
                            );
                            return;
                          }
                          setDialogState(() => isSaving = true);
                          final created = await customersProv.addCustomer(
                            name: name,
                            phone: phoneCtrl.text.trim().isEmpty ? null : phoneCtrl.text.trim(),
                            address: addressCtrl.text.trim().isEmpty ? null : addressCtrl.text.trim(),
                            email: emailCtrl.text.trim().isEmpty ? null : emailCtrl.text.trim(),
                          );
                          setDialogState(() => isSaving = false);
                          if (created != null) {
                            Navigator.pop(dialogCtx);
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text("تم إضافة العميل (${created.name}) بنجاح وسيتزامن مع الديسكتوب!"),
                                  backgroundColor: const Color(0xFF10B981),
                                  behavior: SnackBarBehavior.floating,
                                ),
                              );
                            }
                          } else {
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(customersProv.errorMessage ?? "فشل إضافة العميل"),
                                  backgroundColor: Colors.redAccent,
                                ),
                              );
                            }
                          }
                        },
                ),
              ],
            );
          },
        );
      },
    );
  }
}
