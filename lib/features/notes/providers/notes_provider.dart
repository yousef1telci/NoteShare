import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../auth/providers/auth_provider.dart';
import '../data/notes_repository.dart';
import '../domain/note_model.dart';

final notesRepositoryProvider = Provider<NotesRepository>((ref) {
  final supabase = ref.watch(supabaseProvider);
  return NotesRepository(supabase);
});

final classNotesProvider = FutureProvider.family.autoDispose<List<NoteModel>, String>((ref, classId) async {
  final repository = ref.watch(notesRepositoryProvider);
  return repository.getClassNotes(classId);
});

class NoteActionController extends StateNotifier<AsyncValue<void>> {
  final NotesRepository _repository;
  final Ref _ref;

  NoteActionController(this._repository, this._ref) : super(const AsyncValue.data(null));

  Future<void> addNote(String classId, String content) async {
    state = const AsyncValue.loading();
    try {
      await _repository.createNote(classId, content);
      state = const AsyncValue.data(null);
      _ref.invalidate(classNotesProvider(classId));
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }
}

final noteActionControllerProvider = StateNotifierProvider<NoteActionController, AsyncValue<void>>((ref) {
  final repository = ref.watch(notesRepositoryProvider);
  return NoteActionController(repository, ref);
});
