/// Helper class to populate database with sample data for testing
/// TODO: Implement with Supabase when needed
class SampleDataPopulator {
  /// Add sample posts to database
  Future<void> addSamplePosts() async {
    print('TODO: Implement addSamplePosts with Supabase');
    print('Sample data population not yet implemented for Supabase');
  }

  /// Add sample users (for testing Following feature)
  Future<void> addSampleUsers() async {
    print('TODO: Implement addSampleUsers with Supabase');
    print('Sample data population not yet implemented for Supabase');
  }

  /// Clear all sample posts (use with caution!)
  Future<void> clearAllPosts() async {
    print('TODO: Implement clearAllPosts with Supabase');
    print('Sample data clearing not yet implemented for Supabase');
  }
}

/// Quick function to run the sample data populator
/// Call this from your app (e.g., from a debug menu button)
Future<void> populateSampleData() async {
  final populator = SampleDataPopulator();
  await populator.addSamplePosts();
  await populator.addSampleUsers();
}
