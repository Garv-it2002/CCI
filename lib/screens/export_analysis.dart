import 'package:excel/excel.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';

class ExportAnalysis {
  Future<void> exportTablesToExcel(List<Map<String, dynamic>> products, Map<String, double> totalSales, Map<String, double> totalPurchase, Map<String, double> stockLeft) async {
    // Create an Excel document
    final Excel excel = Excel.createExcel();

    // Create a sheet for the tables
    final Sheet sheet = excel['Sheet1'];

    // Add headers to the tables
    sheet.appendRow(['Product Name', 'Total Sales', 'Total Purchase', 'Stock Left']);

    // Add data to the tables
    for (var product in products) {
      String productName = product['name'] as String;
      String productName1 = '[${productName.replaceAll(' ', '_')}]';
      sheet.appendRow([productName, totalSales[productName1] ?? 0, totalPurchase[productName1] ?? 0, stockLeft[productName1] ?? 0]);
    }

    // Get the directory path to save the file
    Directory appDocumentsDirectory = await getApplicationDocumentsDirectory();
    String appDocumentsPath = appDocumentsDirectory.path;

    // Define the file path with today's date
    String todayDate = DateTime.now().toString().split(' ')[0];
    String filePath = '$appDocumentsPath/analysis_$todayDate.xlsx';

    // Save the Excel file
    final File file = File(filePath);
    await file.writeAsBytes(excel.encode()!);
  }
}
