// ignore_for_file: library_private_types_in_public_api, use_key_in_widget_constructors

import 'package:flutter/material.dart';
import 'screen2.dart';
import 'database_helper.dart';
import 'sales_screen.dart';
import 'package:intl/intl.dart';
import 'purchase_screen.dart';
import 'product_screen.dart';
class Screen1 extends StatefulWidget {
  @override
  _Screen1State createState() => _Screen1State();
}

class _Screen1State extends State<Screen1> {
  final dbHelper = DatabaseHelper();
  List<String> products = [];
  List<String> filteredProducts = [];
  List<Map<String, dynamic>> tableData = [];
  bool isSheet1Active = false;

  @override
  void initState() {
    fetchData();
    filteredProducts = products;
    super.initState();
  }

    Future<void> fetchData() async {
    products = await dbHelper.getProductNames();
    filteredProducts = List.from(products);
    setState(() {}); // Trigger a rebuild after fetching data
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
 
    double calculateTotalWeight() {
    double totalWeight = 0.0;
    for (var data in tableData) {
      if (data['weight'] != null) {
        totalWeight += data['weight'];
      }
    }
    return totalWeight;
  }

      double calculateTotalRate() {
    double totalWeight = 0.0;
    for (var data in tableData) {
      if (data['rate'] != null) {
        totalWeight += data['rate'];
      }
    }
    return totalWeight;
  }

        double calculateTotalTotal() {
    double totalWeight = 0.0;
    for (var data in tableData) {
      if (data['total'] != null) {
        totalWeight += data['total'];
      }
    }
    return totalWeight;
  }

Future<void> saveDataToDatabase() async {
  DatabaseHelper dbHelper = DatabaseHelper();

  DateTime currentDate = DateTime.now();
  String date = DateFormat('dd-MM-yyyy').format(currentDate); // Format date as dd-mm-yyyy

  Map<String, dynamic> allData = {'date': date}; // Include the date in the combined data
  for (var data in tableData) {
    String productName = data['name'];
    double weight = data['weight'] ?? 0.0;

    // Use square brackets to handle product names with spaces and replace spaces with underscores
    allData['[${productName.replaceAll(' ', '_')}]'] = weight;
  }

  isSheet1Active 
      ? await dbHelper.insertPurchaseData(allData)
      : await dbHelper.insertSalesData(allData);

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
     MaterialPageRoute(builder: (context) => ProductScreen()),
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
          ),
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
                        scrollDirection: Axis.horizontal,
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
                                calculateTotalTotal().toStringAsFixed(2),
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
                      onPressed: tableData.isNotEmpty ? () async {
                        await saveDataToDatabase();
                        setState(() {
                          tableData.clear();
                        });
                      } : null, // Disable onPressed if tableData is empty
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