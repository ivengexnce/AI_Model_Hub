import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/ml_model.dart';
import '../providers/auth_provider.dart';
import '../providers/model_provider.dart';
import '../widgets/common_widgets.dart';
import '../widgets/model_card.dart';
import 'add_edit_model_screen.dart';
import 'model_detail_screen.dart';
import 'github_browser_screen.dart';
import 'security_dashboard_screen.dart';
import '../widgets/account_menu.dart';

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
    p.setSelectedSource('All');
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final user = auth.currentUser;
    final p = context.watch<ModelProvider>();

    if (user != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        p.updateCurrentUser(userId: user.uid, userEmail: user.email);
      });
    }
    final items = p.models;
    final gutter = pageGutter(context);
    final c = Theme.of(context).colorScheme;
    final t = Theme.of(context).textTheme;
    final filtersActive =
        p.searchQuery.isNotEmpty || p.selectedCategory != 'All' || p.selectedSource != 'All';

    final countLabel = p.isLoading && items.isEmpty
        ? 'Loading…'
        : '${items.length} ${items.length == 1 ? 'model' : 'models'}'
              '${filtersActive ? ' found' : ' available in Hub'}';

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
          message: p.errorMessage!,
          actionLabel: 'Retry',
          onAction: p.loadModels,
        ),
      );
    } else if (items.isEmpty) {
      body = SliverFillRemaining(
        hasScrollBody: false,
        child: EmptyState(
          icon: filtersActive
              ? Icons.filter_alt_off_outlined
              : Icons.inventory_2_outlined,
          title: filtersActive ? 'No matching models' : 'No models registered',
          message: filtersActive
              ? 'Try widening your search terms or picking another category.'
              : 'Add your first ML model to the zoo or explore open-source GitHub models.',
          actionLabel: filtersActive ? 'Clear filters' : 'Add model',
          onAction: filtersActive ? () => _clearFilters(p) : _openAdd,
        ),
      );
    } else {
      body = SliverPadding(
        padding: EdgeInsets.fromLTRB(gutter, Space.lg, gutter, 96),
        sliver: SliverList.separated(
          itemCount: items.length,
          separatorBuilder: (_, _) => const SizedBox(height: Space.md),
          itemBuilder: (_, i) => ModelCard(
            key: ValueKey(items[i].id.isNotEmpty ? items[i].id : 'item-$i'),
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
                            icon: const Icon(Icons.terminal_rounded, color: Colors.cyanAccent),
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => const GithubBrowserScreen(),
                                ),
                              );
                            },
                          ),
                          IconButton(
                            tooltip: 'Threat Defense Platform',
                            icon: const Icon(Icons.shield_outlined, color: Color(0xFF38BDF8)),
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => const SecurityDashboardScreen(),
                                ),
                              );
                            },
                          ),
                          const AccountMenu(),
                        ],
                      ),
                      const SizedBox(height: Space.xl),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.baseline,
                        textBaseline: TextBaseline.alphabetic,
                        children: [
                          Text('Models', style: t.displaySmall),
                          const SizedBox(width: Space.md),
                          Text(
                            countLabel,
                            style: t.bodyMedium?.copyWith(
                              color: c.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: Space.md),

                      // Quick Registry & Discovery Banner
                      InkWell(
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const GithubBrowserScreen(),
                          ),
                        ),
                        borderRadius: BorderRadius.circular(Radii.sm),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: Space.md, vertical: 10),
                          decoration: BoxDecoration(
                            color: const Color(0xFF0F172A),
                            borderRadius: BorderRadius.circular(Radii.sm),
                            border: Border.all(color: const Color(0xFF1E293B)),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.hub_outlined, size: 16, color: Colors.cyanAccent),
                              const SizedBox(width: Space.sm),
                              Expanded(
                                child: Text(
                                  '${items.where((m) => m.verificationStatus == 'verified').length} Verified Models • Live Foundation Zoo',
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: Color(0xFF94A3B8),
                                    fontWeight: FontWeight.w500,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              const SizedBox(width: 6),
                              const Text(
                                'Explore →',
                                style: TextStyle(
                                  color: Colors.cyanAccent,
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: Space.lg),

                      // Search bar
                      TextField(
                        controller: _search,
                        onChanged: p.setSearchQuery,
                        textInputAction: TextInputAction.search,
                        decoration: InputDecoration(
                          hintText: 'Search all models (e.g. DeepSeek, YOLO, Whisper, LLaMA, XGBoost)...',
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
                      const SizedBox(height: Space.md),

                      // Single Clean ML Task Category Filter Bar
                      _CategoryFilterBar(
                        categories: p.categories,
                        selected: p.selectedCategory,
                        onSelect: p.setSelectedCategory,
                      ),
                    ],
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

class _CategoryFilterBar extends StatelessWidget {
  const _CategoryFilterBar({
    required this.categories,
    required this.selected,
    required this.onSelect,
  });

  final List<String> categories;
  final String selected;
  final ValueChanged<String> onSelect;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 38,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: categories.length,
        separatorBuilder: (_, _) => const SizedBox(width: Space.sm),
        itemBuilder: (context, i) {
          final cat = categories[i];
          final active = cat == selected;
          return FilterChip(
            selected: active,
            showCheckmark: false,
            label: Text(cat),
            onSelected: (_) => onSelect(cat),
          );
        },
      ),
    );
  }
}

