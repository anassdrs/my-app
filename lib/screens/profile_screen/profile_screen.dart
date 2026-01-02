import 'dart:convert';
import 'dart:io';

import 'package:file_selector/file_selector.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';

import '../../blocs/habit_bloc.dart';
import '../../blocs/prayer_bloc.dart';
import '../../blocs/todo_bloc.dart';
import '../../providers/auth_provider.dart';
import '../../providers/theme_provider.dart';
import '../../services/backup_service.dart';
import '../../utils/constants.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen>
    with SingleTickerProviderStateMixin {
  static const XTypeGroup _jsonTypeGroup = XTypeGroup(
    label: 'JSON',
    extensions: ['json'],
  );

  final List<Color> _accentOptions = [
    AppColors.primary,
    AppColors.secondary,
    Color(0xFF2563EB),
    Color(0xFF16A34A),
    Color(0xFFF97316),
    Color(0xFF0F172A),
  ];

  late final TextEditingController _nameController;
  late final TextEditingController _bioController;
  late final AnimationController _introController;
  late final Animation<double> _fadeAnimation;
  late final Animation<Offset> _slideAnimation;
  int? _selectedColorValue;
  bool _isDirty = false;

  @override
  void initState() {
    super.initState();
    final authProvider = context.read<AuthProvider>();
    _nameController = TextEditingController(
      text: authProvider.currentUser?.username ??
          authProvider.currentUserEmail ??
          'User',
    );
    _bioController = TextEditingController(text: authProvider.profileBio);
    _selectedColorValue = authProvider.accentColorValue;

    _nameController.addListener(_markDirty);
    _bioController.addListener(_markDirty);

    _introController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _fadeAnimation = CurvedAnimation(
      parent: _introController,
      curve: Curves.easeOutCubic,
    );
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.08),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(parent: _introController, curve: Curves.easeOutCubic),
    );
    _introController.forward();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final authProvider = context.watch<AuthProvider>();
    if (_isDirty) return;

    final name = authProvider.currentUser?.username ??
        authProvider.currentUserEmail ??
        'User';
    if (_nameController.text != name) {
      _nameController.text = name;
    }

    if (_bioController.text != authProvider.profileBio) {
      _bioController.text = authProvider.profileBio;
    }

    _selectedColorValue ??= authProvider.accentColorValue;
  }

  @override
  void dispose() {
    _nameController
      ..removeListener(_markDirty)
      ..dispose();
    _bioController
      ..removeListener(_markDirty)
      ..dispose();
    _introController.dispose();
    super.dispose();
  }

  void _markDirty() {
    if (_isDirty) {
      setState(() {});
      return;
    }
    setState(() => _isDirty = true);
  }

  Color _resolveAccentColor(BuildContext context, AuthProvider authProvider) {
    final fallback = Theme.of(context).colorScheme.primary;
    final value = _selectedColorValue ?? authProvider.accentColorValue;
    return value == null ? fallback : Color(value);
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();
    final themeProvider = context.watch<ThemeProvider>();
    final accentColor = _resolveAccentColor(context, authProvider);
    final email = authProvider.currentUserEmail ?? 'user@example.com';
    final level = authProvider.currentUser?.level ?? 1;
    final xp = authProvider.currentUser?.xp ?? 0;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          "Profile",
          style: AppTextStyles.heading2.copyWith(
            color: Theme.of(context).colorScheme.onSurface,
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back,
            color: Theme.of(context).colorScheme.onSurface,
          ),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: SlideTransition(
            position: _slideAnimation,
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
              child: Column(
                children: [
                  _buildHeader(context, accentColor, email, level, xp),
                  const SizedBox(height: 24),
                  _buildProfileCard(context, accentColor),
                  const SizedBox(height: 24),
                  _buildThemeToggle(context, themeProvider),
                  const SizedBox(height: 10),
                  _buildOptionTile(
                    context,
                    icon: Icons.settings,
                    title: "Settings",
                    onTap: () {},
                  ),
                  _buildOptionTile(
                    context,
                    icon: Icons.notifications,
                    title: "Notifications",
                    onTap: () {},
                  ),
                  _buildOptionTile(
                    context,
                    icon: Icons.backup,
                    title: "Export Backup",
                    onTap: () => _exportBackup(context),
                  ),
                  _buildOptionTile(
                    context,
                    icon: Icons.restore,
                    title: "Import Backup",
                    onTap: () => _importBackup(context),
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: _isDirty
                          ? () => _saveProfile(context, accentColor)
                          : null,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: accentColor,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      child: const Text(
                        "Save Changes",
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: () {
                        authProvider.logout();
                        Navigator.pop(context);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.error,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      child: const Text(
                        "Log Out",
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(
    BuildContext context,
    Color accentColor,
    String email,
    int level,
    int xp,
  ) {
    final displayName = _nameController.text.trim().isEmpty
        ? 'User'
        : _nameController.text.trim();

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: LinearGradient(
          colors: [
            accentColor.withOpacity(0.9),
            accentColor.withOpacity(0.55),
            Theme.of(context).colorScheme.secondary.withOpacity(0.35),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: accentColor.withOpacity(0.25),
            blurRadius: 18,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Stack(
        children: [
          Positioned(
            right: -40,
            top: -50,
            child: CircleAvatar(
              radius: 60,
              backgroundColor: Colors.white.withOpacity(0.08),
            ),
          ),
          Positioned(
            right: 20,
            bottom: -30,
            child: CircleAvatar(
              radius: 50,
              backgroundColor: Colors.white.withOpacity(0.08),
            ),
          ),
          Column(
            children: [
              Row(
                children: [
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 250),
                    child: CircleAvatar(
                      key: ValueKey(accentColor.value),
                      radius: 38,
                      backgroundColor: Colors.white.withOpacity(0.2),
                      child: CircleAvatar(
                        radius: 32,
                        backgroundColor: Colors.white,
                        child: Text(
                          displayName.substring(0, 1).toUpperCase(),
                          style: AppTextStyles.heading1.copyWith(
                            color: accentColor,
                            fontSize: 26,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          displayName,
                          style: AppTextStyles.heading2.copyWith(
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          email,
                          style: AppTextStyles.bodyMedium.copyWith(
                            color: Colors.white.withOpacity(0.8),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  _statPill("Level", '$level'),
                  const SizedBox(width: 12),
                  _statPill("XP", '$xp'),
                  const Spacer(),
                  Icon(
                    Icons.auto_awesome,
                    color: Colors.white.withOpacity(0.8),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _statPill(String label, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.18),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          Text(
            label,
            style: AppTextStyles.bodyMedium.copyWith(
              color: Colors.white.withOpacity(0.85),
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(width: 8),
          Text(
            value,
            style: AppTextStyles.bodyMedium.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileCard(BuildContext context, Color accentColor) {
    final selectedValue = _selectedColorValue ?? accentColor.value;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 12,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.edit, color: accentColor),
              const SizedBox(width: 10),
              Text(
                "Personalize",
                style: AppTextStyles.heading2.copyWith(
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _nameController,
            decoration: InputDecoration(
              labelText: "Display name",
              filled: true,
              fillColor: Theme.of(context).colorScheme.surface,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide(
                  color: Theme.of(context).dividerColor.withOpacity(0.2),
                ),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide(
                  color: Theme.of(context).dividerColor.withOpacity(0.2),
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _bioController,
            maxLines: 3,
            decoration: InputDecoration(
              labelText: "Bio",
              filled: true,
              fillColor: Theme.of(context).colorScheme.surface,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide(
                  color: Theme.of(context).dividerColor.withOpacity(0.2),
                ),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide(
                  color: Theme.of(context).dividerColor.withOpacity(0.2),
                ),
              ),
            ),
          ),
          const SizedBox(height: 18),
          Text(
            "Accent color",
            style: AppTextStyles.bodyLarge.copyWith(
              fontWeight: FontWeight.w600,
              color: Theme.of(context).colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: _accentOptions.map((color) {
              final isSelected = selectedValue == color.value;
              return GestureDetector(
                onTap: () {
                  setState(() {
                    _selectedColorValue = color.value;
                    _isDirty = true;
                  });
                },
                child: AnimatedScale(
                  scale: isSelected ? 1.05 : 1.0,
                  duration: const Duration(milliseconds: 200),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: color,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: isSelected
                            ? Colors.white
                            : Colors.transparent,
                        width: 3,
                      ),
                      boxShadow: [
                        if (isSelected)
                          BoxShadow(
                            color: color.withOpacity(0.4),
                            blurRadius: 12,
                          ),
                      ],
                    ),
                    child: isSelected
                        ? const Icon(Icons.check, color: Colors.white)
                        : null,
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildThemeToggle(BuildContext context, ThemeProvider themeProvider) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Theme.of(context).primaryColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(
            themeProvider.isDarkMode ? Icons.dark_mode : Icons.light_mode,
            color: Theme.of(context).primaryColor,
          ),
        ),
        title: Text(
          "Dark Mode",
          style: AppTextStyles.bodyLarge.copyWith(
            color: Theme.of(context).colorScheme.onSurface,
          ),
        ),
        trailing: Switch(
          value: themeProvider.isDarkMode,
          onChanged: (value) => themeProvider.toggleTheme(),
          activeThumbColor: Theme.of(context).primaryColor,
        ),
      ),
    );
  }

  Widget _buildOptionTile(
    BuildContext context, {
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, color: Theme.of(context).colorScheme.primary),
      ),
      title: Text(
        title,
        style: AppTextStyles.bodyLarge.copyWith(
          color: Theme.of(context).colorScheme.onSurface,
        ),
      ),
      trailing: Icon(
        Icons.chevron_right,
        color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
      ),
      onTap: onTap,
    );
  }

  Future<void> _saveProfile(BuildContext context, Color accentColor) async {
    final authProvider = context.read<AuthProvider>();
    await authProvider.updateProfile(
      username: _nameController.text,
      bio: _bioController.text,
      accentColorValue: _selectedColorValue ?? accentColor.value,
    );

    if (!mounted) return;
    setState(() => _isDirty = false);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Profile updated.')),
    );
  }

  Future<void> _exportBackup(BuildContext context) async {
    final backupService = BackupService();
    try {
      final backupJson = await backupService.createBackupJson();
      final fileName = 'todo_habit_backup.json';
      String? savedPath;

      try {
        final location = await getSaveLocation(
          suggestedName: fileName,
          acceptedTypeGroups: [_jsonTypeGroup],
        );
        if (location == null) return;

        final file = XFile.fromData(
          utf8.encode(backupJson),
          name: fileName,
          mimeType: 'application/json',
        );
        await file.saveTo(location.path);
        savedPath = location.path;
      } on UnimplementedError {
        final tempDir = await getTemporaryDirectory();
        final filePath = '${tempDir.path}/$fileName';
        final file = File(filePath);
        await file.writeAsString(backupJson);
        await Share.shareXFiles(
          [XFile(filePath, mimeType: 'application/json', name: fileName)],
          text: 'Todo & Habit backup',
        );
      }

      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            savedPath == null
                ? 'Backup exported. Choose a location to save it.'
                : 'Backup exported to $savedPath',
          ),
        ),
      );
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Backup export failed: $e')),
      );
    }
  }

  Future<void> _importBackup(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Restore backup?'),
          content: const Text(
            'This will replace all current data in the app.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, true),
              child: const Text('Restore'),
            ),
          ],
        );
      },
    );

    if (confirmed != true) return;

    final backupService = BackupService();
    try {
      final file = await openFile(acceptedTypeGroups: [_jsonTypeGroup]);
      if (file == null) return;

      final contents = await file.readAsString();
      await backupService.restoreFromJson(contents);

      if (!context.mounted) return;
      context.read<TodoBloc>().add(LoadTodos());
      context.read<HabitBloc>().add(LoadHabits());
      context.read<PrayerBloc>().add(LoadPrayers());
      await Provider.of<AuthProvider>(context, listen: false).init();

      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Backup restored successfully.')),
      );
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Backup restore failed: $e')),
      );
    }
  }
}
