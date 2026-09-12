import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:mobile/core/theme/ora_animations.dart';
import 'package:mobile/core/theme/ora_colors.dart';
import 'package:mobile/core/theme/ora_radius.dart';
import 'package:mobile/core/theme/ora_spacing.dart';
import 'package:mobile/core/theme/ora_typography.dart';
import 'package:mobile/models/chat.dart';
import 'package:mobile/shared/widgets/ora_avatar.dart';

class ChatsPage extends StatefulWidget {
  const ChatsPage({super.key});

  @override
  State<ChatsPage> createState() => _ChatsPageState();
}

class _ChatsPageState extends State<ChatsPage>
    with SingleTickerProviderStateMixin {
  final TextEditingController _searchController = TextEditingController();
  late TabController _tabController;
  String _searchQuery = '';

  final List<String> _tabs = ['Chats', 'Hoods', 'Favorites'];
  final List<String> _tabFilters = ['all', 'hoods', 'favorites'];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _tabs.length, vsync: this);
    _tabController.addListener(() {
      if (!_tabController.indexIsChanging) {
        setState(() {});
      }
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _tabController.dispose();
    super.dispose();
  }

  List<Conversation> _getConversations() {
    final conversations = getFilteredConversations(
      _tabFilters[_tabController.index],
    );

    if (_searchQuery.isNotEmpty) {
      final query = _searchQuery.toLowerCase();
      conversations.retainWhere(
        (c) => c.username.toLowerCase().contains(query),
      );
    }

    // Sort: pinned first, then by time
    conversations.sort((a, b) {
      if (a.isPinned && !b.isPinned) return -1;
      if (!a.isPinned && b.isPinned) return 1;
      return b.lastMessageTime.compareTo(a.lastMessageTime);
    });

    return conversations;
  }

  @override
  Widget build(BuildContext context) {
    final conversations = _getConversations();
    final brightness = Theme.of(context).brightness;

    return Scaffold(
      backgroundColor: ORAColors.background(brightness),
      body: SafeArea(
        child: Column(
          children: [
            // Search bar
            Padding(
              padding: const EdgeInsets.fromLTRB(ORASpacing.lg, ORASpacing.lg, ORASpacing.lg, ORASpacing.sm),
              child: TextField(
                controller: _searchController,
                onChanged: (value) => setState(() => _searchQuery = value),
                style: ORATypography.body(context),
                decoration: InputDecoration(
                  hintText: 'Search conversations...',
                  hintStyle: ORATypography.caption(context),
                  prefixIcon: Icon(
                    Icons.search_rounded,
                    color: ORAColors.textTertiary(brightness),
                    size: 20,
                  ),
                  suffixIcon: _searchQuery.isNotEmpty
                      ? IconButton(
                          icon: Icon(Icons.clear, color: ORAColors.textTertiary(brightness), size: 18),
                          onPressed: () {
                            _searchController.clear();
                            setState(() => _searchQuery = '');
                          },
                        )
                      : null,
                  filled: true,
                  fillColor: ORAColors.surface(brightness),
                  border: OutlineInputBorder(
                    borderRadius: ORARadius.mediumAll,
                    borderSide: BorderSide.none,
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: ORASpacing.lg,
                    vertical: ORASpacing.md,
                  ),
                ),
              ),
            ),
            // Filter tabs
            Container(
              height: 44,
              margin: const EdgeInsets.symmetric(horizontal: ORASpacing.lg, vertical: ORASpacing.sm),
              decoration: BoxDecoration(
                color: ORAColors.surface(brightness),
                borderRadius: ORARadius.mediumAll,
              ),
              child: TabBar(
                controller: _tabController,
                indicator: BoxDecoration(
                  color: ORAColors.primary(brightness),
                  borderRadius: ORARadius.smallAll,
                ),
                indicatorSize: TabBarIndicatorSize.tab,
                labelColor: Colors.white,
                unselectedLabelColor: ORAColors.textTertiary(brightness),
                labelStyle: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
                unselectedLabelStyle: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
                dividerColor: Colors.transparent,
                tabs: _tabs.map((tab) => Tab(text: tab)).toList(),
              ),
            ),
            const SizedBox(height: ORASpacing.sm),
            // Conversation list
            Expanded(
              child: conversations.isEmpty
                  ? _buildEmptyState(brightness)
                  : ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: ORASpacing.lg),
                      itemCount: conversations.length,
                      itemBuilder: (context, index) {
                        final conversation = conversations[index];
                        return _buildConversationTile(conversation, brightness);
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(Brightness brightness) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: ORAColors.primary(brightness).withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.chat_bubble_outline_rounded,
              size: 36,
              color: ORAColors.primary(brightness),
            ),
          ),
          const SizedBox(height: ORASpacing.md),
          Text(
            'Start your first conversation.',
            style: ORATypography.body(context).copyWith(
              color: ORAColors.textSecondary(brightness),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildConversationTile(Conversation conversation, Brightness brightness) {
    final isUnread = conversation.unreadCount > 0;

    return GestureDetector(
      onTap: () {
        context.push("/conversation", extra: conversation);
      },
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: ORASpacing.xs),
        padding: const EdgeInsets.all(ORASpacing.md),
        decoration: BoxDecoration(
          color: isUnread
              ? ORAColors.primary(brightness).withValues(alpha: 0.08)
              : ORAColors.surface(brightness),
          borderRadius: ORARadius.mediumAll,
          border: Border.all(
            color: isUnread
                ? ORAColors.primary(brightness).withValues(alpha: 0.2)
                : ORAColors.border(brightness),
            width: 1,
          ),
        ),
        child: Row(
          children: [
            // Avatar with pin indicator
            Stack(
              children: [
                ORAAvatar(
                  letter: conversation.avatarLetter,
                  size: 52,
                  gradientColors: conversation.avatarColors,
                ),
                if (conversation.isPinned)
                  Positioned(
                    top: 0,
                    right: 0,
                    child: Container(
                      width: 16,
                      height: 16,
                      decoration: BoxDecoration(
                        color: ORAColors.accent(brightness),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.push_pin,
                        color: ORAColors.background(brightness),
                        size: 10,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(width: ORASpacing.md),
            // Content
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        conversation.username,
                        style: ORATypography.label(context).copyWith(
                          color: ORAColors.textPrimary(brightness),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        conversation.timeDisplay,
                        style: ORATypography.caption(context),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          conversation.lastMessage,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: ORATypography.caption(context).copyWith(
                            color: isUnread
                                ? ORAColors.textPrimary(brightness)
                                : ORAColors.textSecondary(brightness),
                          ),
                        ),
                      ),
                      if (conversation.unreadCount > 0) ...[
                        const SizedBox(width: ORASpacing.sm),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: ORASpacing.sm,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: ORAColors.primary(brightness),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            conversation.unreadCount.toString(),
                            style: ORATypography.caption(context).copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    ).animate().fadeIn(duration: ORAAnimations.fast, delay: ORAAnimations.fast).slideY(
          begin: 0.05,
          end: 0,
          duration: ORAAnimations.fast,
          curve: Curves.easeOut,
        );
  }
}