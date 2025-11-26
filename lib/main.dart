import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:talker_flutter/talker_flutter.dart';
import 'package:talker_bloc_logger/talker_bloc_logger.dart';

import 'core/services/hive_service.dart';
import 'core/services/supabase_sync_service.dart';
import 'core/services/logger_service.dart';
import 'core/bloc/auth/auth_bloc.dart';
import 'core/bloc/connectivity/connectivity_cubit.dart';
import 'config/theme_config.dart';

import 'screens/startup/cloud_restore_screen.dart';
import 'screens/startup/startup_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  LoggerService.info("📱 Mobile App Starting...");

  await Supabase.initialize(
    url: 'https://vvbjuezcwyakrnkrmgon.supabase.co', 
    anonKey: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InZ2Ymp1ZXpjd3lha3Jua3JtZ29uIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjMwMzI1ODUsImV4cCI6MjA3ODYwODU4NX0.MBloBPZdwfjit4N5heAxdWwRMOGHF3mPHsTkk-zZkWM', 
  );
  
  await HiveService.init();
  await SupabaseSyncService.init();
  
  Bloc.observer = TalkerBlocObserver(talker: LoggerService.instance);

  runApp(
    MultiBlocProvider(
      providers: [
        BlocProvider<AuthBloc>(create: (_) => AuthBloc()),
        BlocProvider<ConnectivityCubit>(create: (_) => ConnectivityCubit()),
      ],
      child: const CoffeaMobileApp(),
    ),
  );
}

class CoffeaMobileApp extends StatelessWidget {
  const CoffeaMobileApp({super.key});

  @override
  Widget build(BuildContext context) {
    final hasUsers = HiveService.userBox.isNotEmpty;

    return MaterialApp(
      title: 'Coffea Manager',
      debugShowCheckedModeBanner: false,
      theme: ThemeConfig.lightTheme,
      home: hasUsers ? const StartupScreen() : const CloudRestoreScreen(),
    );
  }
}