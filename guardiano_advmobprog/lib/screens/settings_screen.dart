import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/theme_provider.dart';
import '../services/user_service.dart';

// Settings screen where users can modify the application's theme.
class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final UserService _userService = UserService();
  // Temporary theme value while on the Settings screen.
  late bool _tempDarkMode;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    _tempDarkMode = Provider.of<ThemeProvider>(context, listen: false).isDark;
  }

  // Clears the session and returns to the signin screen.
  Future<void> _logout() async {
    await _userService.logout();
    if (!mounted) return;
    Navigator.pushNamedAndRemoveUntil(context, '/signin', (route) => false);
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context, listen: false);

    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          SwitchListTile(
            title: const Text('Dark Mode'),
            subtitle: const Text('Enable or disable Dark Mode.'),
            value: _tempDarkMode,

            // Updates only the temporary value.
            onChanged: (value) {
              setState(() {
                _tempDarkMode = value;
              });

              // Apply the theme immediately.
              if (_tempDarkMode != themeProvider.isDark) {
                themeProvider.toggleTheme();
              }
            },
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.logout, color: Colors.redAccent),
            title: const Text(
              'Log Out',
              style: TextStyle(
                color: Colors.redAccent,
                fontWeight: FontWeight.w600,
              ),
            ),
            subtitle: const Text('Clear session and return to login'),
            onTap: _logout,
          ),
        ],
      ),
    );
  }
}
