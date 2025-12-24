import 'dart:io';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

class ReceiptService {
  static Future<void> generateReceipt({
    required String spotId,
    required DateTime startTime,
    required DateTime endTime,
    required double ratePerHour,
  }) async {
    final pdf = pw.Document();
    final duration = endTime.difference(startTime);
    final hours = duration.inMinutes / 60.0;
    final totalAmount = hours * ratePerHour;

    pdf.addPage(
      pw.Page(
        build: (pw.Context context) => pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text("PARK30 OFFICIAL RECEIPT", style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold)),
            pw.Divider(),
            pw.Text("Spot ID: $spotId"),
            pw.Text("Start Time: ${startTime.toString()}"),
            pw.Text("End Time: ${endTime.toString()}"),
            pw.SizedBox(height: 10),
            pw.Text("Total Stay: ${duration.inHours}h ${duration.inMinutes % 60}m"),
            pw.Text("Rate: \$${ratePerHour.toStringAsFixed(2)} / hour"),
            pw.Divider(),
            pw.Text("TOTAL AMOUNT: \$${totalAmount.toStringAsFixed(2)}", style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold)),
            pw.SizedBox(height: 20),
            pw.Text("Thank you for parking with PARK30!"),
          ],
        ),
      ),
    );

    await Printing.layoutPdf(onLayout: (PdfPageFormat format) async => pdf.save());
  }
}