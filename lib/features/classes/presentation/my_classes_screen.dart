import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../domain/class_model.dart';
import '../providers/classes_provider.dart';
import '../../auth/providers/auth_provider.dart';
import 'create_class_dialog.dart';
import 'join_class_dialog.dart';

class MyClassesScreen extends ConsumerWidget {
  const MyClassesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final myClassesAsync = ref.watch(myClassesProvider);
    final actionState = ref.watch(classActionControllerProvider);
    final currentUserId = ref.watch(supabaseProvider).auth.currentUser?.id;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    ref.listen<AsyncValue<void>>(
      classActionControllerProvider,
      (previous, next) {
        next.whenOrNull(
          error: (error, stackTrace) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(error.toString()),
                backgroundColor: Colors.redAccent,
                behavior: SnackBarBehavior.floating,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            );
          },
          data: (_) {
            if (previous?.isLoading == true) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: const Text('Success!', style: TextStyle(fontWeight: FontWeight.bold)),
                  backgroundColor: Colors.green.shade600,
                  behavior: SnackBarBehavior.floating,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              );
            }
          },
        );
      },
    );

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF121212) : const Color(0xFFF9FAFB),
      appBar: AppBar(
        title: Text(
          'My Classes',
          style: TextStyle(
            fontWeight: FontWeight.w800,
            letterSpacing: -0.5,
            color: isDark ? Colors.white : const Color(0xFF0F172A),
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: false,
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 16),
            decoration: BoxDecoration(
              color: Colors.blueAccent.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: IconButton(
              icon: const Icon(Icons.add_rounded, color: Colors.blueAccent),
              tooltip: 'Create or Join Class',
              onPressed: () {
                showModalBottomSheet(
                  context: context,
                  backgroundColor: isDark ? const Color(0xFF1E293B) : Colors.white,
                  shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
                  builder: (context) => SafeArea(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 40,
                            height: 4,
                            margin: const EdgeInsets.only(bottom: 24),
                            decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(2)),
                          ),
                          ListTile(
                            leading: Container(padding: const EdgeInsets.all(10), decoration: BoxDecoration(color: Colors.indigo.withOpacity(0.1), borderRadius: BorderRadius.circular(12)), child: const Icon(Icons.add_circle_outline_rounded, color: Colors.indigo)),
                            title: const Text('Create a Class', style: TextStyle(fontWeight: FontWeight.w600)),
                            onTap: () {
                              Navigator.pop(context);
                              showDialog(context: context, builder: (context) => const CreateClassDialog());
                            },
                          ),
                          ListTile(
                            leading: Container(padding: const EdgeInsets.all(10), decoration: BoxDecoration(color: Colors.teal.withOpacity(0.1), borderRadius: BorderRadius.circular(12)), child: const Icon(Icons.group_add_outlined, color: Colors.teal)),
                            title: const Text('Join with Invite Code', style: TextStyle(fontWeight: FontWeight.w600)),
                            onTap: () {
                              Navigator.pop(context);
                              showDialog(context: context, builder: (context) => const JoinClassDialog());
                            },
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
      body: myClassesAsync.when(
        loading: () => const Center(child: CircularProgressIndicator(color: Colors.blueAccent)),
        error: (error, stack) => Center(
          child: Text('Error loading classes: $error', style: TextStyle(color: isDark ? Colors.grey[400] : Colors.grey[600])),
        ),
        data: (classes) {

          if (classes.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(32.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: isDark ? Colors.blueAccent.withOpacity(0.1) : Colors.blue.withOpacity(0.05),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(Icons.menu_book_rounded, size: 80, color: isDark ? Colors.blue[300] : Colors.blueAccent),
                    ),
                    const SizedBox(height: 24),
                    Text(
                      'No classes yet',
                      style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: isDark ? Colors.white : const Color(0xFF0F172A)),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'You haven\'t joined any classes yet. Head to the Discover tab or enter an invite code to get started!',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: isDark ? Colors.grey[400] : Colors.grey[600], fontSize: 15, height: 1.5),
                    ),
                  ],
                ),
              ),
            );
          }
          return Stack(
            children: [
              ListView.builder(
                padding: const EdgeInsets.all(16),
                physics: const AlwaysScrollableScrollPhysics(),
                itemCount: classes.length,
                itemBuilder: (context, index) {
                  final cls = classes[index];
                  final isCreator = cls.createdBy == currentUserId;

                  return Container(
                    margin: const EdgeInsets.only(bottom: 16),
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF1E293B) : Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: isDark ? [] : [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.04),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        borderRadius: BorderRadius.circular(20),
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
                        child: Padding(
                          padding: const EdgeInsets.all(20),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      cls.name,
                                      style: TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.w800,
                                        letterSpacing: -0.5,
                                        color: isDark ? Colors.white : const Color(0xFF111827),
                                      ),
                                    ),
                                  ),
                                  if (isCreator) ...[
                                    const SizedBox(width: 8),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: Colors.amber.withOpacity(0.15),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: const Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Icon(Icons.star_rounded, color: Colors.amber, size: 14),
                                          SizedBox(width: 4),
                                          Text('Creator', style: TextStyle(color: Colors.amber, fontSize: 11, fontWeight: FontWeight.bold)),
                                        ],
                                      ),
                                    ),
                                  ],
                                  if (cls.isPrivate && !isCreator) ...[
                                    const SizedBox(width: 8),
                                    Icon(Icons.lock_rounded, size: 18, color: isDark ? Colors.grey[500] : Colors.grey[400]),
                                  ],
                                ],
                              ),
                              if (cls.faculty != null || cls.major != null || cls.academicYear != null) ...[
                                const SizedBox(height: 12),
                                Wrap(
                                  spacing: 8,
                                  runSpacing: 8,
                                  children: [
                                    if (cls.faculty != null && cls.faculty!.isNotEmpty)
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                        decoration: BoxDecoration(color: isDark ? Colors.indigo.withOpacity(0.2) : Colors.indigo.withOpacity(0.08), borderRadius: BorderRadius.circular(8)),
                                        child: Text(cls.faculty!, style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: isDark ? Colors.indigo.shade300 : Colors.indigo.shade600)),
                                      ),
                                    if (cls.major != null && cls.major!.isNotEmpty)
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                        decoration: BoxDecoration(color: isDark ? Colors.teal.withOpacity(0.2) : Colors.teal.withOpacity(0.08), borderRadius: BorderRadius.circular(8)),
                                        child: Text(cls.major!, style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: isDark ? Colors.teal.shade300 : Colors.teal.shade700)),
                                      ),
                                    if (cls.academicYear != null && cls.academicYear!.isNotEmpty)
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                        decoration: BoxDecoration(color: isDark ? Colors.orange.withOpacity(0.2) : Colors.orange.withOpacity(0.08), borderRadius: BorderRadius.circular(8)),
                                        child: Text('Year ${cls.academicYear}', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: isDark ? Colors.orange.shade300 : Colors.orange.shade800)),
                                      ),
                                  ],
                                ),
                              ],
                              if (cls.description != null && cls.description!.isNotEmpty) ...[
                                const SizedBox(height: 12),
                                Text(
                                  cls.description!,
                                  style: TextStyle(color: isDark ? Colors.grey[400] : Colors.grey[600], fontSize: 14, height: 1.4),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ],
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
              if (actionState.isLoading)
                const Center(child: CircularProgressIndicator(color: Colors.blueAccent)),
            ],
          );
        },
      ),
    );
  }
}
