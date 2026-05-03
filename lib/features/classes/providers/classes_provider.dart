import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../auth/providers/auth_provider.dart';
import '../data/classes_repository.dart';
import '../domain/class_model.dart';

final classesRepositoryProvider = Provider<ClassesRepository>((ref) {
  final supabase = ref.watch(supabaseProvider);
  return ClassesRepository(supabase);
});

final myClassesProvider = FutureProvider.autoDispose<List<ClassModel>>((ref) async {
  final repository = ref.watch(classesRepositoryProvider);
  return repository.getMyClasses();
});

final searchQueryProvider = StateProvider<String>((ref) => '');
final facultyFilterProvider = StateProvider<String?>((ref) => null);
final majorFilterProvider = StateProvider<String?>((ref) => null);
final yearFilterProvider = StateProvider<String?>((ref) => null);

final discoverClassesProvider = FutureProvider.autoDispose<List<ClassModel>>((ref) async {
  final repository = ref.watch(classesRepositoryProvider);
  final query = ref.watch(searchQueryProvider);
  final faculty = ref.watch(facultyFilterProvider);
  final major = ref.watch(majorFilterProvider);
  final year = ref.watch(yearFilterProvider);
  
  List<ClassModel> publicClasses;
  if (query.trim().isEmpty) {
    publicClasses = await repository.getDiscoverClasses();
  } else {
    publicClasses = await repository.searchPublicClasses(query);
  }
  
  // Apply category tree filters
  if (faculty != null && faculty.isNotEmpty) {
    publicClasses = publicClasses.where((c) => c.faculty == faculty).toList();
  }
  if (major != null && major.isNotEmpty) {
    publicClasses = publicClasses.where((c) => c.major == major).toList();
  }
  if (year != null && year.isNotEmpty) {
    publicClasses = publicClasses.where((c) => c.academicYear == year).toList();
  }
  
  // Filter out classes the user has already joined
  final myClasses = await ref.watch(myClassesProvider.future);
  final myClassIds = myClasses.map((c) => c.id).toSet();
  
  return publicClasses.where((c) => !myClassIds.contains(c.id)).toList();
});

class ClassActionController extends StateNotifier<AsyncValue<void>> {
  final ClassesRepository _repository;
  final Ref _ref;

  ClassActionController(this._repository, this._ref) : super(const AsyncValue.data(null));

  Future<void> createClass({
    required String name,
    required String description,
    required bool isPrivate,
    String? category,
    String? faculty,
    String? major,
    String? academicYear,
  }) async {
    state = const AsyncValue.loading();
    try {
      await _repository.createClass(
        name: name,
        description: description,
        isPrivate: isPrivate,
        category: category,
        faculty: faculty,
        major: major,
        academicYear: academicYear,
      );
      state = const AsyncValue.data(null);
      // Refresh my classes
      _ref.invalidate(myClassesProvider);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> updateClass({
    required String classId,
    required String name,
    required String description,
    required bool isPrivate,
    String? category,
    String? faculty,
    String? major,
    String? academicYear,
  }) async {
    state = const AsyncValue.loading();
    try {
      await _repository.updateClass(
        classId: classId,
        name: name,
        description: description,
        isPrivate: isPrivate,
        category: category,
        faculty: faculty,
        major: major,
        academicYear: academicYear,
      );
      state = const AsyncValue.data(null);
      _ref.invalidate(myClassesProvider);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> deleteClass(String classId) async {
    state = const AsyncValue.loading();
    try {
      await _repository.deleteClass(classId);
      state = const AsyncValue.data(null);
      _ref.invalidate(myClassesProvider);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> leaveClass(String classId) async {
    state = const AsyncValue.loading();
    try {
      await _repository.leaveClass(classId);
      state = const AsyncValue.data(null);
      _ref.invalidate(myClassesProvider);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> joinClass({String? classId, String? inviteCode}) async {
    state = const AsyncValue.loading();
    try {
      await _repository.joinClass(classId: classId, inviteCode: inviteCode);
      state = const AsyncValue.data(null);
      // Refresh my classes
      _ref.invalidate(myClassesProvider);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }
}

final classActionControllerProvider = StateNotifierProvider<ClassActionController, AsyncValue<void>>((ref) {
  final repository = ref.watch(classesRepositoryProvider);
  return ClassActionController(repository, ref);
});
