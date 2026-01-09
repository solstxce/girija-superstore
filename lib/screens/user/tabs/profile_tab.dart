import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../models/models.dart';
import '../../../services/services.dart';
import '../../../theme/app_theme.dart';
import '../../../theme/theme_provider.dart';
import '../../../widgets/widgets.dart';

class ProfileTab extends StatelessWidget {
  final AppUser user;
  final List<Address> addresses;
  final LocalStorageService storageService;
  final VoidCallback onSignOut;
  final VoidCallback onDataChanged;

  const ProfileTab({
    super.key,
    required this.user,
    required this.addresses,
    required this.storageService,
    required this.onSignOut,
    required this.onDataChanged,
  });

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDark = themeProvider.isDarkMode;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: onSignOut,
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // User Info Card
          AppCard(
            child: Column(
              children: [
                CircleAvatar(
                  radius: 40,
                  backgroundColor: isDark ? AppTheme.blueDark : AppTheme.primaryPastel,
                  child: Text(
                    user.name.isNotEmpty ? user.name[0].toUpperCase() : 'U',
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.w600,
                      color: isDark ? AppTheme.backgroundDark : AppTheme.textPrimary,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  user.name,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  user.email,
                  style: TextStyle(
                    fontSize: 14,
                    color: Theme.of(context).textTheme.bodySmall?.color,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          // Theme Switch
          const SectionHeader(title: 'Appearance'),
          const SizedBox(height: 8),
          AppCard(
            child: Row(
              children: [
                Icon(
                  isDark ? Icons.dark_mode : Icons.light_mode,
                  color: isDark ? AppTheme.blueDark : AppTheme.primaryPastel,
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Text(
                    'Dark Mode',
                    style: TextStyle(
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                Switch(
                  value: isDark,
                  onChanged: (value) => themeProvider.toggleTheme(),
                  activeTrackColor: isDark ? AppTheme.blueDark : AppTheme.primaryPastel,
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          // Addresses Section
          const SectionHeader(title: 'Saved Addresses'),
          const SizedBox(height: 8),
          if (addresses.isEmpty)
            AppCard(
              onTap: () => _showAddAddressDialog(context, null),
              child: const Row(
                children: [
                  Icon(Icons.add_location_alt_outlined),
                  SizedBox(width: 12),
                  Text('Add your first address'),
                ],
              ),
            )
          else
            ...addresses.map((address) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: AppCard(
                    child: Row(
                      children: [
                        const Icon(Icons.location_on_outlined),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Text(
                                    address.label,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  if (address.isDefault) ...[
                                    const SizedBox(width: 8),
                                    const StatusBadge(
                                      label: 'Default',
                                      color: AppTheme.successPastel,
                                    ),
                                  ],
                                ],
                              ),
                              Text(
                                address.fullAddress,
                                style: TextStyle(
                                  fontSize: 13,
                                  color: Theme.of(context).textTheme.bodySmall?.color,
                                ),
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.edit_outlined, size: 20),
                          onPressed: () => _showAddAddressDialog(context, address),
                        ),
                      ],
                    ),
                  ),
                )),
          if (addresses.isNotEmpty)
            TextButton.icon(
              onPressed: () => _showAddAddressDialog(context, null),
              icon: const Icon(Icons.add),
              label: const Text('Add New Address'),
            ),
        ],
      ),
    );
  }

  void _showAddAddressDialog(BuildContext context, Address? address) {
    final labelController = TextEditingController(text: address?.label ?? '');
    final addressController = TextEditingController(text: address?.fullAddress ?? '');
    final cityController = TextEditingController(text: address?.city ?? '');
    final postalController = TextEditingController(text: address?.postalCode ?? '');
    bool isDefault = address?.isDefault ?? addresses.isEmpty;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        child: StatefulBuilder(
          builder: (context, setModalState) => Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  address == null ? 'Add Address' : 'Edit Address',
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 16),
                AppTextField(
                  label: 'Label',
                  hint: 'Home, Office, etc.',
                  controller: labelController,
                ),
                const SizedBox(height: 12),
                AppTextField(
                  label: 'Full Address',
                  hint: 'Street, Building, Apartment',
                  controller: addressController,
                  maxLines: 2,
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: AppTextField(
                        label: 'City',
                        controller: cityController,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: AppTextField(
                        label: 'Postal Code',
                        controller: postalController,
                        keyboardType: TextInputType.number,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                CheckboxListTile(
                  value: isDefault,
                  onChanged: (val) => setModalState(() => isDefault = val!),
                  title: const Text('Set as default address'),
                  contentPadding: EdgeInsets.zero,
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    if (address != null)
                      Expanded(
                        child: AppButton(
                          label: 'Delete',
                          isOutlined: true,
                          onPressed: () async {
                            await storageService.deleteAddress(address.id);
                            onDataChanged();
                            if (context.mounted) Navigator.pop(context);
                          },
                        ),
                      ),
                    if (address != null) const SizedBox(width: 12),
                    Expanded(
                      child: AppButton(
                        label: 'Save',
                        onPressed: () async {
                          if (labelController.text.isEmpty || addressController.text.isEmpty) {
                            return;
                          }

                          final newAddress = Address(
                            id: address?.id ?? 'addr${DateTime.now().millisecondsSinceEpoch}',
                            label: labelController.text,
                            fullAddress: addressController.text,
                            city: cityController.text,
                            postalCode: postalController.text,
                            isDefault: isDefault,
                          );

                          var updatedAddresses = List<Address>.from(addresses);

                          if (isDefault) {
                            updatedAddresses = updatedAddresses.map((a) => a.copyWith(isDefault: false)).toList();
                          }

                          if (address != null) {
                            final index = updatedAddresses.indexWhere((a) => a.id == address.id);
                            if (index != -1) {
                              updatedAddresses[index] = newAddress;
                            }
                          } else {
                            updatedAddresses.add(newAddress);
                          }

                          await storageService.saveAddresses(updatedAddresses);
                          onDataChanged();
                          if (context.mounted) Navigator.pop(context);
                        },
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
