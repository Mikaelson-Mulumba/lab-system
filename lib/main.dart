import 'package:flutter/material.dart';
import 'package:powers_clinical_laboratories/pages/urine_lab_report.dart';

import 'pages/specimen_page.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

// Import your pages
import 'pages/add_patient_page.dart';
import 'pages/lab_report_page.dart';
import 'pages/patients_page.dart';
import 'pages/reports_page.dart';
import 'pages/settings_page.dart';
import 'pages/stock_addition_page.dart';
import 'pages/stock_list_page.dart';

import 'pages/test_type_list_page.dart';
import 'pages/users_page.dart';
import 'pages/home_page.dart';
import 'pages/patient_detail_page.dart';
import 'pages/login_page.dart';
import 'pages/dashboard_page.dart';

void main() {
  // ✅ Initialize sqflite FFI for desktop
  sqfliteFfiInit();
  databaseFactory = databaseFactoryFfi;

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Powers Laboratories',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      initialRoute: '/',
      routes: {
        '/': (context) => const HomePage(),
        '/login': (context) => const LoginPage(),
        '/dashboard': (context) => const DashboardPage(),
        '/add-patient': (context) => const AddPatientPage(),
        '/lab-report': (context) => const LabReportPage(),
        '/urine-lab-report': (context) => const UrineLabReportPage(),
        '/patient-detail': (context) => const PatientDetailPage(patientId: 'P001'),
        '/patients': (context) => const PatientsPage(),
        '/reports': (context) => const ReportsPage(),
        '/settings': (context) => const SettingsPage(),
        '/stock-addition': (context) => const StockAdditionPage(),
        '/stock-list': (context) => const StockListPage(),
        
        '/test-type-list': (context) => const TestTypeListPage(),
        '/users': (context) => const UsersPage(),
        '/specimen': (context) => const SpecimenPage(),
        
      },
    );
  }
}
