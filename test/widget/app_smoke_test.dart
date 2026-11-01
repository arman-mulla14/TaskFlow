import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:taskflow/core/theme/app_theme.dart';
import 'package:taskflow/data/models/phase_model.dart';
import 'package:taskflow/data/models/task_model.dart';
import 'package:taskflow/data/repositories/database_service.dart';
import 'package:taskflow/providers/app_state_provider.dart';
import 'package:taskflow/providers/theme_provider.dart';
import 'package:taskflow/ui/screens/main_scaffold.dart';

void main() {
  late Directory tempDir;
  late DatabaseService db;

  setUp(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    SharedPreferences.setMockInitialValues({});
    tempDir = await Directory.systemTemp.createTemp('taskflow_widget_test_');
    Hive.init(tempDir.path);

    db = DatabaseService();
    await db.init(isTest: true);

    final now = DateTime.now();
    final p1 = Phase(
      id: 'phase_1',
      title: 'Dart Foundations',
      weekDuration: 'Weeks 1–2',
      createdAt: now,
    );
    final t1 = Task(
      id: 'task_1',
      phaseId: 'phase_1',
      title: 'Variables & Data Types',
      status: TaskStatus.pending,
      priority: TaskPriority.high,
      createdAt: now,
    );

    await db.savePhase(p1);
    await db.saveTask(t1);
  });

  tearDown(() async {
    await Hive.close();
    try {
      if (tempDir.existsSync()) {
        tempDir.deleteSync(recursive: true);
      }
    } catch (_) {}
  });

  Widget createTestWidget(AppStateProvider appState) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider<ThemeProvider>(
          create: (_) => ThemeProvider(),
        ),
        ChangeNotifierProvider<AppStateProvider>.value(
          value: appState,
        ),
      ],
      child: Consumer<ThemeProvider>(
        builder: (context, themeProvider, _) {
          return MaterialApp(
            theme: AppTheme.lightTheme,
            darkTheme: AppTheme.darkTheme,
            themeMode: themeProvider.themeMode,
            home: const MainScaffold(),
          );
        },
      ),
    );
  }

  void setPhoneViewport(WidgetTester tester) {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });
  }

  group('TaskFlow Widget Tests', () {
    testWidgets('Renders MainScaffold with BottomNavigation destinations', (tester) async {
      setPhoneViewport(tester);

      final appState = AppStateProvider(db);
      await appState.reloadData();

      await tester.pumpWidget(createTestWidget(appState));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 800));

      expect(find.text('TaskFlow'), findsOneWidget);
      expect(find.text('Home'), findsOneWidget);
      expect(find.text('Tasks'), findsOneWidget);
      expect(find.text('Progress'), findsOneWidget);
      expect(find.text('Projects'), findsOneWidget);
      expect(find.text('Settings'), findsOneWidget);

      // Verify Dashboard contents
      expect(find.text('Import Roadmap Message'), findsOneWidget);
      expect(find.text('Overall Progress'), findsOneWidget);
      expect(find.text('Dart Foundations'), findsWidgets);
    });

    testWidgets('Switches tabs to Tasks and Settings screens', (tester) async {
      setPhoneViewport(tester);

      final appState = AppStateProvider(db);
      await appState.reloadData();

      await tester.pumpWidget(createTestWidget(appState));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 800));

      // Tap on Tasks tab
      await tester.tap(find.text('Tasks'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.text('Tasks & Topics'), findsOneWidget);
      expect(find.text('Variables & Data Types'), findsOneWidget);

      // Tap on Settings tab
      await tester.tap(find.text('Settings'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.text('Appearance & Display'), findsOneWidget);
      expect(find.text('Dark Mode'), findsOneWidget);
    });

    testWidgets('Task completion updates provider and reflects in UI', (tester) async {
      setPhoneViewport(tester);

      final appState = AppStateProvider(db);
      await appState.reloadData();

      await tester.pumpWidget(createTestWidget(appState));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 800));

      // Initial progress is 0%
      expect(find.text('0%'), findsWidgets);

      // Toggle task completion within runAsync for Hive disk persistence
      await tester.runAsync(() async {
        await appState.toggleTaskCompletion('task_1');
      });
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 800));

      // Progress dynamically updates to 100%
      expect(find.text('100%'), findsWidgets);
    });
  });
}
