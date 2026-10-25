import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/project_model.dart';
import '../models/worker_model.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;

  DatabaseHelper._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('workshop_database.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    return await openDatabase(
      path,
      version: 2, // تحديث نسخة قاعدة البيانات لتعميد جدول الدفعات
      onCreate: _createDB,
      onUpgrade: (db, oldVersion, newVersion) async {
        if (oldVersion < 2) {
          await db.execute('''
            CREATE TABLE project_payments (
              id TEXT PRIMARY KEY,
              projectId INTEGER,
              amount REAL,
              date TEXT,
              note TEXT
            )
          ''');
        }
      },
    );
  }

  Future _createDB(Database db, int version) async {
    await db.execute('''
      CREATE TABLE projects (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        clientName TEXT,
        clientPhone TEXT,
        clientAddress TEXT,
        projectStatus TEXT,
        totalContract REAL,
        paymentDate TEXT
      )
    ''');

    await db.execute('''
      CREATE TABLE project_payments (
        id TEXT PRIMARY KEY,
        projectId INTEGER,
        amount REAL,
        date TEXT,
        note TEXT
      )
    ''');

    await db.execute('''
      CREATE TABLE workers (
        id TEXT PRIMARY KEY,
        name TEXT,
        phone TEXT,
        dailyRate REAL
      )
    ''');

    await db.execute('''
      CREATE TABLE worker_transactions (
        id TEXT PRIMARY KEY,
        workerId TEXT,
        amount REAL,
        originalAmount REAL,
        currency TEXT,
        date TEXT,
        note TEXT
      )
    ''');
  }

  // --- عمليات المشاريع والدفعات ---

  Future<int> insertProject(ProjectModel project, double initialPayment) async {
    final db = await instance.database;
    int projectId = await db.insert('projects', {
      'clientName': project.clientName,
      'clientPhone': project.clientPhone,
      'clientAddress': project.clientAddress,
      'projectStatus': project.projectStatus,
      'totalContract': project.totalContract,
      'paymentDate': project.paymentDate.toIso8601String(),
    });

    // إضافة الدفعة الأولى إن وجدت
    if (initialPayment > 0) {
      await insertProjectPayment(
        projectId,
        ProjectPayment(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          amount: initialPayment,
          date: project.paymentDate,
          note: 'الدفعة الأولى عند الاتفاق',
        ),
      );
    }

    return projectId;
  }

  Future<int> insertProjectPayment(int projectId, ProjectPayment payment) async {
    final db = await instance.database;
    return await db.insert('project_payments', {
      'id': payment.id,
      'projectId': projectId,
      'amount': payment.amount,
      'date': payment.date.toIso8601String(),
      'note': payment.note,
    });
  }

  Future<List<ProjectModel>> fetchProjects() async {
    final db = await instance.database;
    final result = await db.query('projects');

    List<ProjectModel> projects = [];
    for (var json in result) {
      int projectId = json['id'] as int;

      // جلب دفوعات هذا المشروع
      final paymentsResult = await db.query(
        'project_payments',
        where: 'projectId = ?',
        whereArgs: [projectId],
      );

      List<ProjectPayment> payments = paymentsResult.map((p) => ProjectPayment(
        id: p['id'] as String,
        amount: p['amount'] as double,
        date: DateTime.parse(p['date'] as String),
        note: p['note'] as String? ?? '',
      )).toList();

      projects.add(ProjectModel(
        id: projectId,
        clientName: json['clientName'] as String,
        clientPhone: json['clientPhone'] as String? ?? '',
        clientAddress: json['clientAddress'] as String? ?? '',
        projectStatus: json['projectStatus'] as String? ?? 'جاري العمل',
        totalContract: json['totalContract'] as double,
        paymentDate: DateTime.parse(json['paymentDate'] as String),
        payments: payments,
      ));
    }
    return projects;
  }

  Future<int> updateProjectStatus(int projectId, String newStatus) async {
    final db = await instance.database;
    return await db.update(
      'projects',
      {'projectStatus': newStatus},
      where: 'id = ?',
      whereArgs: [projectId],
    );
  }

  Future<int> deleteProject(int id) async {
    final db = await instance.database;
    await db.delete('project_payments', where: 'projectId = ?', whereArgs: [id]);
    return await db.delete('projects', where: 'id = ?', whereArgs: [id]);
  }

  // --- عمليات العمال ---

  Future<int> insertWorker(WorkerModel worker) async {
    final db = await instance.database;
    return await db.insert('workers', {
      'id': worker.id,
      'name': worker.name,
      'phone': worker.phone,
      'dailyRate': worker.dailyRate,
    });
  }

  Future<List<WorkerModel>> fetchWorkers() async {
    final db = await instance.database;
    final workerResult = await db.query('workers');

    List<WorkerModel> workers = [];
    for (var wJson in workerResult) {
      String workerId = wJson['id'] as String;

      final transResult = await db.query(
        'worker_transactions',
        where: 'workerId = ?',
        whereArgs: [workerId],
      );

      List<WorkerTransaction> transactions = transResult.map((tJson) => WorkerTransaction(
        id: tJson['id'] as String,
        amount: tJson['amount'] as double,
        originalAmount: tJson['originalAmount'] as double,
        currency: tJson['currency'] as String,
        date: DateTime.parse(tJson['date'] as String),
        note: tJson['note'] as String? ?? '',
      )).toList();

      workers.add(WorkerModel(
        id: workerId,
        name: wJson['name'] as String,
        phone: wJson['phone'] as String? ?? '',
        dailyRate: wJson['dailyRate'] as double,
        transactions: transactions,
      ));
    }
    return workers;
  }

  Future<int> insertWorkerTransaction(String workerId, WorkerTransaction tx) async {
    final db = await instance.database;
    return await db.insert('worker_transactions', {
      'id': tx.id,
      'workerId': workerId,
      'amount': tx.amount,
      'originalAmount': tx.originalAmount,
      'currency': tx.currency,
      'date': tx.date.toIso8601String(),
      'note': tx.note,
    });
  }

  Future<int> clearWorkerTransactions(String workerId) async {
    final db = await instance.database;
    return await db.delete(
      'worker_transactions',
      where: 'workerId = ?',
      whereArgs: [workerId],
    );
  }
}