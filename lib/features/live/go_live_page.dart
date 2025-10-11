import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'models/live_stream_model.dart';
import 'live_host_page.dart';

class GoLivePage extends StatefulWidget {
  const GoLivePage({super.key});

  @override
  State<GoLivePage> createState() => _GoLivePageState();
}

class _GoLivePageState extends State<GoLivePage> {
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();

  StreamPrivacy _privacy = StreamPrivacy.public;
  MonetizationType _monetization = MonetizationType.none;
  String? _category;
  XFile? _coverImage;
  DateTime? _scheduledTime;
  double _ticketPrice = 5.0;
  bool _enableRecording = true;
  bool _allowComments = true;
  bool _allowReactions = true;
  bool _allowGuestRequests = true;

  final List<String> _categories = [
    'Gaming',
    'Music',
    'Sports',
    'Education',
    'Entertainment',
    'Talk Show',
    'Just Chatting',
    'Cooking',
    'Art & Crafts',
    'Fitness',
    'Technology',
    'Business',
  ];

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Color _getBackgroundColor(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark
        ? const Color(0xFF0F1419)
        : const Color(0xFFF8F9FA);
  }

  Color _getCardColor(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark
        ? const Color(0xFF1A1D24)
        : Colors.white;
  }

  Color _getTextColor(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark
        ? Colors.white
        : Colors.black;
  }

  Color _getSubtitleColor(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark
        ? const Color(0xFF8899A6)
        : const Color(0xFF536471);
  }

  Color _getBorderColor(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark
        ? const Color(0xFF2F3336)
        : const Color(0xFFE1E8ED);
  }

  void _showSnackBar(String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Future<void> _pickCoverImage() async {
    try {
      final picker = ImagePicker();
      final image = await picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 80,
      );

      if (image != null) {
        setState(() {
          _coverImage = image;
        });
        _showSnackBar('Cover image selected', const Color(0xFF4A6CF7));
      }
    } catch (e) {
      _showSnackBar('Error selecting image', Colors.red);
    }
  }

  Future<void> _selectScheduledTime() async {
    final date = await showDatePicker(
      context: context,
      initialDate: DateTime.now().add(const Duration(hours: 1)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 30)),
    );

    if (date != null && mounted) {
      final time = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.now(),
      );

      if (time != null && mounted) {
        setState(() {
          _scheduledTime = DateTime(
            date.year,
            date.month,
            date.day,
            time.hour,
            time.minute,
          );
        });
      }
    }
  }

  void _startLiveStream() {
    if (_titleController.text.trim().isEmpty) {
      _showSnackBar('Please enter a title', Colors.orange);
      return;
    }

    if (_monetization == MonetizationType.ticket && _ticketPrice <= 0) {
      _showSnackBar('Please set a valid ticket price', Colors.orange);
      return;
    }

    // Create stream model
    final stream = LiveStreamModel(
      id: 'stream_${DateTime.now().millisecondsSinceEpoch}',
      hostId: 'current_user_id', // TODO: Get from auth
      hostUsername: 'current_username', // TODO: Get from auth
      title: _titleController.text.trim(),
      description: _descriptionController.text.trim(),
      category: _category,
      privacy: _privacy,
      monetizationType: _monetization,
      ticketPrice: _monetization == MonetizationType.ticket
          ? _ticketPrice
          : null,
      scheduledFor: _scheduledTime,
      createdAt: DateTime.now(),
      allowComments: _allowComments,
      allowReactions: _allowReactions,
      allowGuestRequests: _allowGuestRequests,
      isRecording: _enableRecording,
    );

    // Navigate to host page
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => LiveHostPage(stream: stream)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _getBackgroundColor(context),
      appBar: AppBar(
        backgroundColor: _getCardColor(context),
        leading: IconButton(
          icon: Icon(Icons.close, color: _getTextColor(context)),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text('Go Live', style: TextStyle(color: _getTextColor(context))),
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Cover Image
                  GestureDetector(
                    onTap: _pickCoverImage,
                    child: Container(
                      width: double.infinity,
                      height: 200,
                      decoration: BoxDecoration(
                        color: _getCardColor(context),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: _getBorderColor(context),
                          width: 2,
                          style: BorderStyle.solid,
                        ),
                      ),
                      child: _coverImage != null
                          ? ClipRRect(
                              borderRadius: BorderRadius.circular(12),
                              child: Image.network(
                                _coverImage!.path,
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) {
                                  return _buildCoverPlaceholder();
                                },
                              ),
                            )
                          : _buildCoverPlaceholder(),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Title
                  Text(
                    'Stream Title *',
                    style: TextStyle(
                      color: _getTextColor(context),
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _titleController,
                    style: TextStyle(color: _getTextColor(context)),
                    maxLength: 100,
                    decoration: InputDecoration(
                      hintText: 'Give your stream a catchy title...',
                      hintStyle: TextStyle(color: _getSubtitleColor(context)),
                      filled: true,
                      fillColor: _getCardColor(context),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: _getBorderColor(context)),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: _getBorderColor(context)),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Description
                  Text(
                    'Description',
                    style: TextStyle(
                      color: _getTextColor(context),
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _descriptionController,
                    style: TextStyle(color: _getTextColor(context)),
                    maxLines: 3,
                    maxLength: 500,
                    decoration: InputDecoration(
                      hintText: 'Tell viewers what your stream is about...',
                      hintStyle: TextStyle(color: _getSubtitleColor(context)),
                      filled: true,
                      fillColor: _getCardColor(context),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: _getBorderColor(context)),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: _getBorderColor(context)),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Category
                  Text(
                    'Category',
                    style: TextStyle(
                      color: _getTextColor(context),
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: _categories.map((cat) {
                      final isSelected = _category == cat;
                      return GestureDetector(
                        onTap: () {
                          setState(() {
                            _category = isSelected ? null : cat;
                          });
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? const Color(0xFF4A6CF7)
                                : _getCardColor(context),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: isSelected
                                  ? const Color(0xFF4A6CF7)
                                  : _getBorderColor(context),
                            ),
                          ),
                          child: Text(
                            cat,
                            style: TextStyle(
                              color: isSelected
                                  ? Colors.white
                                  : _getTextColor(context),
                              fontWeight: isSelected
                                  ? FontWeight.bold
                                  : FontWeight.normal,
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 24),

                  // Privacy
                  _buildSection(
                    'Privacy',
                    Icons.lock,
                    Column(
                      children: [
                        _buildPrivacyOption(
                          StreamPrivacy.public,
                          'Public',
                          'Anyone can watch',
                          Icons.public,
                        ),
                        _buildPrivacyOption(
                          StreamPrivacy.friendsOnly,
                          'Friends Only',
                          'Only your friends can watch',
                          Icons.group,
                        ),
                        _buildPrivacyOption(
                          StreamPrivacy.private,
                          'Private',
                          'Only invited viewers',
                          Icons.lock,
                        ),
                        _buildPrivacyOption(
                          StreamPrivacy.paid,
                          'Paid Access',
                          'Viewers need a ticket',
                          Icons.paid,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Monetization
                  _buildSection(
                    'Monetization',
                    Icons.monetization_on,
                    Column(
                      children: [
                        _buildMonetizationOption(
                          MonetizationType.none,
                          'Free',
                          'No monetization',
                        ),
                        _buildMonetizationOption(
                          MonetizationType.tips,
                          'Accept Tips',
                          'Viewers can send tips',
                        ),
                        _buildMonetizationOption(
                          MonetizationType.ticket,
                          'Ticket Sales',
                          'Charge for access',
                        ),
                        if (_monetization == MonetizationType.ticket)
                          Padding(
                            padding: const EdgeInsets.only(top: 12),
                            child: Row(
                              children: [
                                Text(
                                  'Ticket Price: \$',
                                  style: TextStyle(
                                    color: _getTextColor(context),
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                Expanded(
                                  child: Slider(
                                    value: _ticketPrice,
                                    min: 1,
                                    max: 100,
                                    divisions: 99,
                                    label:
                                        '\$${_ticketPrice.toStringAsFixed(0)}',
                                    activeColor: const Color(0xFF4A6CF7),
                                    onChanged: (value) {
                                      setState(() {
                                        _ticketPrice = value;
                                      });
                                    },
                                  ),
                                ),
                                Text(
                                  '\$${_ticketPrice.toStringAsFixed(0)}',
                                  style: TextStyle(
                                    color: const Color(0xFF4A6CF7),
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                  ),
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Settings
                  _buildSection(
                    'Stream Settings',
                    Icons.settings,
                    Column(
                      children: [
                        _buildSettingToggle(
                          'Enable Recording',
                          'Save stream for VOD',
                          _enableRecording,
                          (value) => setState(() => _enableRecording = value),
                        ),
                        _buildSettingToggle(
                          'Allow Comments',
                          'Viewers can chat',
                          _allowComments,
                          (value) => setState(() => _allowComments = value),
                        ),
                        _buildSettingToggle(
                          'Allow Reactions',
                          'Viewers can send reactions',
                          _allowReactions,
                          (value) => setState(() => _allowReactions = value),
                        ),
                        _buildSettingToggle(
                          'Allow Guest Requests',
                          'Viewers can request to join',
                          _allowGuestRequests,
                          (value) =>
                              setState(() => _allowGuestRequests = value),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Schedule (Optional)
                  _buildSection(
                    'Schedule (Optional)',
                    Icons.schedule,
                    Column(
                      children: [
                        if (_scheduledTime != null)
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: const Color(0xFF4A6CF7).withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: const Color(0xFF4A6CF7),
                              ),
                            ),
                            child: Row(
                              children: [
                                const Icon(
                                  Icons.event,
                                  color: Color(0xFF4A6CF7),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Scheduled for:',
                                        style: TextStyle(
                                          color: _getSubtitleColor(context),
                                          fontSize: 12,
                                        ),
                                      ),
                                      Text(
                                        '${_scheduledTime!.day}/${_scheduledTime!.month}/${_scheduledTime!.year} at ${_scheduledTime!.hour}:${_scheduledTime!.minute.toString().padLeft(2, '0')}',
                                        style: TextStyle(
                                          color: _getTextColor(context),
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.close),
                                  color: _getTextColor(context),
                                  onPressed: () {
                                    setState(() {
                                      _scheduledTime = null;
                                    });
                                  },
                                ),
                              ],
                            ),
                          ),
                        const SizedBox(height: 8),
                        OutlinedButton.icon(
                          onPressed: _selectScheduledTime,
                          icon: const Icon(Icons.calendar_today),
                          label: Text(
                            _scheduledTime == null
                                ? 'Schedule Stream'
                                : 'Change Schedule',
                          ),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: const Color(0xFF4A6CF7),
                            side: const BorderSide(color: Color(0xFF4A6CF7)),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 100),
                ],
              ),
            ),
          ),

          // Bottom action button
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: _getCardColor(context),
              border: Border(top: BorderSide(color: _getBorderColor(context))),
            ),
            child: SafeArea(
              child: ElevatedButton.icon(
                onPressed: _startLiveStream,
                icon: const Icon(Icons.videocam),
                label: Text(
                  _scheduledTime == null
                      ? 'Start Live Stream'
                      : 'Schedule Live Stream',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF4A6CF7),
                  foregroundColor: Colors.white,
                  minimumSize: const Size(double.infinity, 50),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCoverPlaceholder() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(
          Icons.add_photo_alternate,
          size: 64,
          color: _getSubtitleColor(context),
        ),
        const SizedBox(height: 12),
        Text(
          'Add Cover Image',
          style: TextStyle(color: _getSubtitleColor(context), fontSize: 16),
        ),
        const SizedBox(height: 4),
        Text(
          'Tap to select',
          style: TextStyle(color: _getSubtitleColor(context), fontSize: 12),
        ),
      ],
    );
  }

  Widget _buildSection(String title, IconData icon, Widget child) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _getCardColor(context),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _getBorderColor(context)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: const Color(0xFF4A6CF7), size: 20),
              const SizedBox(width: 8),
              Text(
                title,
                style: TextStyle(
                  color: _getTextColor(context),
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          child,
        ],
      ),
    );
  }

  Widget _buildPrivacyOption(
    StreamPrivacy privacy,
    String title,
    String subtitle,
    IconData icon,
  ) {
    final isSelected = _privacy == privacy;
    return GestureDetector(
      onTap: () => setState(() => _privacy = privacy),
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isSelected
              ? const Color(0xFF4A6CF7).withOpacity(0.1)
              : _getBackgroundColor(context),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected
                ? const Color(0xFF4A6CF7)
                : _getBorderColor(context),
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              color: isSelected
                  ? const Color(0xFF4A6CF7)
                  : _getSubtitleColor(context),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      color: _getTextColor(context),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: TextStyle(
                      color: _getSubtitleColor(context),
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            if (isSelected)
              const Icon(Icons.check_circle, color: Color(0xFF4A6CF7)),
          ],
        ),
      ),
    );
  }

  Widget _buildMonetizationOption(
    MonetizationType monetization,
    String title,
    String subtitle,
  ) {
    final isSelected = _monetization == monetization;
    return GestureDetector(
      onTap: () => setState(() => _monetization = monetization),
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isSelected
              ? const Color(0xFF4A6CF7).withOpacity(0.1)
              : _getBackgroundColor(context),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected
                ? const Color(0xFF4A6CF7)
                : _getBorderColor(context),
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      color: _getTextColor(context),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: TextStyle(
                      color: _getSubtitleColor(context),
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            if (isSelected)
              const Icon(Icons.check_circle, color: Color(0xFF4A6CF7)),
          ],
        ),
      ),
    );
  }

  Widget _buildSettingToggle(
    String title,
    String subtitle,
    bool value,
    Function(bool) onChanged,
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    color: _getTextColor(context),
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  subtitle,
                  style: TextStyle(
                    color: _getSubtitleColor(context),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeColor: const Color(0xFF4A6CF7),
          ),
        ],
      ),
    );
  }
}
