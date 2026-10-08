import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../models/ml_model.dart';
import '../providers/model_provider.dart';
import '../widgets/floating_3d_badge.dart';
import 'add_edit_model_screen.dart';

class ModelDetailScreen extends StatelessWidget {
  final MlModel model;

  const ModelDetailScreen({super.key, required this.model});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0D0E1A),
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            backgroundColor: const Color(0xFF181929),
            iconTheme: const IconThemeData(color: Colors.white),
            expandedHeight: 260,
            pinned: true,
            flexibleSpace: FlexibleSpaceBar(
              title: Text(
                model.name,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  shadows: [Shadow(color: Colors.black87, blurRadius: 10)],
                ),
              ),
              background: Stack(
                fit: StackFit.expand,
                children: [
                  CachedNetworkImage(
                    imageUrl: model.imageUrl,
                    fit: BoxFit.cover,
                    placeholder: (context, url) => Container(
                      color: const Color(0xFF181929),
                      child: const Center(child: CircularProgressIndicator(color: Colors.cyanAccent)),
                    ),
                    errorWidget: (context, url, error) => Container(
                      color: const Color(0xFF181929),
                      child: const Icon(Icons.psychology, size: 80, color: Colors.indigoAccent),
                    ),
                  ),
                  Container(
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Colors.transparent,
                          Color(0xFF0D0E1A),
                        ],
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.edit, color: Colors.white),
                tooltip: 'Edit Model Specs',
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => AddEditModelScreen(modelToEdit: model),
                    ),
                  );
                },
              ),
              IconButton(
                icon: const Icon(Icons.delete_outline, color: Colors.white),
                tooltip: 'Unregister Model',
                onPressed: () => _confirmDelete(context),
              ),
            ],
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Chip(
                        avatar: const Floating3dBadge(icon: Icons.category, color: Colors.cyanAccent, size: 16),
                        label: Text(model.category),
                        backgroundColor: const Color(0xFF181929),
                        side: BorderSide(color: Colors.cyanAccent.withAlpha(50)),
                        labelStyle: const TextStyle(color: Colors.cyanAccent, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(width: 8),
                      Chip(
                        avatar: const Floating3dBadge(icon: Icons.verified, color: Colors.tealAccent, size: 16),
                        label: Text('Version ${model.version}'),
                        backgroundColor: const Color(0xFF181929),
                        side: BorderSide(color: Colors.tealAccent.withAlpha(50)),
                        labelStyle: const TextStyle(color: Colors.tealAccent, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  const Text(
                    'Performance Benchmarks',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: _buildMetricTile(
                          'Accuracy',
                          '${model.accuracy}%',
                          Icons.insights,
                          Colors.greenAccent,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildMetricTile(
                          'Inference Speed',
                          '${model.latencyMs} ms',
                          Icons.bolt,
                          Colors.amberAccent,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildMetricTile(
                          'Framework',
                          model.framework,
                          Icons.memory,
                          Colors.lightBlueAccent,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  _buildSectionHeader('Training & Evaluation Dataset', Icons.dataset),
                  const SizedBox(height: 8),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFF181929),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.white.withAlpha(25)),
                    ),
                    child: Row(
                      children: [
                        const Floating3dBadge(icon: Icons.storage, color: Colors.cyanAccent, size: 20),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            model.datasetName,
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  _buildSectionHeader('Model Summary & Architecture Details', Icons.description),
                  const SizedBox(height: 8),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFF181929),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.white.withAlpha(25)),
                    ),
                    child: Text(
                      model.description,
                      style: const TextStyle(fontSize: 15, height: 1.5, color: Colors.white70),
                    ),
                  ),
                  const SizedBox(height: 32),

                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => AddEditModelScreen(modelToEdit: model),
                              ),
                            );
                          },
                          icon: const Icon(Icons.edit),
                          label: const Text('Edit Model (HTTP PUT)'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.indigo,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      OutlinedButton.icon(
                        onPressed: () => _confirmDelete(context),
                        icon: const Icon(Icons.delete, color: Colors.red),
                        label: const Text('Delete (HTTP DELETE)', style: TextStyle(color: Colors.red)),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
                          side: const BorderSide(color: Colors.red),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title, IconData icon) {
    return Row(
      children: [
        Icon(icon, color: Colors.cyanAccent, size: 20),
        const SizedBox(width: 8),
        Text(
          title,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
        ),
      ],
    );
  }

  Widget _buildMetricTile(String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF181929),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white.withAlpha(25)),
      ),
      child: Column(
        children: [
          Floating3dBadge(icon: icon, color: color, size: 20),
          const SizedBox(height: 6),
          Text(
            value,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 15,
              color: color,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: TextStyle(fontSize: 11, color: Colors.grey[400]),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  void _confirmDelete(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Unregister Model'),
        content: Text('Are you sure you want to unregister "${model.name}"? This action sends an HTTP DELETE request.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () async {
              Navigator.pop(ctx);
              final provider = Provider.of<ModelProvider>(context, listen: false);
              final success = await provider.deleteModel(model.id);
              if (success && context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Model unregistered successfully.')),
                );
                Navigator.pop(context);
              }
            },
            child: const Text('Delete', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}
