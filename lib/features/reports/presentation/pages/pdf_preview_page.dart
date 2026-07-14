import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:printing/printing.dart';

class PDFPreviewPage extends StatelessWidget {
  final Future<Uint8List> pdfFuture;
  final String title;

  const PDFPreviewPage({super.key, required this.pdfFuture, required this.title});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(title),
      ),
      body: FutureBuilder<Uint8List>(
        future: pdfFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error generating PDF: ${snapshot.error}'));
          }
          if (snapshot.hasData) {
            return PdfPreview(
              build: (format) => snapshot.data!,
              canChangeOrientation: false,
              canChangePageFormat: false,
              canDebug: false,
            );
          }
          return const Center(child: Text('Unknown error'));
        },
      ),
    );
  }
}
