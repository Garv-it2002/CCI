// ignore_for_file: library_private_types_in_public_api, use_key_in_widget_constructors

import 'package:flutter/material.dart';
import 'screen2.dart';
import 'database_helper.dart';
import 'sales_screen.dart';
import 'package:intl/intl.dart';
import 'purchase_screen.dart';
import 'analysis.dart';
import 'patiya.dart';
class Screen1 extends StatefulWidget {
  @override
  _Screen1State createState() => _Screen1State();
}

class _Screen1State extends State<Screen1> {
  List<String> products = [
    "20mm SM", "16mm SM", "12mm SM", "10mm SM", "8mm SM", "20mm AS",
    "16mm AS", "12mm AS", "10mm AS", "8mm AS",
    "Local Wire", "Tata Wire", "Cover block", "Ch 2.2K", "Labour", "6mm TMT", "6mm ring",
    "5mm", "Cutting", "Weight", "Patiya", "Gate(L)", "Gate(H)", "Gate(P)", "Jangla", "Garter 4K", "Garter 3K", "Garter 2.5K", "Tee 2.7",
    "Tee 2.2", "AL 50/6", "AL 40/6", "AL 35/5", "AL 32/3", "AL 25/3"
  ];
  List<String> filteredProducts = [];
  List<Map<String, dynamic>> tableData = [];
  bool isSheet1Active = false;

  @override
  void initState() {
    filteredProducts = products;
    super.initState();
  }

  ThemeData _getTheme() {
    return isSheet1Active
        ? ThemeData(primarySwatch: Colors.blue)
        : ThemeData(primarySwatch: Colors.orange);
  }

  void filterProducts(String query) {
    setState(() {
      filteredProducts = products
          .where((product) => product.toLowerCase().contains(query.toLowerCase()))
          .toList();
    });
  }

void navigateToScreen2(String selectedProduct) {
  if (selectedProduct == 'Patiya') {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => Patiya(
          selectedProduct: "Patiya",
          onSave: (data) {
            setState(() {
              tableData.add(data);
            });
          },
          isSheet1Active: isSheet1Active,
      )
      ),
    );
  } else {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => Screen2(
          selectedProduct: selectedProduct,
          onSave: (data) {
            setState(() {
              tableData.add(data);
            });
          },
          isSheet1Active: isSheet1Active,
        ),
      ),
    );
  }
}

 
 //  double calculateTotalWeight() {
 //  double totalWeight = 0.0;
 //  for (var data in tableData) {
 //    if (data['weight'] != null) {
 //      totalWeight += data['weight'];
 //    }
 //  }
 //  return totalWeight;
 //}

 //    double calculateTotalRate() {
 //  double totalWeight = 0.0;
 //  for (var data in tableData) {
 //    if (data['rate'] != null) {
 //      totalWeight += data['rate'];
 //    }
 //  }
 //  return totalWeight;
 //}

    int calculateTotalTotal() {
    double totalWeight = 0;
    for (var data in tableData) {
      if (data['total'] != null) {
        totalWeight += data['total'];
      }
    }
    return totalWeight.floor().toInt();
  }

Future<void> saveDataToDatabase(String? enteredInvoice, String? entereddate) async {
  DatabaseHelper dbHelper = DatabaseHelper();
  //DateTime currentDate = DateTime.now();
  String? date = entereddate;
  String? invoice = enteredInvoice;
  //print(invoice);

  Map<String, dynamic> allData = {'date': date, 'invoice': invoice}; // Include the date in the combined data

  for (var data in tableData) {
    double weight = 0.0;
    String productName = data['name'];
    //print(productName);
    if (productName == 'Patiya') {
      //print('lol');
      String n_wt = data['weight'].toString();
      //print(n_wt);
            // Use square brackets to handle product names with spaces and replace spaces with underscores
      RegExp regex = RegExp(r"(\d+(\.\d+)?)\s?\(");
      String text = n_wt; // Assuming the number is in the 'name' field
      Match? match = regex.firstMatch(text);
      if (match != null) {
        String matchedValue = match.group(1)!;
        double parsedValue = double.parse(matchedValue);
        //print(parsedValue);
        weight = parsedValue;
      }
    }
    else{
      weight = data['weight'];
    }

    if (productName != 'Cutting' && productName != 'Labour' && productName != 'Weight') { // Exclude 'Cutting' and 'Labour'
      // Use square brackets to handle product names with spaces and replace spaces with underscores
      String formattedProductName = '[${productName.replaceAll(' ', '_')}]';
      // Check if the product name already exists in allData
      if (allData.containsKey(formattedProductName)) {
        // If exists, accumulate the weight for the product name
        allData[formattedProductName] = (allData[formattedProductName] ?? 0.0) + weight;
      } else {
        // Add the entry for the product with its weight
        allData[formattedProductName] = weight;
      }
    }
  }

  // Insert the accumulated data after the loop
  if (allData.isNotEmpty) {
    isSheet1Active
        ? await dbHelper.insertPurchaseData(allData)
        : await dbHelper.insertSalesData(allData);
  }
}

Future<Map<String, String>?> _showInvoiceDialog() async {
  TextEditingController _invoiceController = TextEditingController();
  TextEditingController _dateController =
      TextEditingController(text: DateFormat('dd-MM-yyyy').format(DateTime.now()));

  Map<String, String>? result;

  result = await showDialog<Map<String, String>>(
    context: context,
    builder: (BuildContext context) {
      return AlertDialog(
        title: Text('Enter Invoice Details'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: _dateController,
              decoration: InputDecoration(hintText: 'Enter Date (dd-MM-yyyy)'),
            ),
            TextField(
              controller: _invoiceController,
              decoration: InputDecoration(hintText: 'Enter Invoice Number'),
            ),
          ],
        ),
        actions: <Widget>[
          TextButton(
            child: Text('Submit'),
            onPressed: () {
              String invoiceNumber = _invoiceController.text;
              String enteredDate = _dateController.text;

              // Date validation
              if (RegExp(r'^\d{2}-\d{2}-\d{4}$').hasMatch(enteredDate)) {
                // Valid date format (dd-MM-yyyy)
                Navigator.of(context, rootNavigator: true).pop({
                  'invoiceNumber': invoiceNumber,
                  'enteredDate': enteredDate,
                });
              } else {
                // Invalid date format
                // You can show an error message or handle it accordingly
                // For simplicity, here it returns null if the date format is invalid
                Navigator.of(context, rootNavigator: true).pop(null);
              }
            },
          ),
          TextButton(
            child: Text('Cancel'),
            onPressed: () {
              Navigator.of(context, rootNavigator: true).pop(null);
            },
          ),
        ],
      );
    },
  );

  return result;
}





    void navigateToSalesScreen() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => SalesScreen()),
    );
  }

 void navigateToPurchaseScreen() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => PurchaseScreen()),
    );
  }
//
 void navigateToProductScreen() {
   Navigator.push(
     context,
     MaterialPageRoute(builder: (context) => AnalysisScreen()),
   );
 }

 @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Available Goods',
      theme: _getTheme(),
      home: Scaffold(
        appBar: AppBar(
          title: Text(isSheet1Active ? 'Purchase Sheet' : 'Sales Sheet'),
          actions: [
            const SizedBox(width: 30),
            Switch(
              value: isSheet1Active,
              onChanged: (newValue) {
                setState(() {
                  isSheet1Active = newValue;
                });
              },
            ),
            const SizedBox(width: 30),
          IconButton(
            onPressed: navigateToSalesScreen,
            icon: const Icon(Icons.business),
            tooltip: 'Sales Screen', // Adding tooltip for the label
          ),
          const SizedBox(width: 30),
          IconButton(
            onPressed: navigateToPurchaseScreen,
            icon: const Icon(Icons.shopping_cart),
            tooltip: 'Purhase Screen', // Adding tooltip for the label
          ),
          const SizedBox(width: 30),
          IconButton(
            onPressed: navigateToProductScreen,
            icon: Icon(Icons.inventory),
            tooltip: 'Analysis',
          ),
          const SizedBox(width: 30),
          ],
        ),
        
        body: Row(
          children: [
            Expanded(
              flex: 1,
              child: Container(
                padding: const EdgeInsets.all(8.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: TextField(
                        decoration: const InputDecoration(
                          hintText: 'Search for goods',
                          prefixIcon: Icon(Icons.search),
                        ),
                        onChanged: (value) {
                          filterProducts(value);
                        },
                      ),
                    ),
                    Expanded(
                      child: GridView.builder(
                        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 5,
                          crossAxisSpacing: 8.0,
                          mainAxisSpacing: 8.0,
                        ),
                        itemCount: filteredProducts.length,
                        itemBuilder: (context, index) {
                          return Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: ElevatedButton(
                              onPressed: () {
                                navigateToScreen2(filteredProducts[index]);
                              },
                              child: Text(
                                filteredProducts[index],
                                style:const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Expanded(
              flex: 1,
              child: Container(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text(
                      'Goods Table',
                      style: TextStyle(fontSize: 25, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(width: 300, height: 20),
                    Expanded(
                      child: SingleChildScrollView(
                        scrollDirection: Axis.vertical,
                        child: DataTable(
                          columns: const [
                            DataColumn(label: Text('Name')),
                            DataColumn(label: Text('Weight')),
                            DataColumn(label: Text('Rate')),
                            DataColumn(label: Text('Total')),
                            DataColumn(label: Text('Actions')),
                          ],
                          rows: [
                            ...tableData.map((data) {
                              return DataRow(cells: [
                                DataCell(Text(data['name'] ?? '')),
                                DataCell(Text(data['weight']?.toString() ?? '')),
                                DataCell(Text(data['rate']?.toString() ?? '')),
                                DataCell(Text(data['total']?.toString() ?? '')),
                                DataCell(Row(
                                  children: [
                                    IconButton(
                                      icon: const Icon(Icons.delete),
                                      onPressed: () {
                                        setState(() {
                                          tableData.remove(data);
                                        });
                                      },
                                    ),
                                  ],
                                )),
                              ]);
                            }).toList(),
                            DataRow(cells: [
                              const DataCell(Text(
                                'Total',
                                style: TextStyle(fontWeight: FontWeight.bold),
                              )),
                              const DataCell(Text("")),
                              const DataCell(Text("")),
                              DataCell(Text(
                                calculateTotalTotal().toStringAsFixed(0),
                                style: const TextStyle(fontWeight: FontWeight.bold),                                 
                              )),
                              const DataCell(Text('')),
                            ]),
                          ],
                        ),
                      ),
                      ),
                    const SizedBox(height: 20),
                    ElevatedButton(
                      onPressed: tableData.isNotEmpty
                          ? () async {
                              Map<String, String>? result = await _showInvoiceDialog();
                              //if (enteredInvoice != null) {
                              if (result != null && result['invoiceNumber'] != null && result['enteredDate'] != null) {
                                  String? enteredInvoice = result['invoiceNumber']!;
                                  String? enteredDate = result['enteredDate']!;
                                await saveDataToDatabase(enteredInvoice, enteredDate);
                              setState(() {
                                tableData.clear();
                              });
                              }
                            }
                          : null, // Disable onPressed if tableData is empty
                      child: const Text('Save'),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}