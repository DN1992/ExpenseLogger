import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'dart:io' show Platform;
import 'screens/home_screen.dart';
import 'services/database_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize database factory for Linux desktop
  if (Platform.isLinux) {
    // Initialize FFI for Linux
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
    print('Database factory initialized for Linux desktop');
  }
  
  // Test database connection
  try {
    final dbService = DatabaseService();
    await dbService.database;
    print('Database initialized successfully');
    
    // Quick test to verify database is working
    final testDb = await dbService.database;
    print('Database path: ${testDb.path}');
  } catch (e) {
    print('Error initializing database: $e');
  }
  
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        Provider<DatabaseService>(
          create: (_) => DatabaseService(),
        ),
      ],
      child: MaterialApp(
        title: 'Expense Log',
        theme: ThemeData(
          primarySwatch: Colors.blue,
          useMaterial3: true,
          appBarTheme: const AppBarTheme(
            elevation: 0,
            centerTitle: true,
          ),
        ),
        home: const HomeScreen(),
        debugShowCheckedModeBanner: false,
      ),
    );
  }
}