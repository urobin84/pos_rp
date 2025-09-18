import 'package:path/path.dart';
import 'package:pos_rp/models/customer_model.dart';
import 'package:pos_rp/models/transaction_item_model.dart';
import 'package:pos_rp/models/user_model.dart';
import 'package:pos_rp/models/transaction_model.dart';
import 'package:pos_rp/models/purchase_item_model.dart';
import 'package:pos_rp/models/expense_model.dart';
import 'package:pos_rp/models/purchase_model.dart';
import 'package:pos_rp/models/supplier_model.dart';
import 'package:pos_rp/models/product_model.dart';
import 'package:sqflite/sqflite.dart' hide Transaction;

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;

  DatabaseHelper._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('pos.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    return await openDatabase(
      path,
      version: 9, // Incremented version
      onCreate: _createDB,
      onUpgrade: _onUpgrade,
    );
  }

  Future _createDB(Database db, int version) async {
    const idType = 'TEXT PRIMARY KEY';
    const textType = 'TEXT NOT NULL';
    const doubleType = 'REAL NOT NULL';
    const textTypeNullable = 'TEXT';
    const integerType = 'INTEGER NOT NULL';

    await db.execute('''
CREATE TABLE products ( 
  id $idType, 
  name $textType,
  price $doubleType,
  description $textType,
  imageUrl $textType,
  stock $integerType,
  sku $textType,
  category $textType,
  brand $textType,
  costPrice $doubleType,
  minStockLevel $integerType,
  expirationDate $textTypeNullable
  )
''');

    await db.execute('''
CREATE TABLE customers ( 
  id $idType, 
  name $textType,
  email $textType,
  phone $textType,
  address $textType,
  dateOfBirth $textTypeNullable,
  registrationDate $textType
  )
''');

    await db.execute('''
CREATE TABLE transactions (
  id $idType,
  customerName $textType,
  totalAmount $doubleType,
  paymentMethod $textType,
  createdAt $textType,
  status $textType,
  cashierName $textType,
  subtotal $doubleType,
  discount $doubleType,
  additionalCosts $doubleType
)
''');

    await db.execute('''
CREATE TABLE users (
  id $idType,
  name $textType,
  email $textType UNIQUE,
  password $textType,
  phone $textTypeNullable,
  imagePath $textTypeNullable
)
''');

    await db.execute('''
CREATE TABLE transaction_items (
  id TEXT PRIMARY KEY,
  transactionId $textType,
  productId $textType,
  productName $textType,
  quantity $integerType,
  price $doubleType,
  costPrice $doubleType,
  FOREIGN KEY (transactionId) REFERENCES transactions (id) ON DELETE CASCADE
)
''');

    await db.execute('''
CREATE TABLE suppliers (
  id $idType,
  name $textType,
  contactPerson $textTypeNullable,
  phone $textTypeNullable,
  email $textTypeNullable,
  address $textTypeNullable
)
''');

    await db.execute('''
CREATE TABLE purchases (
  id $idType,
  supplierId $textType,
  supplierName $textType,
  purchaseDate $textType,
  totalCost $doubleType
)
''');

    await db.execute(
      '''CREATE TABLE purchase_items (id TEXT PRIMARY KEY, purchaseId TEXT NOT NULL, productId TEXT NOT NULL, productName TEXT NOT NULL, quantity INTEGER NOT NULL, costPrice REAL NOT NULL, FOREIGN KEY (purchaseId) REFERENCES purchases (id) ON DELETE CASCADE)''',
    );

    await db.execute('''
CREATE TABLE expenses (
  id $idType,
  description $textType,
  amount $doubleType,
  category $textType,
  date $textType
)
''');

    await _seedData(db);
  }

  Future<void> _seedData(Database db) async {
    final initialProducts = [
      Product(
        id: 'p1',
        name: 'Bakso Tahu Komplit',
        price: 15000,
        description: 'Paket komplit bakso sapi dengan tahu, mie, dan sayuran.',
        imageUrl:
            'https://via.placeholder.com/150/A1887F/FFFFFF?Text=Bakso+Komplit',
        brand: 'Bakso Enak Joss',
        category: 'Makanan Berat',
        costPrice: 10000,
        stock: 100,
        minStockLevel: 10,
        sku: 'BEJ-BTK',
      ),
      Product(
        id: 'p2',
        name: 'Bakso Saja',
        price: 25000,
        description: 'Satu porsi penuh bakso sapi asli tanpa tambahan.',
        imageUrl: 'https://via.placeholder.com/150/6D4C41/FFFFFF?Text=Bakso',
        brand: 'Bakso Enak Joss',
        category: 'Makanan Berat',
        costPrice: 18000,
        stock: 80,
        minStockLevel: 10,
        sku: 'BEJ-BS',
      ),
      Product(
        id: 'p3',
        name: 'Bakso Tahu',
        price: 20000,
        description: 'Kombinasi bakso sapi kenyal dengan tahu lembut.',
        imageUrl:
            'https://via.placeholder.com/150/4E342E/FFFFFF?Text=Bakso+Tahu',
        brand: 'Bakso Enak Joss',
        category: 'Makanan Berat',
        costPrice: 14000,
        stock: 120,
        minStockLevel: 15,
        sku: 'BEJ-BT',
      ),
      Product(
        id: 'p4',
        name: 'Mochi Paket A',
        price: 30000,
        description: 'Paket mochi isi 10 aneka rasa: Kacang, Coklat, Keju.',
        imageUrl: 'https://via.placeholder.com/150/FFC107/000000?Text=Mochi+A',
        brand: 'momo mochi - sukabumi',
        category: 'Cemilan',
        costPrice: 22000,
        stock: 50,
        minStockLevel: 5,
        sku: 'MM-PKA',
      ),
      Product(
        id: 'p5',
        name: 'Mochi Paket B',
        price: 35000,
        description:
            'Paket mochi isi 10 rasa premium: Durian, Green Tea, Wijen Hitam.',
        imageUrl: 'https://via.placeholder.com/150/8D6E63/FFFFFF?Text=Mochi+B',
        brand: 'momo mochi - sukabumi',
        category: 'Cemilan',
        costPrice: 27000,
        stock: 40,
        minStockLevel: 5,
        sku: 'MM-PKB',
      ),
      Product(
        id: 'p6',
        name: 'Mochi Coklat',
        price: 3500,
        description: 'Mochi satuan dengan isian coklat lumer yang manis.',
        imageUrl: 'https://via.placeholder.com/150/D32F2F/FFFFFF?Text=Mochi',
        brand: 'momo mochi - sukabumi',
        category: 'Cemilan',
        costPrice: 2000,
        stock: 200,
        minStockLevel: 20,
        sku: 'MM-COKLAT',
      ),
    ];

    final initialCustomers = [
      Customer(
        id: 'c1',
        name: 'Budi Santoso',
        email: 'budi.s@example.com',
        phone: '081234567890',
        address: 'Jl. Merdeka No. 1, Jakarta',
        registrationDate: DateTime.now().subtract(const Duration(days: 30)),
      ),
      Customer(
        id: 'c2',
        name: 'Citra Lestari',
        email: 'citra.l@example.com',
        phone: '081209876543',
        address: 'Jl. Pahlawan No. 10, Surabaya',
        registrationDate: DateTime.now().subtract(const Duration(days: 15)),
      ),
      Customer(
        id: 'c3',
        name: 'Agus Wijaya',
        email: 'agus.w@example.com',
        phone: '081211223344',
        address: 'Jl. Diponegoro No. 5, Bandung',
        registrationDate: DateTime.now().subtract(const Duration(days: 5)),
      ),
    ];

    for (var product in initialProducts) {
      await db.insert(
        'products',
        product.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }
    for (var customer in initialCustomers) {
      await db.insert(
        'customers',
        customer.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }
  }

  // Product CRUD
  Future<Product> createProduct(Product product) async {
    final db = await instance.database;
    await db.insert('products', product.toMap());
    return product;
  }

  Future<List<Product>> readAllProducts() async {
    final db = await instance.database;
    final result = await db.query('products');
    return result.map((json) => Product.fromMap(json)).toList();
  }

  Future<int> updateProduct(Product product) async {
    final db = await instance.database;
    return db.update(
      'products',
      product.toMap(),
      where: 'id = ?',
      whereArgs: [product.id],
    );
  }

  Future<int> deleteProduct(String id) async {
    final db = await instance.database;
    return await db.delete('products', where: 'id = ?', whereArgs: [id]);
  }

  // Customer CRUD
  Future<Customer> createCustomer(Customer customer) async {
    final db = await instance.database;
    await db.insert('customers', customer.toMap());
    return customer;
  }

  Future<List<Customer>> readAllCustomers() async {
    final db = await instance.database;
    final result = await db.query('customers');
    return result.map((json) => Customer.fromMap(json)).toList();
  }

  Future<int> updateCustomer(Customer customer) async {
    final db = await instance.database;
    return db.update(
      'customers',
      customer.toMap(),
      where: 'id = ?',
      whereArgs: [customer.id],
    );
  }

  Future<int> deleteCustomer(String id) async {
    final db = await instance.database;
    return await db.delete('customers', where: 'id = ?', whereArgs: [id]);
  }

  // Supplier CRUD
  Future<void> createSupplier(Supplier supplier) async {
    final db = await instance.database;
    await db.insert('suppliers', supplier.toMap());
  }

  Future<List<Supplier>> readAllSuppliers() async {
    final db = await instance.database;
    final result = await db.query('suppliers', orderBy: 'name ASC');
    return result.map((json) => Supplier.fromMap(json)).toList();
  }

  Future<int> updateSupplier(Supplier supplier) async {
    final db = await instance.database;
    return db.update(
      'suppliers',
      supplier.toMap(),
      where: 'id = ?',
      whereArgs: [supplier.id],
    );
  }

  Future<int> deleteSupplier(String id) async {
    final db = await instance.database;
    return await db.delete('suppliers', where: 'id = ?', whereArgs: [id]);
  }

  // Expense CRUD
  Future<void> createExpense(Expense expense) async {
    final db = await instance.database;
    await db.insert('expenses', expense.toMap());
  }

  Future<List<Expense>> readAllExpenses() async {
    final db = await instance.database;
    final result = await db.query('expenses', orderBy: 'date DESC');
    return result.map((json) => Expense.fromMap(json)).toList();
  }

  Future<int> updateExpense(Expense expense) async {
    final db = await instance.database;
    return db.update(
      'expenses',
      expense.toMap(),
      where: 'id = ?',
      whereArgs: [expense.id],
    );
  }

  Future<int> deleteExpense(String id) async {
    final db = await instance.database;
    return await db.delete('expenses', where: 'id = ?', whereArgs: [id]);
  }

  // Purchase CRUD
  Future<void> createPurchase(Purchase purchase) async {
    final db = await instance.database;
    await db.transaction((txn) async {
      await txn.insert('purchases', purchase.toMapForDb());
      for (final item in purchase.items) {
        await txn.insert('purchase_items', item.toMap());
      }
    });
  }

  Future<List<Purchase>> readAllPurchases() async {
    final db = await instance.database;
    final purchaseMaps = await db.query(
      'purchases',
      orderBy: 'purchaseDate DESC',
    );

    final List<Purchase> purchases = [];
    for (final purchaseMap in purchaseMaps) {
      final itemMaps = await db.query(
        'purchase_items',
        where: 'purchaseId = ?',
        whereArgs: [purchaseMap['id']],
      );
      final items =
          itemMaps.map((itemMap) => PurchaseItem.fromMap(itemMap)).toList();
      purchases.add(Purchase.fromMap(purchaseMap, items));
    }
    return purchases;
  }

  // User CRUD
  Future<User> createUser(User user) async {
    final db = await instance.database;
    await db.insert('users', user.toMap());
    return user;
  }

  Future<User?> readUser(String id) async {
    final db = await instance.database;
    final maps = await db.query('users', where: 'id = ?', whereArgs: [id]);
    if (maps.isNotEmpty) {
      return User.fromMap(maps.first);
    }
    return null;
  }

  Future<User?> readUserByEmail(String email) async {
    final db = await instance.database;
    final maps = await db.query(
      'users',
      where: 'email = ?',
      whereArgs: [email],
    );
    if (maps.isNotEmpty) {
      return User.fromMap(maps.first);
    }
    return null;
  }

  Future<int> updateUser(User user) async {
    final db = await instance.database;
    return db.update(
      'users',
      user.toMap(),
      where: 'id = ?',
      whereArgs: [user.id],
    );
  }

  // Transaction CRUD
  Future<void> createTransaction(Transaction transaction) async {
    final db = await instance.database;
    await db.transaction((txn) async {
      await txn.insert('transactions', transaction.toMapForDb());
      for (final item in transaction.items) {
        await txn.insert('transaction_items', item.toMap());
      }
    });
  }

  Future<List<Transaction>> readAllTransactions() async {
    final db = await instance.database;
    final transactionMaps = await db.query(
      'transactions',
      orderBy: 'createdAt DESC',
    );

    final List<Transaction> transactions = [];
    for (final transactionMap in transactionMaps) {
      final itemMaps = await db.query(
        'transaction_items',
        where: 'transactionId = ?',
        whereArgs: [transactionMap['id']],
      );
      final items =
          itemMaps.map((itemMap) => TransactionItem.fromMap(itemMap)).toList();
      transactions.add(Transaction.fromMap(transactionMap, items));
    }
    return transactions;
  }

  // This callback is executed when the database is upgraded to a new version.
  Future _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      const idType = 'TEXT PRIMARY KEY';
      const textType = 'TEXT NOT NULL';
      const doubleType = 'REAL NOT NULL';
      const integerType = 'INTEGER NOT NULL';

      await db.execute('''
CREATE TABLE transactions (
  id $idType,
  customerName $textType,
  totalAmount $doubleType,
  paymentMethod $textType,
  createdAt $textType
)
''');

      await db.execute('''
CREATE TABLE transaction_items (
  id TEXT PRIMARY KEY,
  transactionId $textType,
  productId $textType,
  productName $textType,
  quantity $integerType,
  price $doubleType,
  FOREIGN KEY (transactionId) REFERENCES transactions (id) ON DELETE CASCADE
)
''');
    }
    if (oldVersion < 3) {
      await db.execute(
        'ALTER TABLE products ADD COLUMN sku TEXT NOT NULL DEFAULT \'\'',
      );
      await db.execute(
        'ALTER TABLE products ADD COLUMN category TEXT NOT NULL DEFAULT \'Uncategorized\'',
      );
      await db.execute(
        'ALTER TABLE products ADD COLUMN brand TEXT NOT NULL DEFAULT \'\'',
      );
      await db.execute(
        'ALTER TABLE products ADD COLUMN costPrice REAL NOT NULL DEFAULT 0.0',
      );
      await db.execute(
        'ALTER TABLE products ADD COLUMN minStockLevel INTEGER NOT NULL DEFAULT 0',
      );
      await db.execute('ALTER TABLE products ADD COLUMN expirationDate TEXT');
    }
    if (oldVersion < 4) {
      await db.execute('ALTER TABLE customers ADD COLUMN dateOfBirth TEXT');
      await db.execute(
        'ALTER TABLE customers ADD COLUMN registrationDate TEXT NOT NULL DEFAULT \'${DateTime.now().toIso8601String()}\'',
      );
    }
    if (oldVersion < 5) {
      await db.execute(
        'ALTER TABLE transactions ADD COLUMN status TEXT NOT NULL DEFAULT \'Completed\'',
      );
      await db.execute(
        'ALTER TABLE transactions ADD COLUMN cashierName TEXT NOT NULL DEFAULT \'Admin\'',
      );
      await db.execute(
        'ALTER TABLE transactions ADD COLUMN subtotal REAL NOT NULL DEFAULT 0.0',
      );
      await db.execute(
        'ALTER TABLE transactions ADD COLUMN discount REAL NOT NULL DEFAULT 0.0',
      );
      await db.execute(
        'ALTER TABLE transactions ADD COLUMN additionalCosts REAL NOT NULL DEFAULT 0.0',
      );
    }
    if (oldVersion < 6) {
      const idType = 'TEXT PRIMARY KEY';
      const textType = 'TEXT NOT NULL';
      const textTypeNullable = 'TEXT';
      await db.execute('''
CREATE TABLE users (
  id $idType,
  name $textType,
  email $textType UNIQUE,
  password $textType,
  phone $textTypeNullable,
  imagePath $textTypeNullable
)
''');
    }
    if (oldVersion < 7) {
      await db.execute(
        'ALTER TABLE transaction_items ADD COLUMN costPrice REAL NOT NULL DEFAULT 0.0',
      );
    }
    if (oldVersion < 8) {
      const idType = 'TEXT PRIMARY KEY';
      const textType = 'TEXT NOT NULL';
      const doubleType = 'REAL NOT NULL';
      const textTypeNullable = 'TEXT';

      await db.execute('''
CREATE TABLE suppliers (
  id $idType,
  name $textType,
  contactPerson $textTypeNullable,
  phone $textTypeNullable,
  email $textTypeNullable,
  address $textTypeNullable
)
''');

      await db.execute(
        '''CREATE TABLE purchases (id TEXT PRIMARY KEY, supplierId TEXT NOT NULL, supplierName TEXT NOT NULL, purchaseDate TEXT NOT NULL, totalCost REAL NOT NULL)''',
      );

      await db.execute(
        '''CREATE TABLE purchase_items (id TEXT PRIMARY KEY, purchaseId TEXT NOT NULL, productId TEXT NOT NULL, productName TEXT NOT NULL, quantity INTEGER NOT NULL, costPrice REAL NOT NULL, FOREIGN KEY (purchaseId) REFERENCES purchases (id) ON DELETE CASCADE)''',
      );
    }
    if (oldVersion < 9) {
      const idType = 'TEXT PRIMARY KEY';
      const textType = 'TEXT NOT NULL';
      const doubleType = 'REAL NOT NULL';

      await db.execute('''
CREATE TABLE expenses (
  id $idType,
  description $textType,
  amount $doubleType,
  category $textType,
  date $textType
)
''');
    }
  }
}
