import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../controllers/auth_controller.dart';
import '../../utils/validators.dart';
import '../../utils/constants.dart';

class AccountScreen extends StatefulWidget {
  const AccountScreen({super.key});

  @override
  State<AccountScreen> createState() => _AccountScreenState();
}

class _AccountScreenState extends State<AccountScreen> {
  final _formKey = GlobalKey<FormState>();
  final _displayNameController = TextEditingController();
  bool _isEditing = false;

  @override
  void initState() {
    super.initState();
    // Initialize with current display name
    final authController = context.read<AuthController>();
    _displayNameController.text = authController.currentUser?.displayName ?? '';
  }

  @override
  void dispose() {
    _displayNameController.dispose();
    super.dispose();
  }

  Future<void> _updateProfile() async {
    if (!_formKey.currentState!.validate()) return;

    final authController = context.read<AuthController>();
    final success = await authController.updateUserProfile(
      displayName: _displayNameController.text.trim(),
    );

    if (mounted) {
      if (success) {
        setState(() {
          _isEditing = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Profile updated successfully!'),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(authController.errorMessage ?? 'Failed to update profile'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _cancelEdit() {
    final authController = context.read<AuthController>();
    setState(() {
      _displayNameController.text = authController.currentUser?.displayName ?? '';
      _isEditing = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final authController = context.watch<AuthController>();
    final user = authController.currentUser;

    if (user == null) {
      return const Scaffold(
        body: Center(
          child: Text('No user logged in'),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Account Overview'),
        centerTitle: true,
        elevation: 0,
        actions: [
          if (_isEditing)
            IconButton(
              icon: const Icon(Icons.close),
              onPressed: _cancelEdit,
              tooltip: 'Cancel',
            ),
        ],
      ),
      body: authController.isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(AppConstants.paddingLarge),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // Profile Avatar
                  CircleAvatar(
                    radius: 60,
                    backgroundColor: Theme.of(context).colorScheme.primaryContainer,
                    child: user.photoUrl != null
                        ? ClipOval(
                            child: Image.network(
                              user.photoUrl!,
                              width: 120,
                              height: 120,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) {
                                return const Icon(
                                  Icons.person,
                                  size: 60,
                                );
                              },
                            ),
                          )
                        : Icon(
                            Icons.person,
                            size: 60,
                            color: Theme.of(context).colorScheme.onPrimaryContainer,
                          ),
                  ),
                  const SizedBox(height: AppConstants.paddingLarge),

                  // User Details Card
                  Card(
                    elevation: 2,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppConstants.borderRadiusMedium),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(AppConstants.paddingLarge),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Section Header
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Profile Information',
                                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                      fontWeight: FontWeight.bold,
                                    ),
                              ),
                              if (!_isEditing)
                                IconButton(
                                  icon: const Icon(Icons.edit),
                                  onPressed: () {
                                    setState(() {
                                      _isEditing = true;
                                    });
                                  },
                                  tooltip: 'Edit Profile',
                                ),
                            ],
                          ),
                          const SizedBox(height: AppConstants.paddingMedium),

                          // Display Name Field
                          if (_isEditing)
                            Form(
                              key: _formKey,
                              child: Column(
                                children: [
                                  TextFormField(
                                    controller: _displayNameController,
                                    decoration: const InputDecoration(
                                      labelText: 'Display Name',
                                      hintText: 'Enter your name',
                                      prefixIcon: Icon(Icons.person_outline),
                                    ),
                                    validator: Validators.validateName,
                                    textInputAction: TextInputAction.done,
                                    onFieldSubmitted: (_) => _updateProfile(),
                                  ),
                                  const SizedBox(height: AppConstants.paddingMedium),
                                  SizedBox(
                                    width: double.infinity,
                                    child: ElevatedButton.icon(
                                      onPressed: _updateProfile,
                                      icon: const Icon(Icons.save),
                                      label: const Text('Save Changes'),
                                    ),
                                  ),
                                ],
                              ),
                            )
                          else
                            _buildInfoRow(
                              context,
                              Icons.person_outline,
                              'Display Name',
                              user.displayName ?? 'Not set',
                            ),

                          if (!_isEditing) ...[
                            const Divider(height: AppConstants.paddingLarge),

                            // Email (non-editable)
                            _buildInfoRow(
                              context,
                              Icons.email_outlined,
                              'Email',
                              user.email,
                            ),

                            const Divider(height: AppConstants.paddingLarge),

                            // User ID
                            _buildInfoRow(
                              context,
                              Icons.fingerprint,
                              'User ID',
                              user.uid,
                              isSmall: true,
                            ),

                            const Divider(height: AppConstants.paddingLarge),

                            // Account Created Date
                            _buildInfoRow(
                              context,
                              Icons.calendar_today_outlined,
                              'Member Since',
                              DateFormat('MMM dd, yyyy').format(user.createdAt),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: AppConstants.paddingLarge),

                  // Additional Actions Card
                  Card(
                    elevation: 2,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppConstants.borderRadiusMedium),
                    ),
                    child: Column(
                      children: [
                        ListTile(
                          leading: Icon(
                            Icons.lock_outline,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                          title: const Text('Change Password'),
                          subtitle: const Text('Update your account password'),
                          trailing: const Icon(Icons.chevron_right),
                          onTap: () {
                            // TODO: Navigate to change password screen
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Change password feature coming soon!'),
                              ),
                            );
                          },
                        ),
                        const Divider(height: 1),
                        ListTile(
                          leading: Icon(
                            Icons.image_outlined,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                          title: const Text('Profile Picture'),
                          subtitle: const Text('Upload or change your photo'),
                          trailing: const Icon(Icons.chevron_right),
                          onTap: () {
                            // TODO: Navigate to profile picture upload
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Profile picture upload coming soon!'),
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: AppConstants.paddingXLarge),

                  // Account Stats (optional)
                  Text(
                    'Account active for ${DateTime.now().difference(user.createdAt).inDays} days',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Colors.grey[600],
                        ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildInfoRow(
    BuildContext context,
    IconData icon,
    String label,
    String value, {
    bool isSmall = false,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(
          icon,
          size: 20,
          color: Theme.of(context).colorScheme.primary,
        ),
        const SizedBox(width: AppConstants.paddingSmall),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Colors.grey[600],
                      fontWeight: FontWeight.w500,
                    ),
              ),
              const SizedBox(height: 4),
              Text(
                value,
                style: isSmall
                    ? Theme.of(context).textTheme.bodySmall?.copyWith(
                          fontFamily: 'monospace',
                        )
                    : Theme.of(context).textTheme.bodyLarge,
                overflow: isSmall ? TextOverflow.ellipsis : TextOverflow.visible,
              ),
            ],
          ),
        ),
      ],
    );
  }
}
