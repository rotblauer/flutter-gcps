import 'dart:async';
import 'dart:math';

import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import 'package:geolocator/geolocator.dart';
import 'package:flutter_background_geolocation/flutter_background_geolocation.dart'
    as bg;
import 'secrets.dart';

const _cDatabaseName = 'cattracks_database.db';
const _cTableName = "cattracks";
const dbSchemaColumns = [
  'uuid string',
  'time string',
  'timestamp integer',
  'accuracy real',
  'latitude real',
  'longitude real',
  'speed real',
  'speed_accuracy real',
  'heading real',
  'heading_accuracy real',
  'altitude real',
  'altitude_accuracy real',
  'odometer real',
  'activity_confidence integer',
  'activity_type string',
  'battery_level real',
  'battery_is_charging bool',
  'event string',
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
  m.remove('is_mocked');

  await db.insert(
    _cTableName,
    m,
    conflictAlgorithm: ConflictAlgorithm.replace,
  );
}

class AppPoint {
  final String uuid;
  final DateTime time;
  final int timestamp;
  final double accuracy;
  final double latitude;
  final double longitude;
  final double speed;
  final double speed_accuracy;
  final double heading;
  final double heading_accuracy;
  final double altitude;
  final double altitude_accuracy;
  final double odometer;
  final int activity_confidence;
  final String activity_type;
  final double battery_level;
  final bool battery_is_charging;
  final String event;

  AppPoint({
    this.uuid,
    this.time,
    this.timestamp,
    this.accuracy,
    this.latitude,
    this.longitude,
    this.speed,
    this.speed_accuracy,
    this.heading,
    this.heading_accuracy,
    this.altitude,
    this.altitude_accuracy,
    this.odometer,
    this.activity_confidence,
    this.activity_type,
    this.battery_level,
    this.battery_is_charging,
    this.event,
  });

  // toMap creates a dynamic map for persistence.
  Map<String, dynamic> toMap() {
    return {
      'uuid': uuid,
      'time': time,
      'timestamp': timestamp,
      'accuracy': accuracy,
      'latitude': latitude,
      'longitude': longitude,
      'speed': speed,
      'speed_accuracy': speed_accuracy,
      'heading': heading,
      'heading_accuracy': heading_accuracy,
      'altitude': altitude,
      'altitude_accuracy': altitude_accuracy,
      'odometer': odometer,
      'activity_confidence': activity_confidence,
      'activity_type': activity_type,
      'battery_level': battery_level,
      'battery_is_charging': battery_is_charging,
      'event': event,
    };
  }

  /// Converts the supplied [Map] to an instance of the [Position] class.
  static AppPoint fromMap(dynamic message) {
    if (message == null) {
      return null;
    }

    final Map<dynamic, dynamic> appMap = message;

    if (!appMap.containsKey('latitude')) {
      throw ArgumentError.value(appMap, 'appMap',
          'The supplied map doesn\'t contain the mandatory key `latitude`.');
    }

    if (!appMap.containsKey('longitude')) {
      throw ArgumentError.value(appMap, 'appMap',
          'The supplied map doesn\'t contain the mandatory key `longitude`.');
    }
    if (!appMap.containsKey('time')) {
      throw ArgumentError.value(appMap, 'appMap',
          'The supplied map doesn\'t contain the mandatory key `time`.');
    }

    return AppPoint(
      uuid: appMap['uuid'],
      timestamp: appMap['timestamp'],
      time: appMap['time'],
      latitude: appMap['latitude'],
      longitude: appMap['longitude'],
      accuracy: appMap['accuracy'] ?? -1.0,
      altitude: appMap['altitude'] ?? 0.0,
      altitude_accuracy: appMap['altitude_accuracy'] ?? -1.0,
      heading: appMap['heading'] ?? 0.0,
      heading_accuracy: appMap['heading_accuracy'] ?? -1.0,
      speed: appMap['speed'] ?? 0.0,
      speed_accuracy: appMap['speed_accuracy'] ?? -1.0,
      odometer: appMap['odometer'] ?? 0.0,
      activity_confidence: appMap['activity_confidence'] ?? 0.0,
      activity_type: appMap['activity_type'] ?? "Unknown",
      battery_level: appMap['battery_level'] ?? -1.0,
      battery_is_charging: appMap['battery_is_charging'] ?? false,
      event: appMap['event'] ?? "Unknown",
    );
  }

  static AppPoint fromLocationProvider(bg.Location location) {}

  // toJSON creates a dynamic map for JSON (push).
  Map<String, dynamic> toCattrackJSON() {
    /*
    type TrackPoint struct {
      Uuid       string    `json:"uuid"`
      PushToken  string    `json:"pushToken"`
      Version    string    `json:"version"`
      ID         int64     `json:"id"` //either bolt auto id or unixnano //think nano is better cuz can check for dupery
      Name       string    `json:"name"`
      Lat        float64   `json:"lat"`
      Lng        float64   `json:"long"`
      Accuracy   float64   `json:"accuracy"`  // horizontal, in meters
      VAccuracy  float64   `json:"vAccuracy"` // vertical, in meteres
      Elevation  float64   `json:"elevation"` //in meters
      Speed      float64   `json:"speed"`     //in kilometers per hour
      Tilt       float64   `json:"tilt"`      //degrees?
      Heading    float64   `json:"heading"`   //in degrees
      HeartRate  float64   `json:"heartrate"` // bpm
      Time       time.Time `json:"time"`
      Floor      int       `json:"floor"` // building floor if available
      Notes      string    `json:"notes"` //special events of the day
      COVerified bool      `json:"COVerified"`
      RemoteAddr string    `json:"remoteaddr"`
    }

    */
    return {
      'uuid': uuid,
      'version': appVersion,
      'name': deviceName,
      'time': time,
      'timestamp': timestamp,
      'lat': latitude.toPrecision(9),
      'long': longitude.toPrecision(9),
      'accuracy': accuracy.toPrecision(2),
      'speed': speed.toPrecision(2),
      'speed_accuracy': speed_accuracy.toPrecision(2),
      'heading': heading.toPrecision(0),
      'heading_accuracy': heading_accuracy.toPrecision(1),
      'elevation': altitude.toPrecision(2),
      'vAccuracy': altitude_accuracy.toPrecision(1),
      'notes': <String, dynamic>{
        'activity': activityTypeApp(activity_type),
        'activity_confidence': activity_confidence,
        'numberOfSteps': odometer.toPrecision(0),
        // 'distance'
        'batteryStatus': <String, dynamic>{
          'level': battery_level.toPrecision(0),
          'status':
              battery_is_charging ? 'full' : 'unplugged', // full/unplugged
        }
        // 'imgb64' string
      }
    };
  }
}

extension Precision on double {
  double toPrecision(int fractionDigits) {
    double mod = pow(10, fractionDigits.toDouble());
    return ((this * mod).round().toDouble() / mod);
  }
}

String activityTypeApp(String original) {
  switch (original) {
    case 'still':
      return 'Stationary';
    case 'on_foot':
      return 'Walking';
    case 'on_bicycle':
      return 'Bike';
    case 'running':
      return 'Running';
    case 'in_vehicle':
      return 'Driving';
    default:
      return 'Unknown';
  }
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

Future<List<AppPoint>> firstTracksWithLimit(int limit) async {
  final Database db = await database();
  final List<Map<String, dynamic>> maps =
      await db.query('$_cTableName', limit: limit, orderBy: 'id ASC');

  return List.generate(maps.length, (i) {
    return AppPoint.fromMap(maps[i]);
  });
}

Future<void> deleteTracksBeforeInclusive(int ts) async {
  final Database db = await database();
  await db.delete(_cTableName, where: 'timestamp <= ?', whereArgs: [ts]);
}
