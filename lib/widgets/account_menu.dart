import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../providers/model_provider.dart';
import '../screens/security_dashboard_screen.dart';
import '../theme/app_theme.dart';

class AccountMenu extends StatelessWidget {
  const AccountMenu({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final user = auth.currentUser;
    final c = Theme.of(context).colorScheme;

    if (user == null) {
      return IconButton(
        tooltip: 'Sign In',
        icon: const Icon(Icons.account_circle_outlined),
        onPressed: () => Navigator.pushNamed(context, '/login'),
      );
    }

    final initial = user.displayName.isNotEmpty
        ? user.displayName.substring(0, 1).toUpperCase()
        : user.email.isNotEmpty
            ? user.email.substring(0, 1).toUpperCase()
            : 'U';

    return PopupMenuButton<String>(
      tooltip: 'Account: ${user.email}',
      offset: const Offset(0, 48),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(Radii.md),
        side: BorderSide(color: c.outlineVariant),
      ),
      icon: CircleAvatar(
        radius: 16,
        backgroundColor: c.primaryContainer,
        child: Text(
          initial,
          style: TextStyle(
            color: c.onPrimaryContainer,
            fontWeight: FontWeight.bold,
            fontSize: 13,
          ),
        ),
      ),
      itemBuilder: (context) => [
        PopupMenuItem<String>(
          enabled: false,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                user.displayName.isNotEmpty ? user.displayName : 'Authenticated User',
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
              ),
              Text(
                user.email,
                style: TextStyle(color: c.onSurfaceVariant, fontSize: 11),
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: user.isGuest ? Colors.amber.withAlpha(40) : Colors.green.withAlpha(40),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      user.isGuest ? 'GUEST SESSION' : 'VERIFIED ACCOUNT',
                      style: TextStyle(
                        fontSize: 9,
                        fontWeight: FontWeight.bold,
                        color: user.isGuest ? Colors.amber : Colors.greenAccent,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const PopupMenuDivider(),
        PopupMenuItem<String>(
          value: 'saved_models',
          child: Row(
            children: [
              const Icon(Icons.bookmark_outline_rounded, size: 18, color: Colors.amberAccent),
              const SizedBox(width: 10),
              Text('Saved Models (${context.read<ModelProvider>().savedModelsCount})'),
            ],
          ),
        ),
        PopupMenuItem<String>(
          value: 'saved_decisions',
          child: Row(
            children: [
              const Icon(Icons.history_edu_rounded, size: 18, color: Colors.cyanAccent),
              const SizedBox(width: 10),
              Text('Saved Decisions (${context.read<ModelProvider>().savedDecisions.length})'),
            ],
          ),
        ),
        PopupMenuItem<String>(
          value: 'threat_defense',
          child: const Row(
            children: [
              Icon(Icons.shield_outlined, size: 18, color: Color(0xFF38BDF8)),
              SizedBox(width: 10),
              Text('Threat Defense Platform'),
            ],
          ),
        ),
        const PopupMenuDivider(),
        const PopupMenuItem<String>(
          value: 'logout',
          child: Row(
            children: [
              Icon(Icons.logout_rounded, size: 18, color: Colors.redAccent),
              SizedBox(width: 10),
              Text('Sign Out', style: TextStyle(color: Colors.redAccent)),
            ],
          ),
        ),
      ],
      onSelected: (value) async {
        if (value == 'logout' || value == 'signout') {
          await auth.logout();
        } else if (value == 'saved_models') {
          context.read<ModelProvider>().setSelectedCategory('Saved');
        } else if (value == 'threat_defense') {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const SecurityDashboardScreen()),
          );
        }
      },
    );
  }
}
