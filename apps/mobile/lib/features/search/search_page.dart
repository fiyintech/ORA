import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mobile/core/backend/repositories/impl/providers.dart';
import 'package:mobile/core/models/user.dart';
import 'package:mobile/core/theme/ora_colors.dart';
import 'package:mobile/shared/widgets/ora_avatar.dart';
import 'package:mobile/core/theme/ora_radius.dart';
import 'package:mobile/core/theme/ora_spacing.dart';
import 'package:mobile/core/theme/ora_typography.dart';
import 'package:mobile/shared/widgets/ora_empty_state.dart';
import 'package:mobile/shared/widgets/ora_loading_indicator.dart';

class SearchPage extends ConsumerStatefulWidget {
  const SearchPage({super.key});

  @override
  ConsumerState<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends ConsumerState<SearchPage> {
  final TextEditingController _searchController = TextEditingController();
  List<User> _users = [];
  List<Map<String, dynamic>> _hoods = [];
  List<Map<String, dynamic>> _posts = [];
  bool _isLoading = false;
  String _query = '';

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    final query = _searchController.text.trim();
    if (query != _query) {
      setState(() {
        _query = query;
      });
      _performSearch(query);
    }
  }

  Future<void> _performSearch(String query) async {
    if (query.isEmpty) {
      setState(() {
        _users = [];
        _hoods = [];
        _posts = [];
      });
      return;
    }

    setState(() => _isLoading = true);

    try {
      // Search real users from Supabase
      final userResult = await ref.read(userRepositoryProvider).search(query);
      final searchedUsers = userResult.value ?? [];

      // Deduplicate users by ID
      final uniqueUsers = <String, User>{};
      for (final user in searchedUsers) {
        uniqueUsers[user.id] = user;
      }
      final deduplicatedUsers = uniqueUsers.values.toList();

      // Search posts (real local posts only)
      final allPosts = await ref.read(postRepositoryProvider).loadPosts('feed');
      final searchedPosts = allPosts.value?.where((post) {
        return post.content.toLowerCase().contains(query.toLowerCase()) ||
               post.username.toLowerCase().contains(query.toLowerCase());
      }).map((post) => {
        'id': post.id,
        'username': post.username,
        'content': post.content,
        'type': 'post',
      }).toList() ?? [];

      if (mounted) {
        setState(() {
          _users = deduplicatedUsers;
          _hoods = [];
          _posts = searchedPosts;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
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
        titleSpacing: ORASpacing.md,
        title: TextField(
          controller: _searchController,
          autofocus: true,
          style: ORATypography.body(context),
          decoration: InputDecoration(
            hintText: 'Search users, posts, and hoods...',
            hintStyle: ORATypography.caption(context).copyWith(
              color: ORAColors.textTertiary(brightness),
            ),
            prefixIcon: Icon(
              Icons.search_rounded,
              color: ORAColors.textTertiary(brightness),
            ),
            suffixIcon: _query.isNotEmpty
                ? IconButton(
                    onPressed: () {
                      _searchController.clear();
                    },
                    icon: Icon(
                      Icons.clear_rounded,
                      color: ORAColors.textTertiary(brightness),
                    ),
                  )
                : null,
            filled: true,
            fillColor: ORAColors.surface(brightness),
            border: OutlineInputBorder(
              borderRadius: ORARadius.mediumAll,
              borderSide: BorderSide.none,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: ORARadius.mediumAll,
              borderSide: BorderSide.none,
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: ORARadius.mediumAll,
              borderSide: BorderSide(
                color: ORAColors.primary(brightness),
                width: 1,
              ),
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: ORASpacing.md,
              vertical: ORASpacing.sm,
            ),
          ),
        ),
      ),
      body: _buildBody(brightness),
    );
  }

  Widget _buildBody(Brightness brightness) {
    if (_query.isEmpty) {
      return Center(
        child: ORAEmptyState(
          title: 'Search',
          description: 'Search users, posts, and hoods will be available soon.',
          icon: Icons.search_rounded,
        ),
      );
    }

    if (_isLoading) {
      return const Center(
        child: ORALoadingIndicator(),
      );
    }

    final hasResults = _users.isNotEmpty || _hoods.isNotEmpty || _posts.isNotEmpty;

    if (!hasResults) {
      return Center(
        child: ORAEmptyState(
          title: 'No results found',
          description: 'Try searching for something else.',
          icon: Icons.search_off_rounded,
        ),
      );
    }

    return ListView(
      padding: const EdgeInsets.all(ORASpacing.lg),
      children: [
        if (_users.isNotEmpty) ...[
          Text(
            'Users',
            style: ORATypography.title(context),
          ),
          const SizedBox(height: ORASpacing.md),
          ..._users.map((user) => _buildUserTile(context, user, brightness)),
          const SizedBox(height: ORASpacing.lg),
        ],

        if (_hoods.isNotEmpty) ...[
          Text(
            'Hoods',
            style: ORATypography.title(context),
          ),
          const SizedBox(height: ORASpacing.md),
          ..._hoods.map((hood) => _buildHoodTile(context, hood, brightness)),
          const SizedBox(height: ORASpacing.lg),
        ],

        if (_posts.isNotEmpty) ...[
          Text(
            'Posts',
            style: ORATypography.title(context),
          ),
          const SizedBox(height: ORASpacing.md),
          ..._posts.map((post) => _buildPostTile(context, post, brightness)),
        ],
      ],
    );
  }

  Widget _buildUserTile(BuildContext context, User user, Brightness brightness) {
    return GestureDetector(
      onTap: () {
        context.push('/profile-public', extra: user.id);
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: ORASpacing.sm),
        padding: const EdgeInsets.all(ORASpacing.md),
        decoration: BoxDecoration(
          color: ORAColors.surface(brightness),
          borderRadius: ORARadius.mediumAll,
          border: Border.all(color: ORAColors.border(brightness)),
        ),
        child: Row(
          children: [
            ORAAvatar(
              letter: user.fullName,
              size: 40,
            ),
            const SizedBox(width: ORASpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    user.fullName,
                    style: ORATypography.label(context).copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '@${user.username}',
                    style: ORATypography.caption(context).copyWith(
                      color: ORAColors.textSecondary(brightness),
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.chevron_right_rounded,
              color: ORAColors.textTertiary(brightness),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHoodTile(BuildContext context, Map<String, dynamic> hood, Brightness brightness) {
    return GestureDetector(
      onTap: () {
        // TODO: Navigate to hood detail page
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Hood detail: ${hood['name']}')),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: ORASpacing.sm),
        padding: const EdgeInsets.all(ORASpacing.md),
        decoration: BoxDecoration(
          color: ORAColors.surface(brightness),
          borderRadius: ORARadius.mediumAll,
          border: Border.all(color: ORAColors.border(brightness)),
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: ORAColors.primary(brightness).withValues(alpha: 0.1),
                borderRadius: ORARadius.mediumAll,
              ),
              child: Icon(
                Icons.groups_outlined,
                color: ORAColors.primary(brightness),
              ),
            ),
            const SizedBox(width: ORASpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    hood['name'] ?? 'Hood',
                    style: ORATypography.label(context).copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    hood['description'] ?? '',
                    style: ORATypography.caption(context).copyWith(
                      color: ORAColors.textSecondary(brightness),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            Icon(
              Icons.chevron_right_rounded,
              color: ORAColors.textTertiary(brightness),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPostTile(BuildContext context, Map<String, dynamic> post, Brightness brightness) {
    return GestureDetector(
      onTap: () {
        // Navigate to home feed - the post will be loaded from the feed
        // For now, navigate to home page where the post can be viewed
        context.push('/');
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: ORASpacing.sm),
        padding: const EdgeInsets.all(ORASpacing.md),
        decoration: BoxDecoration(
          color: ORAColors.surface(brightness),
          borderRadius: ORARadius.mediumAll,
          border: Border.all(color: ORAColors.border(brightness)),
        ),
        child: Row(
          children: [
            Icon(
              Icons.article_outlined,
              color: ORAColors.primary(brightness),
            ),
            const SizedBox(width: ORASpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '@${post['username']}',
                    style: ORATypography.label(context).copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    post['content'] ?? '',
                    style: ORATypography.caption(context).copyWith(
                      color: ORAColors.textSecondary(brightness),
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            Icon(
              Icons.chevron_right_rounded,
              color: ORAColors.textTertiary(brightness),
            ),
          ],
        ),
      ),
    );
  }
}