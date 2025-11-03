import 'package:flutter/material.dart';
import '../../../core/services/thumbnail_regeneration_service.dart';
import '../../../core/theme.dart';

/// Admin page for regenerating thumbnails for existing videos
class ThumbnailRegenerationPage extends StatefulWidget {
  const ThumbnailRegenerationPage({super.key});

  @override
  State<ThumbnailRegenerationPage> createState() =>
      _ThumbnailRegenerationPageState();
}

class _ThumbnailRegenerationPageState extends State<ThumbnailRegenerationPage> {
  bool _isLoading = false;
  int _missingCount = 0;
  Map<String, dynamic>? _lastResult;

  @override
  void initState() {
    super.initState();
    _checkMissingThumbnails();
  }

  Future<void> _checkMissingThumbnails() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final count = await ThumbnailRegenerationService.countMissingThumbnails();
      setState(() {
        _missingCount = count;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error checking thumbnails: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _regenerateAllThumbnails() async {
    // Show confirmation dialog
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Regenerate Thumbnails'),
        content: Text(
          'This will regenerate thumbnails for $_missingCount videos. '
          'This may take several minutes depending on video sizes.\n\n'
          'Continue?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: kPrimary),
            child: const Text('Regenerate'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() {
      _isLoading = true;
      _lastResult = null;
    });

    try {
      final result =
          await ThumbnailRegenerationService.regenerateAllMissingThumbnails();
      setState(() {
        _lastResult = result;
        _isLoading = false;
      });

      // Refresh count
      await _checkMissingThumbnails();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Processed: ${result['processed']}, Failed: ${result['failed']}',
            ),
            backgroundColor: result['success'] == true
                ? Colors.green
                : Colors.red,
            duration: const Duration(seconds: 5),
          ),
        );
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Thumbnail Regeneration'),
        backgroundColor: isDark ? kDarkBackground : kLightBackground,
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: isDark
                ? [kDarkBackground, kDarkBackground.withOpacity(0.8)]
                : [kLightBackground, const Color(0xFFF0F2F8)],
          ),
        ),
        child: _isLoading
            ? const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircularProgressIndicator(color: kPrimary),
                    SizedBox(height: 16),
                    Text('Processing...'),
                  ],
                ),
              )
            : SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Info Card
                    _buildInfoCard(isDark),
                    const SizedBox(height: 24),

                    // Status Card
                    _buildStatusCard(isDark),
                    const SizedBox(height: 24),

                    // Action Button
                    if (_missingCount > 0)
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: _regenerateAllThumbnails,
                          icon: const Icon(Icons.refresh_rounded),
                          label: Text('Regenerate $_missingCount Thumbnails'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: kPrimary,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                      ),

                    const SizedBox(height: 16),

                    // Refresh Button
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: _checkMissingThumbnails,
                        icon: const Icon(Icons.sync_rounded),
                        label: const Text('Check Again'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: kPrimary,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          side: const BorderSide(color: kPrimary),
                        ),
                      ),
                    ),

                    // Results Card
                    if (_lastResult != null) ...[
                      const SizedBox(height: 24),
                      _buildResultsCard(isDark),
                    ],
                  ],
                ),
              ),
      ),
    );
  }

  Widget _buildInfoCard(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: (isDark ? Colors.white : Colors.black).withOpacity(0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: (isDark ? Colors.white : Colors.black).withOpacity(0.1),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.info_outline_rounded, color: kPrimary, size: 24),
              const SizedBox(width: 12),
              Text(
                'About This Tool',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : Colors.black87,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            'This tool regenerates missing thumbnails for video posts. '
            'It downloads each video temporarily, generates a thumbnail, '
            'uploads it to storage, and updates the database.',
            style: TextStyle(
              fontSize: 14,
              color: isDark ? Colors.white70 : Colors.black54,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusCard(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [kPrimary.withOpacity(0.1), kPrimary.withOpacity(0.05)],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: kPrimary.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: kPrimary.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              _missingCount > 0
                  ? Icons.warning_amber_rounded
                  : Icons.check_circle_rounded,
              color: _missingCount > 0 ? Colors.orange : Colors.green,
              size: 32,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$_missingCount Videos',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : Colors.black87,
                  ),
                ),
                Text(
                  _missingCount > 0
                      ? 'without thumbnails'
                      : 'All videos have thumbnails!',
                  style: TextStyle(
                    fontSize: 14,
                    color: isDark ? Colors.white70 : Colors.black54,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildResultsCard(bool isDark) {
    final result = _lastResult!;
    final success = result['success'] == true;
    final processed = result['processed'] ?? 0;
    final failed = result['failed'] ?? 0;
    final failedIds = result['failedIds'] as List<String>? ?? [];

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: (isDark ? Colors.white : Colors.black).withOpacity(0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: (isDark ? Colors.white : Colors.black).withOpacity(0.1),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                success
                    ? Icons.check_circle_rounded
                    : Icons.error_outline_rounded,
                color: success ? Colors.green : Colors.red,
                size: 24,
              ),
              const SizedBox(width: 12),
              Text(
                'Last Results',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : Colors.black87,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildResultRow(
            'Processed',
            processed.toString(),
            Colors.green,
            isDark,
          ),
          const SizedBox(height: 8),
          _buildResultRow('Failed', failed.toString(), Colors.red, isDark),
          if (failedIds.isNotEmpty) ...[
            const SizedBox(height: 12),
            Text(
              'Failed Post IDs:',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: isDark ? Colors.white70 : Colors.black54,
              ),
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.red.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                failedIds.join('\n'),
                style: TextStyle(
                  fontSize: 10,
                  fontFamily: 'monospace',
                  color: isDark ? Colors.white54 : Colors.black45,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildResultRow(String label, String value, Color color, bool isDark) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 14,
            color: isDark ? Colors.white70 : Colors.black54,
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            value,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ),
      ],
    );
  }
}
