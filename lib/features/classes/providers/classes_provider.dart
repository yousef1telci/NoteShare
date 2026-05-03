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

final discoverClassesProvider = FutureProvider.autoDispose<List<ClassModel>>((ref) async {
  final repository = ref.watch(classesRepositoryProvider);
  final query = ref.watch(searchQueryProvider);
  
  List<ClassModel> publicClasses;
  if (query.trim().isEmpty) {
    publicClasses = await repository.getDiscoverClasses();
  } else {
    publicClasses = await repository.searchPublicClasses(query);
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
  }) async {
    state = const AsyncValue.loading();
    try {
      await _repository.createClass(
        name: name,
        description: description,
        isPrivate: isPrivate,
        category: category,
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
  }) async {
    state = const AsyncValue.loading();
    try {
      await _repository.updateClass(
        classId: classId,
        name: name,
        description: description,
        isPrivate: isPrivate,
        category: category,
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
