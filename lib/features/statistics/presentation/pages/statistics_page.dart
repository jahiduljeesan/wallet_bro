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
    final categoryAnalytics = provider.getCategoryAnalytics(_selectedPeriod!);
    final periodicData = provider.getPeriodicIncomeAndExpense(_selectedPeriod!);
    
    final sortedPeriodicEntries = periodicData.entries.toList()..sort((a,b) => a.key.compareTo(b.key));
    
    // Check if we have enough data to draw the line chart
    final hasEnoughTrendData = sortedPeriodicEntries.length >= 2;

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
                    // Income vs Expense Trend Chart
                    if (hasEnoughTrendData) ...[
                      Text(
                        'Income vs Expense Trend',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),
                      SizedBox(
                        height: 200,
                        child: LineChart(
                          LineChartData(
                            gridData: const FlGridData(show: false),
                            titlesData: FlTitlesData(
                              show: true,
                              bottomTitles: AxisTitles(
                                sideTitles: SideTitles(
                                  showTitles: true,
                                  getTitlesWidget: (value, meta) {
                                    if (provider.currentFilter == FilterPeriod.year) {
                                      const months = ['Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'];
                                      if (value >= 1 && value <= 12) {
                                        return Padding(
                                          padding: const EdgeInsets.only(top: 8.0),
                                          child: Text(months[value.toInt() - 1], style: const TextStyle(fontSize: 10)),
                                        );
                                      }
                                      return const SizedBox.shrink();
                                    } else if (provider.currentFilter == FilterPeriod.week) {
                                      const days = ['Mon','Tue','Wed','Thu','Fri','Sat','Sun'];
                                      if (value >= 1 && value <= 7) {
                                        return Padding(
                                          padding: const EdgeInsets.only(top: 8.0),
                                          child: Text(days[value.toInt() - 1], style: const TextStyle(fontSize: 10)),
                                        );
                                      }
                                      return const SizedBox.shrink();
                                    } else {
                                      if (value % 5 != 0 && value != 1 && value != provider.getDaysInPeriod(_selectedPeriod!)) {
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
                            borderData: FlBorderData(show: false),
                            lineBarsData: [
                              LineChartBarData(
                                spots: sortedPeriodicEntries
                                    .map((e) => FlSpot(e.key.toDouble(), e.value['income']!))
                                    .toList(),
                                isCurved: true,
                                color: Colors.greenAccent,
                                barWidth: 3,
                                dotData: const FlDotData(show: false),
                                belowBarData: BarAreaData(
                                  show: true,
                                  color: Colors.greenAccent.withValues(alpha: 0.1),
                                ),
                              ),
                              LineChartBarData(
                                spots: sortedPeriodicEntries
                                    .map((e) => FlSpot(e.key.toDouble(), e.value['expense']!))
                                    .toList(),
                                isCurved: true,
                                color: Colors.redAccent,
                                barWidth: 3,
                                dotData: const FlDotData(show: false),
                                belowBarData: BarAreaData(
                                  show: true,
                                  color: Colors.redAccent.withValues(alpha: 0.1),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(width: 12, height: 12, color: Colors.greenAccent),
                          const SizedBox(width: 4),
                          const Text('Income', style: TextStyle(fontSize: 12)),
                          const SizedBox(width: 16),
                          Container(width: 12, height: 12, color: Colors.redAccent),
                          const SizedBox(width: 4),
                          const Text('Expense', style: TextStyle(fontSize: 12)),
                        ],
                      ),
                      const SizedBox(height: 32),
                    ],

                    // Expense Breakdown Donut Chart
                    if (categoryAnalytics.isNotEmpty) ...[
                      Text(
                        'Expense Breakdown',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),
                      SizedBox(
                        height: 200,
                        child: PieChart(
                          PieChartData(
                            sectionsSpace: 2,
                            centerSpaceRadius: 60,
                            sections: categoryAnalytics.map((e) {
                              final i = categoryAnalytics.indexOf(e);
                              final colors = [
                                Colors.redAccent,
                                Colors.blueAccent,
                                Colors.orangeAccent,
                                Colors.purpleAccent,
                                Colors.tealAccent,
                                Colors.amberAccent,
                                Colors.pinkAccent,
                                Colors.cyanAccent,
                              ];
                              final color = colors[i % colors.length];
                              return PieChartSectionData(
                                color: color,
                                value: e['total'],
                                title: "${(e['percentage'] as double).toStringAsFixed(0)}%",
                                radius: 40,
                                titleStyle: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              );
                            }).toList(),
                          ),
                        ),
                      ),
                      const SizedBox(height: 32),

                      // Category Analysis
                      Text(
                        'Category Analysis',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),
                      ...categoryAnalytics.map((e) {
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 16.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              ListTile(
                                contentPadding: EdgeInsets.zero,
                                leading: CircleAvatar(
                                  backgroundColor: Colors.redAccent.withValues(alpha: 0.1),
                                  child: CategoryIcon(
                                    categoryName: e['category'],
                                    isExpense: true,
                                    size: 20,
                                  ),
                                ),
                                title: Text(
                                  e['category'],
                                  style: const TextStyle(fontWeight: FontWeight.bold),
                                ),
                                subtitle: Text(
                                  "Daily Avg: ৳${(e['daily_average'] as double).toStringAsFixed(0)}",
                                ),
                                trailing: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    Text(
                                      '৳${(e['total'] as double).toStringAsFixed(0)}',
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: Colors.redAccent,
                                        fontSize: 16,
                                      ),
                                    ),
                                    Text(
                                      '${(e['percentage'] as double).toStringAsFixed(1)}%',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: theme.textTheme.bodySmall?.color,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              LinearProgressIndicator(
                                value: (e['percentage'] as double) / 100,
                                backgroundColor: Colors.redAccent.withValues(alpha: 0.1),
                                color: Colors.redAccent,
                                minHeight: 6,
                                borderRadius: BorderRadius.circular(3),
                              ),
                            ],
                          ),
                        );
                      }),
                    ],
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
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            CircleAvatar(
              backgroundColor: color.withValues(alpha: 0.1),
              radius: 20,
              child: Icon(icon, color: color),
            ),
            const SizedBox(height: 12),
            Text(
              title,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.textTheme.bodyMedium?.color?.withValues(alpha: 0.7),
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
