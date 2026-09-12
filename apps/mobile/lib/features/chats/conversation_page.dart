import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:mobile/core/theme/ora_animations.dart';
import 'package:mobile/core/theme/ora_colors.dart';
import 'package:mobile/core/theme/ora_radius.dart';
import 'package:mobile/core/theme/ora_spacing.dart';
import 'package:mobile/core/theme/ora_typography.dart';
import 'package:mobile/models/chat.dart';
import 'package:mobile/shared/widgets/ora_avatar.dart';

class ConversationPage extends StatefulWidget {
  final Conversation? conversation;

  const ConversationPage({super.key, this.conversation});

  @override
  State<ConversationPage> createState() => _ConversationPageState();
}

class _ConversationPageState extends State<ConversationPage> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final conversation = widget.conversation ??
        Conversation(
          id: 'default',
          username: 'Unknown',
          avatarLetter: '?',
          avatarColors: const [Color(0xFF6B3FA0), Color(0xFF8B5CF6)],
          lastMessage: '',
          lastMessageTime: DateTime.now(),
          timeDisplay: '',
          messages: const [],
        );
    final brightness = Theme.of(context).brightness;

    return Scaffold(
      backgroundColor: ORAColors.background(brightness),
      appBar: AppBar(
        backgroundColor: ORAColors.surface(brightness).withValues(alpha: 0.85),
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: ORAColors.textSecondary(brightness)),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Row(
          children: [
            // Avatar with online indicator
            Stack(
              children: [
                ORAAvatar(
                  letter: conversation.avatarLetter,
                  size: 36,
                  gradientColors: conversation.avatarColors,
                ),
                Positioned(
                  bottom: 0,
                  right: 0,
                  child: Container(
                    width: 10,
                    height: 10,
                    decoration: BoxDecoration(
                      color: ORAColors.success(brightness),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: ORAColors.surface(brightness),
                        width: 2,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(width: ORASpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    conversation.username,
                    style: ORATypography.label(context).copyWith(
                      color: ORAColors.textPrimary(brightness),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    'Online',
                    style: ORATypography.caption(context).copyWith(
                      color: ORAColors.success(brightness),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.call_outlined, color: ORAColors.textSecondary(brightness)),
            onPressed: () {},
          ),
          IconButton(
            icon: Icon(Icons.videocam_outlined, color: ORAColors.textSecondary(brightness)),
            onPressed: () {},
          ),
          IconButton(
            icon: Icon(Icons.more_vert, color: ORAColors.textSecondary(brightness)),
            onPressed: () {},
          ),
        ],
      ),
      body: Column(
        children: [
          // Messages
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.all(ORASpacing.lg),
              itemCount: conversation.messages.length,
              itemBuilder: (context, index) {
                final message = conversation.messages[index];
                return _buildMessageBubble(message, brightness);
              },
            ),
          ),
          // Input bar
          Container(
            padding: const EdgeInsets.all(ORASpacing.md),
            decoration: BoxDecoration(
              color: ORAColors.surface(brightness),
              border: Border(
                top: BorderSide(color: ORAColors.border(brightness), width: 1),
              ),
            ),
            child: Row(
              children: [
                IconButton(
                  icon: Icon(Icons.attach_file_outlined, color: ORAColors.textTertiary(brightness)),
                  onPressed: () {},
                ),
                IconButton(
                  icon: Icon(Icons.camera_alt_outlined, color: ORAColors.textTertiary(brightness)),
                  onPressed: () {},
                ),
                Expanded(
                  child: TextField(
                    controller: _messageController,
                    style: ORATypography.body(context),
                    decoration: InputDecoration(
                      hintText: 'Message...',
                      hintStyle: ORATypography.caption(context),
                      filled: true,
                      fillColor: ORAColors.background(brightness),
                      border: OutlineInputBorder(
                        borderRadius: ORARadius.largeAll,
                        borderSide: BorderSide.none,
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: ORASpacing.lg,
                        vertical: ORASpacing.md,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: ORASpacing.sm),
                IconButton(
                  icon: Icon(Icons.emoji_emotions_outlined, color: ORAColors.textTertiary(brightness)),
                  onPressed: () {},
                ),
                const SizedBox(width: ORASpacing.sm),
                Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        ORAColors.primary(brightness),
                        ORAColors.secondary(brightness),
                      ],
                    ),
                    shape: BoxShape.circle,
                  ),
                  child: IconButton(
                    icon: const Icon(
                      Icons.send_rounded,
                      color: Colors.white,
                      size: 20,
                    ),
                    onPressed: () {},
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMessageBubble(ChatMessage message, Brightness brightness) {
    final isMine = message.isMine;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: ORASpacing.xs),
      child: Row(
        mainAxisAlignment: isMine ? MainAxisAlignment.end : MainAxisAlignment.start,
        children: [
          if (!isMine) const SizedBox(width: 40),
          Flexible(
            child: Container(
              padding: const EdgeInsets.symmetric(
                horizontal: ORASpacing.lg,
                vertical: ORASpacing.md,
              ),
              decoration: BoxDecoration(
                color: isMine
                    ? ORAColors.primary(brightness)
                    : ORAColors.surface(brightness),
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(isMine ? ORARadius.large : ORARadius.small),
                  topRight: Radius.circular(isMine ? ORARadius.small : ORARadius.large),
                  bottomLeft: Radius.circular(isMine ? ORARadius.large : ORARadius.small),
                  bottomRight: Radius.circular(isMine ? ORARadius.small : ORARadius.large),
                ),
                border: isMine
                    ? null
                    : Border.all(
                        color: ORAColors.border(brightness),
                        width: 1,
                      ),
              ),
              child: Text(
                message.text,
                style: ORATypography.body(context).copyWith(
                  color: isMine ? Colors.white : ORAColors.textPrimary(brightness),
                  height: 1.4,
                ),
              ),
            ),
          ),
          if (isMine) const SizedBox(width: 40),
        ],
      ),
    ).animate().fadeIn(duration: ORAAnimations.fast).slideY(
          begin: 0.1,
          end: 0,
          duration: ORAAnimations.fast,
          curve: Curves.easeOut,
        );
  }
}