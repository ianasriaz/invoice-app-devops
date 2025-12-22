import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:gsheet/constants/app_colors.dart';
import 'package:gsheet/screens/auth/login_screen.dart';
import 'package:gsheet/services/auth_service.dart';
import 'package:url_launcher/url_launcher.dart';

class AppDrawer extends StatefulWidget {
  const AppDrawer({Key? key}) : super(key: key);

  @override
  State<AppDrawer> createState() => _AppDrawerState();
}

class _AppDrawerState extends State<AppDrawer> {
  final _authService = AuthService();

  Future<void> _logout() async {
    try {
      await _authService.signOut();
      if (mounted) {
        // Navigate to login using direct widget navigation
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (context) => LoginScreen()),
          (Route<dynamic> route) => false,
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to logout: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    return Drawer(
      backgroundColor: AppColors.lightBackground,
      child: ListView(
        padding: const EdgeInsets.all(0),
        children: [
          DrawerHeader(
            decoration: BoxDecoration(
              color: AppColors.primary,
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    Icons.receipt_long,
                    size: 36,
                    color: AppColors.primary,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  "INVOICO",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 22,
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.5,
                  ),
                ),
                const SizedBox(height: 6),
                if (user?.email != null)
                  Text(
                    user!.email!,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 11,
                      color: Colors.white.withOpacity(0.85),
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
              ],
            ),
          ),
          ListTile(
            leading: Icon(Icons.home, size: 20, color: AppColors.primary),
            title: Text(
              'Dashboard',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 15,
                color: AppColors.lightText,
              ),
            ),
            dense: true,
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 0),
            onTap: () {
              Navigator.pop(context);
            },
          ),
          ListTile(
            leading:
                Icon(Icons.receipt_long, size: 20, color: AppColors.primary),
            title: Text(
              'Invoices',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 15,
                color: AppColors.lightText,
              ),
            ),
            dense: true,
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 0),
            onTap: () {
              Navigator.pop(context);
              Navigator.pushNamed(context, '/invoices');
            },
          ),
          ListTile(
            leading: Icon(Icons.people, size: 20, color: AppColors.primary),
            title: Text(
              'Clients',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 15,
                color: AppColors.lightText,
              ),
            ),
            dense: true,
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 0),
            onTap: () {
              Navigator.pop(context);
              Navigator.pushNamed(context, '/clients');
            },
          ),
          ListTile(
            leading: Icon(Icons.work, size: 20, color: AppColors.primary),
            title: Text(
              'Services',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 15,
                color: AppColors.lightText,
              ),
            ),
            dense: true,
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 0),
            onTap: () {
              Navigator.pop(context);
              Navigator.pushNamed(context, '/services');
            },
          ),
          ListTile(
            leading:
                Icon(Icons.dashboard, size: 20, color: AppColors.secondary),
            title: Text(
              'Planner',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 15,
                color: AppColors.lightText,
              ),
            ),
            dense: true,
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 0),
            onTap: () async {
              Navigator.pop(context);
              final url = Uri.parse('https://trello.com/b/???/invoice-app-devops');
              if (await canLaunchUrl(url)) {
                await launchUrl(url, mode: LaunchMode.externalApplication);
              } else {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Could not open Planner')),
                  );
                }
              }
            },
          ),
          const Divider(height: 8, indent: 0, endIndent: 0),
          ListTile(
            leading: const Icon(Icons.logout, color: Colors.red, size: 20),
            title: const Text(
              'Logout',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 15,
                color: Colors.red,
              ),
            ),
            dense: true,
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 0),
            onTap: () async {
              Navigator.pop(context); // Close drawer
              final confirmed = await showDialog<bool>(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('Logout'),
                  content: const Text('Are you sure you want to logout?'),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context, false),
                      child: const Text('Cancel'),
                    ),
                    ElevatedButton(
                      onPressed: () => Navigator.pop(context, true),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                      ),
                      child: const Text('Logout'),
                    ),
                  ],
                ),
              );
              if (confirmed == true) {
                _logout();
              }
            },
          ),
        ],
      ),
    );
  }
}
