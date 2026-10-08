import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../services/github_service.dart';
import '../providers/model_provider.dart';

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
                    'Imported "${mlModel.name}" to BroML Hub & Firestore!',
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            duration: const Duration(seconds: 3),
            action: SnackBarAction(
              label: 'Done',
              textColor: Colors.cyanAccent,
              onPressed: () {},
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0D0E1A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF181929),
        elevation: 0,
        title: const Row(
          children: [
            Icon(Icons.terminal_rounded, color: Colors.cyanAccent, size: 24),
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
      body: Column(
        children: [
          // ── Search & Filter header ──────────────────────────────────────────
          Container(
            padding: const EdgeInsets.all(16.0),
            color: const Color(0xFF141524),
            child: Column(
              children: [
                // Search bar
                TextField(
                  controller: _searchController,
                  style: const TextStyle(color: Colors.white),
                  onSubmitted: (_) => _loadRepos(),
                  decoration: InputDecoration(
                    hintText: 'Search GitHub ML models (e.g., yolo, llama, whisper)...',
                    hintStyle: TextStyle(color: Colors.grey[500], fontSize: 13),
                    prefixIcon: const Icon(Icons.search, color: Colors.cyanAccent),
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
                    fillColor: const Color(0xFF222336),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
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
                        selectedColor: Colors.indigo,
                        backgroundColor: const Color(0xFF222336),
                        labelStyle: TextStyle(
                          color: isSelected ? Colors.white : Colors.white70,
                          fontSize: 12,
                          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                          side: BorderSide(
                            color: isSelected ? Colors.cyanAccent : Colors.transparent,
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
                          padding: const EdgeInsets.all(16),
                          physics: const BouncingScrollPhysics(),
                          itemCount: _repos.length,
                          itemBuilder: (context, index) {
                            final repo = _repos[index];
                            final isImported = _importedRepoIds.contains(repo.id);
                            return _buildRepoCard(repo, isImported);
                          },
                        ),
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildRepoCard(GithubRepo repo, bool isImported) {
    final previewModel = repo.toMlModel();

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: const Color(0xFF181929),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isImported ? Colors.cyanAccent.withAlpha(120) : Colors.white.withAlpha(15),
          width: isImported ? 1.5 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(80),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top Row: Avatar + Name + Stars
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: CachedNetworkImage(
                    imageUrl: repo.ownerAvatarUrl,
                    width: 42,
                    height: 42,
                    fit: BoxFit.cover,
                    placeholder: (_, _) => Container(color: Colors.grey[800]),
                    errorWidget: (context, url, error) => Container(
                      color: Colors.indigo,
                      child: const Icon(Icons.code, color: Colors.white, size: 20),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        repo.fullName,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 3),
                      Row(
                        children: [
                          Icon(Icons.star_rounded, color: Colors.amber[400], size: 16),
                          const SizedBox(width: 4),
                          Text(
                            _formatStars(repo.stars),
                            style: TextStyle(
                              color: Colors.amber[300],
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Icon(Icons.code, color: Colors.grey[400], size: 14),
                          const SizedBox(width: 4),
                          Text(
                            repo.language,
                            style: TextStyle(color: Colors.grey[400], fontSize: 12),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Description
            Text(
              repo.description,
              style: const TextStyle(color: Colors.white70, fontSize: 13, height: 1.35),
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 14),

            // Inferred ML Specs Row
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              decoration: BoxDecoration(
                color: const Color(0xFF222336),
                borderRadius: BorderRadius.circular(10),
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
            const SizedBox(height: 14),

            // Action: Import to BroML Hub
            SizedBox(
              width: double.infinity,
              height: 42,
              child: ElevatedButton.icon(
                onPressed: isImported ? null : () => _importRepo(repo),
                style: ElevatedButton.styleFrom(
                  backgroundColor: isImported ? Colors.grey[800] : const Color(0xFF3949AB),
                  foregroundColor: Colors.white,
                  disabledBackgroundColor: const Color(0xFF1E293B),
                  disabledForegroundColor: Colors.cyanAccent,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: isImported
                        ? const BorderSide(color: Colors.cyanAccent, width: 1)
                        : BorderSide.none,
                  ),
                  elevation: isImported ? 0 : 3,
                ),
                icon: Icon(
                  isImported ? Icons.check_circle_rounded : Icons.add_circle_outline_rounded,
                  size: 18,
                  color: isImported ? Colors.cyanAccent : Colors.white,
                ),
                label: Text(
                  isImported ? 'Imported to BroML Hub' : 'Import to BroML Hub',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: isImported ? Colors.cyanAccent : Colors.white,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSpecBadge(String label, String value, Color color) {
    return Column(
      children: [
        Text(label, style: TextStyle(color: Colors.grey[500], fontSize: 10)),
        const SizedBox(height: 2),
        Text(
          value,
          style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.bold),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }

  String _formatStars(int stars) {
    if (stars >= 1000) {
      return '${(stars / 1000).toStringAsFixed(1)}k';
    }
    return stars.toString();
  }
}
