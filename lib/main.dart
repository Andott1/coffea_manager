import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
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

  // 1. Retrieve keys from the environment
  // We use a fallback (empty string) just to prevent a crash if you forget the flag,
  // but Supabase will fail to initialize if they are empty.
  const supabaseUrl = String.fromEnvironment('SUPABASE_URL');
  const supabaseKey = String.fromEnvironment('SUPABASE_ANON_KEY');

  // 2. check if keys are present (Optional safety check)
  if (supabaseUrl.isEmpty || supabaseKey.isEmpty) {
    LoggerService.error('❌ Supabase credentials missing! Run with --dart-define');
  }

  await Supabase.initialize(
    url: supabaseUrl, 
    anonKey: supabaseKey, 
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