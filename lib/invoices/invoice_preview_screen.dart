import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:printing/printing.dart';

import 'invoice_theme_renderer.dart';

class InvoicePreviewScreen extends StatefulWidget {
  const InvoicePreviewScreen({
    super.key,
    required this.data,
  });

  final InvoicePrintData data;

  @override
  State<InvoicePreviewScreen> createState() => _InvoicePreviewScreenState();
}

class _InvoicePreviewScreenState extends State<InvoicePreviewScreen> {
  double _zoom = 1.0;

  Future<void> _downloadPdf(BuildContext context) async {
    final pdfBytes = await InvoiceThemeRenderer.buildPdf(widget.data);
    final filename = 'invoice-${widget.data.billNo}.pdf';

    if (kIsWeb) {
      await Printing.sharePdf(bytes: pdfBytes, filename: filename);
      return;
    }

    final outputPath = await FilePicker.platform.saveFile(
      dialogTitle: 'Save Invoice',
      fileName: filename,
      type: FileType.custom,
      allowedExtensions: ['pdf'],
    );

    if (outputPath == null) return;

    final file = File(outputPath);
    await file.writeAsBytes(pdfBytes, flush: true);
  }

  void _zoomIn() {
    setState(() {
      _zoom = (_zoom + 0.2).clamp(0.5, 3.0);
    });
  }

  void _zoomOut() {
    setState(() {
      _zoom = (_zoom - 0.2).clamp(0.5, 3.0);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Invoice Preview'),
        actions: [
          IconButton(
            icon: const Icon(Icons.zoom_out),
            tooltip: 'Zoom Out',
            onPressed: _zoomOut,
          ),
          IconButton(
            icon: const Icon(Icons.zoom_in),
            tooltip: 'Zoom In',
            onPressed: _zoomIn,
          ),
          IconButton(
            icon: const Icon(Icons.download),
            tooltip: 'Download PDF',
            onPressed: () => _downloadPdf(context),
          ),
        ],
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final baseWidth = constraints.maxWidth.clamp(400.0, 900.0);
          return PdfPreview(
            canChangePageFormat: false,
            canChangeOrientation: false,
            canDebug: false,
            allowPrinting: false,
            allowSharing: false,
            maxPageWidth: baseWidth * _zoom,
            pdfFileName: 'invoice-${widget.data.billNo}.pdf',
            build: (format) => InvoiceThemeRenderer.buildPdf(widget.data),
          );
        },
      ),
    );
  }
}

