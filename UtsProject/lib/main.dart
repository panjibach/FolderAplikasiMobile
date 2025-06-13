import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:utsproject/pages/main_page.dart';
import 'package:utsproject/services/category_services.dart';
import 'package:utsproject/services/transaction_service.dart';
import 'package:intl/intl.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:utsproject/pages/splashscreen.dart';
import 'package:utsproject/pages/transaction_list_page.dart';


void main() async {
  WidgetsFlutterBinding.ensureInitialized(); // Tambahkan ini agar async aman
  await initializeDateFormatting('id', null);

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => CategoryService()),
        ChangeNotifierProvider(create: (_) => TransactionService()),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'UTS Project',
      theme: ThemeData(
        primarySwatch: Colors.deepPurple,
        visualDensity: VisualDensity.adaptivePlatformDensity,
        fontFamily: 'Nunito',
      ),
      home: const SplashScreen(), // ← ini sekarang mulai dari splash
      debugShowCheckedModeBanner: false,
    );
  }
}