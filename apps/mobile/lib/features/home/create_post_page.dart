import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile/core/aura/aura_action.dart';
import 'package:mobile/core/aura/aura_provider.dart';
import 'package:mobile/core/backend/repositories/impl/providers.dart' hide postRepositoryProvider;
import 'package:mobile/core/events/events.dart';
import 'package:mobile/core/models/post.dart';
import 'package:mobile/core/models/hood.dart';
import 'package:mobile/core/services/draft_service.dart';
import 'package:mobile/core/theme/ora_colors.dart';
import 'package:mobile/core/theme/ora_radius.dart';
import 'package:mobile/core/theme/ora_spacing.dart';
import 'package:mobile/core/theme/ora_typography.dart';
import 'package:mobile/features/home/feed_provider.dart';
import 'package:mobile/features/session/session_provider.dart';
import 'package:mobile/shared/widgets/ora_empty_state.dart';
import 'package:mobile/shared/widgets/ora_loading_indicator.dart';
import 'package:image_picker/image_picker.dart';
import 'package:mobile/core/utils/logger.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class CreatePostPage extends ConsumerStatefulWidget {
  const CreatePostPage({super.key});

  @override
  ConsumerState<CreatePostPage> createState() => _CreatePostPageState();
}

class _CreatePostPageState extends ConsumerState<CreatePostPage> {
  final TextEditingController _textController = TextEditingController();
  final ImagePicker _imagePicker = ImagePicker();
  final DraftService _draftService = DraftService();
  
  String _selectedVisibility = 'Public';
  String? _selectedHoodId;
  String? _selectedImagePath;
  final int _maxCharacters = 500;

  Timer? _debounceTimer;

  final List<Map<String, String>> _visibilityOptions = [
    {'value': 'Public', 'label': 'Public'},
    {'value': 'Friends', 'label': 'Friends'},
    {'value': 'Hood', 'label': 'Hood'},
  ];

  List<HoodModel> _availableHoods = [];
  bool _isLoadingHoods = true;

  @override
  void initState() {
    super.initState();
    _checkForDraft();
    _loadHoods();
  }

  Future<void> _loadHoods() async {
    setState(() => _isLoadingHoods = true);
    final repository = ref.read(hoodRepositoryProvider);
    final hoods = await repository.getHoods();
    
    if (mounted) {
      setState(() {
        if (hoods.isSuccess && hoods.value != null) {
          _availableHoods = hoods.value!.map((h) => HoodModel(
            id: h['id'] as String,
            name: h['name'] as String,
            category: h['category'] as String? ?? '',
            description: h['description'] as String? ?? '',
            memberCount: h['memberCount'] as int? ?? 0,
          )).toList();
        } else {
          _availableHoods = [];
        }
        _isLoadingHoods = false;
      });
    }
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    _textController.dispose();
    super.dispose();
  }

  /// Checks for a saved draft and shows a restore dialog if one exists.
  Future<void> _checkForDraft() async {
    final draft = await _draftService.loadDraft();
    if (draft == null || !mounted) return;

    final brightness = Theme.of(context).brightness;

    final result = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: ORAColors.surface(brightness),
        title: Text(
          'Restore your previous draft?',
          style: ORATypography.title(context).copyWith(
            color: ORAColors.textPrimary(brightness),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, 'discard'),
            child: Text(
              'Discard',
              style: TextStyle(color: ORAColors.error(brightness)),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, 'restore'),
            child: Text(
              'Restore',
              style: TextStyle(color: ORAColors.primary(brightness)),
            ),
          ),
        ],
      ),
    );

    if (result == 'restore' && mounted) {
      _restoreDraft(draft);
    } else if (result == 'discard' && mounted) {
      await _draftService.deleteDraft();
    }
  }

  /// Restores a draft into the form fields.
  void _restoreDraft(DraftPost draft) {
    setState(() {
      _textController.text = draft.text;
      _selectedVisibility = draft.visibility;
      _selectedHoodId = draft.hoodId;
      _selectedImagePath = draft.imagePath;
    });
  }

  /// Saves the current form state as a draft.
  Future<void> _saveDraft() async {
    final draft = DraftPost(
      text: _textController.text,
      visibility: _selectedVisibility,
      hoodId: _selectedHoodId,
      imagePath: _selectedImagePath,
    );
    await _draftService.saveDraft(draft);
  }

  /// Debounced draft save — triggers 2 seconds after the last change.
  void _scheduleDraftSave() {
    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(seconds: 2), () {
      _saveDraft();
    });
  }

  /// Called when the user taps the close button or back — discards the draft.
  Future<void> _discardAndClose() async {
    await _draftService.deleteDraft();
    if (mounted) {
      Navigator.of(context).pop();
    }
  }

  Future<void> _pickImage() async {
    try {
      final XFile? image = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1920,
        imageQuality: 85,
      );
      
      if (image != null) {
        setState(() {
          _selectedImagePath = image.path;
        });
        _scheduleDraftSave();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to pick image')),
        );
      }
    }
  }

  Future<void> _createPost() async {
    final text = _textController.text.trim();
    
    // Validate input
    if (text.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Post cannot be empty')),
        );
      }
      return;
    }

    if (text.length > _maxCharacters) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Post exceeds $_maxCharacters characters')),
        );
      }
      return;
    }

    // Get current user from session provider
    final currentUser = ref.read(currentUserProvider);
    if (currentUser == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('You must be logged in to post')),
        );
      }
      return;
    }
    final userId = currentUser.id;
    final username = currentUser.username;

    // ── IDENTITY VERIFICATION LOG (TEMPORARY — Sprint 1.3) ──
    Logger.info(
      '========== IDENTITY VERIFICATION: _createPost (caller) ==========\n'
      'AUTH UID: ${Supabase.instance.client.auth.currentUser?.id}\n'
      'SESSION UID: ${Supabase.instance.client.auth.currentSession?.user.id}\n'
      'CURRENT USER PROVIDER UID: $userId\n'
      'POST USER ID (will be): $userId',
      tag: 'CreatePostPage',
    );
    // ── END IDENTITY VERIFICATION LOG ──

    // Show loading state
    if (mounted) {
      setState(() {});
    }

    try {
      List<String>? mediaUrls;
      
      // Upload image if selected
      if (_selectedImagePath != null) {
        final postRepository = ref.read(postRepositoryProvider);
        final uploadResult = await postRepository.uploadImage(userId, _selectedImagePath!);
        
        if (uploadResult.isFailure) {
          Logger.error(
            'Image upload failed in CreatePostPage.',
            error: uploadResult.failure?.message,
            tag: 'CreatePost',
          );
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Failed to upload image: ${uploadResult.failure?.message}')),
            );
          }
          return;
        }

        mediaUrls = [uploadResult.value!];
        Logger.info(
          'Image uploaded successfully. URL: $mediaUrls',
          tag: 'CreatePost',
        );
      }

      // Create Post object with a temporary ID.
      // The database generates the real UUID via gen_random_uuid(),
      // and the repository returns it via .select().single().
      final post = Post(
        id: '',
        userId: userId,
        username: username,
        content: text,
        hoodId: _selectedVisibility == 'Hood' ? _selectedHoodId : null,
        createdAt: DateTime.now(),
        likes: 0,
        comments: 0,
        mediaUrls: mediaUrls,
        isPublic: _selectedVisibility == 'Public',
      );

      // Call FeedNotifier.createPost() — returns the persisted Post
      // with the database-generated UUID.
      final createdPost = await ref.read(feedProvider.notifier).createPost(post);

      // Award Aura for creating a post
      final auraEngine = ref.read(auraEngineProvider);
      auraEngine.award(userId, AuraAction.createPost);

      // Emit events using the database-generated UUID
      final eventBus = ref.read(eventBusProvider);
      eventBus.publish(PostCreatedEvent(
        postId: createdPost.id,
        userId: userId,
        hoodId: createdPost.hoodId,
      ));
      eventBus.publish(AuraAwardedEvent(
        userId: userId,
        auraAmount: 10,
        reason: 'Post created',
        source: 'post_created',
      ));

      // Delete draft on successful publish
      await _draftService.deleteDraft();

      // Show success message
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Post published')),
        );
      }

      // Return to feed
      if (mounted) {
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to create post: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;

    return Scaffold(
      backgroundColor: ORAColors.background(brightness),
      appBar: AppBar(
        backgroundColor: ORAColors.background(brightness),
        elevation: 0,
        scrolledUnderElevation: 0,
        title: Text(
          'Create Post',
          style: ORATypography.title(context),
        ),
        leading: IconButton(
          icon: Icon(Icons.close, color: ORAColors.textPrimary(brightness)),
          onPressed: _discardAndClose,
        ),
        actions: [
          TextButton(
            onPressed: _createPost,
            child: Text(
              'Post',
              style: ORATypography.label(context).copyWith(
                color: ORAColors.primary(brightness),
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(ORASpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Text input
            TextField(
              controller: _textController,
              maxLines: null,
              maxLength: _maxCharacters,
              style: ORATypography.body(context).copyWith(
                color: ORAColors.textPrimary(brightness),
                fontSize: 16,
                height: 1.5,
              ),
              decoration: InputDecoration(
                hintText: "What's on your mind?",
                hintStyle: ORATypography.body(context).copyWith(
                  color: ORAColors.textTertiary(brightness),
                  fontSize: 16,
                ),
                border: InputBorder.none,
                counterText: '',
              ),
              onChanged: (value) {
                setState(() {});
                _scheduleDraftSave();
              },
            ),
            
            // Character counter
            Padding(
              padding: const EdgeInsets.only(bottom: ORASpacing.lg),
              child: Text(
                '${_textController.text.length}/$_maxCharacters',
                style: ORATypography.caption(context).copyWith(
                  color: _textController.text.length > _maxCharacters
                      ? ORAColors.error(brightness)
                      : ORAColors.textTertiary(brightness),
                ),
              ),
            ),
            
            Divider(color: ORAColors.border(brightness), height: 1),
            const SizedBox(height: ORASpacing.lg),
            
            // Visibility selector
            _buildSectionLabel(context, 'Visibility'),
            const SizedBox(height: ORASpacing.sm),
            Row(
              children: _visibilityOptions.map((option) {
                final isSelected = _selectedVisibility == option['value'];
                return Expanded(
                  child: GestureDetector(
                    onTap: () {
                      setState(() {
                        _selectedVisibility = option['value']!;
                      });
                      _scheduleDraftSave();
                    },
                    child: Container(
                      margin: EdgeInsets.only(
                        right: option != _visibilityOptions.last ? ORASpacing.sm : 0,
                      ),
                      padding: const EdgeInsets.symmetric(vertical: ORASpacing.md),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? ORAColors.primary(brightness).withValues(alpha: 0.2)
                            : ORAColors.surface(brightness),
                        borderRadius: ORARadius.mediumAll,
                        border: Border.all(
                          color: isSelected
                              ? ORAColors.primary(brightness)
                              : ORAColors.border(brightness),
                          width: 1,
                        ),
                      ),
                      child: Center(
                        child: Text(
                          option['label']!,
                          style: ORATypography.caption(context).copyWith(
                            color: isSelected
                                ? ORAColors.primary(brightness)
                                : ORAColors.textSecondary(brightness),
                            fontSize: 14,
                            fontWeight: isSelected
                                ? FontWeight.w600
                                : FontWeight.normal,
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
            
            const SizedBox(height: ORASpacing.xxl),
            
            // Hood selector (only shown when visibility is Hood)
            if (_selectedVisibility == 'Hood') ...[
              _buildSectionLabel(context, 'Select Hood'),
              const SizedBox(height: ORASpacing.sm),
              if (_isLoadingHoods)
                const Center(
                  child: Padding(
                    padding: EdgeInsets.all(ORASpacing.md),
                    child: ORALoadingIndicator(),
                  ),
                )
              else if (_availableHoods.isEmpty)
                ORAEmptyState(
                  title: 'No hoods available',
                  description: 'Join or create a hood to post to it.',
                  icon: Icons.groups_outlined,
                )
              else
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: ORASpacing.md, vertical: ORASpacing.xs),
                  decoration: BoxDecoration(
                    color: ORAColors.surface(brightness),
                    borderRadius: ORARadius.mediumAll,
                    border: Border.all(
                      color: ORAColors.border(brightness),
                      width: 1,
                    ),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: _selectedHoodId,
                      hint: Text(
                        'Choose a hood',
                        style: ORATypography.caption(context).copyWith(
                          color: ORAColors.textTertiary(brightness),
                        ),
                      ),
                      isExpanded: true,
                      style: ORATypography.body(context).copyWith(
                        color: ORAColors.textPrimary(brightness),
                      ),
                      dropdownColor: ORAColors.surface(brightness),
                      items: _availableHoods.map((hood) {
                        return DropdownMenuItem<String>(
                          value: hood.id,
                          child: Text(hood.name),
                        );
                      }).toList(),
                      onChanged: (value) {
                        setState(() {
                          _selectedHoodId = value;
                        });
                        _scheduleDraftSave();
                      },
                    ),
                  ),
                ),
              const SizedBox(height: ORASpacing.xxl),
            ],
            
            // Image picker
            _buildSectionLabel(context, 'Media'),
            const SizedBox(height: ORASpacing.sm),
            GestureDetector(
              onTap: _pickImage,
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: ORASpacing.xxl),
                decoration: BoxDecoration(
                  color: ORAColors.surface(brightness),
                  borderRadius: ORARadius.mediumAll,
                  border: Border.all(
                    color: ORAColors.border(brightness),
                    width: 1,
                  ),
                ),
                child: _selectedImagePath != null
                    ? Column(
                        children: [
                          Image.file(
                            File(_selectedImagePath!),
                            width: double.infinity,
                            fit: BoxFit.cover,
                            height: 200,
                          ),
                          const SizedBox(height: ORASpacing.sm),
                          TextButton(
                            onPressed: () {
                              setState(() {
                                _selectedImagePath = null;
                              });
                              _scheduleDraftSave();
                            },
                            child: Text(
                              'Remove',
                              style: TextStyle(color: ORAColors.error(brightness)),
                            ),
                          ),
                        ],
                      )
                    : Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.image_outlined,
                            color: ORAColors.textTertiary(brightness),
                            size: 24,
                          ),
                          const SizedBox(width: ORASpacing.sm),
                          Text(
                            'Add Image',
                            style: ORATypography.body(context).copyWith(
                              color: ORAColors.textTertiary(brightness),
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionLabel(BuildContext context, String label) {
    final brightness = Theme.of(context).brightness;
    return Text(
      label,
      style: ORATypography.label(context).copyWith(
        color: ORAColors.textPrimary(brightness),
        fontWeight: FontWeight.w600,
      ),
    );
  }
}