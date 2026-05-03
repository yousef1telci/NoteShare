import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../providers/classes_provider.dart';

class DiscoverClassesScreen extends ConsumerStatefulWidget {
  const DiscoverClassesScreen({super.key});

  @override
  ConsumerState<DiscoverClassesScreen> createState() => _DiscoverClassesScreenState();
}

class _DiscoverClassesScreenState extends ConsumerState<DiscoverClassesScreen> {
  final TextEditingController _searchController = TextEditingController();

  final List<String> _faculties = [
    'Engineering', 'Medicine', 'Technology', 'Science', 'Education', 'Economics'
  ];
  final List<String> _majors = [
    "Software Engineering", "Computer Engineering", "Information Systems Engineering", 
    "Electrical and Electronics Engineering", "Mechanical Engineering", "Civil Engineering", "Industrial Engineering",
    "General Medicine", "Internal Medicine", "General Surgery", "Pediatrics", 
    "Obstetrics and Gynecology", "Cardiology", "Neurology", "Orthopedics", 
    "Ophthalmology", "Radiology", "Anesthesiology", "Dermatology", "ENT (Ear, Nose, and Throat)",
    "Electrical Engineering", "Manufacturing Engineering", "Energy Systems Engineering",
    "Mathematics", "Physics", "Chemistry", "Biology",
    "Computer Education and Instructional Technology", "Primary Education", 
    "Mathematics Education", "Science Education", "English Language Teaching", "Preschool Education",
    "Business Administration", "Economics", "Finance", "Public Administration"
  ].toSet().toList(); // Ensure unique values
  final List<String> _years = ['1', '2', '3', '4'];

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged(String query) {
    ref.read(searchQueryProvider.notifier).state = query;
  }

  Widget _buildDropdownFilter(String hint, String? value, List<String> items, Function(String?) onChanged) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4.0),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.grey.shade300),
        ),
        child: DropdownButtonHideUnderline(
          child: DropdownButton<String>(
            hint: Text(hint, style: const TextStyle(fontSize: 14)),
            value: value,
            icon: const Icon(Icons.filter_list, size: 16),
            onChanged: onChanged,
            items: [
              const DropdownMenuItem<String>(
                value: null,
                child: Text('All', style: TextStyle(fontSize: 14)),
              ),
              ...items.map((item) => DropdownMenuItem<String>(
                    value: item,
                    child: Text(item, style: const TextStyle(fontSize: 14)),
                  ))
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final discoverClassesAsync = ref.watch(discoverClassesProvider);
    final actionState = ref.watch(classActionControllerProvider);
    final selectedFaculty = ref.watch(facultyFilterProvider);
    final selectedMajor = ref.watch(majorFilterProvider);
    final selectedYear = ref.watch(yearFilterProvider);

    // Listen to join action success to show snackbar
    ref.listen<AsyncValue<void>>(
      classActionControllerProvider,
      (previous, next) {
        next.whenOrNull(
          data: (_) {
            if (previous?.isLoading == true) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Successfully joined class!'), backgroundColor: Colors.green),
              );
            }
          },
          error: (error, stack) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Failed to join: $error'), backgroundColor: Colors.red),
            );
          },
        );
      },
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text('Discover Classes'),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(120),
          child: Column(
            children: [
              // Search Bar
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                child: TextField(
                  controller: _searchController,
                  onChanged: _onSearchChanged,
                  decoration: InputDecoration(
                    hintText: 'Search for classes...',
                    prefixIcon: const Icon(Icons.search),
                    suffixIcon: _searchController.text.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear),
                            onPressed: () {
                              _searchController.clear();
                              _onSearchChanged('');
                            },
                          )
                        : null,
                    filled: true,
                    fillColor: Theme.of(context).cardColor,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(30),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: const EdgeInsets.symmetric(vertical: 0),
                  ),
                ),
              ),
              // Filter Bar
              SizedBox(
                height: 50,
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: Row(
                    children: [
                      _buildDropdownFilter('Faculty', selectedFaculty, _faculties, (val) {
                        ref.read(facultyFilterProvider.notifier).state = val;
                      }),
                      _buildDropdownFilter('Major', selectedMajor, _majors, (val) {
                        ref.read(majorFilterProvider.notifier).state = val;
                      }),
                      _buildDropdownFilter('Year', selectedYear, _years, (val) {
                        ref.read(yearFilterProvider.notifier).state = val;
                      }),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
      body: discoverClassesAsync.when(
        data: (classes) {
          if (classes.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.category_outlined, size: 80, color: Colors.grey[400]),
                  const SizedBox(height: 16),
                  Text(
                    'No classes match these filters yet.',
                    style: TextStyle(color: Colors.grey[600], fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Try adjusting your search or filters.',
                    style: TextStyle(color: Colors.grey[500], fontSize: 14),
                  ),
                ],
              ),
            );
          }
          return RefreshIndicator(
            onRefresh: () async => ref.refresh(discoverClassesProvider.future),
            child: Stack(
              children: [
                ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: classes.length,
                  itemBuilder: (context, index) {
                    final cls = classes[index];
                    return Card(
                      elevation: 2,
                      margin: const EdgeInsets.only(bottom: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                const CircleAvatar(
                                  backgroundColor: Colors.blueAccent,
                                  child: Icon(Icons.class_, color: Colors.white),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        cls.name,
                                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                                      ),
                                      Text(
                                        'Public Class',
                                        style: TextStyle(color: Colors.grey[600], fontSize: 12),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            if (cls.description != null && cls.description!.isNotEmpty) ...[
                              const SizedBox(height: 12),
                              Text(
                                cls.description!,
                                style: const TextStyle(fontSize: 14),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                            const SizedBox(height: 16),
                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton.icon(
                                onPressed: actionState.isLoading
                                    ? null
                                    : () async {
                                        await ref
                                            .read(classActionControllerProvider.notifier)
                                            .joinClass(classId: cls.id);
                                        if (context.mounted) {
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
                                        }
                                      },
                                icon: const Icon(Icons.login),
                                label: const Text('Join & Explore'),
                                style: ElevatedButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(vertical: 12),
                                ),
                              ),
                            ),
                          ],
                        ),
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
