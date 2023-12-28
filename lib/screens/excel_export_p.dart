// ignore_for_file: await_only_futures, avoid_function_literals_in_foreach_calls

import 'dart:io';
import 'package:excel/excel.dart';
import 'package:path_provider/path_provider.dart';
import 'package:intl/intl.dart';

Future<void> exportPurchaseDataToExcel(List<Map<String, dynamic>> purchaseData, List<String> productNames) async {
  if (purchaseData.isEmpty || productNames.isEmpty) {
    return; // No data to export
  }
  Excel excel = Excel.createExcel();
  Sheet sheetObject = excel['Sheet1']; // Create a new sheet
  // Add headers for columns
  sheetObject.appendRow(['Serial', 'Invoice', 'Date', ...productNames]);
  // Add data rows
  purchaseData.forEach((data) {
    List<dynamic> rowData = [
      num.tryParse(data['serial']?.toString() ?? '0') ?? 0, // Convert serial to number, export null as '0'
      num.tryParse(data['invoice']),
      data['date'] is DateTime ? DateFormat('yyyy-MM-dd').format(data['date']) : data['date'].toString(), // Date format if it's a DateTime object
      for (var productName in productNames)
        data[productName.replaceAll(' ', '_')] != null
            ? num.tryParse(data[productName.replaceAll(' ', '_')].toString()) ?? 0 // Convert to number if not null, else default to '0'
            : 0, // Export null values as '0'
    ];
    sheetObject.appendRow(rowData);
  });
  // Get the document directory path
  String dir = (await getApplicationDocumentsDirectory()).path;
  // Format today's date as part of the file name
  String formattedDate = DateFormat('yyyy-MM-dd').format(DateTime.now());
  // Save the file with today's date as the name
  String fileName = '$dir/PurchaseData_$formattedDate.xlsx';
  // Encode and write the file
  List<int>? excelBytes = await excel.encode();
  if (excelBytes != null) {
    await File(fileName).writeAsBytes(excelBytes);
  }
}


