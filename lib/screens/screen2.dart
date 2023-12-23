// ignore_for_file: library_private_types_in_public_api

import 'package:flutter/material.dart';

class Screen2 extends StatefulWidget {
  final String selectedProduct;
  final Function(Map<String, dynamic>) onSave;
  final bool isSheet1Active;

  const Screen2({
    Key? key,
    required this.selectedProduct,
    required this.onSave,
    required this.isSheet1Active,
  }) : super(key: key);

  @override
  _Screen2State createState() => _Screen2State();
}

class _Screen2State extends State<Screen2> {
  double weight = 0.0;
  double rate = 0.0;
  double total = 0.0;
  late TextEditingController weightController;
  late TextEditingController rateController;
  late FocusNode weightFocusNode;
  late FocusNode rateFocusNode;

  @override
  void initState() {
    super.initState();
    weightController = TextEditingController();
    rateController = TextEditingController();
    weightFocusNode = FocusNode();
    rateFocusNode = FocusNode();
  }

  @override
  void dispose() {
    weightController.dispose();
    rateController.dispose();
    weightFocusNode.dispose();
    rateFocusNode.dispose();
    super.dispose();
  }

  void calculateTotal() {
    setState(() {
      total = (weight * rate).roundToDouble();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.isSheet1Active
            ? 'Details for ${widget.selectedProduct} in Purchase'
            : 'Details for ${widget.selectedProduct} in Sales'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'Product: ${widget.selectedProduct}',
              style: const TextStyle(fontSize: 30, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            TextField(
              controller: weightController,
              focusNode: weightFocusNode,
              autofocus: true,
              keyboardType: TextInputType.number,
              textInputAction: TextInputAction.next,
              decoration: const InputDecoration(
                labelText: 'Enter Weight',
                border: OutlineInputBorder(),
              ),
              onSubmitted: (_) {
                FocusScope.of(context).requestFocus(rateFocusNode);
              },
            ),
            const SizedBox(height: 20),
            TextField(
              controller: rateController,
              focusNode: rateFocusNode,
              keyboardType: TextInputType.number,
              textInputAction: TextInputAction.done,
              decoration: const InputDecoration(
                labelText: 'Enter Rate',
                border: OutlineInputBorder(),
              ),
              onSubmitted: (_) {
                calculateTotal();
                Map<String, dynamic> newData = {
                  'name': widget.selectedProduct,
                  'weight': double.tryParse(weightController.text) ?? 0.0,
                  'rate': double.tryParse(rateController.text) ?? 0.0,
                  'total': (double.tryParse(weightController.text) ?? 0.0) *
                      (double.tryParse(rateController.text) ?? 0.0),
                };
                widget.onSave(newData);
                Navigator.pop(context);
              },
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                calculateTotal();
                Map<String, dynamic> newData = {
                  'name': widget.selectedProduct,
                  'weight': double.tryParse(weightController.text) ?? 0.0,
                  'rate': double.tryParse(rateController.text) ?? 0.0,
                  'total': (double.tryParse(weightController.text) ?? 0.0) *
                      (double.tryParse(rateController.text) ?? 0.0),
                };
                widget.onSave(newData);
                Navigator.pop(context);
              },
              child: const Text('Insert into the table'),
            ),
            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }
}