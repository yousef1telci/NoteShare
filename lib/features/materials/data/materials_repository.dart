import 'dart:io' as io;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:file_picker/file_picker.dart';
import '../domain/material_model.dart';

class MaterialsRepository {
  final SupabaseClient _supabase;

  MaterialsRepository(this._supabase);

  Future<List<MaterialModel>> getClassMaterials(String classId) async {
    final response = await _supabase
        .from('materials')
        .select('*, profiles(full_name)')
        .eq('class_id', classId)
        .order('created_at', ascending: false);
    
    return (response as List).map((json) => MaterialModel.fromJson(json)).toList();
  }

  Future<void> uploadMaterial(String classId, PlatformFile file) async {
    final userId = _supabase.auth.currentUser!.id;
    // Sanitize filename to avoid issues
    final sanitizedName = file.name.replaceAll(RegExp(r'[^a-zA-Z0-9.\-]'), '_');
    final fileName = '${DateTime.now().millisecondsSinceEpoch}_$sanitizedName';
    final filePath = '$classId/$fileName';
    final fileType = file.extension ?? 'unknown';

    String savedPath;
    if (kIsWeb) {
      if (file.bytes != null) {
        savedPath = await _supabase.storage.from('materials').uploadBinary(filePath, file.bytes!);
      } else {
        throw Exception('Unable to get file data on Web');
      }
    } else {
      if (file.path != null) {
        final uploadFile = io.File(file.path!);
        savedPath = await _supabase.storage.from('materials').upload(filePath, uploadFile);
      } else if (file.bytes != null) {
        savedPath = await _supabase.storage.from('materials').uploadBinary(filePath, file.bytes!);
      } else {
        throw Exception('Unable to get file data');
      }
    }

    // In some versions of the Supabase SDK, upload returns the path WITH the bucket name 
    // (e.g., 'materials/classId/fileName'). We must strip it for createSignedUrl to work.
    if (savedPath.startsWith('materials/')) {
      savedPath = savedPath.replaceFirst('materials/', '');
    }
    // Also remove any leading slash
    if (savedPath.startsWith('/')) {
      savedPath = savedPath.substring(1);
    }

    print('=== DEBUG DB INSERT PATH: $savedPath ===');
    await _supabase.from('materials').insert({
      'class_id': classId,
      'uploaded_by': userId,
      'title': file.name,
      'file_url': savedPath,
      'file_type': fileType,
    });
  }

  Future<String> getMaterialUrl(String fileUrl) async {
    // If the database accidentally stored the full URL (e.g., during previous tests), extract just the path
    String path = fileUrl;
    if (path.contains('/object/public/materials/')) {
      path = path.split('/object/public/materials/').last;
    }
    if (path.startsWith('/')) {
      path = path.substring(1);
    }
    
    print('=== DEBUG REQUESTED PATH: $path ===');
    // Generate a signed URL valid for 1 hour
    return await _supabase.storage.from('materials').createSignedUrl(path, 3600);
  }

  Future<void> deleteMaterial(String materialId, String fileUrl) async {
    String path = fileUrl;
    if (path.contains('/object/public/materials/')) {
      path = path.split('/object/public/materials/').last;
    }
    if (path.startsWith('/')) {
      path = path.substring(1);
    }
    
    // 1. Delete from storage bucket
    await _supabase.storage.from('materials').remove([path]);
    
    // 2. Delete from database
    await _supabase.from('materials').delete().eq('id', materialId);
  }

  Future<void> toggleBookmark(String materialId, bool isBookmarked) async {
    final userId = _supabase.auth.currentUser!.id;
    if (isBookmarked) {
      // Remove bookmark
      await _supabase.from('bookmarks').delete()
          .eq('user_id', userId)
          .eq('material_id', materialId);
    } else {
      // Add bookmark
      await _supabase.from('bookmarks').insert({
        'user_id': userId,
        'material_id': materialId,
      });
    }
  }

  Future<Set<String>> getBookmarkedMaterialIds() async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) return {};
    
    final response = await _supabase
        .from('bookmarks')
        .select('material_id')
        .eq('user_id', userId);
        
    return (response as List).map((row) => row['material_id'] as String).toSet();
  }

  Future<List<MaterialModel>> getBookmarkedMaterials() async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) return [];
    
    // Join materials and bookmarks to get only bookmarked materials for the current user
    final response = await _supabase
        .from('materials')
        .select('*, bookmarks!inner(*), profiles(full_name)')
        .eq('bookmarks.user_id', userId)
        .order('created_at', ascending: false);
        
    return (response as List).map((json) => MaterialModel.fromJson(json)).toList();
  }
}
