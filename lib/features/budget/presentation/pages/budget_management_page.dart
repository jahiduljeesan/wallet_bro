import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../features/categories/presentation/providers/category_provider.dart';
import '../../../../features/categories/presentation/widgets/category_icon.dart';
import '../providers/budget_provider.dart';

class BudgetManagementPage extends StatelessWidget {
  const BudgetManagementPage({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final categoryProvider = Provider.of<CategoryProvider>(context);
    final budgetProvider = Provider.of<BudgetProvider>(context);

    // Usually we only set budgets for expense categories
    final categories = categoryProvider.expenseCategories;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('Budget Management'),
      ),
      body: categories.isEmpty
          ? const Center(child: Text('No expense categories found.'))
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: categories.length,
              itemBuilder: (context, index) {
                final cat = categories[index];
                final budget = budgetProvider.getBudget(cat.id);

                return Card(
                  margin: const EdgeInsets.only(bottom: 8),
                  elevation: 0,
                  color: theme.colorScheme.surface,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                    side: BorderSide(color: theme.colorScheme.outlineVariant.withOpacity(0.5)),
                  ),
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: Colors.redAccent.withOpacity(0.1),
                      child: Padding(
                        padding: const EdgeInsets.all(6.0),
                        child: CategoryIcon(
                          categoryName: cat.name,
                          isExpense: true,
                          size: 24,
                        ),
                      ),
                    ),
                    title: Text(
                      cat.name,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    subtitle: Text(
                      budget != null && budget.amount > 0
                          ? 'Limit: ৳${budget.amount.toStringAsFixed(0)} / month'
                          : 'No budget set',
                      style: TextStyle(
                        color: budget != null && budget.amount > 0
                            ? theme.colorScheme.primary
                            : Colors.grey,
                      ),
                    ),
                    trailing: const Icon(Icons.edit_outlined, size: 20),
                    onTap: () => _showSetBudgetSheet(context, cat, budget?.amount ?? 0),
                  ),
                );
              },
            ),
    );
  }

  void _showSetBudgetSheet(BuildContext context, dynamic category, double currentAmount) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => SetBudgetSheet(
        categoryId: category.id,
        categoryName: category.name,
        currentAmount: currentAmount,
      ),
    );
  }
}

class SetBudgetSheet extends StatefulWidget {
  final String categoryId;
  final String categoryName;
  final double currentAmount;

  const SetBudgetSheet({
    super.key,
    required this.categoryId,
    required this.categoryName,
    required this.currentAmount,
  });

  @override
  State<SetBudgetSheet> createState() => _SetBudgetSheetState();
}

class _SetBudgetSheetState extends State<SetBudgetSheet> {
  late TextEditingController _amountController;

  @override
  void initState() {
    super.initState();
    _amountController = TextEditingController(
      text: widget.currentAmount > 0 ? widget.currentAmount.toStringAsFixed(0) : '',
    );
  }

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }

  void _saveBudget() {
    final amountText = _amountController.text.trim();
    final amount = double.tryParse(amountText) ?? 0.0;

    final provider = Provider.of<BudgetProvider>(context, listen: false);
    provider.setBudget(widget.categoryId, amount);

    Navigator.pop(context);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Budget for ${widget.categoryName} updated!')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: EdgeInsets.only(
        left: 24,
        right: 24,
        top: 24,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Set Budget: ${widget.categoryName}',
                style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
              ),
              IconButton(
                icon: const Icon(Icons.close),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Text(
            'Enter 0 or leave empty to remove budget.',
            style: TextStyle(color: Colors.grey, fontSize: 13),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _amountController,
            keyboardType: TextInputType.number,
            decoration: InputDecoration(
              labelText: 'Monthly Limit (৳)',
              filled: true,
              prefixIcon: const Icon(Icons.attach_money),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide.none,
              ),
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: _saveBudget,
            style: ElevatedButton.styleFrom(
              backgroundColor: theme.colorScheme.primary,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
            child: const Text('Save Budget', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          ),
        ],
      ),
    );
  }
}
