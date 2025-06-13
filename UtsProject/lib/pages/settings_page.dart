import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({Key? key}) : super(key: key);

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  // Settings state
  bool _notificationsEnabled = true;
  bool _darkModeEnabled = false;
  String _selectedLanguage = 'English';
  String _selectedCurrency = 'USD';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: Text(
          'Settings',
          style: GoogleFonts.poppins(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
        backgroundColor: Colors.deepPurple,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 20),

            // Appearance section
            _buildSectionHeader('Appearance'),
            _buildSettingCard(
              child: Column(
                children: [
                  _buildSwitchSetting(
                    'Dark Mode',
                    'Switch to dark theme',
                    Icons.dark_mode_outlined,
                    _darkModeEnabled,
                        (value) {
                      setState(() {
                        _darkModeEnabled = value;
                      });
                      // TODO: Implement theme change
                    },
                  ),
                  const Divider(),
                  _buildDropdownSetting(
                    'Language',
                    'Choose your preferred language',
                    Icons.language_outlined,
                    _selectedLanguage,
                    ['English', 'Spanish', 'French', 'German', 'Indonesian'],
                        (value) {
                      setState(() {
                        _selectedLanguage = value!;
                      });
                    },
                  ),
                ],
              ),
            ),

            // Notifications section
            _buildSectionHeader('Notifications'),
            _buildSettingCard(
              child: _buildSwitchSetting(
                'Push Notifications',
                'Receive alerts and reminders',
                Icons.notifications_outlined,
                _notificationsEnabled,
                    (value) {
                  setState(() {
                    _notificationsEnabled = value;
                  });
                },
              ),
            ),

            // Financial settings section
            _buildSectionHeader('Financial Settings'),
            _buildSettingCard(
              child: Column(
                children: [
                  _buildDropdownSetting(
                    'Currency',
                    'Set your preferred currency',
                    Icons.attach_money_outlined,
                    _selectedCurrency,
                    ['USD', 'EUR', 'GBP', 'JPY', 'IDR'],
                        (value) {
                      setState(() {
                        _selectedCurrency = value!;
                      });
                    },
                  ),
                  const Divider(),
                  _buildNavigationSetting(
                    'Budget Planning',
                    'Set monthly budget limits',
                    Icons.account_balance_wallet_outlined,
                        () {
                      // TODO: Navigate to budget planning page
                    },
                  ),
                  const Divider(),
                  _buildNavigationSetting(
                    'Export Data',
                    'Export your financial data',
                    Icons.download_outlined,
                        () {
                      // TODO: Implement export functionality
                    },
                  ),
                ],
              ),
            ),

            // Security section
            _buildSectionHeader('Security'),
            _buildSettingCard(
              child: Column(
                children: [
                  _buildNavigationSetting(
                    'Change Password',
                    'Update your password',
                    Icons.lock_outline,
                        () {
                      // TODO: Navigate to change password page
                    },
                  ),
                  const Divider(),
                  _buildNavigationSetting(
                    'Privacy Settings',
                    'Manage your data and privacy',
                    Icons.privacy_tip_outlined,
                        () {
                      // TODO: Navigate to privacy settings page
                    },
                  ),
                ],
              ),
            ),

            // About section
            _buildSectionHeader('About'),
            _buildSettingCard(
              child: Column(
                children: [
                  _buildNavigationSetting(
                    'About App',
                    'Version 1.0.0',
                    Icons.info_outline,
                        () {
                      // TODO: Navigate to about page
                    },
                  ),
                  const Divider(),
                  _buildNavigationSetting(
                    'Help & Support',
                    'Get help with using the app',
                    Icons.help_outline,
                        () {
                      // TODO: Navigate to help page
                    },
                  ),
                  const Divider(),
                  _buildNavigationSetting(
                    'Terms & Conditions',
                    'Read our terms and conditions',
                    Icons.description_outlined,
                        () {
                      // TODO: Navigate to terms page
                    },
                  ),
                ],
              ),
            ),

            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 8),
      child: Text(
        title,
        style: GoogleFonts.poppins(
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: Colors.deepPurple[800],
        ),
      ),
    );
  }

  Widget _buildSettingCard({required Widget child}) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: child,
    );
  }

  Widget _buildSwitchSetting(
      String title,
      String subtitle,
      IconData icon,
      bool value,
      Function(bool) onChanged,
      ) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.deepPurple.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              icon,
              color: Colors.deepPurple[600],
              size: 22,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: Colors.grey[800],
                  ),
                ),
                Text(
                  subtitle,
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeColor: Colors.deepPurple,
          ),
        ],
      ),
    );
  }

  Widget _buildDropdownSetting(
      String title,
      String subtitle,
      IconData icon,
      String value,
      List<String> options,
      Function(String?) onChanged,
      ) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.deepPurple.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              icon,
              color: Colors.deepPurple[600],
              size: 22,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: Colors.grey[800],
                  ),
                ),
                Text(
                  subtitle,
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
          DropdownButton<String>(
            value: value,
            icon: const Icon(Icons.arrow_drop_down),
            elevation: 16,
            style: GoogleFonts.poppins(
              color: Colors.deepPurple[800],
              fontWeight: FontWeight.w500,
            ),
            underline: Container(
              height: 0,
            ),
            onChanged: onChanged,
            items: options.map<DropdownMenuItem<String>>((String value) {
              return DropdownMenuItem<String>(
                value: value,
                child: Text(value),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildNavigationSetting(
      String title,
      String subtitle,
      IconData icon,
      VoidCallback onTap,
      ) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.deepPurple.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                icon,
                color: Colors.deepPurple[600],
                size: 22,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: Colors.grey[800],
                    ),
                  ),
                  Text(
                    subtitle,
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.arrow_forward_ios,
              color: Colors.grey[400],
              size: 16,
            ),
          ],
        ),
      ),
    );
  }
}