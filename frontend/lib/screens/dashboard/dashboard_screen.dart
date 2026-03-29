import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../constants/app_constants.dart';
import '../../l10n/app_localizations.dart';
import '../../models/chore.dart';
import '../../providers/chore_provider.dart';
import '../../providers/locale_provider.dart';
import '../../services/auth_service.dart';
import '../add_chore/add_chore_screen.dart';
import '../complete_chore/complete_chore_screen.dart';
import '../history/chore_history_screen.dart';
import '../login/login_screen.dart';
import 'widgets/chore_list_tile.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final currentUserId = context.read<AuthService>().currentUserId ?? '';
      final provider = context.read<ChoreProvider>();
      provider.setSeasonFilter(ChoreProvider.currentSeason());
      await provider.refresh(currentUserId);
      await provider.initRealtime(currentUserId);
    });
  }

  Future<void> _refresh() async {
    final currentUserId = context.read<AuthService>().currentUserId ?? '';
    await context.read<ChoreProvider>().refresh(currentUserId);
  }

  void _logout() {
    context.read<AuthService>().logout();
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => const LoginScreen()),
    );
  }

  Future<void> _confirmDelete(Chore chore) async {
    final l10n = AppLocalizations.of(context)!;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.deleteChore),
        content: Text(l10n.deleteConfirm(chore.title)),
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
      final currentUserId = context.read<AuthService>().currentUserId ?? '';
      try {
        await context.read<ChoreProvider>().deleteChore(chore.id, currentUserId);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(AppLocalizations.of(context)!.choreDeleted),
              backgroundColor: Colors.orange,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(AppLocalizations.of(context)!.failedToDelete(e.toString())),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  void _showLanguagePicker() {
    final l10n = AppLocalizations.of(context)!;
    final localeProvider = context.read<LocaleProvider>();
    showDialog<void>(
      context: context,
      builder: (ctx) => SimpleDialog(
        title: Text(l10n.selectLanguage),
        children: [
          _LanguageTile(
            label: l10n.languageEnglish,
            locale: const Locale('en'),
            current: localeProvider.locale,
            onTap: (locale) {
              localeProvider.setLocale(locale);
              Navigator.of(ctx).pop();
            },
          ),
          _LanguageTile(
            label: l10n.languageDutch,
            locale: const Locale('nl'),
            current: localeProvider.locale,
            onTap: (locale) {
              localeProvider.setLocale(locale);
              Navigator.of(ctx).pop();
            },
          ),
          _LanguageTile(
            label: l10n.languageSpanish,
            locale: const Locale('es'),
            current: localeProvider.locale,
            onTap: (locale) {
              localeProvider.setLocale(locale);
              Navigator.of(ctx).pop();
            },
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final provider = context.watch<ChoreProvider>();
    final currentUserId = context.read<AuthService>().currentUserId ?? '';
    final chores = provider.chores;
    final activeFilter = provider.seasonFilter;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.householdChores),
        actions: [
          IconButton(
            icon: const Icon(Icons.language),
            onPressed: _showLanguagePicker,
            tooltip: l10n.selectLanguage,
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: _logout,
            tooltip: l10n.logout,
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(52),
          child: _SeasonFilterBar(
            activeFilter: activeFilter,
            onFilterChanged: (season) {
              context.read<ChoreProvider>().setSeasonFilter(season);
            },
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final result = await Navigator.of(context).push<bool>(
            MaterialPageRoute(builder: (_) => const AddChoreScreen()),
          );
          if (result == true) await _refresh();
        },
        child: const Icon(Icons.add),
      ),
      body: provider.isLoading
          ? const Center(child: CircularProgressIndicator())
          : provider.error != null
              ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(provider.error!, style: const TextStyle(color: Colors.red)),
                      const SizedBox(height: 16),
                      ElevatedButton(onPressed: _refresh, child: Text(l10n.retry)),
                    ],
                  ),
                )
              : chores.isEmpty
                  ? Center(child: Text(l10n.noChoresRelax))
                  : RefreshIndicator(
                      onRefresh: _refresh,
                      child: ListView.builder(
                        itemCount: chores.length,
                        itemBuilder: (context, index) {
                          final chore = chores[index];
                          final due = provider.dueDate(chore.id) ?? DateTime.now();
                          return ChoreListTile(
                            chore: chore,
                            dueDate: due,
                            currentUserId: currentUserId,
                            onTap: () async {
                              final messenger = ScaffoldMessenger.of(context);
                              final taskCompletedMsg = AppLocalizations.of(context)!.taskCompleted;
                              final result = await Navigator.of(context).push<bool>(
                                MaterialPageRoute(
                                  builder: (_) => CompleteChoreScreen(chore: chore),
                                ),
                              );
                              if (result == true && mounted) {
                                messenger.showSnackBar(
                                  SnackBar(
                                    content: Text(taskCompletedMsg),
                                    backgroundColor: Colors.green,
                                  ),
                                );
                              }
                            },
                            onEdit: () async {
                              final result = await Navigator.of(context).push<bool>(
                                MaterialPageRoute(
                                  builder: (_) => AddChoreScreen(chore: chore),
                                ),
                              );
                              if (result == true && mounted) await _refresh();
                            },
                            onDelete: () => _confirmDelete(chore),
                            onHistory: () => Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) => ChoreHistoryScreen(chore: chore),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
    );
  }
}

class _LanguageTile extends StatelessWidget {
  const _LanguageTile({
    required this.label,
    required this.locale,
    required this.current,
    required this.onTap,
  });

  final String label;
  final Locale locale;
  final Locale? current;
  final ValueChanged<Locale> onTap;

  @override
  Widget build(BuildContext context) {
    final isSelected = current?.languageCode == locale.languageCode;
    return SimpleDialogOption(
      onPressed: () => onTap(locale),
      child: Row(
        children: [
          if (isSelected)
            const Icon(Icons.check, color: Colors.teal, size: 18)
          else
            const SizedBox(width: 18),
          const SizedBox(width: 8),
          Text(label),
        ],
      ),
    );
  }
}

class _SeasonFilterBar extends StatelessWidget {
  const _SeasonFilterBar({
    required this.activeFilter,
    required this.onFilterChanged,
  });

  final String? activeFilter;
  final ValueChanged<String?> onFilterChanged;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 48,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        children: [
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: FilterChip(
              label: const Text('All'),
              selected: activeFilter == null,
              onSelected: (_) => onFilterChanged(null),
            ),
          ),
          ...AppConstants.seasons
              .where((s) => s != 'All')
              .map(
                (season) => Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: FilterChip(
                    label: Text(season),
                    selected: activeFilter == season,
                    onSelected: (_) => onFilterChanged(
                      activeFilter == season ? null : season,
                    ),
                  ),
                ),
              ),
        ],
      ),
    );
  }
}
