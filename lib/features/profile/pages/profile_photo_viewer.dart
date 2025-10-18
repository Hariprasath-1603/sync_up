import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../core/theme.dart';

/// Full-screen profile photo viewer with action buttons
class ProfilePhotoViewer extends StatefulWidget {
  const ProfilePhotoViewer({
    super.key,
    required this.photoUrl,
    required this.username,
    this.isOwnProfile = false,
    this.onFollow,
    this.onShare,
    this.onCopyLink,
    this.onQRCode,
  });

  final String photoUrl;
  final String username;
  final bool isOwnProfile;
  final VoidCallback? onFollow;
  final VoidCallback? onShare;
  final VoidCallback? onCopyLink;
  final VoidCallback? onQRCode;

  @override
  State<ProfilePhotoViewer> createState() => _ProfilePhotoViewerState();
}

class _ProfilePhotoViewerState extends State<ProfilePhotoViewer>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;
  final TransformationController _transformationController =
      TransformationController();

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );

    _scaleAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOutCubic,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOut),
    );

    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    _transformationController.dispose();
    super.dispose();
  }

  void _close() {
    HapticFeedback.lightImpact();
    _animationController.reverse().then((_) {
      if (mounted) Navigator.of(context).pop();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: GestureDetector(
        onTap: _close,
        child: Stack(
          fit: StackFit.expand,
          children: [
            // Blurred Background
            FadeTransition(
              opacity: _fadeAnimation,
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 30, sigmaY: 30),
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.black.withOpacity(0.8),
                        Colors.black.withOpacity(0.95),
                        Colors.black,
                      ],
                    ),
                  ),
                ),
              ),
            ),

            // Profile Photo (Pinch to Zoom)
            Center(
              child: ScaleTransition(
                scale: _scaleAnimation,
                child: InteractiveViewer(
                  transformationController: _transformationController,
                  minScale: 1.0,
                  maxScale: 3.0,
                  child: Hero(
                    tag: 'profile_photo_${widget.username}',
                    child: Container(
                      width: MediaQuery.of(context).size.width * 0.7,
                      height: MediaQuery.of(context).size.width * 0.7,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: kPrimary.withOpacity(0.3),
                            blurRadius: 40,
                            spreadRadius: 10,
                          ),
                        ],
                      ),
                      child: ClipOval(
                        child: Image.network(
                          widget.photoUrl,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => Container(
                            color: Colors.grey[800],
                            child: const Icon(
                              Icons.person,
                              size: 100,
                              color: Colors.white54,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),

            // Top Close Button
            Positioned(
              top: MediaQuery.of(context).padding.top + 16,
              right: 16,
              child: FadeTransition(
                opacity: _fadeAnimation,
                child: GestureDetector(
                  onTap: _close,
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.5),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.close,
                      color: Colors.white,
                      size: 24,
                    ),
                  ),
                ),
              ),
            ),

            // Bottom Action Buttons
            Positioned(
              bottom:
                  MediaQuery.of(context).padding.bottom +
                  100, // Increased from 30 to 100 to clear nav bar
              left: 0,
              right: 0,
              child: FadeTransition(
                opacity: _fadeAnimation,
                child: _buildActionButtons(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButtons() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          // Follow/Edit Button (show only if not own profile)
          if (!widget.isOwnProfile)
            _buildActionButton(
              icon: Icons.person_add_outlined,
              label: 'Follow',
              onTap: () {
                HapticFeedback.mediumImpact();
                widget.onFollow?.call();
                _close();
              },
            ),

          // Share Profile
          _buildActionButton(
            icon: Icons.send_outlined,
            label: 'Share profile',
            onTap: () {
              HapticFeedback.lightImpact();
              widget.onShare?.call();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Share profile coming soon!'),
                  duration: Duration(seconds: 2),
                ),
              );
            },
          ),

          // Copy Link
          _buildActionButton(
            icon: Icons.link_outlined,
            label: 'Copy link',
            onTap: () {
              HapticFeedback.lightImpact();
              widget.onCopyLink?.call();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Profile link copied!'),
                  duration: Duration(seconds: 2),
                ),
              );
              _close();
            },
          ),

          // QR Code
          _buildActionButton(
            icon: Icons.qr_code_2_outlined,
            label: 'QR code',
            onTap: () {
              HapticFeedback.lightImpact();
              widget.onQRCode?.call();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('QR code coming soon!'),
                  duration: Duration(seconds: 2),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Icon Container
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.15),
              shape: BoxShape.circle,
              border: Border.all(
                color: Colors.white.withOpacity(0.2),
                width: 1,
              ),
            ),
            child: Icon(icon, color: Colors.white, size: 26),
          ),
          const SizedBox(height: 8),
          // Label
          Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
