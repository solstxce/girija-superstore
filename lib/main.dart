import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'models/models.dart';
import 'services/services.dart';
import 'screens/screens.dart';
import 'theme/app_theme.dart';
import 'theme/theme_provider.dart';
import 'widgets/widgets.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  final storageService = LocalStorageService();
  await storageService.init();
  
  runApp(
    ChangeNotifierProvider(
      create: (_) => ThemeProvider(),
      child: GirijaApp(storageService: storageService),
    ),
  );
}

class GirijaApp extends StatefulWidget {
  final LocalStorageService storageService;
  
  const GirijaApp({super.key, required this.storageService});

  @override
  State<GirijaApp> createState() => _GirijaAppState();
}

class _GirijaAppState extends State<GirijaApp> {
  AppUser? _currentUser;
  bool _isLoading = true;
  String _appVersion = '';
  final UpdateService _updateService = UpdateService();
  final GlobalKey<NavigatorState> _navigatorKey = GlobalKey<NavigatorState>();

  @override
  void initState() {
    super.initState();
    _initialize();
  }

  Future<void> _initialize() async {
    // Get app version from package info
    final packageInfo = await PackageInfo.fromPlatform();
    _appVersion = packageInfo.version;
    
    // Check existing user
    final user = await widget.storageService.getCurrentUser();
    setState(() {
      _currentUser = user;
      _isLoading = false;
    });
    
    // Schedule update check after first frame is built
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkForUpdate();
    });
  }

  Future<void> _checkForUpdate() async {
    debugPrint('🚀 Starting update check...');
    debugPrint('📱 Current app version: $_appVersion');
    
    final updateInfo = await _updateService.checkForUpdate();
    _appVersion, latest=${updateInfo.version}');
    final isUpdateAvailable = _updateService.isUpdateAvailable(_appVersion, updateInfo.version);
    debugPrint('📊 Is update available: $isUpdateAvailable');
    
    if (!isUpdateAvailable) {
      debugPrint('✅ App is up to date');
      return;
    }
    
    final isRequired = _updateService.isUpdateRequired(_appVersion, updateInfo);
    debugPrint('⚠️ Is update required: $isRequired');
    
    final context = _navigatorKey.currentContext;
    if (context != null && mounted) {
      debugPrint('🎯 Showing update dialog');
      showDialog(
        context: context,
        barrierDismissible: !isRequired,
        builder: (context) => UpdateDialog(
          updateInfo: updateInfo,
          currentVersion: _ng update dialog');
      showDialog(
        context: context,
        barrierDismissible: !isRequired,
        builder: (context) => UpdateDialog(
          updateInfo: updateInfo,
          currentVersion: appVersion,
          isRequired: isRequired,
        ),
      );
    } else {
      debugPrint('❌ Navigator context not available');
    }
  }

  void _handleLogin(AppUser user) {
    setState(() => _currentUser = user);
  }

  Future<void> _handleSignOut() async {
    await widget.storageService.clearCurrentUser();
    setState(() => _currentUser = null);
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    
    return MaterialApp(
      navigatorKey: _navigatorKey,
      title: 'Girija Store',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: themeProvider.themeMode,
      home: _isLoading
          ? const _SplashScreen()
          : _currentUser == null
              ? LoginScreen(
                  storageService: widget.storageService,
                  onLogin: _handleLogin,
                )
              : _currentUser!.isAdmin
                  ? AdminHomeScreen(
                      user: _currentUser!,
                      storageService: widget.storageService,
                      onSignOut: _handleSignOut,
                    )
                  : UserHomeScreen(
                      user: _currentUser!,
                      storageService: widget.storageService,
                      onSignOut: _handleSignOut,
                    ),
    );
  }
}

class _SplashScreen extends StatelessWidget {
  const _SplashScreen();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    AppTheme.primaryPastel,
                    AppTheme.secondaryPastel,
                  ],
                ),
                borderRadius: BorderRadius.circular(24),
              ),
              child: const Icon(
                Icons.storefront,
                size: 48,
                color: AppTheme.textPrimary,
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'Girija Store',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.w700,
                color: AppTheme.textPrimary,
              ),
            ),
            const SizedBox(height: 24),
            const CircularProgressIndicator(),
          ],
        ),
      ),
    );
  }
}
