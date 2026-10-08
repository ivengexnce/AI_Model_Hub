import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../providers/auth_provider.dart';
import '../providers/model_provider.dart';
import '../models/ml_model.dart';
import '../widgets/animated_3d_card.dart';
import '../widgets/flip_3d_card.dart';
import '../widgets/floating_3d_badge.dart';
import 'model_detail_screen.dart';
import 'add_edit_model_screen.dart';
import 'login_screen.dart';

class ModelListScreen extends StatelessWidget {
  const ModelListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final modelProvider = Provider.of<ModelProvider>(context);

    return Scaffold(
      backgroundColor: const Color(0xFF0D0E1A),
      appBar: AppBar(
        title: Row(
          children: [
            Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                boxShadow: [
                  BoxShadow(
                    color: Colors.cyanAccent.withAlpha(80),
                    blurRadius: 8,
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.asset('assets/logo_small.png', fit: BoxFit.cover),
              ),
            ),
            const SizedBox(width: 10),
            const Text(
              'BroML',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                letterSpacing: 0.4,
                color: Colors.white,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            onPressed: () => modelProvider.loadModels(),
            tooltip: 'Refresh Models',
          ),
          Consumer<AuthProvider>(
            builder: (context, auth, _) {
              final initial = auth.currentUser?.displayName.isNotEmpty == true
                  ? auth.currentUser!.displayName[0]
                  : 'M';
              return PopupMenuButton<String>(
                icon: CircleAvatar(
                  radius: 14,
                  backgroundColor: Colors.indigo,
                  child: Text(
                    initial,
                    style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                  ),
                ),
                tooltip: 'Account Profile',
                onSelected: (value) async {
                  if (value == 'logout') {
                    final messenger = ScaffoldMessenger.of(context);
                    await auth.logout();
                    if (context.mounted) {
                      Navigator.of(context).pushAndRemoveUntil(
                        PageRouteBuilder(
                          pageBuilder: (ctx, a1, a2) => const LoginScreen(),
                          transitionDuration: const Duration(milliseconds: 350),
                          transitionsBuilder: (ctx, anim, a2, child) =>
                              FadeTransition(opacity: anim, child: child),
                        ),
                        (route) => false,
                      );
                      messenger.showSnackBar(
                        const SnackBar(
                          content: Text('Successfully signed out.'),
                          duration: Duration(seconds: 2),
                        ),
                      );
                    }
                  }
                },
                itemBuilder: (context) => [
                  PopupMenuItem(
                    enabled: false,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          auth.currentUser?.displayName ?? 'ML Engineer',
                          style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
                        ),
                        Text(
                          auth.currentUser?.email ?? 'developer@aimodelhub.ai',
                          style: const TextStyle(fontSize: 11, color: Colors.white70),
                        ),
                      ],
                    ),
                  ),
                  const PopupMenuDivider(),
                  const PopupMenuItem(
                    value: 'logout',
                    child: Row(
                      children: [
                        Icon(Icons.logout, size: 18, color: Colors.redAccent),
                        SizedBox(width: 8),
                        Text('Sign Out', style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.w600)),
                      ],
                    ),
                  ),
                ],
              );
            },
          ),
          const SizedBox(width: 8),
        ],
        elevation: 0,
        backgroundColor: const Color(0xFF181929),
      ),
      body: RefreshIndicator(
        onRefresh: () => modelProvider.loadModels(),
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      decoration: BoxDecoration(
                        boxShadow: [
                          BoxShadow(
                            color: Colors.indigo.withAlpha(20),
                            blurRadius: 16,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: TextField(
                        style: const TextStyle(color: Colors.white),
                        onChanged: (value) => modelProvider.setSearchQuery(value),
                        decoration: InputDecoration(
                          hintText: 'Search models, frameworks, datasets...',
                          hintStyle: TextStyle(color: Colors.grey[400]),
                          prefixIcon: const Icon(Icons.search, color: Colors.cyanAccent),
                          filled: true,
                          fillColor: const Color(0xFF181929),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                            borderSide: BorderSide(color: Colors.white.withAlpha(20)),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                            borderSide: BorderSide(color: Colors.white.withAlpha(20)),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    _buildStatsBanner(modelProvider.models),
                    const SizedBox(height: 16),

                    SizedBox(
                      height: 42,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        physics: const BouncingScrollPhysics(),
                        itemCount: modelProvider.categories.length,
                        itemBuilder: (context, index) {
                          final category = modelProvider.categories[index];
                          final isSelected = category == modelProvider.selectedCategory;
                          return Padding(
                            padding: const EdgeInsets.only(right: 8.0),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              child: FilterChip(
                                label: Text(category),
                                selected: isSelected,
                                onSelected: (_) => modelProvider.setSelectedCategory(category),
                                selectedColor: Colors.indigo,
                                elevation: isSelected ? 4 : 1,
                                shadowColor: Colors.indigo.withAlpha(80),
                                labelStyle: TextStyle(
                                  color: isSelected ? Colors.white : Colors.grey[300],
                                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                ),
                                backgroundColor: const Color(0xFF181929),
                                side: BorderSide(
                                  color: isSelected ? Colors.indigoAccent : Colors.white.withAlpha(25),
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(20),
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Double-tap card to flip 3D specs view. Hover/drag for 3D tilt.',
                      style: TextStyle(fontSize: 12, color: Colors.grey[400], fontStyle: FontStyle.italic),
                    ),
                  ],
                ),
              ),
            ),

            modelProvider.isLoading
                ? const SliverFillRemaining(
                    child: Center(child: CircularProgressIndicator()),
                  )
                : modelProvider.models.isEmpty
                    ? SliverFillRemaining(
                        child: Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Floating3dBadge(icon: Icons.memory, color: Colors.grey, size: 48),
                              const SizedBox(height: 16),
                              Text(
                                'No ML models found',
                                style: TextStyle(fontSize: 18, color: Colors.grey[600]),
                              ),
                              const SizedBox(height: 12),
                              ElevatedButton.icon(
                                onPressed: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => const AddEditModelScreen(),
                                    ),
                                  );
                                },
                                icon: const Icon(Icons.add),
                                label: const Text('Publish First Model'),
                              ),
                            ],
                          ),
                        ),
                      )
                    : SliverPadding(
                        padding: const EdgeInsets.symmetric(horizontal: 16.0),
                        sliver: SliverList(
                          delegate: SliverChildBuilderDelegate(
                            (context, index) {
                              final model = modelProvider.models[index];
                              return Padding(
                                padding: const EdgeInsets.only(bottom: 20.0),
                                child: Animated3dCard(
                                  onTap: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (_) => ModelDetailScreen(model: model),
                                      ),
                                    );
                                  },
                                  child: Flip3dCard(
                                    front: _buildCardFront(model),
                                    back: _buildCardBack(model),
                                  ),
                                ),
                              );
                            },
                            childCount: modelProvider.models.length,
                          ),
                        ),
                      ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => const AddEditModelScreen(),
            ),
          );
        },
        backgroundColor: Colors.indigo,
        elevation: 6,
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text('Publish Model', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      ),
    );
  }

  Widget _buildStatsBanner(List<MlModel> models) {
    double avgAccuracy = 0;
    if (models.isNotEmpty) {
      avgAccuracy = models.map((m) => m.accuracy).reduce((a, b) => a + b) / models.length;
    }

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF3F51B5), Color(0xFF673AB7)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.indigo.withAlpha(76),
            blurRadius: 14,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildStatItem('Models Registered', '${models.length}', Icons.hub),
          Container(width: 1, height: 40, color: Colors.white30),
          _buildStatItem('Avg Accuracy', '${avgAccuracy.toStringAsFixed(1)}%', Icons.analytics),
          Container(width: 1, height: 40, color: Colors.white30),
          _buildStatItem('ML Frameworks', 'PyTorch/TF', Icons.code),
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, String value, IconData icon) {
    return Column(
      children: [
        Floating3dBadge(icon: icon, color: Colors.white, size: 20),
        const SizedBox(height: 6),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: const TextStyle(color: Colors.white70, fontSize: 11),
        ),
      ],
    );
  }

  Widget _buildCardFront(MlModel model) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF181929),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withAlpha(25)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(80),
            blurRadius: 14,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
            child: CachedNetworkImage(
              imageUrl: model.imageUrl,
              height: 160,
              width: double.infinity,
              fit: BoxFit.cover,
              placeholder: (context, url) => Container(
                height: 160,
                color: const Color(0xFF222336),
                child: const Center(child: CircularProgressIndicator(color: Colors.cyanAccent)),
              ),
              errorWidget: (context, url, error) => Container(
                height: 160,
                color: const Color(0xFF222336),
                child: const Icon(Icons.broken_image, size: 48, color: Colors.indigoAccent),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.indigoAccent.withAlpha(35),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        model.category,
                        style: const TextStyle(
                          color: Colors.cyanAccent,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ),
                    Text(
                      'v${model.version}',
                      style: TextStyle(color: Colors.grey[400], fontSize: 12, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  model.name,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  model.description,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(color: Colors.grey[300], fontSize: 13),
                ),
                const SizedBox(height: 12),
                const Divider(color: Colors.white12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _buildMetricChip(
                      Icons.check_circle_outline,
                      '${model.accuracy}% Acc',
                      Colors.greenAccent,
                    ),
                    _buildMetricChip(
                      Icons.bolt,
                      '${model.latencyMs} ms',
                      Colors.amberAccent,
                    ),
                    _buildMetricChip(
                      Icons.layers,
                      model.framework,
                      Colors.lightBlueAccent,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCardBack(MlModel model) {
    return Container(
      constraints: const BoxConstraints(minHeight: 330),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E2C),
        borderRadius: BorderRadius.circular(20),
        boxShadow: const [
          BoxShadow(color: Colors.black45, blurRadius: 10),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Row(
                children: [
                  Icon(Icons.flip, color: Colors.cyanAccent, size: 20),
                  SizedBox(width: 8),
                  Text('3D Specs & Tensor Matrix', style: TextStyle(color: Colors.cyanAccent, fontWeight: FontWeight.bold)),
                ],
              ),
              Text('Double tap to flip back', style: TextStyle(color: Colors.grey[500], fontSize: 11)),
            ],
          ),
          const Divider(color: Colors.white24, height: 20),
          Text(model.name, style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),

          _buildBackRow('Dataset', model.datasetName),
          _buildBackRow('Accuracy Benchmark', '${model.accuracy}% Top-1'),
          _buildBackRow('Inference Latency', '${model.latencyMs} ms / sample'),
          _buildBackRow('Framework Backend', model.framework),
          _buildBackRow('Deployment Target', 'Android ONNX/TFLite'),
          const SizedBox(height: 16),

          Center(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.indigoAccent.withAlpha(40),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.indigoAccent),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.touch_app, color: Colors.indigoAccent, size: 16),
                  SizedBox(width: 6),
                  Text('Tap card to open full details', style: TextStyle(color: Colors.indigoAccent, fontSize: 12)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBackRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Colors.white70, fontSize: 13)),
          Text(value, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
        ],
      ),
    );
  }

  Widget _buildMetricChip(IconData icon, String label, Color color) {
    return Row(
      children: [
        Icon(icon, size: 16, color: color),
        const SizedBox(width: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: color,
          ),
        ),
      ],
    );
  }
}
