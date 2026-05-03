import 'package:supabase_flutter/supabase_flutter.dart';
import '../domain/class_model.dart';

class ClassesRepository {
  final SupabaseClient _supabase;

  ClassesRepository(this._supabase);

  Future<List<ClassModel>> getMyClasses() async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) return [];
    
    // We join the class_members table to get classes the user is a part of
    final response = await _supabase
        .from('classes')
        .select('*, class_members!inner(user_id)')
        .eq('class_members.user_id', userId)
        .order('created_at', ascending: false);

    return (response as List).map((json) => ClassModel.fromJson(json)).toList();
  }

  Future<List<ClassModel>> getDiscoverClasses() async {
    final response = await _supabase
        .from('classes')
        .select()
        .eq('is_private', false)
        .order('created_at', ascending: false);
        
    return (response as List).map((json) => ClassModel.fromJson(json)).toList();
  }

  Future<List<ClassModel>> searchPublicClasses(String query) async {
    if (query.trim().isEmpty) {
      return getDiscoverClasses();
    }
    
    final response = await _supabase
        .from('classes')
        .select()
        .eq('is_private', false)
        .or('name.ilike.%${query.trim()}%,description.ilike.%${query.trim()}%')
        .order('created_at', ascending: false);
        
    return (response as List).map((json) => ClassModel.fromJson(json)).toList();
  }

  Future<ClassModel> createClass({
    required String name,
    required String description,
    required bool isPrivate,
    String? category,
  }) async {
    final userId = _supabase.auth.currentUser!.id;
    
    final response = await _supabase.from('classes').insert({
      'name': name,
      'description': description.isEmpty ? null : description,
      'is_private': isPrivate,
      'category': category,
      'created_by': userId,
    }).select().single();

    try {
      await _supabase.from('class_members').insert({
        'class_id': response['id'],
        'user_id': userId,
        'role': 'admin',
      });
    } catch (_) {
      // Ignore in case a backend trigger already inserted the member
    }
    
    return ClassModel.fromJson(response);
  }

  Future<void> updateClass({
    required String classId,
    required String name,
    required String description,
    required bool isPrivate,
    String? category,
  }) async {
    await _supabase.from('classes').update({
      'name': name,
      'description': description.isEmpty ? null : description,
      'is_private': isPrivate,
      'category': category,
    }).eq('id', classId);
  }

  Future<void> deleteClass(String classId) async {
    await _supabase.from('classes').delete().eq('id', classId);
  }

  Future<void> leaveClass(String classId) async {
    final userId = _supabase.auth.currentUser!.id;
    await _supabase.from('class_members').delete().match({
      'class_id': classId,
      'user_id': userId,
    });
  }

  Future<void> joinClass({String? classId, String? inviteCode}) async {
    if ((classId == null || classId.isEmpty) && (inviteCode == null || inviteCode.isEmpty)) {
      throw Exception('Must provide either classId or inviteCode');
    }
    
    final userId = _supabase.auth.currentUser!.id;

    if (inviteCode != null && inviteCode.isNotEmpty) {
      // Find and join class by invite code using RPC to bypass RLS restrictions
      final cleanCode = inviteCode.trim().toUpperCase();
      final response = await _supabase.rpc('join_class_by_code', params: {'p_invite_code': cleanCode});
      
      if (response == null) {
        throw Exception('Invalid invite code');
      }
      
      // The RPC joins the class_members table automatically. We are done!
      return;
    } else {
      // Join by classId (public classes)
      await _supabase.from('class_members').insert({
        'class_id': classId!,
        'user_id': userId,
        'role': 'member',
      });
    }
  }
}
