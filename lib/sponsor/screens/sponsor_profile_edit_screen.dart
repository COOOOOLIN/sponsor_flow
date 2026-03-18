
import 'dart:typed_data';


import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:supabase_flutter/supabase_flutter.dart';

import '../providers/sponsor_dashboard_provider.dart';

/// =========================================================
/// FORMATTERS
/// =========================================================

class AustralianPhoneFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
      TextEditingValue oldValue,
      TextEditingValue newValue,
      ) {
    final digits = newValue.text.replaceAll(RegExp(r'\D'), '');

    if (digits.isEmpty) {
      return const TextEditingValue(text: '');
    }

    String formatted;

    if (digits.length <= 4) {
      formatted = digits;
    } else if (digits.length <= 7) {
      formatted = '${digits.substring(0, 4)}-${digits.substring(4)}';
    } else {
      final trimmed = digits.substring(0, digits.length.clamp(0, 10));
      formatted =
      '${trimmed.substring(0, 4)}-${trimmed.substring(4, 7)}-${trimmed.substring(7)}';
    }

    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }
}

class SentenceCapitalizationFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
      TextEditingValue oldValue,
      TextEditingValue newValue,
      ) {
    final text = newValue.text;

    if (text.isEmpty) return newValue;

    final buffer = StringBuffer();
    bool capitalizeNext = true;

    for (int i = 0; i < text.length; i++) {
      final char = text[i];

      if (capitalizeNext && RegExp(r'[a-zA-Z]').hasMatch(char)) {
        buffer.write(char.toUpperCase());
        capitalizeNext = false;
      } else {
        buffer.write(char);
      }

      if (char == '.') {
        capitalizeNext = true;
      }
    }

    return TextEditingValue(
      text: buffer.toString(),
      selection: newValue.selection,
    );
  }
}


class BusinessNameFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
      TextEditingValue oldValue,
      TextEditingValue newValue,
      ) {
    final text = newValue.text;

    if (text.isEmpty) return newValue;

    // If user pasted ALL CAPS, convert to title case
    if (text == text.toUpperCase()) {
      final words = text.toLowerCase().split(' ');

      final formatted = words.map((word) {
        if (word.isEmpty) return word;
        return word[0].toUpperCase() + word.substring(1);
      }).join(' ');

      return TextEditingValue(
        text: formatted,
        selection: TextSelection.collapsed(offset: formatted.length),
      );
    }

    return newValue;
  }
}


/// =========================================================
/// MODELS
/// =========================================================

class _SponsorActivityOption {
  final String activityId;
  final String activityName;

  const _SponsorActivityOption({
    required this.activityId,
    required this.activityName,
  });
}

/// =========================================================
/// SCREEN
/// =========================================================

class SponsorProfileEditScreen extends ConsumerStatefulWidget {
  final String sponsorId;

  const SponsorProfileEditScreen({
    super.key,
    required this.sponsorId,
  });

  @override
  ConsumerState<SponsorProfileEditScreen> createState() =>
      _SponsorProfileEditScreenState();
}

class _SponsorProfileEditScreenState
    extends ConsumerState<SponsorProfileEditScreen> {



  final _formKey = GlobalKey<FormState>();

  final _aboutCtrl = TextEditingController();
  final _businessNameCtrl = TextEditingController();
  final _websiteCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _instagramCtrl = TextEditingController();
  final _facebookCtrl = TextEditingController();
  final _youtubeCtrl = TextEditingController();
  final _tiktokCtrl = TextEditingController();
  final _twitterCtrl = TextEditingController();
  final _offerTitleCtrl = TextEditingController();
  final _offerDescCtrl = TextEditingController();

  bool _saving = false;
  bool _loaded = false;
  bool _loadingActivityProfile = false;

  Uint8List? _selectedLogo;
  String? _currentLogoUrl;

  List<_SponsorActivityOption> _activities = [];
  String? _selectedActivityId;

  Widget _socialGuideSection(
      BuildContext context, {
        required String title,
        required String example,
        required List<String> steps,
      }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [

          Text(
            title,
            style: const TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w700,
            ),
          ),

          const SizedBox(height: 6),

          Text(
            "Example: $example",
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Colors.grey.shade600,
            ),
          ),

          const SizedBox(height: 10),

          ...steps.map(
                (s) => Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Text(
                s,
                style: const TextStyle(height: 1.4),
              ),
            ),
          ),
        ],
      ),
    );
  }


  void _showSocialHelp(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 10, 24, 32),
            child: ListView(
              children: [

                Text(
                  "How to find your social profile usernames",
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),

                const SizedBox(height: 8),

                Text(
                  "Enter only the username for each platform. "
                      "You do not need to paste the full website link.",
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Colors.grey.shade700,
                  ),
                ),

                const SizedBox(height: 28),

                _socialGuideSection(
                  context,
                  title: "Instagram",
                  example: "instagram.com/sunrise_cafe",
                  steps: [
                    "1. Open the Instagram app.",
                    "2. Tap your profile picture in the bottom right corner.",
                    "3. Your username appears at the top of the screen.",
                    "4. Example: @sunrise_cafe",
                    "5. Enter only: sunrise_cafe",
                  ],
                ),

                _socialGuideSection(
                  context,
                  title: "Facebook Business Page",
                  example: "facebook.com/sunrisecafe",
                  steps: [
                    "1. Open your Facebook Page.",
                    "2. Tap the three dots (•••) under the page header.",
                    "3. Tap 'Copy link' or 'Share page'.",
                    "4. Your page link will look like:",
                    "   facebook.com/sunrisecafe",
                    "5. Enter only: sunrisecafe",
                  ],
                ),

                _socialGuideSection(
                  context,
                  title: "YouTube Channel",
                  example: "youtube.com/@sunrisecafe",
                  steps: [
                    "1. Open the YouTube app.",
                    "2. Tap your profile picture.",
                    "3. Tap 'Your Channel'.",
                    "4. Your channel address will look like:",
                    "   youtube.com/@sunrisecafe",
                    "5. Enter only: sunrisecafe",
                  ],
                ),

                _socialGuideSection(
                  context,
                  title: "TikTok",
                  example: "tiktok.com/@sunrisecafe",
                  steps: [
                    "1. Open the TikTok app.",
                    "2. Tap 'Profile' in the bottom right.",
                    "3. Your username appears under your profile name.",
                    "4. Example: @sunrisecafe",
                    "5. Enter only: sunrisecafe",
                  ],
                ),

                _socialGuideSection(
                  context,
                  title: "X (Twitter)",
                  example: "x.com/sunrisecafe",
                  steps: [
                    "1. Open the X (Twitter) app.",
                    "2. Tap your profile picture.",
                    "3. Your username appears under your display name.",
                    "4. Example: @sunrisecafe",
                    "5. Enter only: sunrisecafe",
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _socialHelpItem(String title, List<String> steps) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [

          Text(
            title,
            style: const TextStyle(
              fontWeight: FontWeight.w700,
              fontSize: 16,
            ),
          ),

          const SizedBox(height: 6),

          ...steps.map(
                (s) => Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Text(
                '• $s',
                style: const TextStyle(height: 1.4),
              ),
            ),
          ),
        ],
      ),
    );
  }



  @override
  void initState() {
    super.initState();
    _loadInitialData();
  }

  @override
  void dispose() {
    _aboutCtrl.dispose();
    _businessNameCtrl.dispose();
    _websiteCtrl.dispose();
    _phoneCtrl.dispose();
    _emailCtrl.dispose();
    _instagramCtrl.dispose();
    _facebookCtrl.dispose();
    _youtubeCtrl.dispose();
    _tiktokCtrl.dispose();
    _twitterCtrl.dispose();
    _offerTitleCtrl.dispose();
    _offerDescCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadInitialData() async {
    final client = Supabase.instance.client;

    try {
      await _loadGlobalSponsorData(client);
      await _loadSponsoredActivities(client);

      if (_selectedActivityId != null) {
        await _loadActivityProfile(_selectedActivityId!);
      }

      if (mounted) {
        setState(() => _loaded = true);
      }
    } catch (e) {
      debugPrint('SponsorProfileEditScreen initial load error: $e');
      if (mounted) {
        setState(() => _loaded = true);
      }
    }
  }

  Future<void> _loadGlobalSponsorData(SupabaseClient client) async {
    final sponsor = await client
        .from('sponsors')
        .select()
        .eq('id', widget.sponsorId)
        .maybeSingle();

    if (sponsor == null) return;

    _businessNameCtrl.text = (sponsor['name'] ?? '').toString();


  }

  Future<void> _loadSponsoredActivities(SupabaseClient client) async {
    final rows = await client
        .from('sponsor_activities')
        .select('activity_id, activities(id, name)')
        .eq('sponsor_id', widget.sponsorId);

    final parsed = <_SponsorActivityOption>[];

    for (final row in rows as List) {
      final map = row as Map<String, dynamic>;
      final activityId = (map['activity_id'] ?? '').toString();
      if (activityId.isEmpty) continue;

      String activityName = 'Activity';

      final activityData = map['activities'];
      if (activityData is Map<String, dynamic>) {
        final name = activityData['name']?.toString();
        if (name != null && name.trim().isNotEmpty) {
          activityName = _formatActivityName(name);
        }
      }

      parsed.add(
        _SponsorActivityOption(
          activityId: activityId,
          activityName: activityName,
        ),
      );
    }

    parsed.sort(
          (a, b) => a.activityName.toLowerCase().compareTo(
        b.activityName.toLowerCase(),
      ),
    );

    _activities = parsed;

    if (_activities.isNotEmpty) {
      _selectedActivityId ??= _activities.first.activityId;
    }
  }

  Future<void> _loadActivityProfile(String activityId) async {
    if (!mounted) return;

    setState(() {
      _loadingActivityProfile = true;
    });

    final client = Supabase.instance.client;

    try {
      final profile = await client
          .from('sponsor_activity_profiles')
          .select('''
  business_name,
  about_text,
  website_url,
  phone,
  email,
  instagram_url,
  facebook_url,
  youtube_url,
  tiktok_url,
  twitter_url,
  offer_title,
  offer_description,
  logo_path
''')
          .eq('sponsor_id', widget.sponsorId)
          .eq('activity_id', activityId)
          .maybeSingle();

      _businessNameCtrl.text = (profile?['business_name'] ?? '').toString();
      _aboutCtrl.text = (profile?['about_text'] ?? '').toString();
      _websiteCtrl.text = (profile?['website_url'] ?? '').toString();
      _phoneCtrl.text = (profile?['phone'] ?? '').toString();
      _emailCtrl.text = (profile?['email'] ?? '').toString();
      _instagramCtrl.text =
          _extractUsername(profile?['instagram_url']?.toString());
      _facebookCtrl.text =
          _extractUsername(profile?['facebook_url']?.toString());
      _youtubeCtrl.text =
          _extractUsername(profile?['youtube_url']?.toString());
      _tiktokCtrl.text =
          _extractUsername(profile?['tiktok_url']?.toString());
      _twitterCtrl.text =
          _extractUsername(profile?['twitter_url']?.toString());

      _offerTitleCtrl.text = (profile?['offer_title'] ?? '').toString();
      _offerDescCtrl.text = (profile?['offer_description'] ?? '').toString();

      final logoPath = profile?['logo_path']?.toString();

      if (logoPath != null && logoPath.trim().isNotEmpty) {
        final publicUrl =
        client.storage.from('sponsor-logos').getPublicUrl(logoPath);

        _currentLogoUrl =
        '$publicUrl?v=${DateTime.now().millisecondsSinceEpoch}';
      } else {
        _currentLogoUrl = null;
      }
    } catch (e) {
      debugPrint('Activity profile load error: $e');
      _clearActivityProfileControllers();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Could not load activity profile: $e'),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _loadingActivityProfile = false;
        });
      }
    }
  }

  void _clearActivityProfileControllers() {
    _aboutCtrl.clear();
    _websiteCtrl.clear();
    _phoneCtrl.clear();
    _emailCtrl.clear();
    _instagramCtrl.clear();
    _facebookCtrl.clear();
    _youtubeCtrl.clear();
    _tiktokCtrl.clear();
    _twitterCtrl.clear();
  }

  Future<void> _pickLogo() async {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Logo upload not available on web yet'),
      ),
    );
  }

  Future<void> _uploadLogoIfNeeded() async {
    if (_selectedLogo == null) return;

    final client = Supabase.instance.client;

    final path =
        '${widget.sponsorId}/logo_${DateTime.now().millisecondsSinceEpoch}.png';

    try {
      final response = await client.storage.from('sponsor-logos').uploadBinary(
        path,
        _selectedLogo!,
        fileOptions: const FileOptions(
          upsert: true,
          contentType: 'image/png',
        ),
      );

      debugPrint('UPLOAD RESULT: $response');

      await client
          .from('sponsors')
          .update({'logo_path': path})
          .eq('id', widget.sponsorId);

      final publicUrl = client.storage.from('sponsor-logos').getPublicUrl(path);

      if (!mounted) return;

      setState(() {
        _currentLogoUrl = '$publicUrl?v=${DateTime.now().millisecondsSinceEpoch}';
        _selectedLogo = null;
      });

      imageCache.clear();
      imageCache.clearLiveImages();
    } catch (e) {
      debugPrint('UPLOAD ERROR: $e');

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Logo upload failed: $e')),
        );
      }
    }
  }

  Future<void> _onActivitySelected(String activityId) async {
    if (activityId == _selectedActivityId) return;

    setState(() {
      _selectedActivityId = activityId;

      // clear controllers immediately so stale data cannot be saved
      _aboutCtrl.clear();
      _websiteCtrl.clear();
      _phoneCtrl.clear();
      _emailCtrl.clear();
      _instagramCtrl.clear();
      _facebookCtrl.clear();
      _youtubeCtrl.clear();
      _tiktokCtrl.clear();
      _twitterCtrl.clear();

      _loadingActivityProfile = true;
    });

    await _loadActivityProfile(activityId);
  }

  String _extractUsername(String? url) {
    final text = (url ?? '').trim();
    if (text.isEmpty) return '';

    try {
      final uri = Uri.parse(text);
      if (uri.pathSegments.isNotEmpty) {
        return uri.pathSegments.last.replaceAll('@', '');
      }
    } catch (_) {}

    return text
        .replaceAll('https://', '')
        .replaceAll('http://', '')
        .split('/')
        .last
        .replaceAll('@', '');
  }

  String _buildSocialUrl(String username, String base) {
    final trimmed = username.trim();
    if (trimmed.isEmpty) return '';
    return '$base/$trimmed';
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    final activityId = _selectedActivityId;

    if (activityId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No sponsored activity was found.')),
      );
      return;
    }

    setState(() => _saving = true);

    final client = Supabase.instance.client;

    try {
      final businessName = _businessNameCtrl.text.trim();
      final aboutText = _aboutCtrl.text.trim();
      final websiteUrl = _websiteCtrl.text.trim();
      final phone = _phoneCtrl.text.trim();
      final email = _emailCtrl.text.trim();
      final instagramUrl =
      _buildSocialUrl(_instagramCtrl.text, 'https://instagram.com');

      final facebookUrl =
      _buildSocialUrl(_facebookCtrl.text, 'https://facebook.com');

      final youtubeUrl =
      _buildSocialUrl(_youtubeCtrl.text, 'https://youtube.com/@');

      final tiktokUrl =
      _buildSocialUrl(_tiktokCtrl.text, 'https://tiktok.com/@');

      final twitterUrl =
      _buildSocialUrl(_twitterCtrl.text, 'https://x.com');
      final offerTitle = _offerTitleCtrl.text.trim();
      final offerDescription = _offerDescCtrl.text.trim();

      /// ---------------------------------------------------------
      /// UPSERT ACTIVITY PROFILE
      /// ---------------------------------------------------------

      await client.rpc(
        'rpc_update_sponsor_profile_v1',
        params: {
          'p_sponsor_id': widget.sponsorId,
          'p_activity_id': activityId,
          'p_business_name': businessName,
          'p_about_text': aboutText,
          'p_website_url': websiteUrl,
          'p_phone': phone,
          'p_email': email,
          'p_instagram_url': instagramUrl,
          'p_facebook_url': facebookUrl,
          'p_youtube_url': youtubeUrl,
          'p_tiktok_url': tiktokUrl,
          'p_twitter_url': twitterUrl,
          'p_offer_title': offerTitle,
          'p_offer_description': offerDescription,
        },
      );

      /// ---------------------------------------------------------
      /// UPLOAD ACTIVITY-SPECIFIC LOGO
      /// ---------------------------------------------------------

      if (_selectedLogo != null) {
        final path =
            '${widget.sponsorId}/$activityId/logo_${DateTime.now().millisecondsSinceEpoch}.png';

        await client.storage.from('sponsor-logos').uploadBinary(
          path,
          _selectedLogo!,
          fileOptions: const FileOptions(
            upsert: true,
            contentType: 'image/png',
          ),
        );

        await client
            .from('sponsor_activity_profiles')
            .update({'logo_path': path})
            .eq('sponsor_id', widget.sponsorId)
            .eq('activity_id', activityId);

        final publicUrl =
        client.storage.from('sponsor-logos').getPublicUrl(path);

        if (mounted) {
          setState(() {
            _currentLogoUrl =
            '$publicUrl?v=${DateTime.now().millisecondsSinceEpoch}';
            _selectedLogo = null;
          });
        }
      }

      /// ---------------------------------------------------------
      /// REFRESH DASHBOARD
      /// ---------------------------------------------------------

      ref.invalidate(sponsorDashboardProvider);

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Updated ${_selectedActivityLabel ?? 'activity'} profile successfully',
          ),
        ),
      );

      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error saving profile: $e')),
      );
    } finally {
      if (mounted) {
        setState(() => _saving = false);
      }
    }
  }

  String? get _selectedActivityLabel {
    final activity = _activities.cast<_SponsorActivityOption?>().firstWhere(
          (a) => a?.activityId == _selectedActivityId,
      orElse: () => null,
    );
    return activity?.activityName;
  }

  String _formatActivityName(String raw) {
    final cleaned = raw.replaceAll('_', ' ').trim();
    if (cleaned.isEmpty) return 'Activity';

    return cleaned
        .split(RegExp(r'\s+'))
        .map((word) {
      if (word.isEmpty) return word;
      return word[0].toUpperCase() + word.substring(1);
    })
        .join(' ');
  }

  String? _basicUrlValidator(String? value) {
    final text = (value ?? '').trim();
    if (text.isEmpty) return null;

    final uri = Uri.tryParse(text);
    if (uri == null || !uri.hasScheme || uri.host.isEmpty) {
      return 'Enter a valid URL including https://';
    }
    return null;
  }

  String? _basicEmailValidator(String? value) {
    final text = (value ?? '').trim();
    if (text.isEmpty) return null;

    final regex = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');
    if (!regex.hasMatch(text)) {
      return 'Enter a valid email address';
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    if (!_loaded) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final hasActivities = _activities.isNotEmpty;

    return Scaffold(
      backgroundColor: const Color(0xFFF7F9FC),

      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        title: const Text(
          'Business Profile',
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
      ),

      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
          children: [
            _HeaderBlock(
              selectedActivityLabel: _selectedActivityLabel,
            ),
            const SizedBox(height: 20),

            if (!hasActivities)
              const _EmptyActivitiesCard()
            else ...[
              _ActivitySelectorCard(
                activities: _activities,
                selectedActivityId: _selectedActivityId,
                onSelected: _onActivitySelected,
                loading: _loadingActivityProfile,
              ),
              const SizedBox(height: 24),
            ],

            /// BRAND IDENTITY
            _SectionCard(
              title: 'Brand Identity',
              subtitle:
              'Use your official business name or an eye-catching brand that helps users recognise and remember your venue. This name and logo appear across all of your sponsored activities.',
              icon: Icons.storefront_outlined,
              child: Column(
                children: [
                  _input(
                    _businessNameCtrl,
                    'Business name',
                    Icons.storefront_outlined,
                    maxLength: 30,
                    formatters: [
                      BusinessNameFormatter(),
                    ],
                  ),
                  const SizedBox(height: 8),
                  LayoutBuilder(
                    builder: (context, constraints) {
                      final isNarrow = constraints.maxWidth < 400;

                      if (isNarrow) {
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildLogoPreview(),
                            const SizedBox(height: 16),
                            SizedBox(
                              width: double.infinity,
                              child: OutlinedButton.icon(
                                icon: const Icon(Icons.image_outlined),
                                label: const Text('Change logo'),
                                onPressed: _saving ? null : _pickLogo,
                              ),
                            ),
                          ],
                        );
                      }

                      return Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Expanded(
                            flex: 3,
                            child: _buildLogoPreview(),
                          ),
                          const SizedBox(width: 24),
                          Expanded(
                            flex: 2,
                            child: Align(
                              alignment: Alignment.centerLeft,
                              child: OutlinedButton.icon(
                                icon: const Icon(Icons.image_outlined),
                                label: const Text('Change logo'),
                                onPressed: _saving ? null : _pickLogo,
                              ),
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            /// ACTIVITY PROFILE
            _SectionCard(
              title: 'Activity Profile',
              subtitle: hasActivities
                  ? 'These details are saved only for ${_selectedActivityLabel ?? 'the selected activity'}.'
                  : 'No sponsored activities were found for this sponsor.',
              icon: Icons.sports_soccer_outlined,
              child: _loadingActivityProfile
                  ? const Padding(
                padding: EdgeInsets.symmetric(vertical: 28),
                child: Center(child: CircularProgressIndicator()),
              )
                  : Column(
                children: [
                  _input(
                    _aboutCtrl,
                    'About your business',
                    Icons.description_outlined,
                    maxLines: 4,
                    maxLength: 600,
                    formatters: [SentenceCapitalizationFormatter()],
                  ),
                  _input(
                    _websiteCtrl,
                    'Website',
                    Icons.language,
                    maxLength: 120,
                    validator: _basicUrlValidator,
                  ),
                  _input(
                    _phoneCtrl,
                    'Phone',
                    Icons.phone_outlined,
                    keyboardType: TextInputType.phone,
                    maxLength: 12,
                    formatters: [AustralianPhoneFormatter()],
                  ),
                  _input(
                    _emailCtrl,
                    'Email',
                    Icons.email_outlined,
                    keyboardType: TextInputType.emailAddress,
                    maxLength: 120,
                    validator: _basicEmailValidator,
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            /// SOCIAL
            _SectionCard(
              title: 'Social Presence',
              subtitle: hasActivities
                  ? 'These links are saved only for ${_selectedActivityLabel ?? 'the selected activity'}.'
                  : 'Social links are activity-specific.',
              icon: Icons.public,
              trailing: IconButton(
                icon: const Icon(Icons.help_outline),
                tooltip: 'How to find your usernames',
                onPressed: () => _showSocialHelp(context),
              ),
              child: _loadingActivityProfile
                  ? const Padding(
                padding: EdgeInsets.symmetric(vertical: 28),
                child: Center(child: CircularProgressIndicator()),
              )
                  : Column(
                children: [
                  _socialInput(context, _instagramCtrl, 'Instagram',
                      Icons.camera_alt_outlined, 'instagram.com/'),
                  _socialInput(context, _facebookCtrl, 'Facebook',
                      Icons.facebook_outlined, 'facebook.com/'),
                  _socialInput(context, _youtubeCtrl, 'YouTube',
                      Icons.play_circle_outline, 'youtube.com/@'),
                  _socialInput(context, _tiktokCtrl, 'TikTok',
                      Icons.music_note_outlined, 'tiktok.com/@'),
                  _socialInput(context, _twitterCtrl, 'X (Twitter)',
                      Icons.alternate_email, 'x.com/'),
                ],
              ),
            ),

            const SizedBox(height: 24),

            /// OFFER
            _SectionCard(
              title: 'Promotional Offer',
              subtitle:
              'Promote a special deal, discount, or incentive to encourage users to visit your venue.',
              icon: Icons.local_offer_outlined,
              child: Column(
                children: [
                  _input(
                    _offerTitleCtrl,
                    'Offer title',
                    Icons.title_outlined,
                    maxLength: 80,
                    formatters: [SentenceCapitalizationFormatter()],
                  ),
                  _input(
                    _offerDescCtrl,
                    'Offer description',
                    Icons.notes_outlined,
                    maxLines: 3,
                    maxLength: 300,
                    formatters: [SentenceCapitalizationFormatter()],
                  ),
                ],
              ),
            ),

            /// Extra padding so last field isn't hidden by button
            const SizedBox(height: 120),
          ],
        ),
      ),

      /// SAFE AREA SAVE BUTTON
      bottomNavigationBar: SafeArea(
        minimum: const EdgeInsets.fromLTRB(20, 8, 20, 16),
        child: SizedBox(
          height: 52,
          child: ElevatedButton(
            onPressed: (_saving || !hasActivities) ? null : _save,
            style: ElevatedButton.styleFrom(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
            child: _saving
                ? const SizedBox(
              height: 20,
              width: 20,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
                : Text(
              hasActivities ? 'Save Changes' : 'No Activities Available',
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 16,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLogoPreview() {
    const borderColor = Color(0xFFE3E7EB);

    return SizedBox(
      width: double.infinity,
      child: AspectRatio(
        aspectRatio: 3 / 1,
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: borderColor),
            color: Colors.white,
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: _selectedLogo != null
                ? Image.memory(
              _selectedLogo!,
              fit: BoxFit.cover,
            )
                : _currentLogoUrl != null &&
                _currentLogoUrl!.trim().isNotEmpty
                ? Image.network(
              _currentLogoUrl!,
              fit: BoxFit.cover,
              key: ValueKey(_currentLogoUrl),
            )
                : const Center(
              child: Icon(
                Icons.storefront_outlined,
                size: 36,
                color: Colors.grey,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _input(
      TextEditingController c,
      String label,
      IconData icon, {
        int maxLines = 1,
        int? maxLength,
        TextInputType? keyboardType,
        List<TextInputFormatter>? formatters,
        String? Function(String?)? validator,
      }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: TextFormField(
        controller: c,
        maxLines: maxLines,
        maxLength: maxLength,
        keyboardType: keyboardType,
        inputFormatters: formatters,
        validator: validator,
        buildCounter: (
            BuildContext context, {
              required int currentLength,
              required bool isFocused,
              int? maxLength,
            }) {
          if (maxLength == null) return null;

          return Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Text(
              '$currentLength / $maxLength',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey.shade600,
              ),
            ),
          );
        },
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: Icon(icon),
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: Color(0xFFE3E7EB)),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: Color(0xFFE3E7EB)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide(color: Theme.of(context).primaryColor),
          ),
        ),
      ),
    );
  }
}


Widget _socialInput(
    BuildContext context,
    TextEditingController controller,
    String label,
    IconData icon,
    String prefix,
    ) {
  return Padding(
    padding: const EdgeInsets.only(bottom: 16),
    child: TextFormField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon),
        prefixText: '$prefix ',
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Color(0xFFE3E7EB)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Color(0xFFE3E7EB)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: Theme.of(context).primaryColor),
        ),
      ),
    ),
  );
}


/// =========================================================
/// ACTIVITY SELECTOR
/// =========================================================

class _ActivitySelectorCard extends StatelessWidget {
  final List<_SponsorActivityOption> activities;
  final String? selectedActivityId;
  final ValueChanged<String> onSelected;
  final bool loading;

  const _ActivitySelectorCard({
    required this.activities,
    required this.selectedActivityId,
    required this.onSelected,
    required this.loading,
  });

  @override
  Widget build(BuildContext context) {
    return _SectionCard(
      title: 'Sponsored Activities',
      subtitle:
      'Select the activity advertisement you want to edit. Each activity profile is managed separately.',
      icon: Icons.tune_outlined,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: activities.map((activity) {
              final selected = activity.activityId == selectedActivityId;

              return GestureDetector(
                onTap: loading ? null : () => onSelected(activity.activityId),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 160),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: selected
                        ? const Color(0xFFE8F2FF)
                        : const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: selected
                          ? Colors.blue
                          : const Color(0xFFE2E8F0),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [

                      if (selected) ...[
                        const Icon(
                          Icons.check,
                          size: 16,
                          color: Colors.blue,
                        ),
                        const SizedBox(width: 6),
                      ],

                      Text(
                        activity.activityName,
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          color: selected
                              ? Colors.blue.shade800
                              : Colors.black87,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
          if (loading) ...[
            const SizedBox(height: 14),
            Row(
              children: [
                const SizedBox(
                  height: 14,
                  width: 14,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
                const SizedBox(width: 10),
                Text(
                  'Loading selected activity profile...',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _EmptyActivitiesCard extends StatelessWidget {
  const _EmptyActivitiesCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE3E7EB)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.info_outline,
            color: Colors.orange.shade700,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'This sponsor does not currently have any linked activities in sponsor_activities, so there is no activity-specific profile to edit yet.',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Colors.grey.shade700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}




/// =========================================================
/// PAINTERS
/// =========================================================



/// =========================================================
/// UI HELPERS
/// =========================================================

class _HeaderBlock extends StatelessWidget {
  final String? selectedActivityLabel;

  const _HeaderBlock({
    this.selectedActivityLabel,
  });

  @override
  Widget build(BuildContext context) {

    final subtitle = selectedActivityLabel == null
        ? 'Manage your business branding and activity advertisements.'
        : 'You are editing the advertisement for $selectedActivityLabel. '
        'Business name and logo remain shared across your sponsor account.';

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE3E7EB)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 12,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [

          Text(
            'Edit Business Profile',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),

          const SizedBox(height: 6),

          Text(
            subtitle,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Colors.grey.shade600,
              height: 1.35,
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final Widget child;
  final Widget? trailing;

  const _SectionCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.child,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {

    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE3E7EB)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(.03),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [

          Row(
            children: [

              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, size: 18),
              ),

              const SizedBox(width: 12),

              Expanded(
                child: Text(
                  title,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),

              if (trailing != null) trailing!,
            ],
          ),

          const SizedBox(height: 6),

          Text(
            subtitle,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Colors.grey.shade600,
              height: 1.35,
            ),
          ),

          const SizedBox(height: 18),

          child,
        ],
      ),
    );
  }
}