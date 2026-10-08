import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../models/ml_model.dart';
import '../providers/model_provider.dart';
import '../widgets/floating_3d_badge.dart';

class AddEditModelScreen extends StatefulWidget {
  final MlModel? modelToEdit;

  const AddEditModelScreen({super.key, this.modelToEdit});

  @override
  State<AddEditModelScreen> createState() => _AddEditModelScreenState();
}

class _AddEditModelScreenState extends State<AddEditModelScreen> {
  final _formKey = GlobalKey<FormState>();

  late String _name;
  late String _category;
  late String _framework;
  late double _accuracy;
  late int _latencyMs;
  late String _version;
  late String _description;
  late String _datasetName;

  XFile? _selectedImageFile;

  @override
  void initState() {
    super.initState();
    final model = widget.modelToEdit;
    _name = model?.name ?? '';
    _category = model?.category ?? 'Computer Vision';
    _framework = model?.framework ?? 'PyTorch';
    _accuracy = model?.accuracy ?? 92.0;
    _latencyMs = model?.latencyMs ?? 15;
    _version = model?.version ?? '1.0.0';
    _description = model?.description ?? '';
    _datasetName = model?.datasetName ?? '';
  }

  Future<void> _pickImage(ImageSource source) async {
    final provider = Provider.of<ModelProvider>(context, listen: false);
    final picked = await provider.pickImage(source);
    if (picked != null) {
      setState(() {
        _selectedImageFile = picked;
      });
    }
  }

  void _submitForm() async {
    if (!_formKey.currentState!.validate()) return;
    _formKey.currentState!.save();

    final provider = Provider.of<ModelProvider>(context, listen: false);
    bool success;

    if (widget.modelToEdit == null) {
      success = await provider.createModel(
        name: _name,
        category: _category,
        framework: _framework,
        accuracy: _accuracy,
        latencyMs: _latencyMs,
        version: _version,
        description: _description,
        datasetName: _datasetName,
        imageFile: _selectedImageFile,
      );
    } else {
      success = await provider.updateModel(
        widget.modelToEdit!,
        name: _name,
        category: _category,
        framework: _framework,
        accuracy: _accuracy,
        latencyMs: _latencyMs,
        version: _version,
        description: _description,
        datasetName: _datasetName,
        newImageFile: _selectedImageFile,
      );
    }

    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            widget.modelToEdit == null
                ? 'Model published successfully! (HTTP POST)'
                : 'Model updated successfully! (HTTP PUT)',
          ),
        ),
      );
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.modelToEdit != null;
    final provider = Provider.of<ModelProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(isEditing ? 'Edit Model Specs' : 'Publish New ML Model'),
      ),
      body: Stack(
        children: [
          SingleChildScrollView(
            padding: const EdgeInsets.all(20.0),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Architecture Diagram / Test Photo',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    height: 180,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: Colors.grey[200],
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.grey[400]!),
                    ),
                    child: _selectedImageFile != null
                        ? ClipRRect(
                            borderRadius: BorderRadius.circular(16),
                            child: kIsWeb
                                ? Image.network(
                                    _selectedImageFile!.path,
                                    fit: BoxFit.cover,
                                    width: double.infinity,
                                  )
                                : Image.file(
                                    File(_selectedImageFile!.path),
                                    fit: BoxFit.cover,
                                    width: double.infinity,
                                  ),
                          )
                        : isEditing && widget.modelToEdit!.imageUrl.isNotEmpty
                            ? ClipRRect(
                                borderRadius: BorderRadius.circular(16),
                                child: Image.network(
                                  widget.modelToEdit!.imageUrl,
                                  fit: BoxFit.cover,
                                  width: double.infinity,
                                ),
                              )
                            : Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Floating3dBadge(icon: Icons.cloud_upload, color: Colors.indigo, size: 40),
                                  const SizedBox(height: 8),
                                  Text('Upload Diagram / Photo to Firebase Storage',
                                      style: TextStyle(color: Colors.grey[700])),
                                ],
                              ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () => _pickImage(ImageSource.gallery),
                          icon: const Icon(Icons.photo_library),
                          label: const Text('Gallery'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () => _pickImage(ImageSource.camera),
                          icon: const Icon(Icons.camera_alt),
                          label: const Text('Camera'),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  TextFormField(
                    initialValue: _name,
                    decoration: const InputDecoration(
                      labelText: 'Model Name',
                      hintText: 'e.g. ResNet-101 Classifier',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.psychology),
                    ),
                    validator: (val) => val == null || val.trim().isEmpty ? 'Please enter model name' : null,
                    onSaved: (val) => _name = val!.trim(),
                  ),
                  const SizedBox(height: 16),

                  Row(
                    children: [
                      Expanded(
                        child: DropdownButtonFormField<String>(
                          initialValue: provider.categories.contains(_category) ? _category : 'Computer Vision',
                          decoration: const InputDecoration(
                            labelText: 'Domain Category',
                            border: OutlineInputBorder(),
                          ),
                          items: provider.categories
                              .where((c) => c != 'All')
                              .map((cat) => DropdownMenuItem(value: cat, child: Text(cat, overflow: TextOverflow.ellipsis)))
                              .toList(),
                          onChanged: (val) => setState(() => _category = val!),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: DropdownButtonFormField<String>(
                          initialValue: ['PyTorch', 'TensorFlow', 'ONNX', 'Scikit-Learn'].contains(_framework)
                              ? _framework
                              : 'PyTorch',
                          decoration: const InputDecoration(
                            labelText: 'Framework',
                            border: OutlineInputBorder(),
                          ),
                          items: ['PyTorch', 'TensorFlow', 'ONNX', 'Scikit-Learn']
                              .map((fw) => DropdownMenuItem(value: fw, child: Text(fw)))
                              .toList(),
                          onChanged: (val) => setState(() => _framework = val!),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          initialValue: _accuracy.toString(),
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(
                            labelText: 'Accuracy %',
                            hintText: '95.5',
                            border: OutlineInputBorder(),
                            prefixIcon: Icon(Icons.analytics),
                          ),
                          validator: (val) {
                            if (val == null || double.tryParse(val) == null) return 'Valid number required';
                            return null;
                          },
                          onSaved: (val) => _accuracy = double.parse(val!),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextFormField(
                          initialValue: _latencyMs.toString(),
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(
                            labelText: 'Latency (ms)',
                            hintText: '12',
                            border: OutlineInputBorder(),
                            prefixIcon: Icon(Icons.bolt),
                          ),
                          validator: (val) {
                            if (val == null || int.tryParse(val) == null) return 'Valid integer required';
                            return null;
                          },
                          onSaved: (val) => _latencyMs = int.parse(val!),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          initialValue: _version,
                          decoration: const InputDecoration(
                            labelText: 'Version Tag',
                            hintText: '1.0.0',
                            border: OutlineInputBorder(),
                          ),
                          onSaved: (val) => _version = val ?? '1.0.0',
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextFormField(
                          initialValue: _datasetName,
                          decoration: const InputDecoration(
                            labelText: 'Dataset Name',
                            hintText: 'COCO 2017',
                            border: OutlineInputBorder(),
                          ),
                          validator: (val) => val == null || val.trim().isEmpty ? 'Dataset required' : null,
                          onSaved: (val) => _datasetName = val!.trim(),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  TextFormField(
                    initialValue: _description,
                    maxLines: 3,
                    decoration: const InputDecoration(
                      labelText: 'Architecture Description & Training Summary',
                      border: OutlineInputBorder(),
                    ),
                    validator: (val) => val == null || val.trim().isEmpty ? 'Description required' : null,
                    onSaved: (val) => _description = val!.trim(),
                  ),
                  const SizedBox(height: 28),

                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton.icon(
                      onPressed: _submitForm,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.indigo,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      icon: Icon(isEditing ? Icons.save : Icons.cloud_upload),
                      label: Text(
                        isEditing ? 'Save Specs (HTTP PUT)' : 'Register Model (HTTP POST & Firebase)',
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Loading Modal Overlay
          if (provider.isLoading)
            Positioned.fill(
              child: Container(
                color: Colors.black45,
                child: const Center(
                  child: Card(
                    margin: EdgeInsets.all(32),
                    child: Padding(
                      padding: EdgeInsets.all(24.0),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Floating3dBadge(icon: Icons.cloud_upload, color: Colors.indigo, size: 40),
                          SizedBox(height: 16),
                          Text(
                            'Uploading image to Firebase Storage & syncing REST API...',
                            textAlign: TextAlign.center,
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
