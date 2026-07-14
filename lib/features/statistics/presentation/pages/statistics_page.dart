import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/statistics_provider.dart';
import 'package:intl/intl.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../../categories/presentation/widgets/category_icon.dart';

class StatisticsPage extends StatelessWidget {
  const StatisticsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => StatisticsProvider(),
      child: const StatisticsView(),
    );
  }
}

class StatisticsView extends StatefulWidget {
  const StatisticsView({super.key});

  @override
  State<StatisticsView> createState() => _StatisticsViewState();
}

class _StatisticsViewState extends State<StatisticsView> {
  String? _selectedPeriod;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = Provider.of<StatisticsProvider>(context, listen: false);
      if (provider.availablePeriods.isNotEmpty) {
        setState(() {
          _selectedPeriod = provider.availablePeriods.first;
        });
      }
    });
  }

  String _formatPeriodHeader(String period, FilterPeriod filter) {
    try {
      if (filter == FilterPeriod.year) {
        return period; // e.g. "2023"
      } else if (filter == FilterPeriod.week) {
        return period.replaceAll('-W', ' Week '); // e.g. "2023 Week 41"
      } else {
        final parts = period.split('-');
        final dt = DateTime(int.parse(parts[0]), int.parse(parts[1]));
        return DateFormat('MMM yyyy').format(dt);
      }
    } catch (e) {
      return period;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final provider = Provider.of<StatisticsProvider>(context);
    final periods = provider.availablePeriods;

    if (_selectedPeriod == null && periods.isNotEmpty) {
      _selectedPeriod = periods.first;
    } else if (periods.isNotEmpty && !periods.contains(_selectedPeriod)) {
      _selectedPeriod = periods.first;
    }

    if (periods.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: const Text('Statistics')),
        body: const Center(child: Text('Add transactions to see statistics.')),
      );
    }

    final currentSummary = provider.getSummaryForPeriod(_selectedPeriod!);
    final currentTxs = provider.getTransactionsForPeriod(_selectedPeriod!);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(title: const Text('Statistics'), elevation: 0),
      body: CustomScrollView(
        slivers: [
          // Filter Period Toggle
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
              child: SegmentedButton<FilterPeriod>(
                segments: const [
                  ButtonSegment(value: FilterPeriod.week, label: Text('Week')),
                  ButtonSegment(value: FilterPeriod.month, label: Text('Month')),
                  ButtonSegment(value: FilterPeriod.year, label: Text('Year')),
                ],
                selected: {provider.currentFilter},
                onSelectionChanged: (Set<FilterPeriod> newSelection) {
                  provider.setFilter(newSelection.first);
                  setState(() {
                    _selectedPeriod = null; // Will auto-select first available
                  });
                },
              ),
            ),
          ),

          // Period Selector
          SliverToBoxAdapter(
            child: SizedBox(
              height: 60,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: periods.length,
                itemBuilder: (context, index) {
                  final periodStr = periods[index];
                  final isSelected = _selectedPeriod == periodStr;
                  return Padding(
                    padding: const EdgeInsets.only(right: 8.0),
                    child: ChoiceChip(
                      label: Text(_formatPeriodHeader(periodStr, provider.currentFilter)),
                      selected: isSelected,
                      onSelected: (val) {
                        setState(() {
                          _selectedPeriod = periodStr;
                        });
                      },
                      selectedColor: theme.colorScheme.primary,
                      labelStyle: TextStyle(
                        color: isSelected
                            ? Colors.white
                            : theme.textTheme.bodyMedium?.color,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  );
                },
              ),
            ),
          ),

          // Summary Cards
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: _SummaryCard(
                          title: 'Income',
                          amount: currentSummary['income'] ?? 0,
                          color: Colors.green,
                          icon: Icons.arrow_downward_rounded,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _SummaryCard(
                          title: 'Expense',
                          amount: currentSummary['expense'] ?? 0,
                          color: Colors.redAccent,
                          icon: Icons.arrow_outward_rounded,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: _SummaryCard(
                          title: 'Net Balance',
                          amount: currentSummary['net'] ?? 0,
                          color: (currentSummary['net'] ?? 0) >= 0 ? Colors.blue : Colors.orange,
                          icon: Icons.account_balance_wallet,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          // Analytics Title
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 16.0,
                vertical: 8.0,
              ),
              child: Text(
                'Insights & Analytics',
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),

          // Advanced Analytics View
          if (currentSummary['income']! > 0 || currentSummary['expense']! > 0)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Income vs Expense Pie Chart
                    Text(
                      'Income vs Expense',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      height: 200,
                      child: PieChart(
                        PieChartData(
                          sectionsSpace: 4,
                          centerSpaceRadius: 40,
                          sections: [
                            if (currentSummary['income']! > 0)
                              PieChartSectionData(
                                color: Colors.greenAccent,
                                value: currentSummary['income']!,
                                title:
                                    "${((currentSummary['income']! / (currentSummary['income']! + currentSummary['expense']!)) * 100).toStringAsFixed(0)}%",
                                radius: 50,
                                titleStyle: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                            if (currentSummary['expense']! > 0)
                              PieChartSectionData(
                                color: Colors.redAccent,
                                value: currentSummary['expense']!,
                                title:
                                    "${((currentSummary['expense']! / (currentSummary['income']! + currentSummary['expense']!)) * 100).toStringAsFixed(0)}%",
                                radius: 50,
                                titleStyle: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 32),

                    // Daily Expenses Chart
                    Text(
                      provider.currentFilter == FilterPeriod.year ? 'Monthly Expenses' : (provider.currentFilter == FilterPeriod.week ? 'Daily Expenses (Week)' : 'Daily Expenses'),
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      height: 180,
                      child: BarChart(
                        BarChartData(
                          alignment: BarChartAlignment.spaceAround,
                          maxY:
                              (provider
                                  .getPeriodicExpenses(_selectedPeriod!)
                                  .values
                                  .fold<double>(0.0, (m, v) => m > v ? m : v)) *
                              1.2,
                          barTouchData: BarTouchData(enabled: false),
                          titlesData: FlTitlesData(
                            show: true,
                            bottomTitles: AxisTitles(
                              sideTitles: SideTitles(
                                showTitles: true,
                                getTitlesWidget: (value, meta) {
                                  if (provider.currentFilter == FilterPeriod.year) {
                                    // Months: 1=Jan, etc
                                    const months = ['Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'];
                                    if (value >= 1 && value <= 12) {
                                      return Padding(
                                        padding: const EdgeInsets.only(top: 8.0),
                                        child: Text(months[value.toInt() - 1], style: const TextStyle(fontSize: 10)),
                                      );
                                    }
                                    return const SizedBox.shrink();
                                  } else if (provider.currentFilter == FilterPeriod.week) {
                                    // Weekdays: 1=Mon, 7=Sun
                                    const days = ['Mon','Tue','Wed','Thu','Fri','Sat','Sun'];
                                    if (value >= 1 && value <= 7) {
                                      return Padding(
                                        padding: const EdgeInsets.only(top: 8.0),
                                        child: Text(days[value.toInt() - 1], style: const TextStyle(fontSize: 10)),
                                      );
                                    }
                                    return const SizedBox.shrink();
                                  } else {
                                    if (value % 5 != 0 && value != 1) {
                                      return const SizedBox.shrink();
                                    }
                                    return Padding(
                                      padding: const EdgeInsets.only(top: 8.0),
                                      child: Text(
                                        value.toInt().toString(),
                                        style: const TextStyle(fontSize: 10),
                                      ),
                                    );
                                  }
                                },
                              ),
                            ),
                            leftTitles: const AxisTitles(
                              sideTitles: SideTitles(showTitles: false),
                            ),
                            topTitles: const AxisTitles(
                              sideTitles: SideTitles(showTitles: false),
                            ),
                            rightTitles: const AxisTitles(
                              sideTitles: SideTitles(showTitles: false),
                            ),
                          ),
                          gridData: const FlGridData(show: false),
                          borderData: FlBorderData(show: false),
                          barGroups: provider
                              .getPeriodicExpenses(_selectedPeriod!)
                              .entries
                              .map((e) {
                                return BarChartGroupData(
                                  x: e.key,
                                  barRods: [
                                    BarChartRodData(
                                      toY: e.value,
                                      color: Colors.redAccent,
                                      width: 8,
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                  ],
                                );
                              })
                              .toList(),
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Top Categories
                    Text(
                      'Top Expense Categories',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    ...provider
                        .getTopCategories(_selectedPeriod!, isExpense: true)
                        .take(3)
                        .map((e) {
                          return ListTile(
                            contentPadding: EdgeInsets.zero,
                            leading: CircleAvatar(
                              backgroundColor: Colors.redAccent.withOpacity(
                                0.1,
                              ),
                              child: CategoryIcon(
                                categoryName: e.key,
                                isExpense: true,
                                size: 20,
                              ),
                            ),
                            title: Text(e.key),
                            trailing: Text(
                              '৳${e.value.toStringAsFixed(0)}',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Colors.redAccent,
                              ),
                            ),
                          );
                        }),
                  ],
                ),
              ),
            )
          else
            const SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.all(32.0),
                child: Center(child: Text("No data for analytics")),
              ),
            ),

          // Transactions List Title
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 16.0,
                vertical: 8.0,
              ).copyWith(top: 24),
              child: Text(
                'Transactions in ${_formatPeriodHeader(_selectedPeriod!, provider.currentFilter)}',
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),

          // Transactions List
          SliverList(
            delegate: SliverChildBuilderDelegate((context, index) {
              final tx = currentTxs[index];
              final dateStr = DateFormat(
                'MMM d, y h:mm a',
              ).format(tx.timestamp);

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
                    subtitle: Text(tx.note.isNotEmpty ? tx.note : dateStr),
                    trailing: Text(
                      "${tx.isExpense ? '-' : '+'}৳${tx.amount.toStringAsFixed(0)}",
                      style: TextStyle(
                        color: tx.isExpense ? Colors.redAccent : Colors.green,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ),
                ),
              );
            }, childCount: currentTxs.length),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 80)),
        ],
      ),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  final String title;
  final double amount;
  final Color color;
  final IconData icon;

  const _SummaryCard({
    required this.title,
    required this.amount,
    required this.color,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            CircleAvatar(
              backgroundColor: color.withOpacity(0.1),
              radius: 20,
              child: Icon(icon, color: color),
            ),
            const SizedBox(height: 12),
            Text(
              title,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.textTheme.bodyMedium?.color?.withOpacity(0.7),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              '৳${amount.toStringAsFixed(0)}',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
