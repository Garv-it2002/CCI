import 'package:flutter/material.dart';
import 'database_helper.dart'; // Import your DatabaseHelper file

class ProductScreen extends StatefulWidget {
  @override
  _ProductScreenState createState() => _ProductScreenState();
}

class _ProductScreenState extends State<ProductScreen> {
  final dbHelper = DatabaseHelper();
  List<Map<String, dynamic>>? products;
  final _newProductController = TextEditingController(); // Add this line

  @override
  void dispose() {
    _newProductController.dispose(); // Dispose of the controller
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    fetchProducts();
  }

  Future<void> fetchProducts() async {
    final productList = await dbHelper.getProductData();
    setState(() {
      products = productList;
    });
  }

  Future<void> updateProductName(String newName, int index) async {
    if (products != null) {
      final oldName = products![index]['name'];
      await dbHelper.updateProductName(newName, oldName);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Product "$oldName" updated to "$newName"'),
        ),
      );

      await fetchProducts();
    }
  }

  Future<void> addProduct(String newName) async {
    try {
      if (newName.isNotEmpty) {
        final newProduct = {'name': newName};
        await dbHelper.insertProductData(newProduct);

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Product "$newName" added'),
          ),
        );

        await fetchProducts();
      }
    } catch (e) {
      print('Error adding product: $e');
      // Handle the error as needed, e.g., show an error message
    }
  }

  Future<void> removeProduct(int index) async {
    if (products != null) {
      final productName = products![index]['name'];

      // Show a confirmation dialog
      bool confirmDeletion = await showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: Text('Remove Product'),
            content: Text('Are you sure you want to remove "$productName"?'),
            actions: <Widget>[
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop(false); // Dismiss the dialog and return false
                },
                child: Text('CANCEL'),
              ),
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop(true); // Dismiss the dialog and return true
                },
                child: Text('REMOVE'),
              ),
            ],
          );
        },
      );

      // Proceed with deletion if confirmed
      if (confirmDeletion) {
        await dbHelper.removeProduct(productName);

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Product "$productName" removed'),
          ),
        );

        await fetchProducts();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Product List'),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _newProductController, // Add this line
                    decoration: InputDecoration(labelText: 'New Product'),
                    onFieldSubmitted: (value) {
                      addProduct(value);
                    },
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.add),
                  onPressed: () {
                    // Get the value from TextFormField
                    String newValue = ''; // Initialize with an empty string
                    if (_newProductController.text.isNotEmpty) {
                      newValue = _newProductController.text;
                      _newProductController.clear(); // Clear the input field after adding
                      addProduct(newValue); // Call addProduct method
                    }
                  },
                ),
              ],
            ),
          ),
          if (products == null || products!.isEmpty)
            Center(
              child: Text('No products available'),
            )
          else
            Expanded(
              child: ListView.builder(
                itemCount: products!.length,
                itemBuilder: (context, index) {
                  final product = products![index];
                  return ListTile(
                    title: TextFormField(
                      initialValue: product['name'] as String,
                      onChanged: (newValue) {
                        updateProductName(newValue, index);
                      },
                    ),
                    trailing: IconButton(
                      icon: Icon(Icons.delete),
                      onPressed: () {
                        removeProduct(index);
                      },
                    ),
                  );
                },
              ),
            ),
        ],
      ),
    );
  }
}
