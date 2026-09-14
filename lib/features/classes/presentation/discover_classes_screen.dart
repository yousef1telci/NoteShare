import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../domain/class_model.dart';
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
    final isSelected = value != null;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Padding(
      padding: const EdgeInsets.only(right: 10.0),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16),
        decoration: BoxDecoration(
          color: isSelected 
              ? (isDark ? Colors.blueAccent.withOpacity(0.15) : Colors.blue.shade50)
              : (isDark ? const Color(0xFF1F2937) : Colors.white),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: isSelected ? Colors.blueAccent : (isDark ? Colors.grey.shade800 : Colors.grey.shade200),
            width: isSelected ? 1.5 : 1.0,
          ),
          boxShadow: isDark || isSelected ? [] : [
            BoxShadow(
              color: Colors.black.withOpacity(0.03),
              blurRadius: 8,
              offset: const Offset(0, 2),
            )
          ],
        ),
        child: DropdownButtonHideUnderline(
          child: DropdownButton<String>(
            hint: Text(
              hint, 
              style: TextStyle(
                fontSize: 14, 
                color: isDark ? Colors.grey[400] : Colors.grey[600],
                fontWeight: FontWeight.w500,
              ),
            ),
            value: value,
            icon: Icon(
              Icons.keyboard_arrow_down_rounded, 
              size: 20,
              color: isSelected ? Colors.blueAccent : (isDark ? Colors.grey[400] : Colors.grey[600]),
            ),
            onChanged: onChanged,
            dropdownColor: isDark ? const Color(0xFF1F2937) : Colors.white,
            borderRadius: BorderRadius.circular(16),
            items: [
              DropdownMenuItem<String>(
                value: null,
                child: Text('All $hint', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
              ),
              ...items.map((item) => DropdownMenuItem<String>(
                    value: item,
                    child: Text(item, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
                  ))
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final myClassesAsync = ref.watch(myClassesProvider);
    final actionState = ref.watch(classActionControllerProvider);
    final selectedFaculty = ref.watch(facultyFilterProvider);
    final selectedMajor = ref.watch(majorFilterProvider);
    final selectedYear = ref.watch(yearFilterProvider);
    final searchQuery = ref.watch(searchQueryProvider).toLowerCase();
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    final myClassIds = myClassesAsync.value?.map((c) => c.id).toSet() ?? {};

    // Listen to join action success to show snackbar
    ref.listen<AsyncValue<void>>(
      classActionControllerProvider,
      (previous, next) {
        next.whenOrNull(
          data: (_) {
            if (previous?.isLoading == true) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: const Text('Successfully joined class!', style: TextStyle(fontWeight: FontWeight.bold)),
                  backgroundColor: Colors.green.shade600,
                  behavior: SnackBarBehavior.floating,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              );
            }
          },
          error: (error, stack) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Failed to join: $error'), 
                backgroundColor: Colors.redAccent,
                behavior: SnackBarBehavior.floating,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            );
          },
        );
      },
    );

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF121212) : const Color(0xFFF9FAFB),
      appBar: AppBar(
        title: Text(
          'Discover Classes',
          style: TextStyle(
            fontWeight: FontWeight.w800,
            letterSpacing: -0.5,
            color: isDark ? Colors.white : const Color(0xFF111827),
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: false,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(135),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Search Bar
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 8.0),
                child: Container(
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF1F2937) : Colors.white,
                    borderRadius: BorderRadius.circular(30),
                    boxShadow: isDark ? [] : [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.04),
                        blurRadius: 16,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: TextField(
                    controller: _searchController,
                    onChanged: _onSearchChanged,
                    style: TextStyle(color: isDark ? Colors.white : Colors.black87),
                    decoration: InputDecoration(
                      hintText: 'Search for classes...',
                      hintStyle: TextStyle(color: isDark ? Colors.grey[500] : Colors.grey[400]),
                      prefixIcon: Icon(Icons.search_rounded, color: isDark ? Colors.grey[400] : Colors.grey[500]),
                      suffixIcon: _searchController.text.isNotEmpty
                          ? IconButton(
                              icon: Icon(Icons.cancel_rounded, color: isDark ? Colors.grey[500] : Colors.grey[400]),
                              onPressed: () {
                                _searchController.clear();
                                _onSearchChanged('');
                              },
                            )
                          : null,
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              // Filter Bar
              SizedBox(
                height: 48,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 20),
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
              const SizedBox(height: 12),
            ],
          ),
        ),
      ),
      body: StreamBuilder<List<Map<String, dynamic>>>(
        stream: Supabase.instance.client
            .from('classes')
            .stream(primaryKey: ['id'])
            .eq('is_private', false)
            .order('created_at', ascending: false),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: Colors.blueAccent));
          }
          if (snapshot.hasError) {
            return Center(
              child: Text('Error loading classes: ${snapshot.error}'),
            );
          }

          final data = snapshot.data ?? [];
          var classes = data.map((json) => ClassModel.fromJson(json)).toList();

          // Apply client-side filters
          classes = classes.where((c) => !myClassIds.contains(c.id)).toList();
          
          if (searchQuery.trim().isNotEmpty) {
            classes = classes.where((c) => c.name.toLowerCase().contains(searchQuery) || (c.description?.toLowerCase().contains(searchQuery) ?? false)).toList();
          }
          if (selectedFaculty != null && selectedFaculty.isNotEmpty) {
            classes = classes.where((c) => c.faculty == selectedFaculty).toList();
          }
          if (selectedMajor != null && selectedMajor.isNotEmpty) {
            classes = classes.where((c) => c.major == selectedMajor).toList();
          }
          if (selectedYear != null && selectedYear.isNotEmpty) {
            classes = classes.where((c) => c.academicYear == selectedYear).toList();
          }

          if (classes.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: isDark ? Colors.grey.shade800.withOpacity(0.5) : Colors.grey.shade100,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(Icons.category_outlined, size: 64, color: isDark ? Colors.grey[500] : Colors.grey[400]),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'No classes match these filters',
                    style: TextStyle(
                      color: isDark ? Colors.white : const Color(0xFF111827), 
                      fontSize: 18, 
                      fontWeight: FontWeight.w700,
                      letterSpacing: -0.5,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Try adjusting your search or clearing filters.',
                    style: TextStyle(color: isDark ? Colors.grey[400] : Colors.grey[500], fontSize: 15),
                  ),
                ],
              ),
            );
          }
          return ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            itemCount: classes.length,
            itemBuilder: (context, index) {
              final cls = classes[index];
              return Container(
                margin: const EdgeInsets.only(bottom: 20),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF1E293B) : Colors.white,
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: isDark ? [] : [
                    BoxShadow(
                      color: Colors.blueGrey.withOpacity(0.06),
                      blurRadius: 24,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Header: Icon + Title
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: isDark ? Colors.blueAccent.withOpacity(0.15) : Colors.blueAccent.withOpacity(0.08),
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Icon(
                              Icons.auto_stories_rounded, 
                              color: isDark ? Colors.lightBlueAccent : Colors.blueAccent, 
                              size: 28,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  cls.name,
                                  style: TextStyle(
                                    fontWeight: FontWeight.w800,
                                    fontSize: 18,
                                    letterSpacing: -0.5,
                                    color: isDark ? Colors.white : const Color(0xFF111827),
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Public Class',
                                  style: TextStyle(
                                    color: isDark ? Colors.grey[400] : Colors.grey[500],
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      
                      // Metadata Tags (Faculty / Year / Major)
                      if ((cls.faculty != null && cls.faculty!.isNotEmpty) || 
                          (cls.major != null && cls.major!.isNotEmpty) || 
                          (cls.academicYear != null && cls.academicYear!.isNotEmpty)) ...[
                        const SizedBox(height: 20),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            if (cls.faculty != null && cls.faculty!.isNotEmpty)
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                decoration: BoxDecoration(
                                  color: isDark ? Colors.indigo.withOpacity(0.2) : Colors.indigo.withOpacity(0.08),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  cls.faculty!,
                                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: isDark ? Colors.indigo.shade300 : Colors.indigo.shade600),
                                ),
                              ),
                            if (cls.major != null && cls.major!.isNotEmpty)
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                decoration: BoxDecoration(
                                  color: isDark ? Colors.teal.withOpacity(0.2) : Colors.teal.withOpacity(0.08),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  cls.major!,
                                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: isDark ? Colors.teal.shade300 : Colors.teal.shade700),
                                ),
                              ),
                            if (cls.academicYear != null && cls.academicYear!.isNotEmpty)
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                decoration: BoxDecoration(
                                  color: isDark ? Colors.orange.withOpacity(0.2) : Colors.orange.withOpacity(0.08),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  'Year ${cls.academicYear}',
                                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: isDark ? Colors.orange.shade300 : Colors.orange.shade800),
                                ),
                              ),
                          ],
                        ),
                      ],
                      
                      // Description
                      if (cls.description != null && cls.description!.isNotEmpty) ...[
                        const SizedBox(height: 16),
                        Text(
                          cls.description!,
                          style: TextStyle(
                            fontSize: 14,
                            color: isDark ? Colors.grey[300] : Colors.grey[700],
                            height: 1.5,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                      
                      const SizedBox(height: 24),
                      
                      // Action Button
                      SizedBox(
                        width: double.infinity,
                        height: 52,
                        child: ElevatedButton(
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
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blueAccent,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                            elevation: 0,
                          ),
                          child: const Text(
                            'Join & Explore',
                            style: TextStyle(
                              fontSize: 16, 
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.3,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
