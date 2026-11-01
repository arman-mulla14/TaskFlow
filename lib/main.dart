import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'core/theme/app_theme.dart';
import 'data/repositories/database_service.dart';
import 'providers/app_state_provider.dart';
import 'providers/theme_provider.dart';
import 'ui/screens/main_scaffold.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final databaseService = DatabaseService();
  await databaseService.init();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider<ThemeProvider>(
          create: (_) => ThemeProvider(),
        ),
        ChangeNotifierProvider<AppStateProvider>(
          create: (_) => AppStateProvider(databaseService),
        ),
      ],
      child: const TaskFlowApp(),
    ),
  );
}

class TaskFlowApp extends StatelessWidget {
  const TaskFlowApp({super.key});

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);

    return MaterialApp(
      title: 'TaskFlow',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: themeProvider.themeMode,
      home: const MainScaffold(),
    );
  }
}
