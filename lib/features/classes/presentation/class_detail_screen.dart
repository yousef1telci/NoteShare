import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:file_picker/file_picker.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter/services.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import '../../materials/providers/materials_provider.dart';
import '../../materials/domain/material_model.dart';
import '../../auth/providers/auth_provider.dart';
import '../../classes/domain/class_model.dart';
import '../../classes/providers/classes_provider.dart';
import '../../notes/providers/notes_provider.dart';
import '../../notes/domain/note_model.dart';
import 'create_class_dialog.dart';

final userNameProvider = FutureProvider.family<String, String>((ref, userId) async {
  try {
    final res = await Supabase.instance.client.from('profiles').select('full_name').eq('id', userId).maybeSingle();
    return res?['full_name'] as String? ?? 'Unknown User';
  } catch (e) {
    return 'Unknown User';
  }
});

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
  Future<Map<String, dynamic>>? _infoFuture;
  bool _isAITyping = false;
  
  late final Stream<List<Map<String, dynamic>>> _materialsStream;
  late final Stream<List<Map<String, dynamic>>> _classNotesStream;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _tabController.addListener(() {
      setState(() {});
    });
    _fetchInfo();
    
    _materialsStream = Supabase.instance.client
        .from('materials')
        .stream(primaryKey: ['id'])
        .eq('class_id', widget.classId)
        .order('created_at', ascending: false);
        
    _classNotesStream = Supabase.instance.client
        .from('class_notes')
        .stream(primaryKey: ['id'])
        .eq('class_id', widget.classId)
        .order('created_at', ascending: true);
  }

  void _fetchInfo() {
    if (widget.classModel == null) return;
    final client = Supabase.instance.client;
    _infoFuture = Future.wait<dynamic>([
      client.from('profiles').select('full_name').eq('id', widget.classModel!.createdBy).maybeSingle(),
      client.from('class_members').select('id').eq('class_id', widget.classId),
    ]).then((results) {
      final profile = results[0] as Map<String, dynamic>?;
      final members = results[1] as List<dynamic>?;
      return {
        'creatorName': profile?['full_name'] ?? 'Class Administrator',
        'memberCount': members?.length ?? 1,
      };
    }).catchError((_) => {
      'creatorName': 'Class Administrator',
      'memberCount': 1,
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  Future<String> _fetchAIResponse(String prompt) async {
    try {
      final apiKey = dotenv.env['GEMINI_API_KEY'] ?? ''; 
     // final model = GenerativeModel(model: 'gemini-1.5-flash', apiKey: apiKey);
      final model = GenerativeModel(model: 'gemini-2.5-flash', apiKey: apiKey);
      final content = [Content.text(prompt)];
      final response = await model.generateContent(content);
      return response.text ?? "عفواً، لم أتمكن من صياغة إجابة.";
    } catch (e) {
      debugPrint("AI Error: $e");
      return "Error Details: $e";
    }
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
            backgroundColor: Colors.redAccent,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
      }
    }
  }

  Future<void> _openMaterial(String filePath) async {
    try {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Opening file...'), 
          duration: const Duration(seconds: 1),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
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
            backgroundColor: Colors.redAccent,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
      }
    }
  }

  Future<void> _confirmDelete(MaterialModel material) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Delete Material', style: TextStyle(fontWeight: FontWeight.bold)),
        content: const Text('Are you sure you want to delete this material? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.redAccent,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirm == true && context.mounted) {
      ref.read(materialActionControllerProvider.notifier)
          .deleteMaterial(widget.classId, material.id, material.fileUrl);
    }
  }

  void _postNote() async {
    final text = _noteController.text.trim();
    if (text.isNotEmpty) {
      final isAiRequest = text.startsWith('@AI ');
      
      ref.read(noteActionControllerProvider.notifier).addNote(widget.classId, text);
      _noteController.clear();
      FocusScope.of(context).unfocus();

      if (isAiRequest) {
        setState(() => _isAITyping = true);
        final prompt = text.substring(4).trim();
        final aiResponse = await _fetchAIResponse(prompt);
        final finalMessage = '🤖 [AI Tutor]: $aiResponse';
        
        if (mounted) {
           ref.read(noteActionControllerProvider.notifier).addNote(widget.classId, finalMessage);
           setState(() => _isAITyping = false);
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final materialsAsync = ref.watch(classMaterialsProvider(widget.classId));
    final actionState = ref.watch(materialActionControllerProvider);
    final bookmarkedMaterialsAsync = ref.watch(bookmarkedMaterialsProvider);
    final notesAsync = ref.watch(classNotesProvider(widget.classId));
    final noteActionState = ref.watch(noteActionControllerProvider);
    final currentUserId = ref.watch(supabaseProvider).auth.currentUser?.id;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    ref.listen<AsyncValue<void>>(
      materialActionControllerProvider,
      (previous, next) {
        next.whenOrNull(
          error: (error, stackTrace) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Upload failed: $error'),
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
                  content: const Text('Action completed successfully!', style: TextStyle(fontWeight: FontWeight.bold)),
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
          widget.className,
          style: TextStyle(
            fontWeight: FontWeight.w800,
            letterSpacing: -0.5,
            color: isDark ? Colors.white : const Color(0xFF111827),
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: false,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.blueAccent,
          indicatorWeight: 3,
          labelColor: Colors.blueAccent,
          unselectedLabelColor: isDark ? Colors.grey[500] : Colors.grey[400],
          labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
          unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
          tabs: const [
            Tab(text: 'Files', icon: Icon(Icons.folder_open_rounded)),
            Tab(text: 'Chat', icon: Icon(Icons.forum_rounded)),
            Tab(text: 'Info', icon: Icon(Icons.info_outline_rounded)),
          ],
        ),
        actions: [
          if (widget.classModel != null && widget.classModel!.createdBy == currentUserId)
            PopupMenuButton<String>(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
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
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                      title: const Text('Delete Class', style: TextStyle(fontWeight: FontWeight.bold)),
                      content: const Text('Warning: This will delete the class and all its materials. Are you sure?'),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.of(context).pop(false),
                          child: const Text('Cancel'),
                        ),
                        ElevatedButton(
                          onPressed: () => Navigator.of(context).pop(true),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.redAccent,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          child: const Text('Delete'),
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
                  child: Row(children: [Icon(Icons.edit_rounded, size: 20), SizedBox(width: 8), Text('Edit Class')]),
                ),
                const PopupMenuItem(
                  value: 'delete',
                  child: Row(children: [Icon(Icons.delete_rounded, size: 20, color: Colors.redAccent), SizedBox(width: 8), Text('Delete Class', style: TextStyle(color: Colors.redAccent))]),
                ),
              ],
            )
          else if (widget.classModel != null && widget.classModel!.createdBy != currentUserId)
            PopupMenuButton<String>(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              onSelected: (value) async {
                if (value == 'leave') {
                  final confirm = await showDialog<bool>(
                    context: context,
                    builder: (context) => AlertDialog(
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                      title: const Text('Leave Class', style: TextStyle(fontWeight: FontWeight.bold)),
                      content: const Text('Are you sure you want to leave this class?'),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.of(context).pop(false),
                          child: const Text('Cancel'),
                        ),
                        ElevatedButton(
                          onPressed: () => Navigator.of(context).pop(true),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.redAccent,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          child: const Text('Leave'),
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
                  child: Row(children: [Icon(Icons.exit_to_app_rounded, size: 20, color: Colors.redAccent), SizedBox(width: 8), Text('Leave Class', style: TextStyle(color: Colors.redAccent))]),
                ),
              ],
            ),
        ],
      ),
      body: Column(
        children: [
          if (widget.classModel != null && widget.classModel!.isPrivate && widget.classModel!.createdBy == currentUserId && widget.classModel!.inviteCode != null)
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: Colors.blueAccent.withOpacity(0.1),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                children: [
                  const Icon(Icons.key_rounded, color: Colors.blueAccent),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Invite Code: ${widget.classModel!.inviteCode}',
                      style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.blueAccent, fontSize: 14),
                    ),
                  ),
                  InkWell(
                    borderRadius: BorderRadius.circular(8),
                    onTap: () {
                      Clipboard.setData(ClipboardData(text: widget.classModel!.inviteCode!));
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: const Text('Invite code copied to clipboard'),
                          behavior: SnackBarBehavior.floating,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                      );
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.blueAccent.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Text('Copy', style: TextStyle(color: Colors.blueAccent, fontWeight: FontWeight.bold, fontSize: 13)),
                    ),
                  ),
                ],
              ),
            ),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                // 1. FILES TAB
                StreamBuilder<List<Map<String, dynamic>>>(
                  stream: _materialsStream,
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator(color: Colors.blueAccent));
                    }
                    if (snapshot.hasError) {
                      return Center(child: Text('Error: ${snapshot.error}'));
                    }
                    
                    final data = snapshot.data ?? [];
                    final materials = data.map((json) => MaterialModel.fromJson(json)).toList();

                    if (materials.isEmpty) {
                      return Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(24),
                              decoration: BoxDecoration(color: isDark ? Colors.grey.shade800.withOpacity(0.5) : Colors.grey.shade200, shape: BoxShape.circle),
                              child: Icon(Icons.folder_open_rounded, size: 64, color: isDark ? Colors.grey[500] : Colors.grey[400]),
                            ),
                            const SizedBox(height: 24),
                            Text('No files yet', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: isDark ? Colors.white : const Color(0xFF111827))),
                            const SizedBox(height: 8),
                            Text('Upload materials to share with the class.', style: TextStyle(color: isDark ? Colors.grey[400] : Colors.grey[500], fontSize: 15)),
                          ],
                        ),
                      );
                    }
                    return ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        itemCount: materials.length,
                        itemBuilder: (context, index) {
                          final material = materials[index];
                          final isBookmarked = bookmarkedMaterialsAsync.value?.contains(material.id) ?? false;
                          
                          // Determine icon and color based on extension
                          final ext = material.fileUrl.split('.').last.toLowerCase();
                          IconData iconData = Icons.insert_drive_file_rounded;
                          Color iconColor = Colors.blueAccent;
                          if (['pdf'].contains(ext)) { iconData = Icons.picture_as_pdf_rounded; iconColor = Colors.redAccent; }
                          else if (['doc', 'docx'].contains(ext)) { iconData = Icons.description_rounded; iconColor = Colors.blue; }
                          else if (['jpg', 'jpeg', 'png', 'gif'].contains(ext)) { iconData = Icons.image_rounded; iconColor = Colors.green; }
                          else if (['ppt', 'pptx'].contains(ext)) { iconData = Icons.slideshow_rounded; iconColor = Colors.orange; }
                          else if (['xls', 'xlsx'].contains(ext)) { iconData = Icons.table_chart_rounded; iconColor = Colors.teal; }
                          
                          return Container(
                            margin: const EdgeInsets.only(bottom: 12),
                            decoration: BoxDecoration(
                              color: isDark ? const Color(0xFF1E293B) : Colors.white,
                              borderRadius: BorderRadius.circular(16),
                              boxShadow: isDark ? [] : [
                                BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10, offset: const Offset(0, 4)),
                              ],
                            ),
                            child: Material(
                              color: Colors.transparent,
                              child: InkWell(
                                borderRadius: BorderRadius.circular(16),
                                onTap: () => _openMaterial(material.fileUrl),
                                child: Padding(
                                  padding: const EdgeInsets.all(16.0),
                                  child: Row(
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.all(12),
                                        decoration: BoxDecoration(color: iconColor.withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
                                        child: Icon(iconData, color: iconColor, size: 28),
                                      ),
                                      const SizedBox(width: 16),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(material.title, style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16, color: isDark ? Colors.white : Colors.black87), maxLines: 1, overflow: TextOverflow.ellipsis),
                                            const SizedBox(height: 6),
                                            Text('${material.authorName ?? "Unknown User"} • ${material.createdAt.toLocal().toString().substring(0, 10)}', style: TextStyle(color: isDark ? Colors.grey[400] : Colors.grey[500], fontSize: 12, fontWeight: FontWeight.w500)),
                                          ],
                                        ),
                                      ),
                                      Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          if (currentUserId == material.uploadedBy)
                                            IconButton(icon: const Icon(Icons.delete_outline_rounded, color: Colors.redAccent), onPressed: () => _confirmDelete(material)),
                                          IconButton(
                                            icon: Icon(isBookmarked ? Icons.bookmark_rounded : Icons.bookmark_border_rounded, color: isBookmarked ? Colors.amber : (isDark ? Colors.grey[500] : Colors.grey[400])),
                                            onPressed: () => ref.read(bookmarkedMaterialsProvider.notifier).toggleBookmark(material.id),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          );
                        },
                      );
                  },
                ),
                
                // 2. DISCUSSIONS TAB (Chat)
                Column(
                  children: [
                    Expanded(
                      child: StreamBuilder<List<Map<String, dynamic>>>(
                        stream: _classNotesStream,
                        builder: (context, snapshot) {
                          if (snapshot.connectionState == ConnectionState.waiting) {
                            return const Center(child: CircularProgressIndicator(color: Colors.blueAccent));
                          }
                          if (snapshot.hasError) {
                            return Center(child: Text('Error: ${snapshot.error}'));
                          }
                          
                          final data = snapshot.data ?? [];
                          // Reverse the list so the newest message is at index 0 to work perfectly with ListView(reverse: true)
                          final notes = data.map((json) => NoteModel.fromJson(json)).toList().reversed.toList();

                          if (notes.isEmpty) {
                            return Center(
                              child: Text('No messages yet. Start the conversation!', style: TextStyle(color: isDark ? Colors.grey[500] : Colors.grey[400], fontSize: 15)),
                            );
                          }
                          return ListView.builder(
                            reverse: true,
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                            itemCount: notes.length,
                            itemBuilder: (context, index) {
                              final note = notes[index];
                              final isAI = note.content.startsWith('🤖 [AI Tutor]: ');
                              final content = isAI ? note.content.replaceFirst('🤖 [AI Tutor]: ', '') : note.content;
                              final isMe = note.userId == currentUserId && !isAI; // AI is not "me" visually
                              final isCreator = widget.classModel?.createdBy == note.userId && !isAI;
                              
                              if (isAI) {
                                return Align(
                                  alignment: Alignment.centerLeft,
                                  child: Container(
                                    margin: const EdgeInsets.only(bottom: 12),
                                    constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.85),
                                    decoration: BoxDecoration(
                                      gradient: const LinearGradient(colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)]),
                                      borderRadius: BorderRadius.circular(20).copyWith(bottomLeft: const Radius.circular(4)),
                                      boxShadow: [BoxShadow(color: const Color(0xFF8B5CF6).withOpacity(0.3), blurRadius: 8, offset: const Offset(0, 4))],
                                    ),
                                    child: Padding(
                                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          const Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              Icon(Icons.auto_awesome_rounded, color: Colors.white, size: 18),
                                              SizedBox(width: 6),
                                              Text('AI Tutor', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 14, color: Colors.white)),
                                            ],
                                          ),
                                          const SizedBox(height: 8),
                                          Text(
                                            content,
                                            style: const TextStyle(fontSize: 15, color: Colors.white, height: 1.4),
                                          ),
                                          const SizedBox(height: 4),
                                          Align(
                                            alignment: Alignment.bottomRight,
                                            child: Text(
                                              note.createdAt.toLocal().toString().substring(11, 16),
                                              style: TextStyle(fontSize: 10, color: Colors.white.withOpacity(0.7)),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                );
                              }

                              return Align(
                                alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
                                child: Container(
                                  margin: const EdgeInsets.only(bottom: 12),
                                  constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.75),
                                  decoration: BoxDecoration(
                                    color: isMe ? Colors.blueAccent : (isDark ? const Color(0xFF1F2937) : Colors.white),
                                    borderRadius: BorderRadius.circular(20).copyWith(
                                      bottomRight: isMe ? const Radius.circular(4) : const Radius.circular(20),
                                      bottomLeft: !isMe ? const Radius.circular(4) : const Radius.circular(20),
                                    ),
                                    border: isCreator && !isMe ? Border.all(color: Colors.amber, width: 1.5) : null,
                                    boxShadow: isDark ? [] : [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 4, offset: const Offset(0, 2))],
                                  ),
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        if (!isMe)
                                          Consumer(
                                            builder: (context, ref, _) {
                                              final nameAsync = ref.watch(userNameProvider(note.userId));
                                              final displayName = nameAsync.value ?? 'Unknown User';
                                              return Row(
                                                mainAxisSize: MainAxisSize.min,
                                                children: [
                                                  Text(
                                                    displayName,
                                                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: isCreator ? Colors.amber : (isDark ? Colors.blue[300] : Colors.blueAccent)),
                                                  ),
                                                ],
                                              );
                                            },
                                          ),
                                        if (!isMe) const SizedBox(height: 6),
                                        Text(
                                          content,
                                          style: TextStyle(fontSize: 15, color: isMe ? Colors.white : (isDark ? Colors.grey[200] : Colors.black87), height: 1.3),
                                        ),
                                        const SizedBox(height: 4),
                                        Align(
                                          alignment: Alignment.bottomRight,
                                          child: Text(
                                            note.createdAt.toLocal().toString().substring(11, 16),
                                            style: TextStyle(fontSize: 10, color: isMe ? Colors.white70 : (isDark ? Colors.grey[500] : Colors.grey[400])),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              );
                            },
                          );
                        },
                      ),
                    ),
                    if (_isAITyping)
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                        child: Row(
                          children: [
                            const Icon(Icons.auto_awesome_rounded, color: Colors.purpleAccent, size: 16),
                            const SizedBox(width: 8),
                            Text('AI Tutor is typing...', style: TextStyle(color: isDark ? Colors.grey[400] : Colors.grey[600], fontSize: 13, fontStyle: FontStyle.italic)),
                          ],
                        ),
                      ),
                    // Premium Chat Input
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF1E293B) : Colors.white,
                        boxShadow: isDark ? [] : [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10, offset: const Offset(0, -4))],
                      ),
                      child: SafeArea(
                        child: Row(
                          children: [
                            Expanded(
                              child: Container(
                                decoration: BoxDecoration(
                                  color: isDark ? const Color(0xFF0F172A) : Colors.grey.shade100,
                                  borderRadius: BorderRadius.circular(24),
                                ),
                                child: TextField(
                                  controller: _noteController,
                                  style: TextStyle(color: isDark ? Colors.white : Colors.black87),
                                  decoration: InputDecoration(
                                    hintText: 'Type a message...',
                                    hintStyle: TextStyle(color: isDark ? Colors.grey[500] : Colors.grey[500]),
                                    border: InputBorder.none,
                                    contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                                  ),
                                  maxLines: 4,
                                  minLines: 1,
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Container(
                              decoration: BoxDecoration(
                                color: Colors.blueAccent,
                                shape: BoxShape.circle,
                                boxShadow: [BoxShadow(color: Colors.blueAccent.withOpacity(0.3), blurRadius: 8, offset: const Offset(0, 4))],
                              ),
                              child: noteActionState.isLoading
                                  ? const Padding(padding: EdgeInsets.all(14), child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5)))
                                  : IconButton(
                                      icon: const Icon(Icons.send_rounded, color: Colors.white, size: 20),
                                      onPressed: _postNote,
                                    ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),

                // 3. INFO TAB
                SingleChildScrollView(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (widget.classModel != null) ...[
                        // Title
                        Text(
                          widget.classModel!.name,
                          style: TextStyle(fontSize: 26, fontWeight: FontWeight.w800, letterSpacing: -0.5, color: isDark ? Colors.white : const Color(0xFF111827)),
                        ),
                        const SizedBox(height: 16),
                        // Modern Tags
                        Wrap(
                          spacing: 10,
                          runSpacing: 10,
                          children: [
                            if (widget.classModel!.faculty != null && widget.classModel!.faculty!.isNotEmpty)
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                                decoration: BoxDecoration(color: isDark ? Colors.indigo.withOpacity(0.2) : Colors.indigo.withOpacity(0.08), borderRadius: BorderRadius.circular(12)),
                                child: Text(widget.classModel!.faculty!, style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: isDark ? Colors.indigo.shade300 : Colors.indigo.shade600)),
                              ),
                            if (widget.classModel!.major != null && widget.classModel!.major!.isNotEmpty)
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                                decoration: BoxDecoration(color: isDark ? Colors.teal.withOpacity(0.2) : Colors.teal.withOpacity(0.08), borderRadius: BorderRadius.circular(12)),
                                child: Text(widget.classModel!.major!, style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: isDark ? Colors.teal.shade300 : Colors.teal.shade700)),
                              ),
                            if (widget.classModel!.academicYear != null && widget.classModel!.academicYear!.isNotEmpty)
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                                decoration: BoxDecoration(color: isDark ? Colors.orange.withOpacity(0.2) : Colors.orange.withOpacity(0.08), borderRadius: BorderRadius.circular(12)),
                                child: Text('Year ${widget.classModel!.academicYear}', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: isDark ? Colors.orange.shade300 : Colors.orange.shade800)),
                              ),
                          ],
                        ),
                        const SizedBox(height: 32),
                        // Description
                        if (widget.classModel!.description != null && widget.classModel!.description!.isNotEmpty) ...[
                          Text('About this class', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: isDark ? Colors.white : Colors.black87)),
                          const SizedBox(height: 12),
                          Text(
                            widget.classModel!.description!,
                            style: TextStyle(fontSize: 15, color: isDark ? Colors.grey[300] : Colors.grey[700], height: 1.6),
                          ),
                          const SizedBox(height: 32),
                        ],
                        FutureBuilder<Map<String, dynamic>>(
                          future: _infoFuture,
                          builder: (context, snapshot) {
                            final creatorName = snapshot.data?['creatorName'] as String? ?? 'Class Administrator';
                            final memberCount = snapshot.data?['memberCount'] as int? ?? 1;
                            final avatarLetter = creatorName.isNotEmpty ? creatorName[0].toUpperCase() : 'A';
                            
                            // Format date: "Oct 12, 2026"
                            final months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
                            final date = widget.classModel!.createdAt.toLocal();
                            final dateString = '${months[date.month - 1]} ${date.day}, ${date.year}';

                            return Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Profile Card
                                Text('Instructor / Admin', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: isDark ? Colors.white : Colors.black87)),
                                const SizedBox(height: 16),
                                Container(
                                  padding: const EdgeInsets.all(20),
                                  decoration: BoxDecoration(
                                    color: isDark ? const Color(0xFF1E293B) : Colors.white,
                                    borderRadius: BorderRadius.circular(20),
                                    boxShadow: isDark ? [] : [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 16, offset: const Offset(0, 8))],
                                  ),
                                  child: Row(
                                    children: [
                                      CircleAvatar(
                                        radius: 32,
                                        backgroundColor: Colors.blueAccent.withOpacity(0.15),
                                        child: Text(
                                          avatarLetter,
                                          style: const TextStyle(color: Colors.blueAccent, fontSize: 24, fontWeight: FontWeight.bold),
                                        ),
                                      ),
                                      const SizedBox(width: 20),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Row(
                                              children: [
                                                Expanded(
                                                  child: Text(
                                                    creatorName, 
                                                    style: TextStyle(fontWeight: FontWeight.w800, fontSize: 17, color: isDark ? Colors.white : Colors.black87),
                                                    maxLines: 1,
                                                    overflow: TextOverflow.ellipsis,
                                                  ),
                                                ),
                                                const SizedBox(width: 8),
                                                Container(
                                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                                  decoration: BoxDecoration(color: Colors.amber.withOpacity(0.15), borderRadius: BorderRadius.circular(8)),
                                                  child: const Text('Creator', style: TextStyle(color: Colors.amber, fontSize: 11, fontWeight: FontWeight.bold)),
                                                ),
                                              ],
                                            ),
                                            const SizedBox(height: 4),
                                            Text('Manages class files, discussions, and moderation.', style: TextStyle(color: isDark ? Colors.grey[400] : Colors.grey[600], fontSize: 13, height: 1.4)),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(height: 32),
                                // Class Stats
                                Text('Class Stats', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: isDark ? Colors.white : Colors.black87)),
                                const SizedBox(height: 16),
                                Row(
                                  children: [
                                    Expanded(
                                      child: Container(
                                        padding: const EdgeInsets.all(20),
                                        decoration: BoxDecoration(
                                          color: isDark ? const Color(0xFF1E293B) : Colors.white,
                                          borderRadius: BorderRadius.circular(20),
                                          boxShadow: isDark ? [] : [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 16, offset: const Offset(0, 8))],
                                        ),
                                        child: Column(
                                          children: [
                                            Icon(Icons.group_rounded, color: Colors.indigo.shade400, size: 28),
                                            const SizedBox(height: 12),
                                            Text(
                                              memberCount.toString(),
                                              style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: isDark ? Colors.white : Colors.black87),
                                            ),
                                            const SizedBox(height: 4),
                                            Text('Members', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: isDark ? Colors.grey[400] : Colors.grey[600])),
                                          ],
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 16),
                                    Expanded(
                                      child: Container(
                                        padding: const EdgeInsets.all(20),
                                        decoration: BoxDecoration(
                                          color: isDark ? const Color(0xFF1E293B) : Colors.white,
                                          borderRadius: BorderRadius.circular(20),
                                          boxShadow: isDark ? [] : [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 16, offset: const Offset(0, 8))],
                                        ),
                                        child: Column(
                                          children: [
                                            Icon(Icons.calendar_today_rounded, color: Colors.teal.shade400, size: 28),
                                            const SizedBox(height: 12),
                                            Text(
                                              dateString,
                                              style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: isDark ? Colors.white : Colors.black87),
                                            ),
                                            const SizedBox(height: 4),
                                            Text('Created', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: isDark ? Colors.grey[400] : Colors.grey[600])),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            );
                          },
                        ),
                      ] else ...[
                        Center(child: Text('Class information is unavailable.', style: TextStyle(color: isDark ? Colors.grey[500] : Colors.grey[400]))),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: _tabController.index == 0
          ? FloatingActionButton.extended(
              onPressed: actionState.isLoading ? null : _pickAndUploadFile,
              backgroundColor: Colors.blueAccent,
              foregroundColor: Colors.white,
              elevation: 4,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              icon: actionState.isLoading
                  ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                  : const Icon(Icons.cloud_upload_rounded),
              label: Text(actionState.isLoading ? 'Uploading...' : 'Upload File', style: const TextStyle(fontWeight: FontWeight.bold)),
            )
          : null,
    );
  }
}
