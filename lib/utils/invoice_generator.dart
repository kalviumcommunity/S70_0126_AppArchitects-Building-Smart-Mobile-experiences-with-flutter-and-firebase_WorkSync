import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:intl/intl.dart';
import 'package:image_gallery_saver/image_gallery_saver.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/payment.dart';
import '../widgets/translated_text.dart';

class InvoiceGenerator {
  static Future<void> generateAndDownloadInvoice(BuildContext context, Payment payment) async {
    String userName = "User";
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        final userDoc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
        if (userDoc.exists && userDoc.data()!.containsKey('name')) {
          userName = userDoc.data()!['name'];
        } else if (user.displayName != null && user.displayName!.isNotEmpty) {
          userName = user.displayName!;
        }
      }
    } catch (e) {
      print("Error fetching user name: $e");
    }

    final pdf = pw.Document();
    final now = DateTime.now();
    final formattedTimeStamp = DateFormat('MMM dd, yyyy HH:mm:ss').format(now);
    
    final bool isCompleted = payment.status.toLowerCase() == 'completed' || 
                             payment.status.toLowerCase() == 'collected';
    final statusColor = isCompleted ? PdfColors.green : PdfColors.amber800;

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              // Header
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text('WorkSync', style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold, color: PdfColors.blue)),
                      pw.SizedBox(height: 5),
                      pw.Text('Smart Mobile Experiences', style: const pw.TextStyle(fontSize: 14, color: PdfColors.grey700)),
                      pw.SizedBox(height: 5),
                      pw.Text('Issued By: $userName', style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold)),
                    ],
                  ),
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.end,
                    children: [
                      pw.Text('INVOICE', style: pw.TextStyle(fontSize: 32, fontWeight: pw.FontWeight.bold, color: PdfColors.grey300)),
                      pw.Text(formattedTimeStamp, style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey600)),
                    ],
                  ),
                ],
              ),
              pw.SizedBox(height: 40),
              
              // Invoice details
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text('Bill To:', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, color: PdfColors.grey700)),
                      pw.SizedBox(height: 5),
                      pw.Text(payment.clientName, style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold)),
                    ],
                  ),
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.end,
                    children: [
                      pw.Text('Invoice Date:', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, color: PdfColors.grey700)),
                      pw.Text(DateFormat('MMM dd, yyyy').format(payment.createdAt)),
                      pw.SizedBox(height: 10),
                      pw.Text('Payment Status:', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, color: PdfColors.grey700)),
                      pw.Text(payment.status.toUpperCase(), style: pw.TextStyle(color: statusColor, fontWeight: pw.FontWeight.bold)),
                    ],
                  ),
                ],
              ),
              pw.SizedBox(height: 40),

              // Table Header
              pw.Container(
                decoration: pw.BoxDecoration(
                  color: PdfColors.blue50,
                  borderRadius: const pw.BorderRadius.all(pw.Radius.circular(4)),
                ),
                padding: const pw.EdgeInsets.all(12),
                child: pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text('Description', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, color: PdfColors.blue900)),
                    pw.Text('Amount', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, color: PdfColors.blue900)),
                  ],
                ),
              ),
              pw.SizedBox(height: 10),

              // Table Body
              pw.Padding(
                padding: const pw.EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                child: pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text('Services Rendered', style: const pw.TextStyle(fontSize: 14)),
                    pw.Text('INR ${payment.amount.toStringAsFixed(2)}', style: const pw.TextStyle(fontSize: 14)),
                  ],
                ),
              ),
              pw.Divider(color: PdfColors.grey300),
              
              pw.SizedBox(height: 20),

              // Total
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.end,
                children: [
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.end,
                    children: [
                      pw.Text('Total Due', style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold)),
                      pw.SizedBox(height: 5),
                      pw.Text('INR ${payment.amount.toStringAsFixed(2)}', style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold, color: statusColor)),
                    ],
                  ),
                ],
              ),
              pw.SizedBox(height: 60),

              // Footer
              pw.Center(
                child: pw.Text(
                  'Thank you for your business!',
                  style: pw.TextStyle(color: PdfColors.grey600, fontStyle: pw.FontStyle.italic),
                ),
              ),
            ],
          );
        },
      ),
    );

    // Option Dialog
    if (!context.mounted) return;
    showDialog(
      context: context,
      builder: (BuildContext ctx) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const TranslatedText('Download Invoice'),
          content: const TranslatedText('Do you want to preview/save as PDF or save directly to Camera Roll as an Image?'),
          actionsPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          actions: [
            OutlinedButton.icon(
              onPressed: () {
                Navigator.of(ctx).pop();
                _saveAsPdf(context, pdf, payment);
              },
              icon: const Icon(Icons.picture_as_pdf_outlined, size: 18),
              label: const TranslatedText('PDF'),
              style: OutlinedButton.styleFrom(
                foregroundColor: const Color(0xFF1A73E8),
                side: const BorderSide(color: Color(0xFF1A73E8)),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
            ),
            ElevatedButton.icon(
              onPressed: () {
                Navigator.of(ctx).pop();
                _saveToGallery(context, pdf, payment);
              },
              icon: const Icon(Icons.image_outlined, size: 18),
              label: const TranslatedText('Image'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF0F9D58),
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
            ),
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const TranslatedText('Cancel', style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold)),
            ),
          ],
        );
      },
    );
  }

  static Future<void> _saveAsPdf(BuildContext context, pw.Document pdf, Payment payment) async {
    try {
      await Printing.layoutPdf(
        onLayout: (PdfPageFormat format) async => pdf.save(),
        name: 'Invoice_${payment.clientName.replaceAll(' ', '_')}_${DateFormat('yyyyMMdd').format(payment.createdAt)}.pdf',
      );
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Invoice downloaded successfully!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to download invoice: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  static Future<void> _saveToGallery(BuildContext context, pw.Document pdf, Payment payment) async {
    // Request permission first, but skip on Web platform
    if (!kIsWeb) {
      final status = await Permission.storage.request();
      if (!status.isGranted) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Storage permission is required to save to Gallery')),
          );
        }
        // Continue anyway, image_gallery_saver handles some permissions internally on newer OSes
      }
    }

    try {
      // Rasterize the PDF
      final pdfBytes = await pdf.save();
      final stream = Printing.raster(pdfBytes, pages: [0], dpi: 300);
      
      PdfRaster? raster;
      await stream.forEach((element) {
        raster = element;
      });

      if (raster != null) {
        final imageBytes = await raster!.toPng();
        final result = await ImageGallerySaver.saveImage(
            Uint8List.fromList(imageBytes),
            quality: 100,
            name: 'Invoice_${payment.clientName.replaceAll(' ', '_')}_${DateFormat('yyyyMMdd').format(payment.createdAt)}');
            
        if (context.mounted) {
          if (result != null && result['isSuccess'] == true) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Invoice saved to Camera Roll successfully!'),
                backgroundColor: Colors.green,
              ),
            );
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Failed to save invoice to Camera Roll'),
                backgroundColor: Colors.red,
              ),
            );
          }
        }
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error saving to Camera Roll: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}
