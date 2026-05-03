import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../providers/classes_provider.dart';
import 'create_class_dialog.dart';
import 'join_class_dialog.dart';

class MyClassesScreen extends ConsumerWidget {
  const MyClassesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final myClassesAsync = ref.watch(myClassesProvider);
    final actionState = ref.watch(classActionControllerProvider);

    ref.listen<AsyncValue<void>>(
      classActionControllerProvider,
      (previous, next) {
        next.whenOrNull(
          error: (error, stackTrace) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(error.toString()),
                backgroundColor: Colors.red,
              ),
            );
          },
          data: (_) {
            if (previous?.isLoading == true) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Success!'),
                  backgroundColor: Colors.green,
                ),
              );
            }
          },
        );
      },
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Classes'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            tooltip: 'Create or Join Class',
            onPressed: () {
              showModalBottomSheet(
                context: context,
                builder: (context) => SafeArea(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      ListTile(
                        leading: const Icon(Icons.add_circle_outline),
                        title: const Text('Create a Class'),
                        onTap: () {
                          Navigator.pop(context);
                          showDialog(
                            context: context,
                            builder: (context) => const CreateClassDialog(),
                          );
                        },
                      ),
                      ListTile(
                        leading: const Icon(Icons.group_add_outlined),
                        title: const Text('Join with Invite Code'),
                        onTap: () {
                          Navigator.pop(context);
                          showDialog(
                            context: context,
                            builder: (context) => const JoinClassDialog(),
                          );
                        },
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ],
      ),
      body: myClassesAsync.when(
        data: (classes) {
          if (classes.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.class_outlined, size: 80, color: Colors.grey[400]),
                  const SizedBox(height: 16),
                  Text(
                    'You haven\'t joined any classes yet.',
                    style: TextStyle(color: Colors.grey[600], fontSize: 16),
                  ),
                ],
              ),
            );
          }
          return RefreshIndicator(
            onRefresh: () async => ref.refresh(myClassesProvider.future),
            child: Stack(
              children: [
                ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: classes.length,
                  itemBuilder: (context, index) {
                    final cls = classes[index];
                    return Card(
                      margin: const EdgeInsets.only(bottom: 16),
                      child: ListTile(
                        contentPadding: const EdgeInsets.all(16),
                        title: Text(
                          cls.name,
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        subtitle: cls.description != null
                            ? Text(cls.description!)
                            : null,
                        trailing: cls.isPrivate
                            ? const Icon(Icons.lock_outline, size: 20)
                            : null,
                        onTap: () {
                          context.push(
                            Uri(
                              path: '/class-detail',
                              queryParameters: {
                                'id': cls.id,
                                'name': cls.name,
                              },
                            ).toString(),
                            extra: cls,
                          );
                        },
                      ),
                    );
                  },
                ),
                if (actionState.isLoading)
                  const Center(child: CircularProgressIndicator()),
              ],
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(
          child: Text('Error loading classes: $error'),
        ),
      ),
    );
  }
}
