import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/statistics_provider.dart';
import 'package:intl/intl.dart';
import 'package:fl_chart/fl_chart.dart';

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
  String? _selectedMonth;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = Provider.of<StatisticsProvider>(context, listen: false);
      if (provider.availableMonths.isNotEmpty) {
        setState(() {
          _selectedMonth = provider.availableMonths.first;
        });
      }
    });
  }

  String _formatMonthHeader(String yearMonth) {
    try {
      final parts = yearMonth.split('-');
      final dt = DateTime(int.parse(parts[0]), int.parse(parts[1]));
      return DateFormat('MMMM yyyy').format(dt);
    } catch (e) {
      return yearMonth;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final provider = Provider.of<StatisticsProvider>(context);
    final months = provider.availableMonths;

    if (_selectedMonth == null && months.isNotEmpty) {
      _selectedMonth = months.first;
    }

    if (months.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: const Text('Statistics')),
        body: const Center(child: Text('Add transactions to see statistics.')),
      );
    }

    final currentSummary = provider.getSummaryForMonth(_selectedMonth!);
    final currentTxs = provider.getTransactionsForMonth(_selectedMonth!);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('Statistics'),
        elevation: 0,
      ),
      body: CustomScrollView(
        slivers: [
          // Month Selector
          SliverToBoxAdapter(
            child: SizedBox(
              height: 60,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: months.length,
                itemBuilder: (context, index) {
                  final monthStr = months[index];
                  final isSelected = _selectedMonth == monthStr;
                  return Padding(
                    padding: const EdgeInsets.only(right: 8.0),
                    child: ChoiceChip(
                      label: Text(_formatMonthHeader(monthStr)),
                      selected: isSelected,
                      onSelected: (val) {
                        setState(() {
                          _selectedMonth = monthStr;
                        });
                      },
                      selectedColor: theme.colorScheme.primary,
                      labelStyle: TextStyle(
                        color: isSelected ? Colors.white : theme.textTheme.bodyMedium?.color,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
          
          // Monthly Summary Cards
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
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
            ),
          ),
          
          // Category Breakdown Title
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
              child: Text(
                'Income vs Expense',
                style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
              ),
            ),
          ),
          
          // Basic Pie Chart
          if (currentSummary['income']! > 0 || currentSummary['expense']! > 0)
            SliverToBoxAdapter(
              child: SizedBox(
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
                          title: "${((currentSummary['income']! / (currentSummary['income']! + currentSummary['expense']!)) * 100).toStringAsFixed(0)}%",
                          radius: 50,
                          titleStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.white),
                        ),
                      if (currentSummary['expense']! > 0)
                        PieChartSectionData(
                          color: Colors.redAccent,
                          value: currentSummary['expense']!,
                          title: "${((currentSummary['expense']! / (currentSummary['income']! + currentSummary['expense']!)) * 100).toStringAsFixed(0)}%",
                          radius: 50,
                          titleStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.white),
                        ),
                    ],
                  ),
                ),
              ),
            )
          else
            const SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.all(32.0),
                child: Center(child: Text("No data for chart")),
              ),
            ),
          
          // Transactions List Title
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0).copyWith(top: 24),
              child: Text(
                'Transactions in ${_formatMonthHeader(_selectedMonth!)}',
                style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
              ),
            ),
          ),
          
          // Transactions List
          SliverList(
            delegate: SliverChildBuilderDelegate(
              (context, index) {
                final tx = currentTxs[index];
                final dateStr = DateFormat('MMM d, y h:mm a').format(tx.timestamp);
                
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 4.0),
                  child: Card(
                    elevation: 0,
                    color: theme.colorScheme.surface,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    child: ListTile(
                      leading: CircleAvatar(
                        backgroundColor: tx.isExpense ? Colors.redAccent.withOpacity(0.1) : Colors.greenAccent.withOpacity(0.1),
                        child: Icon(
                          tx.isExpense ? Icons.arrow_outward_rounded : Icons.arrow_downward_rounded,
                          color: tx.isExpense ? Colors.redAccent : Colors.green,
                        ),
                      ),
                      title: Text(tx.category, style: const TextStyle(fontWeight: FontWeight.bold)),
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
              },
              childCount: currentTxs.length,
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
            Text(title, style: theme.textTheme.bodyMedium?.copyWith(color: theme.textTheme.bodyMedium?.color?.withOpacity(0.7))),
            const SizedBox(height: 4),
            Text(
              '৳${amount.toStringAsFixed(0)}',
              style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
    );
  }
}
