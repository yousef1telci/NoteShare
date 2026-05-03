import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/classes_provider.dart';
import '../domain/class_model.dart';
import '../../auth/providers/auth_provider.dart';

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
  String? _selectedFaculty;
  String? _selectedMajor;
  String? _selectedYear;

  final List<String> _categories = ["General", "Engineering", "Medicine", "Erasmus"];
  static const List<String> _engineeringMajors = [
    "Software Engineering", "Computer Engineering", "Information Systems Engineering", 
    "Electrical and Electronics Engineering", "Mechanical Engineering", "Civil Engineering", "Industrial Engineering"
  ];

  static const List<String> _medicineSpecialties = [
    "General Medicine", "Internal Medicine", "General Surgery", "Pediatrics", 
    "Obstetrics and Gynecology", "Cardiology", "Neurology", "Orthopedics", 
    "Ophthalmology", "Radiology", "Anesthesiology", "Dermatology", "ENT (Ear, Nose, and Throat)"
  ];

  static const List<String> _technologyMajors = [
    "Software Engineering", "Computer Engineering", "Information Systems Engineering", 
    "Electrical Engineering", "Mechanical Engineering", "Manufacturing Engineering", "Energy Systems Engineering"
  ];

  static const List<String> _scienceMajors = [
    "Mathematics", "Physics", "Chemistry", "Biology"
  ];

  static const List<String> _educationMajors = [
    "Computer Education and Instructional Technology", "Primary Education", 
    "Mathematics Education", "Science Education", "English Language Teaching", "Preschool Education"
  ];

  static const List<String> _economicsMajors = [
    "Business Administration", "Economics", "Finance", "Public Administration"
  ];

  final Map<String, List<String>> _facultyMajorsMap = {
    "Engineering": _engineeringMajors,
    "Medicine": _medicineSpecialties,
    "Technology": _technologyMajors,
    "Science": _scienceMajors,
    "Education": _educationMajors,
    "Economics": _economicsMajors,
  };

  List<String> get _faculties => _facultyMajorsMap.keys.toList();
  List<String> get _currentMajors => _selectedFaculty != null ? (_facultyMajorsMap[_selectedFaculty] ?? []) : [];
  final List<String> _years = ['1', '2', '3', '4'];

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
      if (widget.classToEdit!.faculty != null && _faculties.contains(widget.classToEdit!.faculty)) {
        _selectedFaculty = widget.classToEdit!.faculty;
      }
      if (widget.classToEdit!.major != null && _currentMajors.contains(widget.classToEdit!.major)) {
        _selectedMajor = widget.classToEdit!.major;
      }
      if (widget.classToEdit!.academicYear != null && _years.contains(widget.classToEdit!.academicYear)) {
        _selectedYear = widget.classToEdit!.academicYear;
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
      final userProfileAsync = ref.read(userProfileProvider);
      final isAdmin = userProfileAsync.value?['is_admin'] == true;
      final finalIsPrivate = isAdmin ? _isPrivate : true;

      if (widget.classToEdit != null) {
        ref.read(classActionControllerProvider.notifier).updateClass(
              classId: widget.classToEdit!.id,
              name: _nameController.text.trim(),
              description: _descriptionController.text.trim(),
              isPrivate: finalIsPrivate,
              category: _selectedCategory,
              faculty: _selectedFaculty,
              major: _selectedMajor,
              academicYear: _selectedYear,
            );
      } else {
        ref.read(classActionControllerProvider.notifier).createClass(
              name: _nameController.text.trim(),
              description: _descriptionController.text.trim(),
              isPrivate: finalIsPrivate,
              category: _selectedCategory,
              faculty: _selectedFaculty,
              major: _selectedMajor,
              academicYear: _selectedYear,
            );
      }
      Navigator.of(context).pop(true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.classToEdit != null;
    final userProfileAsync = ref.watch(userProfileProvider);
    final isAdmin = userProfileAsync.value?['is_admin'] == true;
    final displayIsPrivate = isAdmin ? _isPrivate : true;

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
              DropdownButtonFormField<String?>(
                value: _selectedFaculty,
                decoration: const InputDecoration(
                  labelText: 'Faculty (Optional)',
                  border: OutlineInputBorder(),
                ),
                items: [
                  const DropdownMenuItem<String?>(
                    value: null,
                    child: Text('None'),
                  ),
                  ..._faculties.map((faculty) {
                    return DropdownMenuItem<String?>(
                      value: faculty,
                      child: Text(faculty),
                    );
                  }),
                ],
                onChanged: (value) {
                  setState(() {
                    _selectedFaculty = value;
                    _selectedMajor = null;
                  });
                },
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String?>(
                value: _selectedMajor,
                decoration: const InputDecoration(
                  labelText: 'Major (Optional)',
                  border: OutlineInputBorder(),
                ),
                items: [
                  const DropdownMenuItem<String?>(
                    value: null,
                    child: Text('None'),
                  ),
                  ..._currentMajors.map((major) {
                    return DropdownMenuItem<String?>(
                      value: major,
                      child: Text(major),
                    );
                  }),
                ],
                onChanged: _selectedFaculty == null
                    ? null
                    : (value) {
                        setState(() {
                          _selectedMajor = value;
                        });
                      },
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String?>(
                value: _selectedYear,
                decoration: const InputDecoration(
                  labelText: 'Academic Year (Optional)',
                  border: OutlineInputBorder(),
                ),
                items: [
                  const DropdownMenuItem<String?>(
                    value: null,
                    child: Text('None'),
                  ),
                  ..._years.map((year) {
                    return DropdownMenuItem<String?>(
                      value: year,
                      child: Text(year),
                    );
                  }),
                ],
                onChanged: (value) {
                  setState(() {
                    _selectedYear = value;
                  });
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
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SwitchListTile(
                    title: const Text('Private Class'),
                    subtitle: const Text('Requires invite code to join'),
                    value: displayIsPrivate,
                    onChanged: isAdmin
                        ? (value) {
                            setState(() {
                              _isPrivate = value;
                            });
                          }
                        : null,
                  ),
                  if (!isAdmin)
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0),
                      child: Text(
                        'Only admins can create public classes.',
                        style: TextStyle(color: Colors.grey[600], fontSize: 12),
                      ),
                    ),
                ],
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
