import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'models/models.dart';
import 'services/services.dart';
import 'screens/screens.dart';
import 'theme/app_theme.dart';
import 'theme/theme_provider.dart';

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

  @override
  void initState() {
    super.initState();
    _checkExistingUser();
  }

  Future<void> _checkExistingUser() async {
    final user = await widget.storageService.getCurrentUser();
    setState(() {
      _currentUser = user;
      _isLoading = false;
    });
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
