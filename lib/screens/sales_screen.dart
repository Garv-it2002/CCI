// ignore_for_file: use_build_context_synchronously, library_private_types_in_public_api, use_key_in_widget_constructors

import 'package:flutter/material.dart';
import 'database_helper.dart'; // Update with your database helper import
import 'excel_export.dart';

class SalesScreen extends StatefulWidget {
  @override
  _SalesScreenState createState() => _SalesScreenState();
}

class _SalesScreenState extends State<SalesScreen> {
  final DatabaseHelper _databaseHelper = DatabaseHelper();
  List<String> productNames = [];
  List<Map<String, dynamic>> salesData = [];
  bool isEditing = false;

  @override
  void initState() {
    super.initState();
    fetchData(); // Call fetchData to populate the data
  }

  void enableEditing() {
    setState(() {
      isEditing = true;
    });
  }

  void saveChanges() {
    setState(() {
      isEditing = false;
    });

    // Save the updated sales data to the database
    _databaseHelper.saveChanges(salesData);
  }

   final snackBar = const SnackBar(
    content: Text('Export Successful!'),
    duration: Duration(seconds: 2), // Adjust the duration as needed
  );

  void fetchData() async {
      List<Map<String, dynamic>> fetchedSalesData =
          await _databaseHelper.getSalesData();
      List<Map<String, dynamic>> fetchedProductData =
          await _databaseHelper.getProductData();

      setState(() {
        salesData = fetchedSalesData;
        productNames = fetchedProductData
            .map((product) => product['name'] as String)
            .toList();
      });
  }

  Future<bool> _onWillPop() async {
    if (isEditing) {
      return await showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Save Changes?'),
          content: const Text('Do you want to save your changes before leaving?'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(false); // Return without saving
              },
              child: const Text('No'),
            ),
            TextButton(
              onPressed: () {
                saveChanges(); // Save changes
                Navigator.of(context).pop(true); // Return and close screen
              },
              child: const Text('Yes'),
            ),
          ],
        ),
      ) ?? false; // Return false if dialog is dismissed
    }
    return true;
  }

  @override
  Widget build(BuildContext context) {
    final verticalScrollController = ScrollController();
    final horizontalScrollController = ScrollController();

    return WillPopScope(
      onWillPop: _onWillPop,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Sales Data'),
          backgroundColor: Colors.orange,
          actions: [
            isEditing
                ? IconButton(
                    icon: const Icon(Icons.save),
                    onPressed: saveChanges,
                    tooltip: 'Save',
                  )
                : IconButton(
                    icon: const Icon(Icons.edit),
                    onPressed: enableEditing,
                    tooltip: 'Edit',
                  ),
                const SizedBox(width: 50),
                IconButton(
                  icon: const Icon(Icons.file_download), // Add an export icon
                  onPressed: () {
                  exportSalesDataToExcel(salesData, productNames);
                  ScaffoldMessenger.of(context).showSnackBar(snackBar);  
                  },
                  tooltip: 'Export to Excel',
                ),
                const SizedBox(width: 50),
                IconButton(
                  icon: const Icon(Icons.align_vertical_center), // Add an export icon
                  onPressed: () async {
                    DatabaseHelper dbHelper = DatabaseHelper();
                    bool updatesMade = await dbHelper.aggregateSalesOldData(context);
                    
                    if (updatesMade) {
                      await dbHelper.cloneAndReplaceSalesTable();
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(builder: (BuildContext context) => SalesScreen()),
                      );
                    }
                  },
                  tooltip: 'Combine old entries',
                ),
                const SizedBox(width: 50),
          ],
        ),
        body: productNames.isEmpty || salesData.isEmpty
            ? const Center(
                child: Text("No data available"),
              )
            : Scrollbar(
                controller: verticalScrollController,
                thumbVisibility: true,
                thickness: 8.0,
                radius: const Radius.circular(4.0),
                scrollbarOrientation: ScrollbarOrientation.right,
                child: SingleChildScrollView(
                  controller: verticalScrollController,
                  scrollDirection: Axis.vertical,
                  child: Scrollbar(
                    controller: horizontalScrollController,
                    thumbVisibility: true,
                    thickness: 8.0,
                    radius: const Radius.circular(4.0),
                    scrollbarOrientation: ScrollbarOrientation.top,
                    notificationPredicate: (notification) {
                      return notification is ScrollUpdateNotification;
                    },
                    child: SingleChildScrollView(
                      controller: horizontalScrollController,
                      scrollDirection: Axis.horizontal,
                      child: DataTable(
                        columns: [
                          const DataColumn(label: Text('Serial')),
                          const DataColumn(label: Text('Date')), // Date column
                          for (var productName in productNames)
                            DataColumn(
                                label: Text(productName)), // Product columns
                        ],
                        rows: salesData.map((data) {
                          List<DataCell> cells = [
                            DataCell(
                              Text(data['serial'].toString()), // Display serial number
                            ),
                            DataCell(
                              isEditing
                                  ? TextFormField(
                                      initialValue: data['date']?.toString() ?? 'null',
                                      onChanged: (newValue) {
                                        setState(() {
                                          data['date'] = newValue; // Update the 'date' value
                                        });
                                      },
                                    )
                                  : Text(data['date']?.toString() ?? 'null'),
                            ),
                          ];

                          for (var productName in productNames) {
                            var formattedProductName =
                                productName.replaceAll(' ', '_');
                            cells.add(
                              DataCell(
                                isEditing
                                    ? TextFormField(
                                        initialValue: data[formattedProductName]?.toString() ?? '0',
                                        onChanged: (newValue) {
                                          setState(() {
                                            data[formattedProductName] = newValue; // Update the respective product value
                                          });
                                        },
                                      )
                                    : Text(data[formattedProductName]?.toString() ?? '0'),
                              ),
                            );
                          }

                          return DataRow(cells: cells);
                        }).toList(),
                      ),
                    ),
                  ),
                ),
              ),
      ),
    );
  }
}
