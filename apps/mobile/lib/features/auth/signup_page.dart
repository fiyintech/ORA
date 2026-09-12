import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile/features/session/session_provider.dart';
import 'package:mobile/shared/widgets/ora_button.dart';
import 'package:mobile/shared/widgets/ora_text_field.dart';

class SignupPage extends ConsumerStatefulWidget {
  const SignupPage({super.key});

  @override
  ConsumerState<SignupPage> createState() => _SignupPageState();
}

class _SignupPageState extends ConsumerState<SignupPage> {
  final _fullNameController = TextEditingController();
  final _usernameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void dispose() {
    _fullNameController.dispose();
    _usernameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  String _getUserFriendlyError(dynamic error) {
    final errorString = error.toString().toLowerCase();
    
    if (errorString.contains('username') && 
        (errorString.contains('already') || errorString.contains('taken') || errorString.contains('duplicate'))) {
      return 'Username is already taken.';
    } else if (errorString.contains('email') && 
               (errorString.contains('already') || errorString.contains('taken') || errorString.contains('duplicate'))) {
      return 'An account already exists with this email.';
    } else if (errorString.contains('weak_password') || 
               errorString.contains('password')) {
      return 'Password must be at least 8 characters.';
    } else if (errorString.contains('invalid_email') || 
               errorString.contains('email')) {
      return 'Please enter a valid email address.';
    } else if (errorString.contains('network') || 
               errorString.contains('connection') ||
               errorString.contains('socket')) {
      return 'Couldn\'t connect to ORA.\nCheck your internet connection.';
    } else {
      return 'Something went wrong.\nPlease try again.';
    }
  }

  Future<void> _signup() async {
    // Validate inputs
    final fullName = _fullNameController.text.trim();
    final username = _usernameController.text.trim();
    final email = _emailController.text.trim();
    final password = _passwordController.text;
    final confirmPassword = _confirmPasswordController.text;

    if (fullName.isEmpty) {
      setState(() {
        _errorMessage = 'Please enter your full name.';
      });
      return;
    }

    if (username.isEmpty) {
      setState(() {
        _errorMessage = 'Please enter a username.';
      });
      return;
    }

    if (email.isEmpty) {
      setState(() {
        _errorMessage = 'Please enter your email.';
      });
      return;
    }

    if (password.isEmpty) {
      setState(() {
        _errorMessage = 'Please enter your password.';
      });
      return;
    }

    if (password != confirmPassword) {
      setState(() {
        _errorMessage = 'Passwords do not match.';
      });
      return;
    }

    if (password.length < 8) {
      setState(() {
        _errorMessage = 'Password must be at least 8 characters.';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final user = await ref.read(sessionProvider.notifier).register(
            fullName: fullName,
            username: username,
            email: email,
            password: password,
          );

      if (mounted) {
        setState(() {
          _isLoading = false;
        });

        // If no session was created (e.g. email confirmation required),
        // navigate to the verify email screen.
        if (user == null) {
          context.go('/verify-email');
        }
        // Otherwise navigation is handled by the router.
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = _getUserFriendlyError(e);
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0B), // Obsidian Black
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 48),
              // Title
              const Text(
                'Create Account',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 48),
              // Full Name field
              ORATextField(
                label: 'Full Name',
                hintText: 'Enter your full name',
                controller: _fullNameController,
                enabled: !_isLoading,
              ),
              const SizedBox(height: 24),
              // Username field
              ORATextField(
                label: 'Username',
                hintText: 'Choose a username',
                controller: _usernameController,
                enabled: !_isLoading,
              ),
              const SizedBox(height: 24),
              // Email field
              ORATextField(
                label: 'Email',
                hintText: 'Enter your email',
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                enabled: !_isLoading,
              ),
              const SizedBox(height: 24),
              // Password field
              ORATextField(
                label: 'Password',
                hintText: 'Create a password',
                controller: _passwordController,
                isPassword: true,
                enabled: !_isLoading,
              ),
              const SizedBox(height: 24),
              // Confirm Password field
              ORATextField(
                label: 'Confirm Password',
                hintText: 'Confirm your password',
                controller: _confirmPasswordController,
                isPassword: true,
                enabled: !_isLoading,
              ),
              if (_errorMessage != null) ...[
                const SizedBox(height: 16),
                Text(
                  _errorMessage!,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Colors.red,
                    fontSize: 14,
                  ),
                ),
              ],
              const SizedBox(height: 32),
              // Create Account button
              ORAButton(
                text: 'Create Account',
                onPressed: _isLoading ? null : _signup,
                isLoading: _isLoading,
              ),
              const SizedBox(height: 24),
              // Already have an account?
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text(
                    'Already have an account? ',
                    style: TextStyle(
                      color: Color(0xFFB0B0B0), // Soft Gray
                      fontSize: 16,
                    ),
                  ),
                  TextButton(
                    onPressed: _isLoading ? null : () {
                      context.push("/login");
                    },
                    child: const Text(
                      'Login',
                      style: TextStyle(
                        color: Color(0xFF6B3FA0), // Royal Purple
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
