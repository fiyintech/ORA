import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:mobile/features/session/session_provider.dart';

class OnboardingPage extends ConsumerStatefulWidget {
  const OnboardingPage({super.key});

  @override
  ConsumerState<OnboardingPage> createState() => _OnboardingPageState();
}

class _OnboardingPageState extends ConsumerState<OnboardingPage> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  final List<OnboardingContent> _pages = [
    OnboardingContent(
      title: 'Your Reputation Matters',
      subtitle: 'Every interaction builds your digital identity.',
    ),
    OnboardingContent(
      title: 'Find Your Hood',
      subtitle: 'Join communities where you truly belong.',
    ),
    OnboardingContent(
      title: 'Build Your Aura',
      subtitle:
          'Earn respect through consistency, achievements and genuine connections.',
    ),
    OnboardingContent(
      title: 'Welcome to ORA',
      subtitle: 'Built on Reputation.',
    ),
  ];

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _onPageChanged(int index) {
    setState(() {
      _currentPage = index;
    });
  }

  void _nextPage() {
    if (_currentPage < _pages.length - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  void _skip() {
    _navigateToAuth();
  }

  void _getStarted() {
    _navigateToAuth();
  }

  Future<void> _navigateToAuth() async {
    await ref.read(onboardingCompletedProvider.notifier).complete();
    if (!mounted) return;
    context.go("/auth");
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0B), // Obsidian Black
      body: SafeArea(
        child: Column(
          children: [
            // Skip button
            Align(
              alignment: Alignment.topRight,
              child: TextButton(
                onPressed: _skip,
                child: const Text(
                  'Skip',
                  style: TextStyle(
                    color: Color(0xFFB0B0B0), // Soft Gray
                    fontSize: 16,
                  ),
                ),
              ),
            ),
            // PageView
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                onPageChanged: _onPageChanged,
                itemCount: _pages.length,
                itemBuilder: (context, index) {
                  return OnboardingPageContent(
                    content: _pages[index],
                    index: index,
                  );
                },
              ),
            ),
            // Bottom controls
            Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                children: [
                  // Page indicator
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(
                      _pages.length,
                      (index) => AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        margin: const EdgeInsets.symmetric(horizontal: 4),
                        height: 8,
                        width: _currentPage == index ? 24 : 8,
                        decoration: BoxDecoration(
                          color: _currentPage == index
                              ? const Color(0xFF6B3FA0) // Royal Purple
                              : const Color(0xFF3A3A3A), // Soft dark surface
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),
                  // Next / Get Started button
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton(
                      onPressed: _currentPage == _pages.length - 1
                          ? _getStarted
                          : _nextPage,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(
                          0xFF6B3FA0,
                        ), // Royal Purple
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        elevation: 0,
                      ),
                      child: Text(
                        _currentPage == _pages.length - 1
                            ? 'Get Started'
                            : 'Next',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class OnboardingContent {
  final String title;
  final String subtitle;

  OnboardingContent({required this.title, required this.subtitle});
}

class OnboardingPageContent extends StatelessWidget {
  final OnboardingContent content;
  final int index;

  const OnboardingPageContent({
    super.key,
    required this.content,
    required this.index,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // ORA Logo placeholder
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              color: const Color(
                0xFF6B3FA0,
              ).withValues(alpha: 0.1), // Royal Purple with opacity
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.branding_watermark,
              size: 60,
              color: const Color(0xFF6B3FA0), // Royal Purple
            ),
          ),
          const SizedBox(height: 48),
          // Title
          Text(
                content.title,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  height: 1.3,
                ),
              )
              .animate()
              .fadeIn(duration: 600.ms, delay: (index * 100).ms)
              .slideY(
                begin: 0.2,
                end: 0,
                duration: 600.ms,
                delay: (index * 100).ms,
                curve: Curves.easeOut,
              ),
          const SizedBox(height: 16),
          // Subtitle
          Text(
                content.subtitle,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 16,
                  color: Color(0xFFB0B0B0), // Soft Gray
                  height: 1.5,
                ),
              )
              .animate()
              .fadeIn(duration: 600.ms, delay: (index * 100 + 200).ms)
              .slideY(
                begin: 0.2,
                end: 0,
                duration: 600.ms,
                delay: (index * 100 + 200).ms,
                curve: Curves.easeOut,
              ),
        ],
      ),
    );
  }
}
