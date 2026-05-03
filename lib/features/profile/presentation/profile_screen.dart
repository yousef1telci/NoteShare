import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../auth/providers/auth_provider.dart';
import '../../materials/providers/materials_provider.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  Future<void> _openMaterial(BuildContext context, WidgetRef ref, String filePath) async {
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

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(supabaseProvider).auth.currentUser;
    final bookmarkedMaterialsAsync = ref.watch(bookmarkedMaterialsListProvider);
    final bookmarkedIdsAsync = ref.watch(bookmarkedMaterialsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () {
              ref.read(authControllerProvider.notifier).signOut();
            },
            tooltip: 'Sign Out',
          ),
        ],
      ),
      body: Column(
        children: [
          // User Info Section
          Container(
            padding: const EdgeInsets.all(24.0),
            width: double.infinity,
            color: Colors.blue.withOpacity(0.05),
            child: Column(
              children: [
                const CircleAvatar(
                  radius: 40,
                  backgroundColor: Colors.blueAccent,
                  child: Icon(Icons.person, size: 50, color: Colors.white),
                ),
                const SizedBox(height: 16),
                Text(
                  user?.email ?? 'Unknown User',
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          
          const Divider(height: 1),
          
          // Bookmarks Section Header
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                const Icon(Icons.bookmark, color: Colors.amber),
                const SizedBox(width: 8),
                const Text(
                  'My Bookmarks',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const Spacer(),
                bookmarkedMaterialsAsync.maybeWhen(
                  data: (materials) => Text('${materials.length} items'),
                  orElse: () => const SizedBox.shrink(),
                ),
              ],
            ),
          ),
          
          // Bookmarks List
          Expanded(
            child: bookmarkedMaterialsAsync.when(
              data: (materials) {
                if (materials.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.bookmark_border, size: 60, color: Colors.grey[400]),
                        const SizedBox(height: 16),
                        Text(
                          'No bookmarks yet.',
                          style: TextStyle(color: Colors.grey[600], fontSize: 16),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Explore classes and save materials to find them here.',
                          style: TextStyle(color: Colors.grey[500], fontSize: 14),
                        ),
                      ],
                    ),
                  );
                }
                
                return RefreshIndicator(
                  onRefresh: () async {
                    ref.invalidate(bookmarkedMaterialsListProvider);
                  },
                  child: ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    itemCount: materials.length,
                    itemBuilder: (context, index) {
                      final material = materials[index];
                      // Use the local bookmarked IDs to allow un-bookmarking optimistically
                      final isBookmarked = bookmarkedIdsAsync.value?.contains(material.id) ?? true;
                      
                      // If it was optimistically unbookmarked but the list hasn't refreshed yet, hide it
                      if (!isBookmarked) return const SizedBox.shrink();

                      return Card(
                        margin: const EdgeInsets.only(bottom: 12),
                        child: ListTile(
                          leading: const Icon(Icons.insert_drive_file, color: Colors.blueAccent),
                          title: Text(
                            material.title,
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          subtitle: Text(
                            'Uploaded ${material.createdAt.toLocal().toString().split('.')[0]}',
                          ),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: const Icon(Icons.bookmark, color: Colors.amber),
                                onPressed: () {
                                  ref.read(bookmarkedMaterialsProvider.notifier).toggleBookmark(material.id);
                                },
                              ),
                            ],
                          ),
                          onTap: () => _openMaterial(context, ref, material.fileUrl),
                        ),
                      );
                    },
                  ),
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, stack) => Center(
                child: Text('Error loading bookmarks: $error'),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
