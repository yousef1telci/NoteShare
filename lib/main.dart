import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'core/constants/app_theme.dart';
import 'core/router/app_router.dart';

import 'package:flutter_dotenv/flutter_dotenv.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: ".env");
  
  // Initialize Supabase
  await Supabase.initialize(
    url: 'https://wjdccufwfqzizxewbxgs.supabase.co',
    anonKey: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6IndqZGNjdWZ3ZnF6aXp4ZXdieGdzIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzY5NTA4OTAsImV4cCI6MjA5MjUyNjg5MH0.jxrRpxQD_XElRYTBfz6HgCIeYUcHMK_0iT3b9nzgG9Y',
  );

  runApp(
    const ProviderScope(
      child: NoteShareApp(),
    ),
  );
}

class NoteShareApp extends ConsumerWidget {
  const NoteShareApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // We watch the router provider to get the latest routes with auth state redirect
    final router = ref.watch(routerProvider);

    return MaterialApp.router(
      title: 'NoteShare',
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.system,
      routerConfig: router,
      debugShowCheckedModeBanner: false,
    );
  }
}
