import 'package:supabase_flutter/supabase_flutter.dart';
import '../domain/note_model.dart';

class NotesRepository {
  final SupabaseClient _supabase;

  NotesRepository(this._supabase);

  Future<List<NoteModel>> getClassNotes(String classId) async {
    final response = await _supabase
        .from('class_notes')
        .select('*, profiles(full_name)')
        .eq('class_id', classId)
        .order('created_at', ascending: false);
    
    return (response as List).map((json) => NoteModel.fromJson(json)).toList();
  }

  Future<NoteModel> createNote(String classId, String content) async {
    final userId = _supabase.auth.currentUser!.id;
    final response = await _supabase.from('class_notes').insert({
      'class_id': classId,
      'user_id': userId,
      'content': content,
    }).select().single();
    
    return NoteModel.fromJson(response);
  }
}
