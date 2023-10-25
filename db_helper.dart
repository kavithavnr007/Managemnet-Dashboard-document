import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';

class DatabaseConnection{

  Future<Database> setDatabase() async {
    var directory = await getApplicationDocumentsDirectory();
    var path = join(directory.path, 'db_crud');
    var database = await openDatabase(path, version: 2, onCreate: _createDatabase, onUpgrade: _onUpgrade);
    return database;
  }

  Future<void> _createDatabase(Database database, int version) async {
    String sql = "CREATE TABLE EmployeeProductivityFilter(id INTEGER PRIMARY KEY, selectedManagerOrEmployee TEXT, isWeekly INTEGER, isEmployee INTEGER, selectedWeek TEXT, selectedYear INTEGER, selectedMonth INTEGER)";
    await database.execute(sql);
  }

  Future<void> _onUpgrade(Database database, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      // Add the new columns to the existing table
      await database.execute("ALTER TABLE EmployeeProductivityFilter ADD COLUMN selectedYear INTEGER");
      await database.execute("ALTER TABLE EmployeeProductivityFilter ADD COLUMN selectedMonth INTEGER");
    }
  }
}