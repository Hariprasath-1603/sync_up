/// Supabase Configuration
/// Get these values from: https://app.supabase.com/project/_/settings/api
class SupabaseConfig {
  // Supabase project URL
  static const String supabaseUrl = 'https://cgkexriarshbftnjftlm.supabase.co';

  // Supabase anon/public key
  static const String supabaseAnonKey =
      'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImNna2V4cmlhcnNoYmZ0bmpmdGxtIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjEyMzMzOTEsImV4cCI6MjA3NjgwOTM5MX0.Oqu5iT8z7THNynICZX9p308ZSLUCi9Ld5VWu4zhIqIA'; // Storage bucket names
  static const String profilePhotosBucket = 'profile-photos';
  static const String coverPhotosBucket = 'profile-photos';
  static const String postsBucket = 'posts';
  static const String storiesBucket = 'stories';
}
