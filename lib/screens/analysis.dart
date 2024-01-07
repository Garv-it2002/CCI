import 'package:flutter/material.dart';
import 'database_helper.dart'; // Import your DatabaseHelper
import 'package:charts_flutter/flutter.dart' as charts;
import 'export_analysis.dart';

class AnalysisScreen extends StatefulWidget {
  @override
  _AnalysisScreenState createState() => _AnalysisScreenState();
}

class _AnalysisScreenState extends State<AnalysisScreen> {
    ScrollController _scrollController = ScrollController();
  Map<String, double> totalSales = {};
  Map<String, double> totalPurchase = {};
  Map<String, double> stockLeft = {};
  late List<Map<String, dynamic>> products;

  @override
  void initState() {
    super.initState();
    fetchData();
  }

Widget _buildSalesColumnChart() {
  List<charts.Series<MapEntry<String, double>, String>> series = [
    charts.Series<MapEntry<String, double>, String>(
      id: 'Sales',
      domainFn: (MapEntry<String, double> sales, _) => sales.key,
      measureFn: (MapEntry<String, double> sales, _) => sales.value,
      data: totalSales.entries.map((entry) => MapEntry(entry.key, entry.value)).toList(),
      colorFn: (_, __) => charts.ColorUtil.fromDartColor(Colors.orange), // Change color to orange
    ),
  ];

  return LayoutBuilder(
    builder: (context, constraints) {
      return SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: SizedBox(
          width: constraints.maxWidth, // Occupy available width
            child: charts.BarChart(
              series,
              animate: true,
              barGroupingType: charts.BarGroupingType.grouped,
              vertical: true,
              domainAxis: charts.OrdinalAxisSpec(
                renderSpec: charts.NoneRenderSpec(), // Remove domain axis labels and gridlines
              ),
              behaviors: [
                charts.ChartTitle('Sales Data'),
                charts.LinePointHighlighter(
                  showHorizontalFollowLine:
                      charts.LinePointHighlighterFollowLineType.none,
                  showVerticalFollowLine:
                      charts.LinePointHighlighterFollowLineType.nearest,
                ),
              ],
            ),
          //),
        ),
      );
    },
  );
}

void exportTables() async {
  try {
    List<Map<String, dynamic>> products = await DatabaseHelper().getProductData();
    ExportAnalysis exporter = ExportAnalysis();
    exporter.exportTablesToExcel(products, totalSales, totalPurchase, stockLeft);
  } catch (e) {
    print('Error exporting tables: $e');
    // Handle the error as needed
  }
}
//.........................

Widget _buildPurchaseColumnChart() {
  List<charts.Series<MapEntry<String, double>, String>> series = [
    charts.Series<MapEntry<String, double>, String>(
      id: 'Purchase',
      domainFn: (MapEntry<String, double> purchase, _) => purchase.key,
      measureFn: (MapEntry<String, double> purchase, _) => purchase.value,
      data: totalPurchase.entries.map((entry) => MapEntry(entry.key, entry.value)).toList(),
      colorFn: (_, __) => charts.ColorUtil.fromDartColor(Colors.blue), // Change color to blue
    ),
  ];

  return LayoutBuilder(
    builder: (context, constraints) {
      return SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: SizedBox(
          width: constraints.maxWidth, // Occupy available width
          child: charts.BarChart(
            series,
            animate: true,
            barGroupingType: charts.BarGroupingType.grouped,
            vertical: true,
            domainAxis: charts.OrdinalAxisSpec(
              renderSpec: charts.NoneRenderSpec(), // Remove domain axis labels and gridlines
            ),
            behaviors: [
              charts.ChartTitle('Purchase Data'),
              charts.LinePointHighlighter(
                showHorizontalFollowLine: charts.LinePointHighlighterFollowLineType.none,
                showVerticalFollowLine: charts.LinePointHighlighterFollowLineType.nearest,
              ),
            ],
          ),
        ),
      );
    },
  );
}
//-----------------------------

  Future<void> fetchData() async {
    try {
      products = await DatabaseHelper().getProductData();

      for (Map<String, dynamic> product in products) {
        String productName = product['name'] as String;
        productName = '[${productName.replaceAll(' ', '_')}]';
        //print(productName);
        double sales = await DatabaseHelper().getTotalSales(productName);
        double purchase = await DatabaseHelper().getTotalPurchase(productName);

        setState(() {
          totalSales[productName] = sales;
          totalPurchase[productName] = purchase;
          stockLeft[productName] = purchase - sales;
        });
      }
    } catch (e) {
      // Handle or log the error as needed
    }
  }

  double calculateTotalSales() {
  double sum = 0;
  totalSales.forEach((key, value) {
    sum += value;
  });
  double fsum = double.parse(sum.toStringAsFixed(2));
  return fsum;
}

  double calculateTotalPurchase() {
  double sum = 0;
  totalPurchase.forEach((key, value) {
    sum += value;
  });
  double fsum = double.parse(sum.toStringAsFixed(2));
  return fsum;
}

   final snackBar = const SnackBar(
    content: Text('Export Successful!'),
    duration: Duration(seconds: 2), // Adjust the duration as needed
  );


    @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Analysis'),
        backgroundColor: Colors.grey,
        actions: [
                IconButton(
                  icon: const Icon(Icons.file_download), // Add an export icon
                  onPressed: () {
                  exportTables();
                  ScaffoldMessenger.of(context).showSnackBar(snackBar);  
                  },
                  tooltip: 'Export to Excel',
                ),
                const SizedBox(width: 30),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    children: [

                      Expanded(
                        child: Container(
                          margin: EdgeInsets.all(20.0),
                          decoration: BoxDecoration(
                            border: Border.all(),
                          ),
                          child: _buildSalesColumnChart(),
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: Column(
                    children: [

                      Expanded(
                        child: Container(
                          margin: EdgeInsets.all(20.0),
                          decoration: BoxDecoration(
                            border: Border.all(),
                          ),
                          child: _buildPurchaseColumnChart(),
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: Column(
                    children: [
                      Expanded(
                        child: Container(
                          child: Column(
                            children: [
Expanded(
  child: Container(
    margin: EdgeInsets.all(20.0),
    decoration: BoxDecoration(
      color: Colors.orange, // Grey background color
      border: Border.all(),
    ),
    child: Center(
      child: Text(
        'Total Sales: \₹${calculateTotalSales()}',
        textAlign: TextAlign.center,
        style: TextStyle(
          fontSize: 25.0,
          fontWeight: FontWeight.bold,
        ),
      ),
    ),
  ),
),

Expanded(
  child: Container(
    margin: EdgeInsets.all(20.0),
    decoration: BoxDecoration(
      color: Colors.blue, // Grey background color
      border: Border.all(),
    ),
    child: Center(
      child: Text(
        'Total Purchase: \₹${calculateTotalPurchase()}',
        textAlign: TextAlign.center,
        style: TextStyle(
          fontSize: 25.0,
          fontWeight: FontWeight.bold,
        ),
      ),
    ),
  ),
),

                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: FutureBuilder<List<Map<String, dynamic>>>(
              future: DatabaseHelper().getProductData(),
              builder: (context, snapshot) {
                if (snapshot.connectionState != ConnectionState.done) {
                  return Center(child: CircularProgressIndicator());
                }

                if (snapshot.hasError) {
                  return Center(child: Text('Error fetching data'));
                }

                List<Map<String, dynamic>> products = snapshot.data ?? [];
                List<DataRow> rows = [];

                for (var product in products) {
                  String productName = product['name'] as String;
                  String productName1 = '[${productName.replaceAll(' ', '_')}]';

                  DataRow row = DataRow(
                    cells: [
                      DataCell(Text(productName)),
                      DataCell(Text('${totalSales[productName1] ?? 0}')),
                      DataCell(Text('${totalPurchase[productName1] ?? 0}')),
                      DataCell(Text('${stockLeft[productName1] ?? 0}')),
                    ],
                  );
                  rows.add(row);
                }

                return Container(
                  margin: EdgeInsets.all(20.0),
                  child: Container(
                    decoration: BoxDecoration(
                      border: Border.all(),
                      boxShadow: [],
                    ),
                    child: SingleChildScrollView(
                      controller: _scrollController,
                      scrollDirection: Axis.vertical,
                      child: SizedBox(
                        width: MediaQuery.of(context).size.width,
                        child: Scrollbar(
                          thumbVisibility: true,
                          trackVisibility: true,
                          controller: _scrollController,
                          child: DataTable(
                            columns: [
                              DataColumn(label: Text('Product Name')),
                              DataColumn(label: Text('Total Sales')),
                              DataColumn(label: Text('Total Purchase')),
                              DataColumn(label: Text('Stock Left')),
                            ],
                            rows: rows,
                          ),
                        ),
                      ),
                    ),
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
