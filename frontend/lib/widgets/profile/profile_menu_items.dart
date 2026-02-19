import 'package:flutter/material.dart';

class ProfileMenuItems extends StatelessWidget {
  final List<ProfileMenuItem> items;

  const ProfileMenuItems({super.key, required this.items});

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Column(
      children: items.map((item) {
        return ListTile(
          leading: Icon(item.icon, size: 22),
          title: Text(
            item.title,
            style: textTheme.bodyMedium,
          ),
          trailing: const Icon(Icons.chevron_right),
          onTap: item.onTap,
        );
      }).toList(),
    );
  }
}

class ProfileMenuItem {
  final IconData icon;
  final String title;
  final VoidCallback onTap;

  ProfileMenuItem({
    required this.icon,
    required this.title,
    required this.onTap,
  });
}
