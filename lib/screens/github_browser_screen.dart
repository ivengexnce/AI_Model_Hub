import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../services/github_service.dart';
import '../providers/model_provider.dart';
import '../providers/auth_provider.dart';

class GithubBrowserScreen extends StatefulWidget {
  const GithubBrowserScreen({super.key});

  @override
  State<GithubBrowserScreen> createState() => _GithubBrowserScreenState();
}

class _GithubBrowserScreenState extends State<GithubBrowserScreen> {
  final GithubService _githubService = GithubService();
  final TextEditingController _searchController = TextEditingController();

  List<GithubRepo> _repos = [];
  bool _isLoading = true;
  String _selectedCategory = 'All';
  final Set<String> _importedRepoIds = {};

  final List<String> _categories = [
    'All',
    'Computer Vision',
    'Natural Language Processing',
    'Audio & Speech',
    'Reinforcement Learning',
  ];

  @override
  void initState() {
    super.initState();
    _loadRepos();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadRepos() async {
    setState(() => _isLoading = true);
    final results = await _githubService.searchRepositories(
      query: _searchController.text.trim(),
      categoryFilter: _selectedCategory,
    );
    if (mounted) {
      setState(() {
        _repos = results;
        _isLoading = false;
      });
    }
  }

  Future<void> _importRepo(GithubRepo repo) async {
    final modelProvider = Provider.of<ModelProvider>(context, listen: false);
    final authUser = Provider.of<AuthProvider>(context, listen: false).currentUser;
    final mlModel = repo.toMlModel();

    setState(() {
      _importedRepoIds.add(repo.id);
    });

    final success = await modelProvider.createModel(
      name: mlModel.name,
      category: mlModel.category,
      framework: mlModel.framework,
      accuracy: mlModel.accuracy,
      latencyMs: mlModel.latencyMs,
      version: mlModel.version,
      description: mlModel.description,
      datasetName: mlModel.datasetName,
      githubUrl: mlModel.githubUrl,
      creatorId: authUser?.uid ?? '',
      creatorEmail: authUser?.email ?? '',
    );

    if (mounted) {
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: const Color(0xFF1E3A8A),
            behavior: SnackBarBehavior.floating,
            content: Row(
              children: [
                const Icon(Icons.check_circle, color: Colors.cyanAccent, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Imported "${mlModel.name}" to BroML Hub!',
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            duration: const Duration(seconds: 3),
            action: SnackBarAction(
              label: 'View',
              textColor: Colors.cyanAccent,
              onPressed: () => Navigator.pop(context),
            ),
          ),
        );
      } else {
        setState(() {
          _importedRepoIds.remove(repo.id);
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to import model. Please try again.'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    }
  }

  Future<void> _toggleSave(GithubRepo repo) async {
    final modelProvider = Provider.of<ModelProvider>(context, listen: false);
    final mlModel = repo.toMlModel();
    final added = await modelProvider.toggleSaveModel(mlModel);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: added ? const Color(0xFF1E3A8A) : const Color(0xFF334155),
          behavior: SnackBarBehavior.floating,
          content: Row(
            children: [
              Icon(
                added ? Icons.bookmark_added_rounded : Icons.bookmark_remove_rounded,
                color: Colors.cyanAccent,
                size: 20,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  added
                      ? 'Saved "${mlModel.name}" to your profile!'
                      : 'Removed "${mlModel.name}" from saved profile.',
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final modelProvider = context.watch<ModelProvider>();

    return Scaffold(
      backgroundColor: const Color(0xFF0D0E1A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF161729),
        elevation: 0,
        title: const Row(
          children: [
            Icon(Icons.terminal_rounded, color: Colors.cyanAccent, size: 22),
            SizedBox(width: 10),
            Text(
              'Browse GitHub Models',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
            ),
          ],
        ),
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 900),
          child: Column(
            children: [
              // ── Search & Filter header ──────────────────────────────────────────
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 16.0),
                decoration: const BoxDecoration(
                  color: Color(0xFF141524),
                  border: Border(
                    bottom: BorderSide(color: Color(0xFF22243A), width: 1),
                  ),
                ),
                child: Column(
                  children: [
                    // Search bar
                    TextField(
                      controller: _searchController,
                      style: const TextStyle(color: Colors.white, fontSize: 14),
                      onSubmitted: (_) => _loadRepos(),
                      decoration: InputDecoration(
                        hintText: 'Search GitHub ML models (e.g., yolo, llama, whisper, bert)...',
                        hintStyle: TextStyle(color: Colors.grey[400], fontSize: 13),
                        prefixIcon: const Icon(Icons.search, color: Colors.cyanAccent, size: 20),
                        suffixIcon: _searchController.text.isNotEmpty
                            ? IconButton(
                                icon: const Icon(Icons.clear, color: Colors.white54, size: 18),
                                onPressed: () {
                                  _searchController.clear();
                                  _loadRepos();
                                },
                              )
                            : null,
                        filled: true,
                        fillColor: const Color(0xFF1E2036),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: const BorderSide(color: Color(0xFF2B2E4E), width: 1),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: const BorderSide(color: Colors.cyanAccent, width: 1.5),
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),
                    // Category Chips
                    SizedBox(
                      height: 36,
                      child: ListView.separated(
                        scrollDirection: Axis.horizontal,
                        itemCount: _categories.length,
                        separatorBuilder: (_, _) => const SizedBox(width: 8),
                        itemBuilder: (context, index) {
                          final cat = _categories[index];
                          final isSelected = cat == _selectedCategory;
                          return ChoiceChip(
                            label: Text(cat),
                            selected: isSelected,
                            onSelected: (selected) {
                              if (selected) {
                                setState(() => _selectedCategory = cat);
                                _loadRepos();
                              }
                            },
                            selectedColor: const Color(0xFF3949AB),
                            backgroundColor: const Color(0xFF1E2036),
                            labelStyle: TextStyle(
                              color: isSelected ? Colors.white : Colors.white70,
                              fontSize: 12,
                              fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20),
                              side: BorderSide(
                                color: isSelected ? Colors.cyanAccent : const BorderSide(color: Color(0xFF2E3254)).color,
                                width: 1,
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),

              // ── Repos List ──────────────────────────────────────────────────────
              Expanded(
                child: _isLoading
                    ? const Center(
                        child: CircularProgressIndicator(color: Colors.cyanAccent),
                      )
                    : _repos.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.search_off, size: 54, color: Colors.grey[600]),
                                const SizedBox(height: 12),
                                Text(
                                  'No GitHub repositories found',
                                  style: TextStyle(color: Colors.grey[400], fontSize: 16),
                                ),
                                const SizedBox(height: 8),
                                TextButton.icon(
                                  onPressed: () {
                                    _searchController.clear();
                                    setState(() => _selectedCategory = 'All');
                                    _loadRepos();
                                  },
                                  icon: const Icon(Icons.refresh, color: Colors.cyanAccent),
                                  label: const Text('Reset search', style: TextStyle(color: Colors.cyanAccent)),
                                ),
                              ],
                            ),
                          )
                        : RefreshIndicator(
                            color: Colors.cyanAccent,
                            backgroundColor: const Color(0xFF181929),
                            onRefresh: _loadRepos,
                            child: ListView.builder(
                              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                              physics: const BouncingScrollPhysics(),
                              itemCount: _repos.length,
                              itemBuilder: (context, index) {
                                final repo = _repos[index];
                                final isImported = _importedRepoIds.contains(repo.id);
                                final isSaved = modelProvider.isModelSaved(repo.toMlModel());
                                return _buildRepoCard(repo, isImported, isSaved);
                              },
                            ),
                          ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRepoCard(GithubRepo repo, bool isImported, bool isSaved) {
    final previewModel = repo.toMlModel();

    return Container(
      margin: const EdgeInsets.only(bottom: 18),
      decoration: BoxDecoration(
        color: const Color(0xFF181A2E),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isImported
              ? Colors.cyanAccent.withAlpha(140)
              : isSaved
                  ? Colors.indigoAccent.withAlpha(140)
                  : const Color(0xFF2B2E4E),
          width: (isImported || isSaved) ? 1.5 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(100),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(18.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top Row: Avatar + Name + Stars & Lang + Copy Link
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: CachedNetworkImage(
                    imageUrl: repo.ownerAvatarUrl,
                    width: 44,
                    height: 44,
                    fit: BoxFit.cover,
                    placeholder: (_, _) => Container(color: Colors.grey[800]),
                    errorWidget: (context, url, error) => Container(
                      color: Colors.indigo,
                      child: const Icon(Icons.code, color: Colors.white, size: 22),
                    ),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        repo.fullName,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          letterSpacing: -0.2,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 5),
                      Wrap(
                        spacing: 8,
                        runSpacing: 4,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: Colors.amber.withAlpha(25),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: Colors.amber.withAlpha(80)),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.star_rounded, color: Colors.amber[400], size: 14),
                                const SizedBox(width: 3),
                                Text(
                                  _formatStars(repo.stars),
                                  style: TextStyle(
                                    color: Colors.amber[300],
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: Colors.white.withAlpha(12),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: Colors.white.withAlpha(30)),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.code, color: Colors.grey[300], size: 13),
                                const SizedBox(width: 4),
                                Text(
                                  repo.language,
                                  style: TextStyle(color: Colors.grey[300], fontSize: 11),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                IconButton(
                  tooltip: 'Copy GitHub Link',
                  icon: const Icon(Icons.copy_rounded, color: Colors.white54, size: 18),
                  onPressed: () {
                    Clipboard.setData(ClipboardData(text: repo.htmlUrl));
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Copied link: ${repo.htmlUrl}'),
                        behavior: SnackBarBehavior.floating,
                        duration: const Duration(seconds: 2),
                      ),
                    );
                  },
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Description
            Text(
              repo.description,
              style: const TextStyle(
                color: Color(0xFFCBD5E1),
                fontSize: 13,
                height: 1.4,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 14),

            // Inferred ML Specs Row
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: const Color(0xFF1F223B),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFF2E3358)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildSpecBadge('Category', previewModel.category, Colors.cyanAccent),
                  _buildSpecBadge('Framework', previewModel.framework, Colors.indigoAccent),
                  _buildSpecBadge('Est. Acc.', '${previewModel.accuracy}%', Colors.greenAccent),
                  _buildSpecBadge('Latency', '${previewModel.latencyMs}ms', Colors.orangeAccent),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Responsive Action Row: Save to Profile & Import to Hub
            Row(
              children: [
                // Button 1: Save to Profile / Local
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _toggleSave(repo),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
                      side: BorderSide(
                        color: isSaved ? Colors.cyanAccent : const Color(0xFF475569),
                        width: isSaved ? 1.5 : 1,
                      ),
                      backgroundColor: isSaved ? Colors.cyan.withAlpha(25) : Colors.transparent,
                      foregroundColor: isSaved ? Colors.cyanAccent : Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    icon: Icon(
                      isSaved ? Icons.bookmark_rounded : Icons.bookmark_border_rounded,
                      size: 16,
                      color: isSaved ? Colors.cyanAccent : Colors.white70,
                    ),
                    label: FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(
                        isSaved ? 'Saved in Profile' : 'Save to Profile',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                          color: isSaved ? Colors.cyanAccent : Colors.white,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                // Button 2: Import to BroML Hub
                Expanded(
                  child: FilledButton.icon(
                    onPressed: isImported ? null : () => _importRepo(repo),
                    style: FilledButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
                      backgroundColor: isImported ? const Color(0xFF1E293B) : const Color(0xFF4338CA),
                      disabledBackgroundColor: const Color(0xFF1E293B),
                      disabledForegroundColor: Colors.cyanAccent,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                        side: isImported
                            ? const BorderSide(color: Colors.cyanAccent, width: 1)
                            : BorderSide.none,
                      ),
                    ),
                    icon: Icon(
                      isImported ? Icons.check_circle_rounded : Icons.cloud_upload_outlined,
                      size: 16,
                      color: isImported ? Colors.cyanAccent : Colors.white,
                    ),
                    label: FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(
                        isImported ? 'Imported to Hub' : 'Import to Hub',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                          color: isImported ? Colors.cyanAccent : Colors.white,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSpecBadge(String label, String value, Color color) {
    return Expanded(
      child: Column(
        children: [
          Text(
            label.toUpperCase(),
            style: TextStyle(
              color: Colors.grey[400],
              fontSize: 10,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.5,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 3),
          Text(
            value,
            style: TextStyle(
              color: color,
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  String _formatStars(int stars) {
    if (stars >= 1000) {
      return '${(stars / 1000).toStringAsFixed(1)}k';
    }
    return stars.toString();
  }
}
