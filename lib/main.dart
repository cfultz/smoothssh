import 'package:flutter/material.dart';
import 'theme/app_theme.dart';
import 'services/settings_service.dart';
import 'screens/dashboard_screen.dart';
import 'screens/lock_screen.dart';

final ValueNotifier<ThemeConfig> themeNotifier = ValueNotifier(
  ThemeConfig(baseTheme: 'dark', accentColor: 'blue')
);

bool globalIsAppLocked = false;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  final settings = SettingsService();
  final savedTheme = await settings.getThemeConfig();
  themeNotifier.value = savedTheme;
  
  globalIsAppLocked = await settings.isAppLockEnabled();
  
  runApp(const SmoothSSHApp());
}

class SmoothSSHApp extends StatefulWidget {
  const SmoothSSHApp({super.key});

  @override
  State<SmoothSSHApp> createState() => _SmoothSSHAppState();
}

class _SmoothSSHAppState extends State<SmoothSSHApp> with WidgetsBindingObserver {
  
  Key _lockKey = UniqueKey();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused && globalIsAppLocked) {
      setState(() {
        _lockKey = UniqueKey();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<ThemeConfig>(
      valueListenable: themeNotifier,
      builder: (context, currentConfig, _) {
        final currentTheme = AppTheme.getTheme(currentConfig);
        
        return MaterialApp(
          title: 'SmoothSSH',
          debugShowCheckedModeBanner: false,
          theme: currentTheme,
          
          builder: (context, child) {
            return Container(
              color: currentTheme.scaffoldBackgroundColor, 
              child: child,
            );
          },
          
          home: globalIsAppLocked 
              ? LockScreen(key: _lockKey, child: const DashboardScreen()) 
              : const DashboardScreen(),
        );
      },
    );
  }
}