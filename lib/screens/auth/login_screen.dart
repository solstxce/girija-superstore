import 'package:flutter/material.dart';
import '../../models/models.dart';
import '../../services/services.dart';
import '../../theme/app_theme.dart';
import '../../widgets/widgets.dart';

class LoginScreen extends StatefulWidget {
  final LocalStorageService storageService;
  final Function(AppUser) onLogin;

  const LoginScreen({
    super.key,
    required this.storageService,
    required this.onLogin,
  });

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  bool _isAdmin = false;
  bool _isLoading = false;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final user = AppUser(
        id: 'user_${DateTime.now().millisecondsSinceEpoch}',
        name: _nameController.text.trim(),
        email: _emailController.text.trim(),
        phone: _phoneController.text.trim(),
        role: _isAdmin ? UserRole.admin : UserRole.customer,
      );

      await widget.storageService.saveCurrentUser(user);

      // Initialize sample data if first time
      final products = await widget.storageService.getProducts();
      if (products.isEmpty) {
        final sampleProducts = SampleDataService.getSampleProducts();
        await widget.storageService.saveProducts(sampleProducts);

        if (!_isAdmin) {
          final sampleAddresses = SampleDataService.getSampleAddresses();
          await widget.storageService.saveAddresses(sampleAddresses);

          final sampleOrders =
              SampleDataService.getSampleOrders(user.id, user.name);
          await widget.storageService.saveOrders(sampleOrders);
        }
      }

      widget.onLogin(user);
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Logo/Header
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
                    child: Icon(
                      Icons.storefront,
                      size: 48,
                      color: Theme.of(context).brightness == Brightness.dark ? AppTheme.backgroundDark : AppTheme.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'Girija Store',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.w700,
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Your neighborhood supermarket',
                    style: TextStyle(
                      fontSize: 14,
                      color: Theme.of(context).brightness == Brightness.dark ? AppTheme.textSecondaryDark : AppTheme.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 40),

                  // Role Selection
                  Row(
                    children: [
                      Expanded(
                        child: _RoleCard(
                          icon: Icons.person_outline,
                          label: 'Customer',
                          isSelected: !_isAdmin,
                          onTap: () => setState(() => _isAdmin = false),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: _RoleCard(
                          icon: Icons.admin_panel_settings_outlined,
                          label: 'Admin',
                          isSelected: _isAdmin,
                          onTap: () => setState(() => _isAdmin = true),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 32),

                  // Form Fields
                  AppTextField(
                    label: 'Full Name',
                    hint: 'Enter your name',
                    controller: _nameController,
                    prefixIcon: const Icon(Icons.person_outline),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Please enter your name';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  AppTextField(
                    label: 'Email',
                    hint: 'Enter your email',
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                    prefixIcon: const Icon(Icons.email_outlined),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Please enter your email';
                      }
                      if (!value.contains('@')) {
                        return 'Please enter a valid email';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  AppTextField(
                    label: 'Phone Number',
                    hint: 'Enter your phone number',
                    controller: _phoneController,
                    keyboardType: TextInputType.phone,
                    prefixIcon: const Icon(Icons.phone_outlined),
                  ),
                  const SizedBox(height: 32),

                  // Login Button
                  AppButton(
                    label: _isAdmin ? 'Continue as Admin' : 'Continue as Customer',
                    onPressed: _handleLogin,
                    isLoading: _isLoading,
                    width: double.infinity,
                    icon: Icons.arrow_forward,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Your data will be stored locally on this device',
                    style: TextStyle(
                      fontSize: 12,
                      color: Theme.of(context).brightness == Brightness.dark ? AppTheme.textSecondaryDark : AppTheme.textSecondary,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _RoleCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _RoleCard({
    required this.icon,
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: isSelected
              ? (isDark ? AppTheme.blueDark : AppTheme.primaryPastel).withValues(alpha: 0.3)
              : (isDark ? AppTheme.surfaceDark : AppTheme.surfaceLight),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? (isDark ? AppTheme.blueDark : AppTheme.primaryPastel) : (isDark ? AppTheme.borderDark : AppTheme.borderLight),
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Column(
          children: [
            Icon(
              icon,
              size: 32,
              color: isSelected
                  ? (isDark ? AppTheme.textPrimaryDark : AppTheme.textPrimary)
                  : (isDark ? AppTheme.textSecondaryDark : AppTheme.textSecondary),
            ),
            const SizedBox(height: 8),
            Text(
              label,
              style: TextStyle(
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                color: isSelected
                    ? (isDark ? AppTheme.textPrimaryDark : AppTheme.textPrimary)
                    : (isDark ? AppTheme.textSecondaryDark : AppTheme.textSecondary),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
