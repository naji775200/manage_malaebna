import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;

  DatabaseHelper._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('malaebna.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    return await openDatabase(
      path,
      version: 1,
      onCreate: _createDB,
    );
  }

  Future<void> _createDB(Database db, int version) async {
    // Addresses Table
    await db.execute('''
      CREATE TABLE addresses (
        id TEXT PRIMARY KEY,
        country TEXT,
        city TEXT,
        district TEXT,
        latitude REAL,
        longitude REAL
      )
    ''');

    // Players Table
    await db.execute('''
      CREATE TABLE players (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        phone_number TEXT UNIQUE,
        created_at TEXT,
        last_login_at TEXT,
        auth_provider TEXT,
        date_of_birth TEXT,
        address_id TEXT,
        number_of_matches INTEGER DEFAULT 0,
        average_rating REAL DEFAULT 0,
        level TEXT,
        status TEXT DEFAULT 'active',
        FOREIGN KEY (address_id) REFERENCES addresses (id)
      )
    ''');

    // Owners Table
    await db.execute('''
      CREATE TABLE owners (
        id TEXT PRIMARY KEY,
        name TEXT,
        phone_number TEXT UNIQUE,
        status TEXT DEFAULT 'active'
      )
    ''');

    // Stadiums Table
    await db.execute('''
      CREATE TABLE stadiums (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        address_id TEXT,
        description TEXT,
        bank_number TEXT,
        average_review REAL DEFAULT 0,
        booked_count INTEGER DEFAULT 0,
        phone_number TEXT UNIQUE,
        type TEXT,
        status TEXT DEFAULT 'active',
        FOREIGN KEY (address_id) REFERENCES addresses (id)
      )
    ''');

    // Fields Table
    await db.execute('''
      CREATE TABLE fields (
        id TEXT PRIMARY KEY,
        stadium_id TEXT,
        name TEXT,
        size TEXT,
        surface_type TEXT,
        created_at TEXT,
        status TEXT DEFAULT 'active',
        recommended_players_number INTEGER,
        FOREIGN KEY (stadium_id) REFERENCES stadiums (id)
      )
    ''');

    // Services Table
    await db.execute('''
      CREATE TABLE services (
        id TEXT PRIMARY KEY,
        english_name  TEXT,
        arabic_name TEXT,
        icon_name TEXT
      )
    ''');

    // Stadiums Services Table
    await db.execute('''
      CREATE TABLE stadiums_services (
        id TEXT PRIMARY KEY,
        stadium_id TEXT,
        service_id TEXT,
        created_at TEXT,
        FOREIGN KEY (stadium_id) REFERENCES stadiums (id),
        FOREIGN KEY (service_id) REFERENCES services (id)
      )
    ''');

    // Payments Table
    await db.execute('''
      CREATE TABLE payments (
        id TEXT PRIMARY KEY,
        amount REAL,
        currency TEXT,
        payment_method TEXT,
        status TEXT DEFAULT 'pending',
        transaction_id TEXT,
        payment_status TEXT DEFAULT 'pending'
      )
    ''');

    // Matches Table
    await db.execute('''
      CREATE TABLE matches (
        id TEXT PRIMARY KEY,
        field_id TEXT,
        date TEXT,
        start_time TEXT,
        end_time TEXT,
        current_players INTEGER DEFAULT 0,
        players_needed INTEGER,
        status TEXT DEFAULT 'active',
        created_at TEXT,
        description TEXT,
        level TEXT,
        FOREIGN KEY (field_id) REFERENCES fields (id),
        UNIQUE (field_id, date, start_time, end_time)
      )
    ''');

    // Match History Table
    await db.execute('''
      CREATE TABLE match_history (
        id TEXT PRIMARY KEY,
        match_id TEXT,
        result TEXT,
        FOREIGN KEY (match_id) REFERENCES matches (id)
      )
    ''');

    // Booking Table
    await db.execute('''
      CREATE TABLE booking (
        id TEXT PRIMARY KEY,
        player_id TEXT,
        match_id TEXT,
        payment_id TEXT,
        number_of_players INTEGER,
        status TEXT DEFAULT 'pending',
        created_at TEXT,
        FOREIGN KEY (player_id) REFERENCES players (id),
        FOREIGN KEY (match_id) REFERENCES matches (id),
        FOREIGN KEY (payment_id) REFERENCES payments (id),
        UNIQUE (match_id, player_id)
      )
    ''');

    // Booking Players Table
    await db.execute('''
      CREATE TABLE booking_players (
        id TEXT PRIMARY KEY,
        booking_id TEXT,
        player_id TEXT,
        name TEXT,
        added_by TEXT,
        FOREIGN KEY (booking_id) REFERENCES booking (id),
        FOREIGN KEY (player_id) REFERENCES players (id),
        FOREIGN KEY (added_by) REFERENCES players (id)
      )
    ''');

    // Reviews Table
    await db.execute('''
      CREATE TABLE reviews (
        id TEXT PRIMARY KEY,
        player_id TEXT,
        stadium_id TEXT,
        rating INTEGER,
        comment TEXT,
        created_at TEXT,
        reviewer_type TEXT,
        FOREIGN KEY (player_id) REFERENCES players (id),
        FOREIGN KEY (stadium_id) REFERENCES stadiums (id),
        UNIQUE (player_id, stadium_id)
      )
    ''');

    // Entity Images Table
    await db.execute('''
      CREATE TABLE entity_images (
        id TEXT PRIMARY KEY,
        entity_type TEXT NOT NULL,
        entity_id TEXT NOT NULL,
        image_url TEXT NOT NULL,
        created_at TEXT
      )
    ''');

    // Working Hours Table
    await db.execute('''
      CREATE TABLE working_hours (
        id TEXT PRIMARY KEY,
        stadium_id TEXT,
        start_time TEXT,
        end_time TEXT,
        day_of_week TEXT,
        FOREIGN KEY (stadium_id) REFERENCES stadiums (id),
        UNIQUE (stadium_id, day_of_week)
      )
    ''');

    // Times Off Table
    await db.execute('''
      CREATE TABLE times_off (
        id TEXT PRIMARY KEY,
        stadium_id TEXT,
        start_time TEXT,
        end_time TEXT,
        frequency TEXT,
        days_of_week TEXT,
        specific_date TEXT,
        title TEXT,
        FOREIGN KEY (stadium_id) REFERENCES stadiums (id)
      )
    ''');

    // Coupons Table
    await db.execute('''
      CREATE TABLE coupons (
        id TEXT PRIMARY KEY,
        stadium_id TEXT,
        name TEXT,
        code TEXT,
        discount_percentage INTEGER,
        expiration_date TEXT,
        status TEXT DEFAULT 'active',
        start_time TEXT,
        end_time TEXT,
        days_of_week TEXT,
        FOREIGN KEY (stadium_id) REFERENCES stadiums (id)
      )
    ''');

    // Coupon Usage Table
    await db.execute('''
      CREATE TABLE coupon_usage (
        id TEXT PRIMARY KEY,
        coupon_id TEXT,
        player_id TEXT,
        used_at TEXT,
        FOREIGN KEY (coupon_id) REFERENCES coupons (id),
        FOREIGN KEY (player_id) REFERENCES players (id)
      )
    ''');

    // Prices Table
    await db.execute('''
      CREATE TABLE prices (
        id TEXT PRIMARY KEY,
        field_id TEXT,
        start_time TEXT,
        end_time TEXT,
        price_per_hour REAL,
        days_of_week TEXT,
        FOREIGN KEY (field_id) REFERENCES fields (id)
      )
    ''');

    // Notifications Table
    await db.execute('''
      CREATE TABLE notifications (
        id TEXT PRIMARY KEY,
        sender_id TEXT,
        receiver_id TEXT,
        message TEXT,
        type TEXT,
        is_read INTEGER DEFAULT 0,
        sent_at TEXT,
        FOREIGN KEY (sender_id) REFERENCES players (id),
        FOREIGN KEY (receiver_id) REFERENCES players (id)
      )
    ''');

    // Stadium Owners Table
    await db.execute('''
      CREATE TABLE stadium_owners (
        id TEXT PRIMARY KEY,
        stadium_id TEXT,
        owner_id TEXT,
        created_at TEXT,
        FOREIGN KEY (stadium_id) REFERENCES stadiums (id),
        FOREIGN KEY (owner_id) REFERENCES owners (id)
      )
    ''');

    // Cancellations Table
    await db.execute('''
      CREATE TABLE cancellations (
        id TEXT PRIMARY KEY,
        booking_id TEXT,
        reason TEXT,
        refund_amount REAL,
        canceled_at TEXT,
        FOREIGN KEY (booking_id) REFERENCES booking (id)
      )
    ''');

    // Logs Table
    await db.execute('''
      CREATE TABLE logs (
        id TEXT PRIMARY KEY,
        log_type TEXT NOT NULL,
        entity_id TEXT NOT NULL,
        action TEXT NOT NULL,
        performed_by TEXT,
        description TEXT,
        created_at TEXT
      )
    ''');
  }

  // Helper method to close the database
  Future<void> close() async {
    final db = await instance.database;
    db.close();
  }

  // Helper method to clear all data from the database
  Future<void> clearAllData() async {
    final db = await instance.database;

    // Get list of all tables
    final tables = await db.rawQuery(
        "SELECT name FROM sqlite_master WHERE type='table' AND name NOT LIKE 'sqlite_%' AND name NOT LIKE 'android_%'");

    // Use a transaction for better performance and to ensure atomicity
    await db.transaction((txn) async {
      for (final table in tables) {
        final tableName = table['name'] as String;
        await txn.rawDelete('DELETE FROM $tableName');
        print('Cleared table: $tableName');
      }
    });

    print('All local database tables have been cleared');
  }
}
