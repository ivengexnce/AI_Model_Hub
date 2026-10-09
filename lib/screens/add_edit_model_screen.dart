import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../models/ml_model.dart';
import '../providers/auth_provider.dart';
import '../providers/model_provider.dart';
import '../widgets/common_widgets.dart';
import '../widgets/model_image.dart';

class AddEditModelScreen extends StatefulWidget {
  final MlModel? modelToEdit;

  const AddEditModelScreen({super.key, this.modelToEdit});

  @override
  State<AddEditModelScreen> createState() => _AddEditModelScreenState();
}

class _AddEditModelScreenState extends State<AddEditModelScreen> {
  static const _frameworks = ['PyTorch', 'TensorFlow', 'ONNX', 'Scikit-Learn'];

  final _formKey = GlobalKey<FormState>();
  late final List<String> _categories;

  late String _name;
  late String _category;
  late String _framework;
  late double _accuracy;
  late int _latencyMs;
  late String _version;
  late String _description;
  late String _datasetName;
  late String _githubUrl;

  XFile? _selectedImageFile;

  bool get _isEditing => widget.modelToEdit != null;

  @override
  void initState() {
    super.initState();
    final model = widget.modelToEdit;
    _categories = context
        .read<ModelProvider>()
        .categories
        .where((c) => c != 'All')
        .toList();
    _name = model?.name ?? '';
    _category = _categories.contains(model?.category)
        ? model!.category
        : _categories.first;
    _framework = _frameworks.contains(model?.framework)
        ? model!.framework
        : _frameworks.first;
    _accuracy = model?.accuracy ?? 92.0;
    _latencyMs = model?.latencyMs ?? 15;
    _version = model?.version ?? '1.0.0';
    _description = model?.description ?? '';
    _datasetName = model?.datasetName ?? '';
    _githubUrl = model?.githubUrl ?? '';
  }

  double? _parseAccuracy(String? s) =>
      double.tryParse((s ?? '').trim().replaceAll(',', '.'));

  Future<void> _pickImage(ImageSource source) async {
    final provider = context.read<ModelProvider>();
    final picked = await provider.pickImage(source);
    if (picked != null && mounted) {
      setState(() => _selectedImageFile = picked);
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    _formKey.currentState!.save();

    final messenger = ScaffoldMessenger.of(context);
    final nav = Navigator.of(context);
    final provider = context.read<ModelProvider>();
    final bool success;

    final authUser = context.read<AuthProvider>().currentUser;

    if (!_isEditing) {
      success = await provider.createModel(
        name: _name,
        category: _category,
        framework: _framework,
        accuracy: _accuracy,
        latencyMs: _latencyMs,
        version: _version,
        description: _description,
        datasetName: _datasetName,
        githubUrl: _githubUrl,
        creatorId: authUser?.uid ?? '',
        creatorEmail: authUser?.email ?? '',
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
        githubUrl: _githubUrl,
        newImageFile: _selectedImageFile,
      );
    }

    if (success) {
      messenger.showSnackBar(
        SnackBar(
          content: Text(_isEditing ? 'Changes saved' : 'Model published'),
        ),
      );
      nav.pop();
    } else {
      messenger.showSnackBar(
        const SnackBar(
          content: Text('Couldn’t save the model. Please try again.'),
        ),
      );
    }
  }

  Widget _imagePreview(ColorScheme c, TextTheme t) {
    final Widget content;
    if (_selectedImageFile != null) {
      content = kIsWeb
          ? Image.network(_selectedImageFile!.path, fit: BoxFit.cover)
          : Image.file(File(_selectedImageFile!.path), fit: BoxFit.cover);
    } else if (_isEditing && widget.modelToEdit!.imageUrl.isNotEmpty) {
      content = ModelImage(url: widget.modelToEdit!.imageUrl);
    } else {
      content = Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.add_photo_alternate_outlined,
            size: 28,
            color: c.onSurfaceVariant,
          ),
          const SizedBox(height: Space.sm),
          Text('Optional — a placeholder is used if empty', style: t.bodySmall),
        ],
      );
    }

    return AspectRatio(
      aspectRatio: 16 / 9,
      child: Container(
        width: double.infinity,
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          color: c.surfaceContainerLow,
          borderRadius: BorderRadius.circular(Radii.md),
          border: Border.all(color: c.outlineVariant),
        ),
        child: content,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final p = context.watch<ModelProvider>();
    final c = Theme.of(context).colorScheme;
    final t = Theme.of(context).textTheme;
    final gutter = pageGutter(context, maxWidth: 640);
    const gap = SizedBox(height: Space.lg);

    return Scaffold(
      appBar: AppBar(title: Text(_isEditing ? 'Edit model' : 'New model')),
      body: SingleChildScrollView(
        padding: EdgeInsets.fromLTRB(gutter, Space.sm, gutter, Space.xxxl),
        child: Form(
          key: _formKey,
          autovalidateMode: AutovalidateMode.onUserInteraction,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SectionLabel('Cover image'),
              _imagePreview(c, t),
              const SizedBox(height: Space.md),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _pickImage(ImageSource.gallery),
                      icon: const Icon(Icons.photo_library_outlined, size: 18),
                      label: const Text('Gallery'),
                    ),
                  ),
                  const SizedBox(width: Space.md),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _pickImage(ImageSource.camera),
                      icon: const Icon(Icons.photo_camera_outlined, size: 18),
                      label: const Text('Camera'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: Space.xxl),
              const SectionLabel('Basics'),
              TextFormField(
                initialValue: _name,
                textInputAction: TextInputAction.next,
                textCapitalization: TextCapitalization.sentences,
                decoration: const InputDecoration(
                  labelText: 'Model name',
                  hintText: 'e.g. ResNet-101 classifier',
                ),
                validator: (v) => v == null || v.trim().length < 2
                    ? 'Enter a model name'
                    : null,
                onSaved: (v) => _name = v!.trim(),
              ),
              gap,
              DropdownButtonFormField<String>(
                initialValue: _category,
                isExpanded: true,
                style: t.bodyLarge,
                dropdownColor: c.surfaceContainer,
                borderRadius: BorderRadius.circular(Radii.sm),
                decoration: const InputDecoration(labelText: 'Category'),
                items: [
                  for (final cat in _categories)
                    DropdownMenuItem(
                      value: cat,
                      child: Text(cat, overflow: TextOverflow.ellipsis),
                    ),
                ],
                onChanged: (v) => setState(() => _category = v ?? _category),
              ),
              gap,
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      initialValue: _framework,
                      isExpanded: true,
                      style: t.bodyLarge,
                      dropdownColor: c.surfaceContainer,
                      borderRadius: BorderRadius.circular(Radii.sm),
                      decoration: const InputDecoration(labelText: 'Framework'),
                      items: [
                        for (final fw in _frameworks)
                          DropdownMenuItem(
                            value: fw,
                            child: Text(fw, overflow: TextOverflow.ellipsis),
                          ),
                      ],
                      onChanged: (v) =>
                          setState(() => _framework = v ?? _framework),
                    ),
                  ),
                  const SizedBox(width: Space.md),
                  Expanded(
                    child: TextFormField(
                      initialValue: _version,
                      textInputAction: TextInputAction.next,
                      decoration: const InputDecoration(
                        labelText: 'Version',
                        hintText: '1.0.0',
                      ),
                      validator: (v) =>
                          v == null || v.trim().isEmpty ? 'Required' : null,
                      onSaved: (v) => _version = v!.trim(),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: Space.xxl),
              const SectionLabel('Benchmarks'),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: TextFormField(
                      initialValue: _accuracy.toString(),
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      textInputAction: TextInputAction.next,
                      decoration: const InputDecoration(
                        labelText: 'Accuracy (%)',
                        hintText: '95.5',
                      ),
                      validator: (v) {
                        final n = _parseAccuracy(v);
                        if (n == null) return 'Enter a number';
                        if (n < 0 || n > 100) return 'Between 0 and 100';
                        return null;
                      },
                      onSaved: (v) => _accuracy = _parseAccuracy(v)!,
                    ),
                  ),
                  const SizedBox(width: Space.md),
                  Expanded(
                    child: TextFormField(
                      initialValue: _latencyMs.toString(),
                      keyboardType: TextInputType.number,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                      textInputAction: TextInputAction.next,
                      decoration: const InputDecoration(
                        labelText: 'Latency (ms)',
                        hintText: '12',
                      ),
                      validator: (v) => int.tryParse((v ?? '').trim()) == null
                          ? 'Enter a whole number'
                          : null,
                      onSaved: (v) => _latencyMs = int.parse(v!.trim()),
                    ),
                  ),
                ],
              ),
              gap,
              TextFormField(
                initialValue: _datasetName,
                textInputAction: TextInputAction.next,
                decoration: const InputDecoration(
                  labelText: 'Dataset',
                  hintText: 'e.g. COCO 2017',
                ),
                validator: (v) =>
                    v == null || v.trim().isEmpty ? 'Enter a dataset' : null,
                onSaved: (v) => _datasetName = v!.trim(),
              ),
              gap,
              TextFormField(
                initialValue: _githubUrl,
                keyboardType: TextInputType.url,
                textInputAction: TextInputAction.next,
                decoration: const InputDecoration(
                  labelText: 'GitHub Repository Link (Optional)',
                  hintText: 'https://github.com/username/project',
                  prefixIcon: Icon(Icons.code_rounded),
                ),
                onSaved: (v) => _githubUrl = (v ?? '').trim(),
              ),
              const SizedBox(height: Space.xxl),
              const SectionLabel('About'),
              TextFormField(
                initialValue: _description,
                minLines: 4,
                maxLines: 8,
                keyboardType: TextInputType.multiline,
                textCapitalization: TextCapitalization.sentences,
                decoration: const InputDecoration(
                  labelText: 'Description',
                  hintText: 'Architecture, training setup and intended use',
                  alignLabelWithHint: true,
                ),
                validator: (v) => v == null || v.trim().isEmpty
                    ? 'Enter a description'
                    : null,
                onSaved: (v) => _description = v!.trim(),
              ),
              const SizedBox(height: Space.xxl),
              FilledButton(
                onPressed: p.isLoading ? null : _submit,
                child: p.isLoading
                    ? const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          ButtonSpinner(),
                          SizedBox(width: Space.md),
                          Text('Saving…'),
                        ],
                      )
                    : Text(_isEditing ? 'Save changes' : 'Publish model'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
