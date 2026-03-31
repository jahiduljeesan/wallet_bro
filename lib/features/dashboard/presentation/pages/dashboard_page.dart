import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:intl/intl.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../providers/dashboard_provider.dart';

import '../../../transactions/presentation/pages/add_transaction_sheet.dart';

class DashboardPage extends StatelessWidget {
  const DashboardPage({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final provider = Provider.of<DashboardProvider>(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(title: const Text('Dashboard'), elevation: 0),
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
                      
                      // Quick Insight Card
                      Expanded(
                        flex: 2,
                        child: InsightCard(
                          title: 'Top Category',
                          value: provider.topCategory,
                          subtitle: 'Most spent this month',
                          icon: Icons.stars_rounded,
                          color: Colors.orangeAccent,
                        ),
                      ),
                    ],
                  ),
                ],
              ).animate().fadeIn(duration: 800.ms).slideY(begin: 0.1, end: 0, curve: Curves.easeOutCubic),
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
          SliverList(
            delegate: SliverChildBuilderDelegate(
              (context, index) {
                if (provider.transactions.isEmpty) {
                  return const Padding(
                    padding: EdgeInsets.all(32.0),
                    child: Center(
                      child: Text('No transactions yet. Start adding!'),
                    ),
                  );
                }

                final tx = provider.transactions[index];
                return Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16.0,
                    vertical: 4.0,
                  ),
                  child: Card(
                    elevation: 0,
                    color: theme.colorScheme.surface,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: ListTile(
                      leading: CircleAvatar(
                        backgroundColor: tx.isExpense
                            ? Colors.redAccent.withOpacity(0.1)
                            : Colors.greenAccent.withOpacity(0.1),
                        child: Icon(
                          tx.isExpense
                              ? Icons.arrow_outward_rounded
                              : Icons.arrow_downward_rounded,
                          color: tx.isExpense ? Colors.redAccent : Colors.green,
                        ),
                      ),
                      title: Text(
                        tx.category,
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      subtitle: Text(
                        tx.note.isNotEmpty
                            ? tx.note
                            : tx.timestamp.toString().substring(0, 10),
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
                ).animate(delay: (index * 50).ms).fadeIn().slideX(begin: 0.2, end: 0);
              },
              childCount: provider.transactions.isEmpty
                  ? 1
                  : provider.transactions.length,
            ),
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
            'Total Balance',
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
  const SpendingBarChart({Key? key, required this.data}) : super(key: key);

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
  const CategoryPieChart({Key? key, required this.data}) : super(key: key);

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
                          title: '',
                          radius: 35,
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

  const InsightCard({Key? key, required this.title, required this.value, required this.subtitle, required this.icon, required this.color}) : super(key: key);

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
