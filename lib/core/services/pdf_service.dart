import 'dart:typed_data';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:intl/intl.dart';
import 'hive_service.dart';

class PDFService {
  static Future<Uint8List> generateReport(String title) async {
    final pdf = pw.Document();

    final transactions = HiveService.transactionsBox.values.toList()
      ..sort((a, b) => b.timestamp.compareTo(a.timestamp));
      
    final totalIncome = transactions.where((t) => !t.isExpense).fold(0.0, (sum, t) => sum + t.amount);
    final totalExpense = transactions.where((t) => t.isExpense).fold(0.0, (sum, t) => sum + t.amount);

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        build: (pw.Context context) {
          return [
            pw.Header(
              level: 0,
              child: pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text('ExpenseBuddy Report', style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold)),
                  pw.Text(DateFormat('MMM dd, yyyy').format(DateTime.now())),
                ],
              ),
            ),
            pw.SizedBox(height: 20),
            
            // Summary Section
            pw.Container(
              padding: const pw.EdgeInsets.all(16),
              decoration: pw.BoxDecoration(
                border: pw.Border.all(color: PdfColors.grey300),
                borderRadius: const pw.BorderRadius.all(pw.Radius.circular(8)),
                color: PdfColors.grey100,
              ),
              child: pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceAround,
                children: [
                  pw.Column(
                    children: [
                      pw.Text('Total Income', style: const pw.TextStyle(color: PdfColors.green)),
                      pw.Text('Tk${totalIncome.toStringAsFixed(2)}', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 16)),
                    ]
                  ),
                  pw.Column(
                    children: [
                      pw.Text('Total Expense', style: const pw.TextStyle(color: PdfColors.red)),
                      pw.Text('Tk${totalExpense.toStringAsFixed(2)}', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 16)),
                    ]
                  ),
                  pw.Column(
                    children: [
                      pw.Text('Net Balance'),
                      pw.Text('Tk${(totalIncome - totalExpense).toStringAsFixed(2)}', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 16)),
                    ]
                  ),
                ],
              ),
            ),
            pw.SizedBox(height: 20),
            
            pw.Text('Recent Transactions', style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold)),
            pw.Divider(),
            pw.SizedBox(height: 10),
            
            pw.Table.fromTextArray(
              context: context,
              headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold, color: PdfColors.white),
              headerDecoration: const pw.BoxDecoration(color: PdfColors.blueGrey800),
              cellAlignment: pw.Alignment.centerLeft,
              data: [
                ['Date', 'Category', 'Type', 'Note', 'Amount'],
                ...transactions.take(100).map((tx) => [
                      DateFormat('MMM dd, yyyy').format(tx.timestamp),
                      tx.category,
                      tx.isExpense ? 'Expense' : 'Income',
                      tx.note,
                      'Tk${tx.amount.toStringAsFixed(2)}'
                    ]),
              ],
            ),
          ];
        },
      ),
    );

    return pdf.save();
  }
}
