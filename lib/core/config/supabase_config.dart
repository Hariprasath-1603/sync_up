/// Supabase Configuration
/// 
/// Central configuration for all Supabase services:
/// - Authentication (PKCE flow)
/// - PostgreSQL Database
/// - Storage Buckets
/// 
/// Get these values from: https://app.supabase.com/project/_/settings/api
/// 
/// Security Note: In production, consider using environment variables
/// or secure configuration management instead of hardcoding credentials
class SupabaseConfig {
  // ============================================================================
  // API CREDENTIALS
  // ============================================================================
  
  /// Supabase project URL - unique identifier for your project
  static const String supabaseUrl = 'https://cgkexriarshbftnjftlm.supabase.co';

  /// Supabase anonymous/public key
  /// Safe to expose in client apps - provides row-level security
  /// Real permissions are controlled by Supabase RLS policies
  static const String supabaseAnonKey =
      'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImNna2V4cmlhcnNoYmZ0bmpmdGxtIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjEyMzMzOTEsImV4cCI6MjA3NjgwOTM5MX0.Oqu5iT8z7THNynICZX9p308ZSLUCi9Ld5VWu4zhIqIA';
  
  // ============================================================================
  // STORAGE BUCKETS
  // ============================================================================
  // Each bucket is configured with specific access policies in Supabase dashboard
  
  /// Bucket for user profile pictures (avatars)
  static const String profilePhotosBucket = 'profile-photos';
  
  /// Bucket for profile cover/banner images
  static const String coverPhotosBucket = 'profile-photos';
  
  /// Bucket for regular post images and videos
  static const String postsBucket = 'posts';
  
  /// Bucket for 24-hour story content
  static const String storiesBucket = 'stories';
  
  /// Bucket for short-form vertical video content (TikTok-style)
  static const String reelsBucket = 'reels';
}
