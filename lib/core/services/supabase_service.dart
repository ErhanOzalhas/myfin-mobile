import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseService {
  static const String url = 'https://lsiauqlsohdfynwuobqh.supabase.co';

  static const String anonKey = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImxzaWF1cWxzb2hkZnlud3VvYnFoIiwicm9sZSI6ImFub24iLCJpYXQiOjE3ODI3Njg3MTUsImV4cCI6MjA5ODM0NDcxNX0.ObQP-ZPFi4l9Be7SWjndrFNCYWLDW99qWAQzy045B88';

  static SupabaseClient get client => Supabase.instance.client;

  static Future<void> initialize() async {
    await Supabase.initialize(
      url: url,
      anonKey: anonKey,
    );
  }
}
