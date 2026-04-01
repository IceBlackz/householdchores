import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../l10n/app_localizations.dart';
import '../../models/app_user.dart';
import '../../services/auth_service.dart';
import '../../services/chore_service.dart';

class UserManagementScreen extends StatefulWidget {
  const UserManagementScreen({super.key});
  @override
  State<UserManagementScreen> createState() => _UserManagementScreenState();
}

class _UserManagementScreenState extends State<UserManagementScreen> {
  List<AppUser> _users = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _fetchUsers();
  }

  Future<void> _fetchUsers() async {
    setState(() { _isLoading = true; _error = null; });
    try {
      final users = await context.read<ChoreService>().fetchUsers();
      if (mounted) setState(() { _users = users; _isLoading = false; });
    } catch (e) {
      if (mounted) setState(() { _error = e.toString(); _isLoading = false; });
    }
  }

  Future<void> _showUserDialog({AppUser? user}) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (_) => _UserDialog(user: user),
    );
    if (result == true) await _fetchUsers();
  }

  Future<void> _confirmDelete(AppUser user) async {
    final l10n = AppLocalizations.of(context)!;
    final currentUserId = context.read<AuthService>().currentUserId;

    if (user.id == currentUserId) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(l10n.cannotDeleteSelf),
        backgroundColor: Colors.orange,
      ));
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.deleteUser),
        content: Text(l10n.deleteUserConfirm(user.displayName)),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(l10n.cancel),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: Text(l10n.delete),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      try {
        await context.read<ChoreService>().deleteUser(user.id);
        await _fetchUsers();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text(l10n.userDeleted),
            backgroundColor: Colors.orange,
          ));
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text(e.toString()),
            backgroundColor: Colors.red,
          ));
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final currentUserId = context.read<AuthService>().currentUserId;

    return Scaffold(
      appBar: AppBar(title: Text(l10n.manageUsers)),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showUserDialog(),
        icon: const Icon(Icons.person_add),
        label: Text(l10n.addUser),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(_error!, style: const TextStyle(color: Colors.red)),
                      const SizedBox(height: 16),
                      ElevatedButton(
                          onPressed: _fetchUsers, child: Text(l10n.retry)),
                    ],
                  ),
                )
              : _users.isEmpty
                  ? Center(child: Text(l10n.noUsersFound))
                  : ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: _users.length,
                      itemBuilder: (_, index) {
                        final user = _users[index];
                        final isSelf = user.id == currentUserId;
                        return Card(
                          margin: const EdgeInsets.only(bottom: 8),
                          child: ListTile(
                            leading: CircleAvatar(
                              backgroundColor: user.isAdmin
                                  ? Colors.teal
                                  : Colors.grey.shade300,
                              child: Text(
                                user.displayName.isNotEmpty
                                    ? user.displayName[0].toUpperCase()
                                    : '?',
                                style: TextStyle(
                                  color: user.isAdmin
                                      ? Colors.white
                                      : Colors.grey.shade700,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            title: Row(
                              children: [
                                Text(user.displayName),
                                if (isSelf) ...[
                                  const SizedBox(width: 6),
                                  Chip(
                                    label: Text(l10n.youLabel,
                                        style: const TextStyle(fontSize: 11)),
                                    padding: EdgeInsets.zero,
                                    visualDensity: VisualDensity.compact,
                                    backgroundColor: Colors.blue.shade50,
                                  ),
                                ],
                                if (user.isAdmin) ...[
                                  const SizedBox(width: 6),
                                  Chip(
                                    label: Text(l10n.adminBadge,
                                        style: const TextStyle(fontSize: 11)),
                                    padding: EdgeInsets.zero,
                                    visualDensity: VisualDensity.compact,
                                    backgroundColor: Colors.teal.shade50,
                                    side: BorderSide(
                                        color: Colors.teal.shade200),
                                  ),
                                ],
                              ],
                            ),
                            subtitle: Text(user.email,
                                style: TextStyle(color: Colors.grey.shade600)),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                  icon: const Icon(Icons.edit,
                                      color: Colors.grey),
                                  tooltip: l10n.edit,
                                  onPressed: () =>
                                      _showUserDialog(user: user),
                                ),
                                IconButton(
                                  icon: Icon(Icons.delete_outline,
                                      color: isSelf
                                          ? Colors.grey.shade300
                                          : Colors.red.shade300),
                                  tooltip: l10n.deleteUser,
                                  onPressed: isSelf
                                      ? null
                                      : () => _confirmDelete(user),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
    );
  }
}

// ---------------------------------------------------------------------------
// Add / Edit dialog
// ---------------------------------------------------------------------------

class _UserDialog extends StatefulWidget {
  const _UserDialog({this.user});
  final AppUser? user;

  @override
  State<_UserDialog> createState() => _UserDialogState();
}

class _UserDialogState extends State<_UserDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmController = TextEditingController();
  bool _isAdmin = false;
  bool _isSaving = false;
  bool _changePassword = false;

  bool get _isEditing => widget.user != null;

  @override
  void initState() {
    super.initState();
    if (_isEditing) {
      _nameController.text = widget.user!.name;
      _emailController.text = widget.user!.email;
      _isAdmin = widget.user!.isAdmin;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSaving = true);
    final l10n = AppLocalizations.of(context)!;
    final service = context.read<ChoreService>();

    try {
      if (_isEditing) {
        await service.updateUser(
          widget.user!.id,
          name:     _nameController.text.trim(),
          email:    _emailController.text.trim(),
          isAdmin:  _isAdmin,
          password: (_changePassword && _passwordController.text.isNotEmpty)
              ? _passwordController.text
              : null,
        );
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text(l10n.userUpdated),
            backgroundColor: Colors.green,
          ));
        }
      } else {
        await service.createUser(
          name:     _nameController.text.trim(),
          email:    _emailController.text.trim(),
          password: _passwordController.text,
          isAdmin:  _isAdmin,
        );
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text(l10n.userAdded),
            backgroundColor: Colors.green,
          ));
        }
      }
      if (mounted) Navigator.of(context).pop(true);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(e.toString()),
          backgroundColor: Colors.red,
        ));
        setState(() => _isSaving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return AlertDialog(
      title: Text(_isEditing ? l10n.editUser : l10n.addUser),
      content: SizedBox(
        width: 360,
        child: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: _nameController,
                  decoration: InputDecoration(labelText: l10n.userName),
                  validator: (v) => (v == null || v.trim().isEmpty)
                      ? l10n.requiredField
                      : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _emailController,
                  decoration: InputDecoration(labelText: l10n.email),
                  keyboardType: TextInputType.emailAddress,
                  validator: (v) => (v == null || v.trim().isEmpty)
                      ? l10n.requiredField
                      : null,
                ),
                const SizedBox(height: 8),
                if (_isEditing)
                  SwitchListTile(
                    title: Text(l10n.changePassword),
                    value: _changePassword,
                    onChanged: (v) => setState(() => _changePassword = v),
                    contentPadding: EdgeInsets.zero,
                  ),
                if (!_isEditing || _changePassword) ...[
                  TextFormField(
                    controller: _passwordController,
                    decoration: InputDecoration(labelText: l10n.newPassword),
                    obscureText: true,
                    validator: (v) {
                      if (!_isEditing || _changePassword) {
                        if (v == null || v.isEmpty) return l10n.requiredField;
                        if (v.length < 8) return l10n.passwordTooShort;
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _confirmController,
                    decoration:
                        InputDecoration(labelText: l10n.passwordConfirm),
                    obscureText: true,
                    validator: (v) {
                      if (!_isEditing || _changePassword) {
                        if (v != _passwordController.text) {
                          return l10n.passwordsDoNotMatch;
                        }
                      }
                      return null;
                    },
                  ),
                ],
                const SizedBox(height: 8),
                SwitchListTile(
                  title: Text(l10n.adminBadge),
                  subtitle: Text(l10n.adminBadgeSubtitle),
                  value: _isAdmin,
                  onChanged: (v) => setState(() => _isAdmin = v),
                  contentPadding: EdgeInsets.zero,
                ),
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isSaving ? null : () => Navigator.of(context).pop(false),
          child: Text(l10n.cancel),
        ),
        FilledButton(
          onPressed: _isSaving ? null : _save,
          child: _isSaving
              ? const SizedBox(
                  width: 16, height: 16,
                  child: CircularProgressIndicator(
                      strokeWidth: 2, color: Colors.white))
              : Text(l10n.save),
        ),
      ],
    );
  }
}