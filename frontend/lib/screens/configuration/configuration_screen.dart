import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../l10n/app_localizations.dart';
import '../../models/house.dart';
import '../../providers/house_provider.dart';
import '../../services/connection_validator.dart';

class ConfigurationScreen extends StatefulWidget {
  // FIX (session 2): accept the house being edited so _editHouse passes data correctly
  const ConfigurationScreen({super.key, this.houseToEdit});

  final House? houseToEdit;

  @override
  State<ConfigurationScreen> createState() => _ConfigurationScreenState();
}

class _ConfigurationScreenState extends State<ConfigurationScreen>
    // FIX (this session): mixin required for TabController
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _urlController = TextEditingController();
  final _haWebhookController = TextEditingController();
  String? _validationError;
  bool _isChecking = false;
  bool _isValid = false;

  bool get _isEditing => widget.houseToEdit != null;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);

    if (_isEditing) {
      final h = widget.houseToEdit!;
      _nameController.text = h.name;
      _urlController.text = h.url;
      _haWebhookController.text = h.haWebhookUrl ?? '';
      // Jump straight to the form tab when editing
      _tabController.index = 1;
    } else {
      _urlController.text = HouseProvider.defaultLocalHouseUrl;
      _nameController.text = HouseProvider.defaultLocalHouseName;
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    _nameController.dispose();
    _urlController.dispose();
    _haWebhookController.dispose();
    super.dispose();
  }

  Future<void> _checkConnection() async {
    setState(() {
      _validationError = null;
      _isChecking = true;
      _isValid = false;
    });

    final url = _urlController.text.trim();
    if (url.isEmpty) {
      setState(() {
        _validationError = 'Please enter a URL';
        _isChecking = false;
      });
      return;
    }

    try {
      final isValid = await ConnectionValidator.validateHouse(url);
      setState(() {
        _isValid = isValid;
        _isChecking = false;
      });
    } catch (e) {
      setState(() {
        _validationError = ConnectionValidator.getErrorMessage(e);
        _isChecking = false;
      });
    }
  }

  Future<void> _saveHouse() async {
    if (!_formKey.currentState!.validate()) return;

    final url = _urlController.text.trim();
    final name = _nameController.text.trim();
    final haWebhookUrl = _haWebhookController.text.trim().isEmpty
        ? null
        : _haWebhookController.text.trim();
    final l10n = AppLocalizations.of(context)!;
    final houseProvider = context.read<HouseProvider>();

    try {
      if (_isEditing) {
        // FIX (session 2): edit the passed house, not the app-level active house
        await houseProvider.editHouse(
          widget.houseToEdit!.id,
          name: name,
          url: url,
          haWebhookUrl: haWebhookUrl,
        );
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(l10n.houseUpdated),
          backgroundColor: Colors.green,
        ));
      } else {
        // FIX (this session): addHouse now returns the new ID — switch to that,
        // not to houseProvider.activeHouseId which points to the previously active house
        final newId = await houseProvider.addHouse(
          name: name,
          url: url,
          haWebhookUrl: haWebhookUrl,
        );
        await houseProvider.switchHouse(newId);
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(l10n.houseAdded),
          backgroundColor: Colors.green,
        ));
      }

      if (mounted) Navigator.of(context).pop(true);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(l10n.saveFailed(e.toString())),
        backgroundColor: Colors.red,
      ));
    }
  }

  Future<void> _deleteHouse(House house) async {
    final l10n = AppLocalizations.of(context)!;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.deleteHouse),
        content: Text(l10n.deleteHouseConfirm(house.name)),
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
        await context.read<HouseProvider>().deleteHouse(house.id);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text(l10n.houseDeleted),
            backgroundColor: Colors.orange,
          ));
        }
      } catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(l10n.deleteHouseFailed(e.toString())),
          backgroundColor: Colors.red,
        ));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final houseProvider = context.watch<HouseProvider>();

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.houseConfiguration),
        actions: [
          IconButton(
            icon: const Icon(Icons.check),
            onPressed: _saveHouse,
            tooltip: 'Save',
          ),
        ],
        // FIX (this session): the TabBar that was missing — TabBarView was uncontrolled
        bottom: TabBar(
          controller: _tabController,
          tabs: [
            const Tab(icon: Icon(Icons.home), text: 'Houses'),
            Tab(
              icon: Icon(_isEditing ? Icons.edit : Icons.add_circle_outline),
              text: _isEditing ? 'Edit' : 'Add',
            ),
            const Tab(icon: Icon(Icons.cloud), text: 'Home Assistant'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildHousesTab(houseProvider, l10n),
          _buildAddEditFormTab(houseProvider, l10n),
          _buildHaSettingsTab(houseProvider, l10n),
        ],
      ),
    );
  }

  Widget _buildHousesTab(HouseProvider houseProvider, AppLocalizations l10n) {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: houseProvider.houses.length,
      itemBuilder: (context, index) {
        final house = houseProvider.houses[index];
        final isActive = house.id == houseProvider.activeHouseId;

        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: isActive ? Colors.teal : Colors.grey.shade300,
              child: Icon(Icons.home,
                  color: isActive ? Colors.white : Colors.grey),
            ),
            title: Text(house.name),
            subtitle: Text(house.url),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: const Icon(Icons.edit),
                  onPressed: () => _editHouse(house),
                  tooltip: 'Edit',
                ),
                IconButton(
                  icon: const Icon(Icons.delete),
                  onPressed: () => _deleteHouse(house),
                  tooltip: 'Delete',
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildAddEditFormTab(
      HouseProvider houseProvider, AppLocalizations l10n) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              _isEditing ? 'Editing: ${widget.houseToEdit!.name}' : l10n.addNewHouse,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _nameController,
              decoration: InputDecoration(
                labelText: l10n.houseName,
                hintText: l10n.enterHouseNameHint,
              ),
              validator: (v) =>
                  (v == null || v.isEmpty) ? l10n.requiredField : null,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _urlController,
              decoration: InputDecoration(
                labelText: l10n.serverUrl,
                hintText: l10n.enterServerUrlHint,
                prefixIcon: const Icon(Icons.link),
              ),
              keyboardType: TextInputType.url,
              validator: (v) {
                if (v == null || v.isEmpty) return l10n.requiredField;
                final uri = Uri.tryParse(v);
                if (uri == null || !uri.isAbsolute) return l10n.invalidUrlError;
                return null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _haWebhookController,
              decoration: InputDecoration(
                labelText: l10n.homeAssistantWebhook,
                hintText: l10n.enterHaWebhookUrlHint,
                prefixIcon: const Icon(Icons.cloud),
              ),
              keyboardType: TextInputType.url,
              validator: (v) {
                if (v != null && v.isNotEmpty) {
                  final uri = Uri.tryParse(v);
                  if (uri == null || !uri.isAbsolute) return l10n.invalidUrlError;
                }
                return null;
              },
            ),
            if (_validationError != null)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(_validationError!,
                    style: const TextStyle(color: Colors.red)),
              ),
            if (_isChecking)
              const Padding(
                padding: EdgeInsets.only(top: 8),
                child: CircularProgressIndicator(),
              ),
            if (!_isChecking && _isValid)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(l10n.connectionValid,
                    style: const TextStyle(color: Colors.green)),
              ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _checkConnection,
              child: Text(l10n.testConnection),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHaSettingsTab(
      HouseProvider houseProvider, AppLocalizations l10n) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text(
          l10n.activeHouseHaWebhook,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        Text(
          houseProvider.activeHouse?.haWebhookUrl ?? 'Not configured',
          style: Theme.of(context).textTheme.bodyMedium,
        ),
        const SizedBox(height: 16),
        Text(l10n.haWebhookDescription,
            style: Theme.of(context).textTheme.bodySmall),
      ],
    );
  }

  /// Pushes a new ConfigurationScreen pre-filled with this house's data.
  Future<void> _editHouse(House house) async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        // FIX (session 2): pass houseToEdit so the new screen's initState
        // fills the right controllers instead of opening blank
        builder: (_) => ConfigurationScreen(houseToEdit: house),
      ),
    );
    // Editing calls houseProvider.editHouse() directly, no extra refresh needed
  }
}