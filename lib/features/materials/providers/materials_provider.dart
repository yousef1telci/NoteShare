import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:file_picker/file_picker.dart';
import '../../auth/providers/auth_provider.dart';
import '../data/materials_repository.dart';
import '../domain/material_model.dart';

final materialsRepositoryProvider = Provider<MaterialsRepository>((ref) {
  final supabase = ref.watch(supabaseProvider);
  return MaterialsRepository(supabase);
});

final classMaterialsProvider = FutureProvider.family.autoDispose<List<MaterialModel>, String>((ref, classId) async {
  final repository = ref.watch(materialsRepositoryProvider);
  return repository.getClassMaterials(classId);
});

class MaterialActionController extends StateNotifier<AsyncValue<void>> {
  final MaterialsRepository _repository;
  final Ref _ref;

  MaterialActionController(this._repository, this._ref) : super(const AsyncValue.data(null));

  Future<void> uploadMaterial(String classId, PlatformFile file) async {
    state = const AsyncValue.loading();
    try {
      await _repository.uploadMaterial(classId, file);
      state = const AsyncValue.data(null);
      // Refresh the materials list for this class
      _ref.invalidate(classMaterialsProvider(classId));
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> deleteMaterial(String classId, String materialId, String fileUrl) async {
    state = const AsyncValue.loading();
    try {
      await _repository.deleteMaterial(materialId, fileUrl);
      state = const AsyncValue.data(null);
      // Refresh the materials list for this class
      _ref.invalidate(classMaterialsProvider(classId));
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<String> getUrl(String filePath) {
    return _repository.getMaterialUrl(filePath);
  }
}

final materialActionControllerProvider = StateNotifierProvider<MaterialActionController, AsyncValue<void>>((ref) {
  final repository = ref.watch(materialsRepositoryProvider);
  return MaterialActionController(repository, ref);
});

class BookmarkedMaterialsNotifier extends AutoDisposeAsyncNotifier<Set<String>> {
  @override
  Future<Set<String>> build() async {
    final repository = ref.watch(materialsRepositoryProvider);
    return repository.getBookmarkedMaterialIds();
  }

  Future<void> toggleBookmark(String materialId) async {
    final repository = ref.read(materialsRepositoryProvider);
    final previousState = state.value ?? {};
    final isBookmarked = previousState.contains(materialId);

    // Optimistically update UI
    if (isBookmarked) {
      state = AsyncValue.data(Set.from(previousState)..remove(materialId));
    } else {
      state = AsyncValue.data(Set.from(previousState)..add(materialId));
    }

    try {
      await repository.toggleBookmark(materialId, isBookmarked);
    } catch (e, st) {
      // Revert on error
      state = AsyncValue.error(e, st);
      // Re-fetch to ensure consistency
      ref.invalidateSelf();
    }
  }
}

final bookmarkedMaterialsProvider = AsyncNotifierProvider.autoDispose<BookmarkedMaterialsNotifier, Set<String>>(() {
  return BookmarkedMaterialsNotifier();
});

final bookmarkedMaterialsListProvider = FutureProvider.autoDispose<List<MaterialModel>>((ref) async {
  final repository = ref.watch(materialsRepositoryProvider);
  return repository.getBookmarkedMaterials();
});
