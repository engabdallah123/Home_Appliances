import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/theme/theme_provider.dart';
import '../../../core/widgets/custom_text_field.dart';
import '../../../core/widgets/offline_banner.dart';
import '../models/expense_model.dart';
import '../providers/expenses_provider.dart';

class ExpensesScreen extends StatefulWidget {
  const ExpensesScreen({super.key});

  @override
  State<ExpensesScreen> createState() => _ExpensesScreenState();
}

class _ExpensesScreenState extends State<ExpensesScreen> {
  DateTime _currentDate = DateTime.now();
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadExpenses();
    });
  }

  void _onScroll() {
    if (_scrollController.hasClients &&
        _scrollController.position.pixels >= _scrollController.position.maxScrollExtent - 250) {
      final prov = Provider.of<ExpensesProvider>(context, listen: false);
      if (prov.hasMore && !prov.isLoadingMore && !prov.isLoading) {
        prov.fetchMoreExpenses();
      }
    }
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  void _loadExpenses() {
    Provider.of<ExpensesProvider>(context, listen: false)
        .fetchExpenses(month: _currentDate.month, year: _currentDate.year);
  }

  void _prevMonth() {
    setState(() {
      _currentDate = DateTime(_currentDate.year, _currentDate.month - 1, 1);
    });
    _loadExpenses();
  }

  void _nextMonth() {
    setState(() {
      _currentDate = DateTime(_currentDate.year, _currentDate.month + 1, 1);
    });
    _loadExpenses();
  }

  Future<void> _openAddExpenseModal() async {
    final titleCtrl = TextEditingController();
    final amountCtrl = TextEditingController();
    final notesCtrl = TextEditingController();
    String selectedCategory = "كهرباء ومياه";
    final categories = [
      "كهرباء ومياه",
      "إيجار",
      "صيانة ومعدات",
      "رواتب وأجور",
      "أدوات مكتبية وتغليف",
      "ضيافة ونظافة",
      "أخرى",
    ];
    final isDark = Provider.of<ThemeProvider>(context, listen: false).isDarkMode;

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.getSurface(isDark),
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => StatefulBuilder(
        builder: (modalCtx, setModalState) => Padding(
          padding: EdgeInsets.only(
            left: 16,
            right: 16,
            top: 20,
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 20,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.receipt_long_rounded, color: AppColors.primaryLight),
                  const SizedBox(width: 8),
                  Text(
                    "تسجيل مصروف جديد",
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppColors.getTextPrimary(isDark)),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              CustomTextField(
                controller: titleCtrl,
                label: "بيان المصروف *",
                hint: "مثلاً: فاتورة الكهرباء، أدوات نظافة...",
                prefixIcon: Icons.edit_note_rounded,
              ),
              const SizedBox(height: 12),
              CustomTextField(
                controller: amountCtrl,
                label: "المبلغ (ج.م) *",
                hint: "0.00",
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                prefixIcon: Icons.attach_money_rounded,
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                value: selectedCategory,
                dropdownColor: AppColors.getSurface(isDark),
                style: TextStyle(color: AppColors.getTextPrimary(isDark), fontSize: 14),
                decoration: InputDecoration(
                  labelText: "فئة المصروف *",
                  labelStyle: TextStyle(color: AppColors.getTextSecondary(isDark), fontSize: 13),
                  prefixIcon: const Icon(Icons.category_rounded, color: AppColors.primaryLight),
                  filled: true,
                  fillColor: AppColors.getInputBackground(isDark),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide(color: AppColors.getBorder(isDark)),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide(color: AppColors.getBorder(isDark)),
                  ),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                ),
                items: categories.map((cat) => DropdownMenuItem(value: cat, child: Text(cat))).toList(),
                onChanged: (val) {
                  if (val != null) {
                    setModalState(() {
                      selectedCategory = val;
                    });
                  }
                },
              ),
              const SizedBox(height: 12),
              CustomTextField(
                controller: notesCtrl,
                label: "ملاحظات إضافية (اختياري)",
                hint: "تفاصيل أو رقم إيصال...",
                prefixIcon: Icons.notes_rounded,
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  onPressed: () async {
                    final amt = double.tryParse(amountCtrl.text.trim()) ?? 0;
                    if (titleCtrl.text.trim().isEmpty || amt <= 0) return;

                    Navigator.pop(ctx);
                    final prov = Provider.of<ExpensesProvider>(context, listen: false);
                    final success = await prov.createExpense(
                      title: titleCtrl.text.trim(),
                      amount: amt,
                      category: selectedCategory,
                      notes: notesCtrl.text.trim(),
                    );

                    if (success && mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          backgroundColor: AppColors.success,
                          content: Text("تم تسجيل المصروف بنجاح وجاري مزامنته مع الكاشير."),
                        ),
                      );
                    }
                  },
                  child: const Text("حفظ المصروف", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 15)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Provider.of<ThemeProvider>(context).isDarkMode;
    final prov = Provider.of<ExpensesProvider>(context);
    final currencyFormatter = NumberFormat("#,##0.00", "ar_EG");
    final dateFormatter = DateFormat("dd/MM/yyyy HH:mm");
    final monthFormatter = DateFormat("MMMM yyyy", "ar_EG");

    return Scaffold(
      backgroundColor: AppColors.getBackground(isDark),
      appBar: AppBar(
        backgroundColor: AppColors.getSurface(isDark),
        elevation: 0,
        title: Text(
          "المصروفات الشهرية",
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: AppColors.getTextPrimary(isDark)),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.refresh_rounded, color: AppColors.getTextPrimary(isDark)),
            onPressed: _loadExpenses,
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: AppColors.primary,
        icon: const Icon(Icons.add_rounded, color: Colors.white),
        label: const Text("تسجيل مصروف", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        onPressed: _openAddExpenseModal,
      ),
      body: Column(
        children: [
          const OfflineBanner(),

          // Month Selector Bar
          Padding(
            padding: const EdgeInsets.all(16),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: AppColors.getSurface(isDark),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppColors.getBorder(isDark)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  IconButton(
                    icon: Icon(Icons.chevron_right_rounded, color: AppColors.getTextPrimary(isDark)),
                    onPressed: _nextMonth,
                  ),
                  Text(
                    monthFormatter.format(_currentDate),
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: AppColors.getTextPrimary(isDark)),
                  ),
                  IconButton(
                    icon: Icon(Icons.chevron_left_rounded, color: AppColors.getTextPrimary(isDark)),
                    onPressed: _prevMonth,
                  ),
                ],
              ),
            ),
          ),

          // Total Monthly Expenses Card
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF4F46E5), Color(0xFF6366F1)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF4F46E5).withOpacity(0.3),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.account_balance_wallet_rounded, color: Colors.white70, size: 18),
                      SizedBox(width: 8),
                      Text("إجمالي مصروفات هذا الشهر", style: TextStyle(color: Colors.white70, fontSize: 12)),
                    ],
                  ),
                  const SizedBox(height: 8),
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerRight,
                    child: Text(
                      "${currencyFormatter.format(prov.totalAmount)} ج.م",
                      style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
                    ),
                  ),
                  Text(
                    "${prov.expenses.length} حركة مصروف مسجلة",
                    style: const TextStyle(color: Colors.white70, fontSize: 11),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 12),

          // Expenses List
          Expanded(
            child: prov.isLoading
                ? const Center(child: CircularProgressIndicator(color: AppColors.primaryLight))
                : prov.expenses.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.receipt_long_outlined, size: 54, color: AppColors.getTextMuted(isDark)),
                            const SizedBox(height: 12),
                            Text("لا توجد مصروفات مسجلة لهذا الشهر", style: TextStyle(color: AppColors.getTextMuted(isDark), fontSize: 14)),
                          ],
                        ),
                      )
                    : RefreshIndicator(
                        onRefresh: () async => _loadExpenses(),
                        child: ListView.separated(
                          controller: _scrollController,
                          physics: const AlwaysScrollableScrollPhysics(),
                          padding: const EdgeInsets.fromLTRB(16, 8, 16, 80),
                          itemCount: prov.expenses.length + (prov.isLoadingMore ? 1 : 0),
                          separatorBuilder: (_, __) => const SizedBox(height: 10),
                          itemBuilder: (ctx, idx) {
                            if (idx == prov.expenses.length) {
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
                            final exp = prov.expenses[idx];
                            return _buildExpenseCard(isDark, exp, currencyFormatter, dateFormatter);
                          },
                        ),
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildExpenseCard(bool isDark, ExpenseModel exp, NumberFormat currencyFormatter, DateFormat dateFormatter) {
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
            height: 44,
            width: 44,
            decoration: BoxDecoration(
              color: AppColors.danger.withOpacity(0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            alignment: Alignment.center,
            child: const Icon(Icons.outbox_rounded, color: AppColors.danger, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  exp.title,
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppColors.getTextPrimary(isDark)),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Wrap(
                  crossAxisAlignment: WrapCrossAlignment.center,
                  spacing: 6,
                  runSpacing: 4,
                  children: [
                    if (exp.category != null)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          exp.category!,
                          style: const TextStyle(fontSize: 10, color: AppColors.primaryLight, fontWeight: FontWeight.w600),
                        ),
                      ),
                    Text(
                      dateFormatter.format(exp.date),
                      style: TextStyle(fontSize: 11, color: AppColors.getTextMuted(isDark)),
                    ),
                  ],
                ),
                if (exp.notes != null && exp.notes!.isNotEmpty) ...[
                  const SizedBox(height: 3),
                  Text(
                    exp.notes!,
                    style: TextStyle(fontSize: 11, color: AppColors.getTextMuted(isDark)),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: 8),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              "- ${currencyFormatter.format(exp.amount)} ج.م",
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.danger),
            ),
          ),
        ],
      ),
    );
  }
}
