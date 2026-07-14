import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:intl/intl.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../providers/dashboard_provider.dart';

import '../../../transactions/presentation/pages/add_transaction_sheet.dart';
import '../../../categories/presentation/widgets/category_icon.dart';
import '../../../profile/presentation/pages/profile_page.dart';
import '../../../budget/presentation/providers/budget_provider.dart';
import '../../../categories/presentation/providers/category_provider.dart';
import '../../../transactions/domain/models/transaction_model.dart';

class DashboardPage extends StatelessWidget {
  const DashboardPage({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final provider = Provider.of<DashboardProvider>(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('Dashboard'), 
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.person_outline_rounded),
            onPressed: () {
              Navigator.push(context, MaterialPageRoute(builder: (_) => const ProfilePage()));
            },
          )
        ],
      ),
      body: CustomScrollView(
        slivers: [
          // Balance Card
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: BalanceCard(
                balance: provider.totalBalance,
                income: provider.currentMonthIncome,
                expense: provider.currentMonthExpense,
              ),
            ),
          ),

          // Spending Charts Section
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
              child: Column(
                children: [
                  // Bar Chart: Weekly Spending
                  SpendingBarChart(data: provider.getWeeklySpendingData()),
                  const SizedBox(height: 16),
                  
                  // Row for Pie Chart and Insights
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Pie Chart: Category Breakdown
                      Expanded(
                        flex: 3,
                        child: CategoryPieChart(data: provider.getCategoryData()),
                      ),
                      const SizedBox(width: 16),
                      
                      // Quick Insight Cards
                      Expanded(
                        flex: 2,
                        child: SizedBox(
                          height: 180,
                          child: PageView(
                            children: [
                              InsightCard(
                                title: 'Top Category',
                                value: provider.topCategory,
                                subtitle: 'Most spent this month',
                                icon: Icons.stars_rounded,
                                color: Colors.orangeAccent,
                              ),
                              InsightCard(
                                title: 'Avg Expense',
                                value: CurrencyFormatter.format(provider.averageExpenseByCategory),
                                subtitle: 'Per category',
                                icon: Icons.analytics,
                                color: Colors.blueAccent,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ).animate().fadeIn(duration: 800.ms).slideY(begin: 0.1, end: 0, curve: Curves.easeOutCubic),
            ),
          ),

          // Budget Progress Section
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
              child: BudgetProgressSection().animate().fadeIn(duration: 800.ms).slideY(begin: 0.1, end: 0, curve: Curves.easeOutCubic),
            ),
          ),

          // Recent Transactions Title
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 16.0,
                vertical: 8.0,
              ),
              child: Text(
                'Recent Transactions',
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),

          // Transactions List
          Builder(
            builder: (context) {
              if (provider.transactions.isEmpty) {
                return const SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.all(32.0),
                    child: Center(
                      child: Text('No transactions yet. Start adding!'),
                    ),
                  ),
                );
              }

              final groupedTx = provider.groupedTransactions;
              final List<dynamic> listItems = [];
              final sortedDates = groupedTx.keys.toList()..sort((a, b) => b.compareTo(a));
              
              for (var date in sortedDates) {
                listItems.add(date);
                listItems.addAll(groupedTx[date]!);
              }

              return SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    final item = listItems[index];

                    if (item is DateTime) {
                      // Date Header
                      final dailyTotal = provider.getDailyTotal(item);
                      final isToday = DateTime.now().year == item.year &&
                          DateTime.now().month == item.month &&
                          DateTime.now().day == item.day;
                      final isYesterday = DateTime.now().subtract(const Duration(days: 1)).year == item.year &&
                          DateTime.now().subtract(const Duration(days: 1)).month == item.month &&
                          DateTime.now().subtract(const Duration(days: 1)).day == item.day;
                      
                      String dateText = DateFormat('MMM dd, yyyy').format(item);
                      if (isToday) dateText = 'Today, $dateText';
                      if (isYesterday) dateText = 'Yesterday, $dateText';

                      return Padding(
                        padding: const EdgeInsets.fromLTRB(24, 24, 24, 8),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              dateText,
                              style: theme.textTheme.titleSmall?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: theme.colorScheme.primary,
                              ),
                            ),
                            Text(
                              'Total: ${CurrencyFormatter.formatWithSign(dailyTotal.abs(), dailyTotal < 0)}',
                              style: theme.textTheme.titleSmall?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: dailyTotal < 0 ? Colors.redAccent : Colors.green,
                              ),
                            ),
                          ],
                        ),
                      );
                    }

                    // Transaction Item
                    final tx = item as TransactionModel;
                    return Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16.0,
                        vertical: 4.0,
                      ),
                      child: Dismissible(
                        key: ValueKey(tx.id),
                        direction: DismissDirection.endToStart,
                        background: Container(
                          alignment: Alignment.centerRight,
                          padding: const EdgeInsets.only(right: 20),
                          decoration: BoxDecoration(
                            color: Colors.redAccent,
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: const Icon(Icons.delete_outline, color: Colors.white),
                        ),
                        onDismissed: (direction) {
                          provider.deleteTransaction(tx.id);
                          ScaffoldMessenger.of(context).clearSnackBars();
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: const Text('Transaction deleted'),
                              backgroundColor: Colors.redAccent,
                              behavior: SnackBarBehavior.floating,
                              duration: const Duration(seconds: 3),
                              action: SnackBarAction(
                                label: 'UNDO',
                                textColor: Colors.white,
                                onPressed: () {
                                  provider.addTransaction(tx);
                                },
                              ),
                            ),
                          );
                        },
                        child: Card(
                          elevation: 0,
                          color: theme.colorScheme.surface,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: ListTile(
                            onTap: () => AddTransactionSheet.show(context, transaction: tx),
                            leading: CircleAvatar(
                              backgroundColor: tx.isExpense
                                  ? Colors.redAccent.withOpacity(0.1)
                                  : Colors.greenAccent.withOpacity(0.1),
                              child: Padding(
                                padding: const EdgeInsets.all(6.0),
                                child: CategoryIcon(
                                  categoryName: tx.category,
                                  isExpense: tx.isExpense,
                                  size: 24,
                                ),
                              ),
                            ),
                            title: Text(
                              tx.category,
                              style: const TextStyle(fontWeight: FontWeight.bold),
                            ),
                            subtitle: Text(
                              tx.note.isNotEmpty
                                  ? tx.note
                                  : DateFormat.jm().format(tx.timestamp),
                            ),
                            trailing: Text(
                              CurrencyFormatter.formatWithSign(tx.amount, tx.isExpense),
                              style: TextStyle(
                                color: tx.isExpense ? Colors.redAccent : Colors.green,
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ).animate(delay: (index > 15 ? 0 : index * 30).ms).fadeIn().slideX(begin: 0.2, end: 0);
                  },
                  childCount: listItems.length,
                ),
              );
            },
          ),

          const SliverToBoxAdapter(
            child: SizedBox(height: 80),
          ), // Bottom padding
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => AddTransactionSheet.show(context),
        backgroundColor: theme.colorScheme.primary,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }
}

class BalanceCard extends StatelessWidget {
  final double balance;
  final double income;
  final double expense;

  const BalanceCard({
    super.key,
    required this.balance,
    required this.income,
    required this.expense,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isDark
              ? [const Color(0xFF1E293B), const Color(0xFF0F172A)]
              : [
                  theme.colorScheme.primary,
                  theme.colorScheme.primary.withOpacity(0.8),
                ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: theme.colorScheme.primary.withOpacity(0.3),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Cash Balance',
            style: theme.textTheme.titleMedium?.copyWith(color: Colors.white70),
          ),
          const SizedBox(height: 8),
          TweenAnimationBuilder<double>(
            tween: Tween<double>(begin: 0, end: balance),
            duration: const Duration(milliseconds: 1000),
            curve: Curves.easeOutCubic,
            builder: (context, value, _) {
              return Text(
                CurrencyFormatter.format(value, showDecimals: true),
                style: theme.textTheme.headlineLarge?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  letterSpacing: -1,
                ),
              );
            },
          ),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(child: _buildStat(context, 'Income', income, Icons.arrow_downward_rounded, Colors.greenAccent)),
              const SizedBox(width: 16),
              Expanded(child: _buildStat(context, 'Expense', expense, Icons.arrow_outward_rounded, Colors.redAccent)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStat(
    BuildContext context,
    String title,
    double amount,
    IconData icon,
    Color color,
  ) {
    final theme = Theme.of(context);
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.2),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: color, size: 20),
        ),
        const SizedBox(width: 12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: Colors.white70,
              ),
            ),
            const SizedBox(height: 2),
            Text(CurrencyFormatter.format(amount), style: theme.textTheme.titleMedium?.copyWith(color: Colors.white, fontWeight: FontWeight.bold)),
          ],
        ),
      ],
    );
  }
}

class SpendingBarChart extends StatelessWidget {
  final List<MapEntry<DateTime, double>> data;
  const SpendingBarChart({super.key, required this.data});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final maxVal = data.isEmpty ? 100.0 : data.map((e) => e.value).fold(0.0, (a, b) => a > b ? a : b);
    final limit = maxVal == 0 ? 100.0 : maxVal * 1.2;

    return Container(
      height: 220,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Weekly Spending', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: 20),
          Expanded(
            child: BarChart(
              BarChartData(
                alignment: BarChartAlignment.spaceAround,
                maxY: limit,
                barTouchData: BarTouchData(enabled: true),
                titlesData: FlTitlesData(
                  show: true,
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (value, meta) {
                        if (value < 0 || value >= data.length) return const SizedBox.shrink();
                        final date = data[value.toInt()].key;
                        return Padding(
                          padding: const EdgeInsets.only(top: 8.0),
                          child: Text(DateFormat('E').format(date).substring(0, 1), style: theme.textTheme.bodySmall),
                        );
                      },
                    ),
                  ),
                  leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                ),
                gridData: FlGridData(show: false),
                borderData: FlBorderData(show: false),
                barGroups: data.asMap().entries.map((e) {
                  return BarChartGroupData(
                    x: e.key,
                    barRods: [
                      BarChartRodData(
                        toY: e.value.value,
                        color: theme.colorScheme.primary,
                        width: 16,
                        borderRadius: BorderRadius.circular(4),
                        backDrawRodData: BackgroundBarChartRodData(show: true, toY: limit, color: theme.colorScheme.primary.withOpacity(0.05)),
                      )
                    ],
                  );
                }).toList(),
              ),
            ).animate().scaleY(begin: 0, end: 1, duration: 1000.ms, curve: Curves.elasticOut),
          ),
        ],
      ),
    );
  }
}

class CategoryPieChart extends StatelessWidget {
  final Map<String, double> data;
  const CategoryPieChart({super.key, required this.data});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = [Colors.blueAccent, Colors.purpleAccent, Colors.orangeAccent, Colors.greenAccent, Colors.redAccent, Colors.tealAccent];

    return Container(
      height: 180,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Categories', style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold)),
          Expanded(
            child: data.isEmpty
                ? const Center(child: Text('No Data', style: TextStyle(fontSize: 12)))
                : PieChart(
                    PieChartData(
                      sectionsSpace: 4,
                      centerSpaceRadius: 25,
                      sections: data.entries.toList().asMap().entries.map((e) {
                        final index = e.key;
                        final entry = e.value;
                        return PieChartSectionData(
                          color: colors[index % colors.length],
                          value: entry.value,
                          title: CurrencyFormatter.format(entry.value, showDecimals: false),
                          titleStyle: const TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                          radius: 45,
                        );
                      }).toList(),
                    ),
                  ).animate().scale(duration: 800.ms, curve: Curves.easeOutBack),
          ),
        ],
      ),
    );
  }
}

class InsightCard extends StatelessWidget {
  final String title;
  final String value;
  final String subtitle;
  final IconData icon;
  final Color color;

  const InsightCard({super.key, required this.title, required this.value, required this.subtitle, required this.icon, required this.color});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      height: 180,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 28),
          const Spacer(),
          Text(title, style: theme.textTheme.bodySmall?.copyWith(color: theme.hintColor)),
          const SizedBox(height: 4),
          Text(value, style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold), maxLines: 1, overflow: TextOverflow.ellipsis),
          const SizedBox(height: 2),
          Text(subtitle, style: const TextStyle(fontSize: 10, color: Colors.grey)),
        ],
      ),
    );
  }
}

class LineChartWidget extends StatelessWidget {
  const LineChartWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return LineChart(
      LineChartData(
        gridData: FlGridData(show: false),
        titlesData: FlTitlesData(show: false),
        borderData: FlBorderData(show: false),
        lineBarsData: [
          LineChartBarData(
            spots: const [
              FlSpot(0, 3),
              FlSpot(1, 1),
              FlSpot(2, 4),
              FlSpot(3, 2),
              FlSpot(4, 5),
              FlSpot(5, 3),
            ],
            isCurved: true,
            color: Theme.of(context).colorScheme.primary,
            barWidth: 4,
            isStrokeCapRound: true,
            dotData: FlDotData(show: false),
            belowBarData: BarAreaData(
              show: true,
              color: Theme.of(context).colorScheme.primary.withOpacity(0.2),
            ),
          ),
        ],
      ),
    );
  }
}

class BudgetProgressSection extends StatelessWidget {
  const BudgetProgressSection({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final budgetProvider = Provider.of<BudgetProvider>(context);
    final categoryProvider = Provider.of<CategoryProvider>(context);
    
    final activeBudgets = budgetProvider.budgets.where((b) => b.amount > 0).toList();
    if (activeBudgets.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Budgets',
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        Builder(
          builder: (context) {
            double totalBudget = 0.0;
            double totalSpent = 0.0;
            final now = DateTime.now();

            for (var budget in activeBudgets) {
              totalBudget += budget.amount;
              totalSpent += budgetProvider.getSpentAmount(budget.categoryId, now);
            }

            final totalProgress = totalBudget > 0 ? (totalSpent / totalBudget).clamp(0.0, 1.0) : 0.0;
            final isTotalExceeded = totalSpent > totalBudget;
            final totalRemaining = totalBudget - totalSpent;

            return Container(
              margin: const EdgeInsets.only(bottom: 24),
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    theme.colorScheme.primaryContainer,
                    theme.colorScheme.primary.withOpacity(0.1),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                  color: theme.colorScheme.primary.withOpacity(0.2),
                  width: 1,
                ),
                boxShadow: [
                  BoxShadow(
                    color: theme.colorScheme.primary.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  )
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: theme.colorScheme.primary.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Icon(Icons.account_balance_wallet_rounded, color: theme.colorScheme.primary, size: 20),
                          ),
                          const SizedBox(width: 12),
                          Text(
                            'Monthly Limit',
                            style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                      Text(
                        '৳${totalSpent.toStringAsFixed(0)} / ৳${totalBudget.toStringAsFixed(0)}',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: isTotalExceeded ? Colors.redAccent : theme.colorScheme.primary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: LinearProgressIndicator(
                      value: totalProgress,
                      minHeight: 12,
                      backgroundColor: theme.colorScheme.surfaceContainerHighest,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        isTotalExceeded ? Colors.redAccent : (totalProgress > 0.8 ? Colors.orangeAccent : theme.colorScheme.primary),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '${(totalProgress * 100).toStringAsFixed(1)}% Used',
                        style: theme.textTheme.bodySmall,
                      ),
                      Text(
                        isTotalExceeded ? 'Exceeded by ৳${(-totalRemaining).toStringAsFixed(0)}' : '৳${totalRemaining.toStringAsFixed(0)} remaining',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: isTotalExceeded ? Colors.redAccent : Colors.grey,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
        ),
        ...activeBudgets.map((budget) {
          final category = categoryProvider.expenseCategories.cast<dynamic>().firstWhere(
            (c) => c.id == budget.categoryId, 
            orElse: () => null
          );
          
          if (category == null) return const SizedBox.shrink();

          final spent = budgetProvider.getSpentAmount(budget.categoryId, DateTime.now());
          final remaining = budgetProvider.getRemainingBudget(budget.categoryId, DateTime.now());
          final progress = (spent / budget.amount).clamp(0.0, 1.0);
          final isExceeded = spent > budget.amount;

          return Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: theme.cardColor,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                )
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        CategoryIcon(
                          categoryName: category.name,
                          isExpense: true,
                          size: 18,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          category.name,
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                    Text(
                      '৳${spent.toStringAsFixed(0)} / ৳${budget.amount.toStringAsFixed(0)}',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: isExceeded ? Colors.redAccent : theme.textTheme.bodyMedium?.color,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: LinearProgressIndicator(
                    value: progress,
                    minHeight: 8,
                    backgroundColor: theme.colorScheme.surfaceContainerHighest,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      isExceeded ? Colors.redAccent : (progress > 0.8 ? Colors.orangeAccent : Colors.greenAccent),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  isExceeded ? 'Exceeded by ৳${(-remaining).toStringAsFixed(0)}' : '৳${remaining.toStringAsFixed(0)} left',
                  style: TextStyle(
                    fontSize: 12,
                    color: isExceeded ? Colors.redAccent : Colors.grey,
                  ),
                ),
              ],
            ),
          );
        }),
      ],
    );
  }
}
