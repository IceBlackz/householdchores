import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../l10n/app_localizations.dart';
import '../../models/dashboard_preferences.dart';
import '../../models/chore.dart';
import '../../models/room.dart';
import '../../providers/chore_provider.dart';
import '../../providers/house_provider.dart';
import '../../providers/locale_provider.dart';
import '../../services/dashboard_preferences_service.dart';
import '../../services/auth_service.dart';
import '../../services/chore_service.dart';
import '../../services/notification_service.dart';
import '../../services/settings_service.dart';
import '../../utils/room_icons.dart';
import '../admin/app_settings_screen.dart';
import '../add_chore/add_chore_screen.dart';
import '../admin/user_management_screen.dart';
import '../configuration/configuration_screen.dart';
import '../complete_chore/complete_chore_screen.dart';
import '../history/chore_history_screen.dart';
import '../install/install_guide_screen.dart';
import '../login/login_screen.dart';
import '../rooms/rooms_screen.dart';
import '../settings/dashboard_preferences_screen.dart';
import 'widgets/chore_list_tile.dart';

enum _DashboardFilter { all, mine, attention, critical }

enum _DashboardMenuAction {
  manageUsers,
  appSettings,
  dashboardPreferences,
  rooms,
  configureHouses,
  language,
  help,
  install,
  logout,
}

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  _DashboardFilter _workloadFilter = _DashboardFilter.all;
  DashboardPreferences _dashboardPreferences = const DashboardPreferences();
  List<Room> _rooms = [];
  String? _activeRoomId;
  StreamSubscription<String>? _notificationSubscription;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final currentUserId = context.read<AuthService>().currentUserId ?? '';
      final provider = context.read<ChoreProvider>();
      await _loadDashboardPreferences();
      await _loadRooms();
      provider.setSeasonFilter(ChoreProvider.currentSeason());
      await provider.refresh(currentUserId);
      await provider.initRealtime(currentUserId);
      await _syncMobileNotifications();
      await _completePendingNotificationAction();
    });
    _notificationSubscription = NotificationService.instance.completeActions
        .listen((choreId) {
          _completeChoreFromNotification(choreId);
        });
  }

  Future<void> _loadRooms() async {
    try {
      final rooms = await context.read<ChoreService>().fetchRooms();
      if (!mounted) return;
      setState(() {
        _rooms = rooms;
        if (_activeRoomId != null &&
            !_rooms.any((room) => room.id == _activeRoomId)) {
          _activeRoomId = null;
        }
      });
    } catch (_) {
      // Room filters are helpful, but should never block the dashboard.
    }
  }

  Future<void> _loadDashboardPreferences() async {
    final preferences = await DashboardPreferencesService().load();
    if (!mounted) return;
    setState(() {
      _dashboardPreferences = preferences;
      _workloadFilter = _filterFromPreference(preferences.defaultFilter);
    });
  }

  @override
  void dispose() {
    _notificationSubscription?.cancel();
    super.dispose();
  }

  Future<void> _refresh() async {
    final currentUserId = context.read<AuthService>().currentUserId ?? '';
    await context.read<ChoreProvider>().refresh(currentUserId);
    await _syncMobileNotifications();
  }

  Future<void> _syncMobileNotifications() async {
    final auth = context.read<AuthService>();
    final settingsService = context.read<SettingsService>();
    final choreProvider = context.read<ChoreProvider>();
    final currentUserId = auth.currentUserId;
    if (currentUserId == null || currentUserId.isEmpty) return;

    try {
      final settings = await settingsService.fetchNotificationSettings();
      if (!mounted) return;
      await NotificationService.instance.scheduleDueReminders(
        chores: choreProvider.chores,
        dueDates: choreProvider.dueDates,
        maxDueDates: choreProvider.maxDueDates,
        currentUserId: currentUserId,
        settings: settings,
      );
    } catch (_) {
      // Notification scheduling should never block using the dashboard.
    }
  }

  Future<void> _completePendingNotificationAction() async {
    final choreId = NotificationService.instance.takePendingCompleteAction();
    if (choreId != null) {
      await _completeChoreFromNotification(choreId);
    }
  }

  Future<void> _completeChoreFromNotification(String choreId) async {
    if (!mounted) return;
    final currentUserId = context.read<AuthService>().currentUserId;
    if (currentUserId == null || currentUserId.isEmpty) return;

    try {
      await context.read<ChoreProvider>().completeChore(choreId, currentUserId);
      await _syncMobileNotifications();
      if (!mounted) return;
      _showCompletionSuccess();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            AppLocalizations.of(context)!.failedToSubmit(e.toString()),
          ),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _logout() {
    context.read<AuthService>().logout();
    Navigator.of(
      context,
    ).pushReplacement(MaterialPageRoute(builder: (_) => const LoginScreen()));
  }

  Future<void> _openDashboardPreferences() async {
    await Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const DashboardPreferencesScreen()),
    );
    await _loadDashboardPreferences();
  }

  Future<void> _quickCompleteChore(Chore chore) async {
    final currentUserId = context.read<AuthService>().currentUserId;
    if (currentUserId == null || currentUserId.isEmpty) return;

    try {
      await context.read<ChoreProvider>().completeChore(
        chore.id,
        currentUserId,
      );
      await _syncMobileNotifications();
      if (!mounted) return;
      _showCompletionSuccess();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            AppLocalizations.of(context)!.failedToSubmit(e.toString()),
          ),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _showCompletionSuccess() {
    final message = _dashboardPreferences.celebrationsEnabled
        ? 'Nice work. One less chore in the orbit.'
        : AppLocalizations.of(context)!.taskCompleted;
    if (_dashboardPreferences.celebrationsEnabled) {
      HapticFeedback.mediumImpact();
    }
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.green),
    );
  }

  _DashboardFilter _filterFromPreference(String filter) {
    switch (filter) {
      case DashboardPreferences.defaultFilterMine:
        return _DashboardFilter.mine;
      case DashboardPreferences.defaultFilterAttention:
        return _DashboardFilter.attention;
      case DashboardPreferences.defaultFilterCritical:
        return _DashboardFilter.critical;
      default:
        return _DashboardFilter.all;
    }
  }

  Future<void> _handleMenuAction(_DashboardMenuAction action) async {
    switch (action) {
      case _DashboardMenuAction.manageUsers:
        await Navigator.of(
          context,
        ).push(MaterialPageRoute(builder: (_) => const UserManagementScreen()));
      case _DashboardMenuAction.appSettings:
        await Navigator.of(
          context,
        ).push(MaterialPageRoute(builder: (_) => const AppSettingsScreen()));
      case _DashboardMenuAction.dashboardPreferences:
        await _openDashboardPreferences();
      case _DashboardMenuAction.rooms:
        await Navigator.of(
          context,
        ).push(MaterialPageRoute(builder: (_) => const RoomsScreen()));
        await _loadRooms();
        await _refresh();
      case _DashboardMenuAction.configureHouses:
        await Navigator.of(
          context,
        ).push(MaterialPageRoute(builder: (_) => const ConfigurationScreen()));
      case _DashboardMenuAction.language:
        _showLanguagePicker();
      case _DashboardMenuAction.help:
        _showGettingStartedSheet();
      case _DashboardMenuAction.install:
        await Navigator.of(
          context,
        ).push(MaterialPageRoute(builder: (_) => const InstallGuideScreen()));
      case _DashboardMenuAction.logout:
        _logout();
    }
  }

  Future<void> _switchHouse(String houseId) async {
    final houseProvider = context.read<HouseProvider>();
    if (houseId == houseProvider.activeHouseId) return;

    await houseProvider.switchHouse(houseId);
    if (!mounted) return;

    context.read<AuthService>().logout();
    Navigator.of(
      context,
    ).pushReplacement(MaterialPageRoute(builder: (_) => const LoginScreen()));
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
        await context.read<ChoreProvider>().deleteChore(
          chore.id,
          currentUserId,
        );
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
              content: Text(
                AppLocalizations.of(context)!.failedToDelete(e.toString()),
              ),
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

  void _showGettingStartedSheet() {
    final l10n = AppLocalizations.of(context)!;
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (ctx) => SafeArea(
        child: ListView(
          shrinkWrap: true,
          padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
          children: [
            Text(
              l10n.dashboardHelpTitle,
              style: Theme.of(
                ctx,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            _GuideRow(
              icon: Icons.add_task,
              color: Colors.teal,
              title: l10n.gettingStartedAddChoreTitle,
              body: l10n.gettingStartedAddChoreBody,
            ),
            _GuideRow(
              icon: Icons.group,
              color: Colors.indigo,
              title: l10n.gettingStartedUsersTitle,
              body: l10n.gettingStartedUsersBody,
            ),
            _GuideRow(
              icon: Icons.done_all,
              color: Colors.green,
              title: l10n.gettingStartedCompleteTitle,
              body: l10n.gettingStartedCompleteBody,
            ),
            _GuideRow(
              icon: Icons.filter_alt,
              color: Colors.deepOrange,
              title: l10n.dashboardHelpFiltersTitle,
              body: l10n.dashboardHelpFiltersBody,
            ),
          ],
        ),
      ),
    );
  }

  bool _isDueOrOverdue(Chore chore, ChoreProvider provider) {
    final dueDate = provider.dueDate(chore.id);
    if (dueDate == null || dueDate.year < 2000) return true;
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final dueDay = DateTime(dueDate.year, dueDate.month, dueDate.day);
    return !dueDay.isAfter(today);
  }

  bool _isCritical(Chore chore, ChoreProvider provider) {
    final maxDate = provider.maxDueDate(chore.id);
    if (maxDate == null || maxDate.year < 2000) return false;
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final maxDay = DateTime(maxDate.year, maxDate.month, maxDate.day);
    return maxDay.isBefore(today);
  }

  List<Chore> _filteredChores(
    List<Chore> chores,
    ChoreProvider provider,
    String currentUserId,
    bool isCleaner,
  ) {
    final roomFiltered = _activeRoomId == null
        ? chores
        : chores.where((c) => c.room?.id == _activeRoomId).toList();

    switch (_workloadFilter) {
      case _DashboardFilter.mine:
        if (isCleaner) return roomFiltered;
        return roomFiltered
            .where((c) => c.activeAssigneeId == currentUserId)
            .toList();
      case _DashboardFilter.attention:
        return roomFiltered.where((c) => _isDueOrOverdue(c, provider)).toList();
      case _DashboardFilter.critical:
        return roomFiltered.where((c) => _isCritical(c, provider)).toList();
      case _DashboardFilter.all:
        return roomFiltered;
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final provider = context.watch<ChoreProvider>();
    final houseProvider = context.watch<HouseProvider>();
    final authService = context.read<AuthService>();
    final currentUserId = authService.currentUserId ?? '';
    final isCleaner = authService.isCurrentUserCleaner;
    final chores = provider.chores;
    final visibleChores = _filteredChores(
      chores,
      provider,
      currentUserId,
      isCleaner,
    );
    final assignedToMe = chores
        .where((c) => c.activeAssigneeId == currentUserId)
        .length;
    final needsAttention = chores
        .where((c) => _isDueOrOverdue(c, provider))
        .length;
    final critical = chores.where((c) => _isCritical(c, provider)).length;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.householdChores),
        actions: [
          // House switcher
          if (!isCleaner)
            PopupMenuButton<String>(
              tooltip: l10n.activeHouse,
              icon: const Icon(Icons.home_outlined),
              onSelected: (houseId) async {
                await _switchHouse(houseId);
              },
              itemBuilder: (_) => houseProvider.houses
                  .map(
                    (house) => PopupMenuItem(
                      value: house.id,
                      child: Row(
                        children: [
                          Icon(
                            Icons.home,
                            color: house.id == houseProvider.activeHouseId
                                ? Colors.teal
                                : Colors.grey,
                          ),
                          const SizedBox(width: 8),
                          Expanded(child: Text(house.name)),
                        ],
                      ),
                    ),
                  )
                  .toList(),
            ),
          PopupMenuButton<_DashboardMenuAction>(
            tooltip: 'App menu',
            icon: const Icon(Icons.menu),
            onSelected: _handleMenuAction,
            itemBuilder: (_) => [
              if (authService.isCurrentUserAdmin)
                PopupMenuItem(
                  value: _DashboardMenuAction.manageUsers,
                  child: _MenuItem(
                    icon: Icons.manage_accounts,
                    label: l10n.manageUsers,
                  ),
                ),
              if (authService.isCurrentUserAdmin)
                const PopupMenuItem(
                  value: _DashboardMenuAction.appSettings,
                  child: _MenuItem(icon: Icons.tune, label: 'App settings'),
                ),
              if (!isCleaner)
                const PopupMenuItem(
                  value: _DashboardMenuAction.dashboardPreferences,
                  child: _MenuItem(
                    icon: Icons.dashboard_customize_outlined,
                    label: 'Dashboard preferences',
                  ),
                ),
              if (!isCleaner)
                const PopupMenuItem(
                  value: _DashboardMenuAction.rooms,
                  child: _MenuItem(
                    icon: Icons.meeting_room_outlined,
                    label: 'Rooms and focus zones',
                  ),
                ),
              if (!isCleaner)
                PopupMenuItem(
                  value: _DashboardMenuAction.configureHouses,
                  child: _MenuItem(
                    icon: Icons.home_work_outlined,
                    label: l10n.houseConfiguration,
                  ),
                ),
              const PopupMenuDivider(),
              PopupMenuItem(
                value: _DashboardMenuAction.language,
                child: _MenuItem(
                  icon: Icons.language,
                  label: l10n.selectLanguage,
                ),
              ),
              PopupMenuItem(
                value: _DashboardMenuAction.help,
                child: _MenuItem(
                  icon: Icons.help_outline,
                  label: l10n.dashboardHelpTitle,
                ),
              ),
              const PopupMenuItem(
                value: _DashboardMenuAction.install,
                child: _MenuItem(
                  icon: Icons.install_mobile,
                  label: 'Install app',
                ),
              ),
              const PopupMenuDivider(),
              PopupMenuItem(
                value: _DashboardMenuAction.logout,
                child: _MenuItem(icon: Icons.logout, label: l10n.logout),
              ),
            ],
          ),
        ],
      ),
      floatingActionButton: isCleaner
          ? null
          : FloatingActionButton(
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
                  Text(
                    provider.error!,
                    style: const TextStyle(color: Colors.red),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(onPressed: _refresh, child: Text(l10n.retry)),
                ],
              ),
            )
          : RefreshIndicator(
              onRefresh: _refresh,
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.only(bottom: 88),
                children: [
                  _DashboardHeader(
                    houseName: houseProvider.activeHouseName,
                    userName: authService.currentUserName,
                  ),
                  if (chores.isEmpty)
                    isCleaner
                        ? const _CleanerEmptyState()
                        : _EmptyDashboard(
                            isAdmin: authService.isCurrentUserAdmin,
                            onAddChore: () async {
                              final result = await Navigator.of(context)
                                  .push<bool>(
                                    MaterialPageRoute(
                                      builder: (_) => const AddChoreScreen(),
                                    ),
                                  );
                              if (result == true) await _refresh();
                            },
                            onManageUsers: () => Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) => const UserManagementScreen(),
                              ),
                            ),
                            onConfigureHouse: () => Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) => const ConfigurationScreen(),
                              ),
                            ),
                          )
                  else ...[
                    _DashboardStats(
                      assignedToMe: assignedToMe,
                      needsAttention: needsAttention,
                      critical: critical,
                      total: chores.length,
                    ),
                    _WorkloadFilterBar(
                      selected:
                          isCleaner && _workloadFilter == _DashboardFilter.mine
                          ? _DashboardFilter.all
                          : _workloadFilter,
                      showMineFilter: !isCleaner,
                      onSelected: (filter) {
                        setState(() => _workloadFilter = filter);
                      },
                    ),
                    if (!isCleaner)
                      _RoomFilterBar(
                        rooms: _rooms,
                        activeRoomId: _activeRoomId,
                        onChanged: (roomId) {
                          setState(() => _activeRoomId = roomId);
                        },
                      ),
                    if (visibleChores.isEmpty)
                      const _FilteredEmptyState()
                    else
                      ...visibleChores.map((chore) {
                        final due =
                            provider.dueDate(chore.id) ?? DateTime.now();
                        final maxDue =
                            provider.maxDueDate(chore.id) ?? DateTime.now();
                        return ChoreListTile(
                          chore: chore,
                          dueDate: due,
                          maxDueDate: maxDue,
                          currentUserId: currentUserId,
                          onTap: () async {
                            final result = await Navigator.of(context)
                                .push<bool>(
                                  MaterialPageRoute(
                                    builder: (_) =>
                                        CompleteChoreScreen(chore: chore),
                                  ),
                                );
                            if (result == true && mounted) {
                              _showCompletionSuccess();
                            }
                          },
                          onQuickComplete:
                              _dashboardPreferences.quickCompleteEnabled
                              ? () => _quickCompleteChore(chore)
                              : null,
                          onEdit: isCleaner
                              ? null
                              : () async {
                                  final result = await Navigator.of(context)
                                      .push<bool>(
                                        MaterialPageRoute(
                                          builder: (_) =>
                                              AddChoreScreen(chore: chore),
                                        ),
                                      );
                                  if (result == true && mounted) {
                                    await _refresh();
                                  }
                                },
                          onDelete: isCleaner
                              ? null
                              : () => _confirmDelete(chore),
                          onHistory: isCleaner
                              ? null
                              : () => Navigator.of(context).push(
                                  MaterialPageRoute(
                                    builder: (_) =>
                                        ChoreHistoryScreen(chore: chore),
                                  ),
                                ),
                        );
                      }),
                  ],
                ],
              ),
            ),
    );
  }
}

// ---------------------------------------------------------------------------

class _MenuItem extends StatelessWidget {
  const _MenuItem({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [Icon(icon, size: 20), const SizedBox(width: 12), Text(label)],
    );
  }
}

// ---------------------------------------------------------------------------

class _DashboardHeader extends StatelessWidget {
  const _DashboardHeader({required this.houseName, required this.userName});

  final String houseName;
  final String? userName;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final subtitle = userName == null
        ? l10n.dashboardSubtitleNoUser(houseName)
        : l10n.dashboardSubtitle(houseName, userName!);

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.teal.shade700, Colors.blueGrey.shade700],
        ),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.home_work_outlined, color: Colors.white),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  l10n.dashboardOverview,
                  style: theme.textTheme.titleLarge?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            subtitle,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: Colors.white.withValues(alpha: 0.88),
            ),
          ),
        ],
      ),
    );
  }
}

class _DashboardStats extends StatelessWidget {
  const _DashboardStats({
    required this.assignedToMe,
    required this.needsAttention,
    required this.critical,
    required this.total,
  });

  final int assignedToMe;
  final int needsAttention;
  final int critical;
  final int total;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isNarrow = constraints.maxWidth < 560;
          return GridView.count(
            crossAxisCount: isNarrow ? 2 : 4,
            childAspectRatio: isNarrow ? 2.7 : 2.4,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: 8,
            crossAxisSpacing: 8,
            children: [
              _StatTile(
                icon: Icons.person_pin_circle_outlined,
                color: Colors.teal,
                label: l10n.assignedToMe,
                value: assignedToMe,
              ),
              _StatTile(
                icon: Icons.priority_high,
                color: Colors.orange,
                label: l10n.needsAttention,
                value: needsAttention,
              ),
              _StatTile(
                icon: Icons.warning_amber_rounded,
                color: Colors.red,
                label: l10n.critical,
                value: critical,
              ),
              _StatTile(
                icon: Icons.inventory_2_outlined,
                color: Colors.indigo,
                label: l10n.totalChores,
                value: total,
              ),
            ],
          );
        },
      ),
    );
  }
}

class _StatTile extends StatelessWidget {
  const _StatTile({
    required this.icon,
    required this.color,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final MaterialColor color;
  final String label;
  final int value;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: color.shade50,
        border: Border.all(color: color.shade100),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        child: Row(
          children: [
            Icon(icon, color: color.shade700),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    value.toString(),
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      height: 1,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _WorkloadFilterBar extends StatelessWidget {
  const _WorkloadFilterBar({
    required this.selected,
    required this.showMineFilter,
    required this.onSelected,
  });

  final _DashboardFilter selected;
  final bool showMineFilter;
  final ValueChanged<_DashboardFilter> onSelected;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final items = [
      _FilterButtonData(
        filter: _DashboardFilter.all,
        icon: Icons.list_alt,
        label: l10n.filterAll,
      ),
      if (showMineFilter)
        _FilterButtonData(
          filter: _DashboardFilter.mine,
          icon: Icons.person,
          label: l10n.filterMine,
        ),
      _FilterButtonData(
        filter: _DashboardFilter.attention,
        icon: Icons.flag_outlined,
        label: l10n.filterNeedsAttention,
      ),
      _FilterButtonData(
        filter: _DashboardFilter.critical,
        icon: Icons.warning_amber_rounded,
        label: l10n.filterCritical,
      ),
    ];

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
      child: Row(
        children: [
          for (var index = 0; index < items.length; index++)
            Expanded(
              child: Padding(
                padding: EdgeInsets.only(
                  right: index == items.length - 1 ? 0 : 6,
                ),
                child: _FilterButton(
                  data: items[index],
                  selected: selected == items[index].filter,
                  onSelected: onSelected,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _FilterButtonData {
  const _FilterButtonData({
    required this.filter,
    required this.icon,
    required this.label,
  });

  final _DashboardFilter filter;
  final IconData icon;
  final String label;
}

class _FilterButton extends StatelessWidget {
  const _FilterButton({
    required this.data,
    required this.selected,
    required this.onSelected,
  });

  final _FilterButtonData data;
  final bool selected;
  final ValueChanged<_DashboardFilter> onSelected;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Tooltip(
      message: data.label,
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: () => onSelected(data.filter),
        child: Container(
          height: 44,
          decoration: BoxDecoration(
            color: selected
                ? colorScheme.primaryContainer
                : colorScheme.surface,
            border: Border.all(
              color: selected
                  ? colorScheme.primary
                  : colorScheme.outlineVariant,
            ),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(data.icon, size: 17),
              const SizedBox(height: 1),
              Text(
                data.label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _RoomFilterBar extends StatelessWidget {
  const _RoomFilterBar({
    required this.rooms,
    required this.activeRoomId,
    required this.onChanged,
  });

  final List<Room> rooms;
  final String? activeRoomId;
  final ValueChanged<String?> onChanged;

  @override
  Widget build(BuildContext context) {
    if (rooms.isEmpty) return const SizedBox.shrink();

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 6),
      child: Row(
        children: [
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: FilterChip(
              avatar: const Icon(Icons.home_work_outlined, size: 16),
              label: const Text('All rooms'),
              selected: activeRoomId == null,
              onSelected: (_) => onChanged(null),
            ),
          ),
          ...rooms.map(
            (room) => Padding(
              padding: const EdgeInsets.only(right: 8),
              child: FilterChip(
                avatar: Icon(iconForRoom(room), size: 16),
                label: Text(room.name),
                selected: activeRoomId == room.id,
                onSelected: (_) =>
                    onChanged(activeRoomId == room.id ? null : room.id),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyDashboard extends StatelessWidget {
  const _EmptyDashboard({
    required this.isAdmin,
    required this.onAddChore,
    required this.onManageUsers,
    required this.onConfigureHouse,
  });

  final bool isAdmin;
  final VoidCallback onAddChore;
  final VoidCallback onManageUsers;
  final VoidCallback onConfigureHouse;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(color: Colors.blueGrey.shade100),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(Icons.checklist_rtl, size: 42, color: Colors.teal.shade700),
              const SizedBox(height: 12),
              Text(
                l10n.gettingStartedTitle,
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(l10n.gettingStartedBody),
              const SizedBox(height: 18),
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: [
                  FilledButton.icon(
                    onPressed: onAddChore,
                    icon: const Icon(Icons.add_task),
                    label: Text(l10n.addFirstChore),
                  ),
                  if (isAdmin)
                    OutlinedButton.icon(
                      onPressed: onManageUsers,
                      icon: const Icon(Icons.group_add),
                      label: Text(l10n.manageUsers),
                    ),
                  OutlinedButton.icon(
                    onPressed: onConfigureHouse,
                    icon: const Icon(Icons.settings),
                    label: Text(l10n.configureHouse),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              _GuideRow(
                icon: Icons.add_task,
                color: Colors.teal,
                title: l10n.gettingStartedAddChoreTitle,
                body: l10n.gettingStartedAddChoreBody,
              ),
              _GuideRow(
                icon: Icons.group,
                color: Colors.indigo,
                title: l10n.gettingStartedUsersTitle,
                body: l10n.gettingStartedUsersBody,
              ),
              _GuideRow(
                icon: Icons.done_all,
                color: Colors.green,
                title: l10n.gettingStartedCompleteTitle,
                body: l10n.gettingStartedCompleteBody,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _GuideRow extends StatelessWidget {
  const _GuideRow({
    required this.icon,
    required this.color,
    required this.title,
    required this.body,
  });

  final IconData icon;
  final MaterialColor color;
  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: color.shade50,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: color.shade700, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: Theme.of(
                    context,
                  ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 2),
                Text(body, style: Theme.of(context).textTheme.bodySmall),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _FilteredEmptyState extends StatelessWidget {
  const _FilteredEmptyState();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 36, 24, 24),
      child: Column(
        children: [
          Icon(Icons.task_alt, size: 44, color: Colors.green.shade700),
          const SizedBox(height: 12),
          Text(
            l10n.noFilteredChoresTitle,
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 4),
          Text(
            l10n.noFilteredChoresBody,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ],
      ),
    );
  }
}

class _CleanerEmptyState extends StatelessWidget {
  const _CleanerEmptyState();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 42, 24, 24),
      child: Column(
        children: [
          Icon(
            Icons.cleaning_services_outlined,
            size: 44,
            color: Colors.teal.shade700,
          ),
          const SizedBox(height: 12),
          Text(
            'No cleaner tasks yet',
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 4),
          Text(
            'A household admin can add chores to this list by enabling the cleaner switch on a task.',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------

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
