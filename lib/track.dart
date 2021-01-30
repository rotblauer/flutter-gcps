import 'dart:async';

import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import 'package:geolocator/geolocator.dart';

const _cDatabaseName = 'cattracks_database.db';
const _cTableName = "cattracks";
const dbSchemaColumns = [
  'longitude numeric',
  'latitude numeric',
  'timestamp integer',
  'accuracy numeric',
  'altitude numeric',
  'floor integer',
  'heading numeric',
  'speed numeric',
  'speed_accuracy numeric'
];

// https://github.com/flutter/website/issues/2774
// Hi, if you like to make an unified database instance for the whole application, I suggest this way:
Future<Database> database() async {
  return openDatabase(
    // Set the path to the database. Note: Using the `join` function from the
    // `path` package is best practice to ensure the path is correctly
    // constructed for each platform.
    join(await getDatabasesPath(), 'cattracks_database.db'),

    // When the database is first created, create a table to store cats.
    onCreate: (db, version) {
      return db.execute(
        // "DROP TABLE IF EXISTS $_cTableName;" +
        'CREATE TABLE IF NOT EXISTS $_cTableName (id INTEGER PRIMARY KEY,' +
            dbSchemaColumns.join(", ") +
            ")",
      );
    },

    // // [onConfigure] is the first callback invoked when opening the database. It allows you to perform database initialization such as enabling foreign keys or write-ahead logging
    // onConfigure: (db) {
    //   return rmrfDb();
    // },

    // Set the version. This executes the onCreate function and provides a
    // path to perform database upgrades and downgrades.
    version: 1,
  );
}

Future<void> resetDB() async {
  var p = join(await getDatabasesPath(), _cDatabaseName);
  if (await databaseExists(p)) return deleteDatabase(p);
}

Future<void> insertTrack(Position position) async {
  final Database db = await database();
  final Map<String, dynamic> m = position.toJson();

  // App-specific key/value demands.
  if (!m.containsKey('timestamp') || m['timestamp'] == null) {
    return;
  }

  // App-specific mutations.
  m['timestamp'] = m['timestamp'] / 1000;
  m.remove('is_mocked');

  await db.insert(
    _cTableName,
    m,
    conflictAlgorithm: ConflictAlgorithm.replace,
  );
}

Future<int> countTracks() async {
  final Database db = await database();
  return Sqflite.firstIntValue(
      await db.rawQuery('SELECT COUNT(*) FROM $_cTableName'));
}

Future<int> lastId() async {
  final Database db = await database();
  var x = await db.rawQuery('SELECT id LIMIT 1 FROM $_cTableName');
  int lastID = Sqflite.firstIntValue(x);
  return lastID;
}