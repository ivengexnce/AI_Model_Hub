import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/ml_model.dart';
import '../providers/auth_provider.dart';
import '../providers/model_provider.dart';
import '../widgets/common_widgets.dart';
import '../widgets/model_card.dart';
import 'add_edit_model_screen.dart';
import 'model_detail_screen.dart';
import 'login_screen.dart';
import 'github_browser_screen.dart';

class ModelListScreen extends StatefulWidget {
  const ModelListScreen({super.key});

  @override
  State<ModelListScreen> createState() => _ModelListScreenState();
}

class _ModelListScreenState extends State<ModelListScreen> {
  late final TextEditingController _search;

  @override
  void initState() {
    super.initState();
    _search = TextEditingController(
      text: context.read<ModelProvider>().searchQuery,
    );
  }

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  void _openAdd() => Navigator.push(
    context,
    MaterialPageRoute(builder: (_) => const AddEditModelScreen()),
  );

  void _openDetail(MlModel m) => Navigator.push(
    context,
    MaterialPageRoute(builder: (_) => ModelDetailScreen(model: m)),
  );

  void _clearFilters(ModelProvider p) {
    _search.clear();
    p.setSearchQuery('');
    p.setSelectedCategory('All');
  }

  @override
  Widget build(BuildContext context) {
    final p = context.watch<ModelProvider>();
    final items = p.models;
    final gutter = pageGutter(context);
    final c = Theme.of(context).colorScheme;
    final t = Theme.of(context).textTheme;
    final filtersActive =
        p.searchQuery.isNotEmpty || p.selectedCategory != 'All';

    final countLabel = p.isLoading && items.isEmpty
        ? 'Loading…'
        : '${items.length} ${items.length == 1 ? 'model' : 'models'}'
              '${filtersActive ? ' found' : ''}';

    final Widget body;
    if (p.isLoading && items.isEmpty) {
      body = SliverPadding(
        padding: EdgeInsets.fromLTRB(gutter, Space.lg, gutter, Space.xl),
        sliver: const SliverToBoxAdapter(child: SkeletonList()),
      );
    } else if (p.errorMessage != null && items.isEmpty) {
      body = SliverFillRemaining(
        hasScrollBody: false,
        child: EmptyState(
          icon: Icons.cloud_off_outlined,
          title: 'Couldn’t load models',
          message: 'Check your connection and try again.',
          actionLabel: 'Try again',
          onAction: p.loadModels,
        ),
      );
    } else if (items.isEmpty) {
      body = SliverFillRemaining(
        hasScrollBody: false,
        child: filtersActive
            ? EmptyState(
                icon: Icons.search_off_outlined,
                title: 'No matching models',
                message: 'Try a different search or category.',
                actionLabel: 'Clear filters',
                onAction: () => _clearFilters(p),
              )
            : EmptyState(
                icon: Icons.inventory_2_outlined,
                title: 'No models yet',
                message: 'Register your first model to track its accuracy, latency and dataset.',
                actionLabel: 'Register a model',
                onAction: _openAdd,
              ),
      );
    } else {
      body = SliverPadding(
        padding: EdgeInsets.fromLTRB(gutter, Space.lg, gutter, 96),
        sliver: SliverList.separated(
          itemCount: items.length,
          separatorBuilder: (_, _) => const SizedBox(height: Space.md),
          itemBuilder: (_, i) => ModelCard(
            key: ValueKey(items[i].id),
            model: items[i],
            onTap: () => _openDetail(items[i]),
          ),
        ),
      );
    }

    return Scaffold(
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _openAdd,
        icon: const Icon(Icons.add),
        label: const Text('New model'),
      ),
      body: SafeArea(
        bottom: false,
        child: RefreshIndicator(
          onRefresh: p.loadModels,
          child: CustomScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            slivers: [
              SliverPadding(
                padding: EdgeInsets.fromLTRB(
                  gutter,
                  Space.md,
                  gutter,
                  Space.lg,
                ),
                sliver: SliverToBoxAdapter(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const BrandMark(),
                          const Spacer(),
                          IconButton(
                            tooltip: 'Browse GitHub Models',
                            icon: const Icon(Icons.terminal_rounded),
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => const GithubBrowserScreen(),
                                ),
                              );
                            },
                          ),
                          const _AccountMenu(),
                        ],
                      ),
                      const SizedBox(height: Space.xxl),
                      Text('Models', style: t.displaySmall),
                      const SizedBox(height: Space.xs),
                      Text(
                        countLabel,
                        style: t.bodyMedium?.copyWith(
                          color: c.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(height: Space.xl),
                      TextField(
                        controller: _search,
                        onChanged: p.setSearchQuery,
                        textInputAction: TextInputAction.search,
                        decoration: InputDecoration(
                          hintText: 'Search models',
                          prefixIcon: const Icon(Icons.search, size: 20),
                          suffixIcon: _search.text.isEmpty
                              ? null
                              : IconButton(
                                  tooltip: 'Clear search',
                                  icon: const Icon(Icons.close, size: 18),
                                  onPressed: () {
                                    _search.clear();
                                    p.setSearchQuery('');
                                  },
                                ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              SliverToBoxAdapter(
                child: SizedBox(
                  height: 36,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    padding: EdgeInsets.symmetric(horizontal: gutter),
                    itemCount: p.categories.length,
                    separatorBuilder: (_, _) =>
                        const SizedBox(width: Space.sm),
                    itemBuilder: (_, i) {
                      final cat = p.categories[i];
                      return _Pill(
                        label: cat,
                        selected: p.selectedCategory == cat,
                        onTap: () => p.setSelectedCategory(cat),
                      );
                    },
                  ),
                ),
              ),
              body,
            ],
          ),
        ),
      ),
    );
  }
}

class _Pill extends StatelessWidget {
  const _Pill({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = Theme.of(context).colorScheme;
    final t = Theme.of(context).textTheme;
    return Material(
      color: selected ? c.onSurface : Colors.transparent,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(Radii.sm),
        side: BorderSide(color: selected ? c.onSurface : c.outlineVariant),
      ),
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14),
          child: Center(
            child: Text(
              label,
              style: t.labelMedium?.copyWith(
                color: selected ? c.surface : c.onSurface,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _AccountMenu extends StatelessWidget {
  const _AccountMenu();

  @override
  Widget build(BuildContext context) {
    final user = context.select<AuthProvider, AuthUser?>((a) => a.currentUser);
    final savedCount = context.select<ModelProvider, int>((p) => p.savedModels.length);
    final c = Theme.of(context).colorScheme;
    final t = Theme.of(context).textTheme;
    final name = user?.displayName ?? '';
    final initial = name.isNotEmpty ? name[0].toUpperCase() : '?';

    return PopupMenuButton<String>(
      tooltip: 'Account',
      offset: const Offset(0, 44),
      onSelected: (v) async {
        if (v == 'saved') {
          context.read<ModelProvider>().setSelectedCategory('Saved');
        } else if (v == 'signout') {
          await context.read<AuthProvider>().logout();
          if (context.mounted) {
            Navigator.of(context).pushAndRemoveUntil(
              MaterialPageRoute(builder: (_) => const LoginScreen()),
              (route) => false,
            );
          }
        }
      },
      itemBuilder: (_) => [
        PopupMenuItem<String>(
          enabled: false,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(name.isEmpty ? 'Account' : name, style: t.titleSmall),
              if (user != null) Text(user.email, style: t.bodySmall),
              if (user != null && user.role.isNotEmpty)
                Text(
                  user.role,
                  style: t.labelSmall?.copyWith(color: c.primary),
                ),
            ],
          ),
        ),
        const PopupMenuDivider(),
        PopupMenuItem<String>(
          value: 'saved',
          child: Row(
            children: [
              const Icon(Icons.bookmark_outline_rounded, size: 18),
              const SizedBox(width: 8),
              Text('Saved Models ($savedCount)'),
            ],
          ),
        ),
        const PopupMenuDivider(),
        const PopupMenuItem<String>(
          value: 'signout',
          child: Row(
            children: [
              Icon(Icons.logout_rounded, size: 18, color: Colors.redAccent),
              SizedBox(width: 8),
              Text('Sign out', style: TextStyle(color: Colors.redAccent)),
            ],
          ),
        ),
      ],
      child: CircleAvatar(
        radius: 16,
        backgroundColor: c.surfaceContainerHigh,
        child: Text(initial, style: t.labelMedium),
      ),
    );
  }
}
