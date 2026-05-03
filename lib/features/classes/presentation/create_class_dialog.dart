import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/classes_provider.dart';
import '../domain/class_model.dart';

class CreateClassDialog extends ConsumerStatefulWidget {
  final ClassModel? classToEdit;
  const CreateClassDialog({super.key, this.classToEdit});

  @override
  ConsumerState<CreateClassDialog> createState() => _CreateClassDialogState();
}

class _CreateClassDialogState extends ConsumerState<CreateClassDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  bool _isPrivate = false;
  String _selectedCategory = 'General';

  final List<String> _categories = ["General", "Engineering", "Medicine", "Erasmus"];

  @override
  void initState() {
    super.initState();
    if (widget.classToEdit != null) {
      _nameController.text = widget.classToEdit!.name;
      _descriptionController.text = widget.classToEdit!.description ?? '';
      _isPrivate = widget.classToEdit!.isPrivate;
      if (widget.classToEdit!.category != null && _categories.contains(widget.classToEdit!.category)) {
        _selectedCategory = widget.classToEdit!.category!;
      }
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  void _submit() {
    if (_formKey.currentState!.validate()) {
      if (widget.classToEdit != null) {
        ref.read(classActionControllerProvider.notifier).updateClass(
              classId: widget.classToEdit!.id,
              name: _nameController.text.trim(),
              description: _descriptionController.text.trim(),
              isPrivate: _isPrivate,
              category: _selectedCategory,
            );
      } else {
        ref.read(classActionControllerProvider.notifier).createClass(
              name: _nameController.text.trim(),
              description: _descriptionController.text.trim(),
              isPrivate: _isPrivate,
              category: _selectedCategory,
            );
      }
      Navigator.of(context).pop(true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.classToEdit != null;
    return AlertDialog(
      title: Text(isEditing ? 'Edit Class' : 'Create New Class'),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Class Name',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a name';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: _selectedCategory,
                decoration: const InputDecoration(
                  labelText: 'Category',
                  border: OutlineInputBorder(),
                ),
                items: _categories.map((category) {
                  return DropdownMenuItem(
                    value: category,
                    child: Text(category),
                  );
                }).toList(),
                onChanged: (value) {
                  if (value != null) {
                    setState(() {
                      _selectedCategory = value;
                    });
                  }
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _descriptionController,
                decoration: const InputDecoration(
                  labelText: 'Description (Optional)',
                  border: OutlineInputBorder(),
                ),
                maxLines: 3,
              ),
              const SizedBox(height: 16),
              SwitchListTile(
                title: const Text('Private Class'),
                subtitle: const Text('Requires invite code to join'),
                value: _isPrivate,
                onChanged: (value) {
                  setState(() {
                    _isPrivate = value;
                  });
                },
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _submit,
          child: Text(isEditing ? 'Save' : 'Create'),
        ),
      ],
    );
  }
}
