import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'constants/app_theme.dart';
import 'services/storage_service.dart';
import 'services/theme_service.dart';
import 'screens/home_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Set system UI overlay style
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
    ),
  );

  final storageService = StorageService();
  final themeService = ThemeService();

  await storageService.init();

  runApp(RidoApp(
    storageService: storageService,
    themeService: themeService,
  ));
}

class RidoApp extends StatefulWidget {
  final StorageService storageService;
  final ThemeService themeService;

  const RidoApp({
    super.key,
    required this.storageService,
    required this.themeService,
  });

  @override
  State<RidoApp> createState() => _RidoAppState();
}

class _RidoAppState extends State<RidoApp> {
  @override
  void initState() {
    super.initState();
    widget.themeService.addListener(_onThemeChanged);
  }

  @override
  void dispose() {
    widget.themeService.removeListener(_onThemeChanged);
    super.dispose();
  }

  void _onThemeChanged() {
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Rido',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: widget.themeService.themeMode,
      home: HomeScreen(
        storageService: widget.storageService,
        themeService: widget.themeService,
      ),
    );
  }
}
