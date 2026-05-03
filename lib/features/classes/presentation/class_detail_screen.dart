import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:file_picker/file_picker.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../materials/providers/materials_provider.dart';
import '../../materials/domain/material_model.dart';
import '../../auth/providers/auth_provider.dart';
import '../../classes/domain/class_model.dart';
import '../../classes/providers/classes_provider.dart';
import '../../notes/providers/notes_provider.dart';
import 'package:flutter/services.dart';

import 'create_class_dialog.dart';

class ClassDetailScreen extends ConsumerStatefulWidget {
  final String classId;
  final String className;
  final ClassModel? classModel;

  const ClassDetailScreen({
    super.key,
    required this.classId,
    required this.className,
    this.classModel,
  });

  @override
  ConsumerState<ClassDetailScreen> createState() => _ClassDetailScreenState();
}

class _ClassDetailScreenState extends ConsumerState<ClassDetailScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _noteController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(() {
      setState(() {});
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  Future<void> _pickAndUploadFile() async {
    try {
      final result = await FilePicker.pickFiles(withData: true);
      if (result != null && result.files.isNotEmpty) {
        final file = result.files.first;
        ref.read(materialActionControllerProvider.notifier).uploadMaterial(widget.classId, file);
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error picking file: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _openMaterial(String filePath) async {
    try {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Opening file...'), duration: Duration(seconds: 1)),
      );
      
      final url = await ref.read(materialActionControllerProvider.notifier).getUrl(filePath);
      final uri = Uri.parse(url);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        throw 'Could not launch url';
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error opening file: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _confirmDelete(MaterialModel material) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Material'),
        content: const Text('Are you sure you want to delete this material? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirm == true && context.mounted) {
      ref.read(materialActionControllerProvider.notifier)
          .deleteMaterial(widget.classId, material.id, material.fileUrl);
    }
  }

  void _postNote() {
    final text = _noteController.text.trim();
    if (text.isNotEmpty) {
      ref.read(noteActionControllerProvider.notifier).addNote(widget.classId, text);
      _noteController.clear();
      FocusScope.of(context).unfocus();
    }
  }

  @override
  Widget build(BuildContext context) {
    final materialsAsync = ref.watch(classMaterialsProvider(widget.classId));
    final actionState = ref.watch(materialActionControllerProvider);
    final classActionState = ref.watch(classActionControllerProvider);
    final bookmarkedMaterialsAsync = ref.watch(bookmarkedMaterialsProvider);
    
    final notesAsync = ref.watch(classNotesProvider(widget.classId));
    final noteActionState = ref.watch(noteActionControllerProvider);
    
    final currentUserId = ref.watch(supabaseProvider).auth.currentUser?.id;

    ref.listen<AsyncValue<void>>(
      materialActionControllerProvider,
      (previous, next) {
        next.whenOrNull(
          error: (error, stackTrace) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Upload failed: $error'),
                backgroundColor: Colors.red,
              ),
            );
          },
          data: (_) {
            if (previous?.isLoading == true) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Action completed successfully!'),
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
        title: Text(widget.className),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Files', icon: Icon(Icons.folder)),
            Tab(text: 'Discussions', icon: Icon(Icons.forum)),
          ],
        ),
        actions: [
          if (widget.classModel != null && widget.classModel!.createdBy == currentUserId)
            PopupMenuButton<String>(
              onSelected: (value) async {
                if (value == 'edit') {
                  await showDialog<bool>(
                    context: context,
                    builder: (context) => CreateClassDialog(classToEdit: widget.classModel),
                  );
                } else if (value == 'delete') {
                  final confirm = await showDialog<bool>(
                    context: context,
                    builder: (context) => AlertDialog(
                      title: const Text('Delete Class'),
                      content: const Text('Warning: This will delete the class and all its materials. Are you sure?'),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.of(context).pop(false),
                          child: const Text('Cancel'),
                        ),
                        TextButton(
                          onPressed: () => Navigator.of(context).pop(true),
                          child: const Text('Delete', style: TextStyle(color: Colors.red)),
                        ),
                      ],
                    ),
                  );
                  if (confirm == true && context.mounted) {
                    await ref.read(classActionControllerProvider.notifier).deleteClass(widget.classId);
                    if (context.mounted) {
                      Navigator.of(context).pop();
                    }
                  }
                }
              },
              itemBuilder: (context) => [
                const PopupMenuItem(
                  value: 'edit',
                  child: Text('Edit Class'),
                ),
                const PopupMenuItem(
                  value: 'delete',
                  child: Text('Delete Class', style: TextStyle(color: Colors.red)),
                ),
              ],
            )
          else if (widget.classModel != null && widget.classModel!.createdBy != currentUserId)
            PopupMenuButton<String>(
              onSelected: (value) async {
                if (value == 'leave') {
                  final confirm = await showDialog<bool>(
                    context: context,
                    builder: (context) => AlertDialog(
                      title: const Text('Leave Class'),
                      content: const Text('Are you sure you want to leave this class?'),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.of(context).pop(false),
                          child: const Text('Cancel'),
                        ),
                        TextButton(
                          onPressed: () => Navigator.of(context).pop(true),
                          child: const Text('Leave', style: TextStyle(color: Colors.red)),
                        ),
                      ],
                    ),
                  );
                  if (confirm == true && context.mounted) {
                    await ref.read(classActionControllerProvider.notifier).leaveClass(widget.classId);
                    if (context.mounted) {
                      Navigator.of(context).pop();
                    }
                  }
                }
              },
              itemBuilder: (context) => [
                const PopupMenuItem(
                  value: 'leave',
                  child: Text('Leave Class', style: TextStyle(color: Colors.red)),
                ),
              ],
            ),
        ],
      ),
      body: Column(
        children: [
          if (widget.classModel != null && widget.classModel!.isPrivate && widget.classModel!.createdBy == currentUserId && widget.classModel!.inviteCode != null)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              color: Colors.blue.withOpacity(0.1),
              child: Row(
                children: [
                  const Icon(Icons.key, color: Colors.blue),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Invite Code: ${widget.classModel!.inviteCode}',
                      style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.blue),
                    ),
                  ),
                  TextButton.icon(
                    icon: const Icon(Icons.copy, size: 18),
                    label: const Text('Copy'),
                    onPressed: () {
                      Clipboard.setData(ClipboardData(text: widget.classModel!.inviteCode!));
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Invite code copied to clipboard')),
                      );
                    },
                  ),
                ],
              ),
            ),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                // FILES TAB
                materialsAsync.when(
                  data: (materials) {
                    if (materials.isEmpty) {
                      return const Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.folder_open, size: 80, color: Colors.grey),
                            SizedBox(height: 16),
                            Text(
                              'No materials uploaded yet.',
                              style: TextStyle(color: Colors.grey, fontSize: 16),
                            ),
                          ],
                        ),
                      );
                    }
                    return RefreshIndicator(
                      onRefresh: () async => ref.refresh(classMaterialsProvider(widget.classId).future),
                      child: ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: materials.length,
                        itemBuilder: (context, index) {
                          final material = materials[index];
                          final isBookmarked = bookmarkedMaterialsAsync.value?.contains(material.id) ?? false;
                          
                          return Card(
                            margin: const EdgeInsets.only(bottom: 12),
                            child: ListTile(
                              leading: const Icon(Icons.insert_drive_file, color: Colors.blueAccent),
                              title: Text(
                                material.title,
                                style: const TextStyle(fontWeight: FontWeight.bold),
                              ),
                              subtitle: Text(
                                '${material.authorName ?? "Unknown User"} • ${material.createdAt.toLocal().toString().split('.')[0]}',
                              ),
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  if (currentUserId == material.uploadedBy)
                                    IconButton(
                                      icon: const Icon(Icons.delete_outline, color: Colors.red),
                                      onPressed: () => _confirmDelete(material),
                                    ),
                                  IconButton(
                                    icon: Icon(
                                      isBookmarked ? Icons.bookmark : Icons.bookmark_border,
                                      color: isBookmarked ? Colors.amber : null,
                                    ),
                                    onPressed: () {
                                      ref.read(bookmarkedMaterialsProvider.notifier).toggleBookmark(material.id);
                                    },
                                  ),
                                ],
                              ),
                              onTap: () => _openMaterial(material.fileUrl),
                            ),
                          );
                        },
                      ),
                    );
                  },
                  loading: () => const Center(child: CircularProgressIndicator()),
                  error: (error, stack) => Center(
                    child: Text('Error: $error'),
                  ),
                ),
                
                // DISCUSSIONS TAB
                Column(
                  children: [
                    Expanded(
                      child: notesAsync.when(
                        data: (notes) {
                          if (notes.isEmpty) {
                            return const Center(
                              child: Text(
                                'No discussions yet. Start one!',
                                style: TextStyle(color: Colors.grey, fontSize: 16),
                              ),
                            );
                          }
                          return ListView.builder(
                            reverse: true, // Show latest notes at bottom or top depending on preference. Usually reverse makes latest at bottom like a chat. Let's not reverse for standard feed.
                            padding: const EdgeInsets.all(16),
                            itemCount: notes.length,
                            itemBuilder: (context, index) {
                              final note = notes[index];
                              final isMe = note.userId == currentUserId;
                              
                              return Card(
                                margin: const EdgeInsets.only(bottom: 12),
                                elevation: 1,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                child: Padding(
                                  padding: const EdgeInsets.all(16),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          CircleAvatar(
                                            radius: 14,
                                            backgroundColor: isMe ? Colors.blueAccent : Colors.grey[400],
                                            child: const Icon(Icons.person, size: 16, color: Colors.white),
                                          ),
                                          const SizedBox(width: 8),
                                          Text(
                                            isMe ? 'You' : (note.authorName ?? 'Unknown User'),
                                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                                          ),
                                          const Spacer(),
                                          Text(
                                            note.createdAt.toLocal().toString().split('.')[0],
                                            style: TextStyle(color: Colors.grey[600], fontSize: 10),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 8),
                                      Text(note.content, style: const TextStyle(fontSize: 15)),
                                    ],
                                  ),
                                ),
                              );
                            },
                          );
                        },
                        loading: () => const Center(child: CircularProgressIndicator()),
                        error: (error, stack) => Center(child: Text('Error: $error')),
                      ),
                    ),
                    // Add Note Input
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Theme.of(context).cardColor,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.05),
                            blurRadius: 10,
                            offset: const Offset(0, -5),
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: _noteController,
                              decoration: InputDecoration(
                                hintText: 'Share a note or announcement...',
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(24),
                                  borderSide: BorderSide.none,
                                ),
                                filled: true,
                                fillColor: Colors.grey[200],
                                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                              ),
                              maxLines: null,
                            ),
                          ),
                          const SizedBox(width: 8),
                          if (noteActionState.isLoading)
                            const Padding(
                              padding: EdgeInsets.all(12.0),
                              child: SizedBox(
                                width: 24,
                                height: 24,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              ),
                            )
                          else
                            IconButton(
                              icon: const Icon(Icons.send, color: Colors.blueAccent),
                              onPressed: _postNote,
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: _tabController.index == 0
          ? FloatingActionButton.extended(
              onPressed: actionState.isLoading ? null : _pickAndUploadFile,
              icon: actionState.isLoading
                  ? const SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                    )
                  : const Icon(Icons.upload_file),
              label: actionState.isLoading ? const Text('Uploading...') : const Text('Upload Material'),
            )
          : null,
    );
  }
}
