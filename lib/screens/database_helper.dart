// ignore_for_file: use_build_context_synchronously

import 'package:path/path.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class DatabaseHelper {
  static Database? _database;
  final String productTableName = 'product_table';
  final String salesTableName = 'sales_table';
  final String purchaseTableName = 'purchase_table';

  Future<Database> get database async {
    if (_database != null) return _database!;

    _database = await initDatabase();
    return _database!;
  }

Future<Database> initDatabase() async {
  sqfliteFfiInit();
  databaseFactory = databaseFactoryFfi;
  String path = await getDatabasesPath();

  return await openDatabase(
    join(path, 'your_database_name.db'),
    version: 1,
     onConfigure: (Database db) {
      // Ensure the database is configured for write operations
      db.execute('PRAGMA synchronous = NORMAL');
    },
    onCreate: (Database db, int version) async {
      await db.execute('''
        CREATE TABLE $productTableName (
          name TEXT PRIMARY KEY
        )
      ''');

      List<String> initialProductNames = [
        "20mm SM", "16mm SM", "12mm SM", "10mm SM", "8mm SM",
        "20mm AS", "16mm AS", "12mm AS", "10mm AS", "8mm AS",
        "6mm TMT", "6mm ring", "5mm", "2mm", "Weight",
        "Garter 4K", "Garter 3K", "Garter 2.5K", "Tee 2.7", "Tee 2.2",
        "AL 50/6", "AL 40/6", "AL 35/6", "AL 35/5", "AL 25/3",
        "Local Wire", "Tata Wire", "Cover block", "Patiya", "Ch 2.2K"
      ];

      for (String productName in initialProductNames) {
        await db.insert(productTableName, {'name': productName});
      }

      // Create sales table with dynamic product columns
    await db.execute('''
      CREATE TABLE $salesTableName (
        serial INTEGER PRIMARY KEY AUTOINCREMENT,
        date TEXT,
        ${initialProductNames.map((name) => '[${name.replaceAll(' ', '_')}] INTEGER').join(',')}
      )
    ''');   

    // Create purchase table with dynamic product columns
    await db.execute('''
      CREATE TABLE $purchaseTableName (
        serial INTEGER PRIMARY KEY AUTOINCREMENT,
        date TEXT,
        ${initialProductNames.map((name) => '[${name.replaceAll(' ', '_')}] INTEGER').join(',')}
      )
    ''');
    },
  );
}


Future<int> insertSalesData(Map<String, dynamic> data) async {
  Database db = await database;
  Map<String, dynamic> newData = {};

  data.forEach((key, value) {
    newData[key.replaceAll(' ', '_')] = value;
  });

  return await db.insert(salesTableName, newData);
}

Future<int> insertPurchaseData(Map<String, dynamic> data) async {
  Database db = await database;
  Map<String, dynamic> newData = {};

  data.forEach((key, value) {
    newData[key.replaceAll(' ', '_')] = value;
  });

  return await db.insert(purchaseTableName, newData);
}

  Future<List<Map<String, dynamic>>> getSalesData() async {
      Database db = await database;
      List<Map<String, dynamic>> results = await db.query(salesTableName);
      List<Map<String, dynamic>> mutableResults = results.map((data) {
        return Map<String, dynamic>.from(data);
      }).toList();
      return mutableResults;
  }

  Future<List<Map<String, dynamic>>> getProductData() async {
    Database db = await database;
    return await db.query(productTableName);
  }

Future<void> saveChanges(List<Map<String, dynamic>> updatedSalesData) async {
    Database db = await database;
    for (var data in updatedSalesData) {
      Map<String, dynamic> valuesToUpdate = {};

      // Extract values to update excluding the 'serial' field
      for (var entry in data.entries) {
        if (entry.key != 'serial') {
          String columnName = '[${entry.key}]'; // Enclose all columns within square brackets
          valuesToUpdate[columnName] = entry.value;
        }
      }

      int serial = data['serial']; // Assuming 'serial' is the primary key

      await db.update(
        salesTableName,
        Map<String, dynamic>.from(valuesToUpdate), // Use a mutable copy of the data
        where: 'serial = ?',
        whereArgs: [serial],
      );
    }
}

  Future<List<Map<String, dynamic>>> getPurchaseData() async {
      Database db = await database;
      List<Map<String, dynamic>> results = await db.query(purchaseTableName);

      List<Map<String, dynamic>> mutableResults = results.map((data) {
        return Map<String, dynamic>.from(data);
      }).toList();

      return mutableResults;
  }

  Future<void> saveChangesToPurchaseData(List<Map<String, dynamic>> updatedPurchaseData) async {
      Database db = await database;
      for (var data in updatedPurchaseData) {
        Map<String, dynamic> valuesToUpdate = {};

        for (var entry in data.entries) {
          if (entry.key != 'serial') {
            String columnName = '[${entry.key}]';
            valuesToUpdate[columnName] = entry.value;
          }
        }

        int serial = data['serial'];

        await db.update(
          purchaseTableName,
          Map<String, dynamic>.from(valuesToUpdate),
          where: 'serial = ?',
          whereArgs: [serial],
        );
      }
  }


Future<bool> aggregateSalesOldData(BuildContext context) async {
  try {
    Database db = await database;
    DateTime tenDaysAgo = DateTime.now().subtract(const Duration(days: 10));

    String formattedDate = '${tenDaysAgo.day.toString().padLeft(2, '0')}-${tenDaysAgo.month.toString().padLeft(2, '0')}-${tenDaysAgo.year}';

    List<Map<String, dynamic>> oldSalesEntries = await db.rawQuery(
      'SELECT * FROM sales_table WHERE date < ?',
      [formattedDate],
    );

    if (oldSalesEntries.length == 1) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No old entries available for sales.'),
        ),
      );
      return false; // Directly return false if only one entry is available
    }

    DateTime? mostRecentDate;
    if (oldSalesEntries.isNotEmpty) {
      mostRecentDate = oldSalesEntries
          .map((entry) => _parseCustomDateFormat(entry['date'] as String))
          .reduce((value, element) => value.isAfter(element) ? value : element);
    }

    String formattedMostRecentDate = mostRecentDate != null
        ? DateFormat('dd-MM-yyyy').format(mostRecentDate)
        : 'N/A'; // or any default value if mostRecentDate is null

    if (oldSalesEntries.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No old entries available for sales.'),
        ),
      );
      return false; // No old entries available, no further operations
    }

    Map<String, dynamic> combinedSalesEntries = {};

    void combineSalesEntries(List<Map<String, dynamic>> entries) {
      entries.forEach((entry) {
        entry.forEach((key, value) {
          if (key != 'date' && key != 'serial') {
            String formattedKey = '[$key]';
            combinedSalesEntries[formattedKey] =
                (combinedSalesEntries[formattedKey] ?? 0) + (value ?? 0);
          }
        });
      });
    }

    combineSalesEntries(oldSalesEntries);

bool updatesMade = await db.transaction((txn) async {
  // Exclude the row with the minimum id from deletion
  await txn.rawDelete(
    'DELETE FROM sales_table WHERE date < ? AND serial != (SELECT MIN(serial) FROM sales_table WHERE date < ?)',
    [formattedDate, formattedDate],
  );

      String latestDateQuery = '''
        SELECT MAX(date) AS latest_date FROM sales_table
        ''';

      List<Map<String, dynamic>> latestDateResult = await txn.rawQuery(latestDateQuery);
      String? latestDate =
          latestDateResult.isNotEmpty ? latestDateResult.first['latest_date'] : null;

      if (latestDate != null) {
        combinedSalesEntries['date'] = latestDate;
         List<Map<String, dynamic>> existingRow = await txn.rawQuery(
      'SELECT * FROM sales_table ORDER BY serial LIMIT 1',
    );

    if (existingRow.isNotEmpty) {
      combinedSalesEntries['date'] = formattedMostRecentDate;
      // Update the existing row with combinedSalesEntries values
      await txn.update(
        'sales_table',
        combinedSalesEntries,
        where: 'serial = ?',
        whereArgs: [existingRow.first['serial']],
      );
    }
      return true; // Updates were made
      }
      return false; // No updates made (latestDate was null)
    });

    return updatesMade;
  } catch (e) {
    //print('Error in aggregateSalesOldData: $e');
    // Handle or log the error as needed
    return false; // Error occurred, no updates made
  }
}

DateTime _parseCustomDateFormat(String dateString) {
  final parts = dateString.split('-');
  final day = int.parse(parts[0]);
  final month = int.parse(parts[1]);
  final year = int.parse(parts[2]);
  return DateTime(year, month, day);
}

Future<bool> aggregatePurchaseOldData(BuildContext context) async {
  try {
    Database db = await database;
    DateTime tenDaysAgo = DateTime.now().subtract(const Duration(days: 10));

    String formattedDate = '${tenDaysAgo.day.toString().padLeft(2, '0')}-${tenDaysAgo.month.toString().padLeft(2, '0')}-${tenDaysAgo.year}';

    List<Map<String, dynamic>> oldPurchaseEntries = await db.rawQuery(
        'SELECT * FROM purchase_table WHERE date < ?',
      [formattedDate],
    );

    if (oldPurchaseEntries.length == 1) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No old entries available for sales.'),
        ),
      );
      return false; // Directly return false if only one entry is available
    }

    DateTime? mostRecentDate;
    if (oldPurchaseEntries.isNotEmpty) {
      mostRecentDate = oldPurchaseEntries
          .map((entry) => _parseCustomDateFormat(entry['date'] as String))
          .reduce((value, element) => value.isAfter(element) ? value : element);
    }

    String formattedMostRecentDate = mostRecentDate != null
        ? DateFormat('dd-MM-yyyy').format(mostRecentDate)
        : 'N/A'; // or any default value if mostRecentDate is null

    if (oldPurchaseEntries.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No old entries available for sales.'),
        ),
      );
      return false; // No old entries available, no further operations
    }

    Map<String, dynamic> combinedPurchaseEntries = {};

    void combinePurchaseEntries(List<Map<String, dynamic>> entries) {
      entries.forEach((entry) {
        entry.forEach((key, value) {
          if (key != 'date' && key != 'serial') {
            String formattedKey = '[$key]';
            combinedPurchaseEntries[formattedKey] =
                (combinedPurchaseEntries[formattedKey] ?? 0) + (value ?? 0);
          }
        });
      });
    }

    combinePurchaseEntries(oldPurchaseEntries);

bool updatesMade = await db.transaction((txn) async {
  // Exclude the row with the minimum id from deletion
  await txn.rawDelete(
    'DELETE FROM purchase_table WHERE date < ? AND serial != (SELECT MIN(serial) FROM sales_table WHERE date < ?)',
    [formattedDate, formattedDate],
  );

      String latestDateQuery = '''
        SELECT MAX(date) AS latest_date FROM purchase_table
        ''';

      List<Map<String, dynamic>> latestDateResult = await txn.rawQuery(latestDateQuery);
      String? latestDate =
          latestDateResult.isNotEmpty ? latestDateResult.first['latest_date'] : null;

      if (latestDate != null) {
        combinedPurchaseEntries['date'] = latestDate;
         List<Map<String, dynamic>> existingRow = await txn.rawQuery(
      'SELECT * FROM purchase_table ORDER BY serial LIMIT 1',
    );

    if (existingRow.isNotEmpty) {
      combinedPurchaseEntries['date'] = formattedMostRecentDate;
      // Update the existing row with combinedSalesEntries values
      await txn.update(
        'purchase_table',
        combinedPurchaseEntries,
        where: 'serial = ?',
        whereArgs: [existingRow.first['serial']],
      );
    }
      return true; // Updates were made
      }
      return false; // No updates made (latestDate was null)
    });

    return updatesMade;
  } catch (e) {
    //print('Error in aggregatePurchaseOldData: $e');
    // Handle or log the error as needed
    return false; // Error occurred, no updates made
  }
}

Future<void> cloneAndReplaceSalesTable() async {
  try {
    Database db = await database;

    // Retrieve column names excluding 'serial'
    List<Map<String, dynamic>> columns = await db.rawQuery('PRAGMA table_info(sales_table)');
    List<String> columnNames = columns.map((column) => column['name'] as String).toList();
    columnNames.remove('serial');

    // Generate column names string for the new table
    String columnDefinitions = columnNames.map((name) {
      String type = (columns.firstWhere((column) => column['name'] == name)['type'] ?? 'TEXT') as String;
      return '[$name] $type';
    }).join(', ');

    // Create sales_temp table without autoincrement yet
    await db.execute('''
      CREATE TABLE sales_temp (
        serial INTEGER PRIMARY KEY,
        $columnDefinitions
      )
    ''');

    // Get data from sales_table
    List<Map<String, dynamic>> data = await db.query('sales_table');

    // Insert data into sales_temp with specified column names and handle data type conversion
    await db.transaction((txn) async {
      for (var row in data) {
        // Prepare values for insertion
        List<dynamic> values = [];
        for (var name in columnNames) {
          // Convert data types if needed
          dynamic value = row[name];
          values.add(value);
        }

        // Insert data into sales_temp table
        await txn.rawInsert(
          'INSERT INTO sales_temp (${columnNames.map((name) => '[$name]').join(', ')}) VALUES (${List.filled(columnNames.length, '?').join(', ')})',
          values,
        );
      }
    });

    // Drop the original sales_table
    await db.execute('DROP TABLE sales_table');

    // Rename sales_temp to sales_table
    await db.execute('ALTER TABLE sales_temp RENAME TO sales_table');
  } catch (e) {
    //print('Error in cloneAndReplaceSalesTable: $e');
    // Handle or log the error as needed
  }
}

Future<void> cloneAndReplacePurchaseTable() async {
  try {
    Database db = await database;

    // Retrieve column names excluding 'serial'
    List<Map<String, dynamic>> columns = await db.rawQuery('PRAGMA table_info(purchase_table)');
    List<String> columnNames = columns.map((column) => column['name'] as String).toList();
    columnNames.remove('serial');

    // Generate column names string for the new table
    String columnDefinitions = columnNames.map((name) {
      String type = (columns.firstWhere((column) => column['name'] == name)['type'] ?? 'TEXT') as String;
      return '[$name] $type';
    }).join(', ');

    // Create purchase_temp table without autoincrement yet
    await db.execute('''
      CREATE TABLE purchase_temp (
        serial INTEGER PRIMARY KEY,
        $columnDefinitions
      )
    ''');

    // Get data from purchase_table
    List<Map<String, dynamic>> data = await db.query('purchase_table');

    // Insert data into purchase_temp with specified column names and handle data type conversion
    await db.transaction((txn) async {
      for (var row in data) {
        // Prepare values for insertion
        List<dynamic> values = [];
        for (var name in columnNames) {
          // Convert data types if needed
          dynamic value = row[name];
          values.add(value);
        }

        // Insert data into purchase_temp table
        await txn.rawInsert(
          'INSERT INTO purchase_temp (${columnNames.map((name) => '[$name]').join(', ')}) VALUES (${List.filled(columnNames.length, '?').join(', ')})',
          values,
        );
      }
    });

    // Drop the original purchase_table
    await db.execute('DROP TABLE purchase_table');

    // Rename purchase_temp to purchase_table
    await db.execute('ALTER TABLE purchase_temp RENAME TO purchase_table');
  } catch (e) {
    //print('Error in cloneAndReplacePurchaseTable: $e');
    // Handle or log the error as needed
  }
}

Future<int> getTotalSales(String productName) async {
  try {
    Database db = await database;
    List<Map<String, dynamic>> sales = await db.query(
      salesTableName,
      where: '$productName > 0', // Assuming the column value > 0 means sales occurred for the product
    );

    int totalSales = 0;

    //print('Sales for $productName: $sales');

    for (Map<String, dynamic> sale in sales) {
      sale.forEach((key, value) {
        if (key != 'serial' && key != 'date' && value is int && value > 0) {
          totalSales += value;
          //print('Adding $value to totalSales. Current totalSales: $totalSales');
        }
      });
    }

    //print('Final total sales for $productName: $totalSales');

    return totalSales;
  } catch (e) {
    //print('Error in getTotalSales: $e');
    // Handle or log the error as needed
    return 0; // Return a default value
  }
}

Future<int> getTotalPurchase(String productName) async {
  try {
    Database db = await database;
    List<Map<String, dynamic>> purchases = await db.query(
      purchaseTableName,
      where: '$productName > 0', // Assuming the column value > 0 means purchases occurred for the product
    );

    int totalPurchases = 0;

    //print('Purchases for $productName: $purchases');

    for (Map<String, dynamic> purchase in purchases) {
      purchase.forEach((key, value) {
        if (key != 'serial' && key != 'date' && value is int && value > 0) {
          totalPurchases += value;
          //print('Adding $value to totalPurchases. Current totalPurchases: $totalPurchases');
        }
      });
    }

    //print('Final total purchases for $productName: $totalPurchases');

    return totalPurchases;
  } catch (e) {
    //print('Error in getTotalPurchase: $e');
    // Handle or log the error as needed
    return 0; // Return a default value
  }
}
}

