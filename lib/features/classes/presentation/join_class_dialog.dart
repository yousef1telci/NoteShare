import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/classes_provider.dart';

class JoinClassDialog extends ConsumerStatefulWidget {
  final String? predefinedClassId;

  const JoinClassDialog({super.key, this.predefinedClassId});

  @override
  ConsumerState<JoinClassDialog> createState() => _JoinClassDialogState();
}

class _JoinClassDialogState extends ConsumerState<JoinClassDialog> {
  final _formKey = GlobalKey<FormState>();
  final _inviteCodeController = TextEditingController();

  @override
  void dispose() {
    _inviteCodeController.dispose();
    super.dispose();
  }

  void _submit() {
    if (widget.predefinedClassId != null) {
      ref.read(classActionControllerProvider.notifier).joinClass(
            classId: widget.predefinedClassId,
          );
      Navigator.of(context).pop();
    } else if (_formKey.currentState!.validate()) {
      ref.read(classActionControllerProvider.notifier).joinClass(
            inviteCode: _inviteCodeController.text.trim(),
          );
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Join a Class'),
      content: widget.predefinedClassId != null
          ? const Text('Are you sure you want to join this class?')
          : Form(
              key: _formKey,
              child: TextFormField(
                controller: _inviteCodeController,
                decoration: const InputDecoration(
                  labelText: 'Invite Code',
                  border: OutlineInputBorder(),
                  hintText: 'Enter the private invite code',
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter an invite code';
                  }
                  return null;
                },
              ),
            ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _submit,
          child: const Text('Join'),
        ),
      ],
    );
  }
}
