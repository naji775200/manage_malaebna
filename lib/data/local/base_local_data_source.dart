import 'package:sqflite/sqflite.dart';
import '../local/database_helper.dart';

abstract class BaseLocalDataSource<T> {
  final String tableName;

  BaseLocalDataSource(this.tableName);

  Future<Database> get database async => await DatabaseHelper.instance.database;

  Future<String> insert(Map<String, dynamic> row) async {
    final db = await database;

    // Security warning for payments table
    if (tableName == 'payments') {
      print(
          '⚠️⚠️⚠️ WARNING: Using generic insert method for payments table! This bypasses stadium filtering.');
    }

    await db.insert(tableName, row,
        conflictAlgorithm: ConflictAlgorithm.replace);
    return row['id'] as String;
  }

  Future<int> update(Map<String, dynamic> row) async {
    final db = await database;

    // Security warning for payments table
    if (tableName == 'payments') {
      print(
          '⚠️⚠️⚠️ WARNING: Using generic update method for payments table! This bypasses stadium filtering.');
    }

    return await db.update(
      tableName,
      row,
      where: 'id = ?',
      whereArgs: [row['id']],
    );
  }

  Future<int> delete(String id) async {
    final db = await database;

    // Security warning for payments table
    if (tableName == 'payments') {
      print(
          '⚠️⚠️⚠️ WARNING: Using generic delete method for payments table! This bypasses stadium filtering.');
    }

    return await db.delete(
      tableName,
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<Map<String, dynamic>?> getById(String id) async {
    final db = await database;

    // Security warning for payments table
    if (tableName == 'payments') {
      print(
          '⚠️⚠️⚠️ WARNING: Using generic getById method for payments table! This bypasses stadium filtering.');
      print(
          '⚠️⚠️⚠️ Use PaymentLocalDataSource.getPaymentById(id, stadiumId: stadiumId) instead.');
      return null; // Block access for security
    }

    final maps = await db.query(
      tableName,
      where: 'id = ?',
      whereArgs: [id],
    );

    if (maps.isNotEmpty) {
      return maps.first;
    }
    return null;
  }

  Future<List<Map<String, dynamic>>> getAll() async {
    final db = await database;

    // Security warning for payments table
    if (tableName == 'payments') {
      print(
          '⚠️⚠️⚠️ WARNING: Using generic getAll method for payments table! This bypasses stadium filtering.');
      print(
          '⚠️⚠️⚠️ Use PaymentLocalDataSource.getAllPayments(stadiumId: stadiumId) instead.');
      return []; // Return empty list for security
    }

    return await db.query(tableName);
  }
}
