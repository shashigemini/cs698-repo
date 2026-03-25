import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class HomeDrawer extends StatelessWidget {
  const HomeDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: ListView(
        children: [
          const DrawerHeader(child: Text('Navigation')),
          ListTile(
            title: const Text('Sign In / Register'),
            onTap: () => context.push('/login'),
          ),
          ListTile(
            title: const Text('Account Settings'),
            onTap: () => context.push('/settings'),
          ),
          ListTile(
            title: const Text('Logout'),
            onTap: () => context.go('/login'),
          ),
        ],
      ),
    );
  }
}
