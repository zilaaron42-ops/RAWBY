// ============================================================
// RAWBY — Login Screen
// Dark background, cream input fields, green button
// ============================================================
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../providers/user_session_provider.dart';
import '../providers/router_provider.dart';
import '../services/api_service.dart';
import '../theme/app_colors.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  bool _isLoading = false;
  bool _obscurePassword = true;
  String? _errorMessage;

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final api = ref.read(apiServiceProvider);
      final result = await api.login(
        username: _usernameController.text.trim(),
        password: _passwordController.text,
      );

      // Set auth token
      final token = result['token'] as String?;
      if (token != null) api.setAuthToken(token);

      // API returns { token, user: { id, username, ... } }
      final user = result['user'] as Map<String, dynamic>? ?? result;

      // Update user session
      ref.read(userSessionProvider.notifier).setUser(
            userId: user['id'] as String? ?? '',
            username: user['username'] as String? ?? '',
            displayName: user['displayName'] as String? ?? '',
            email: user['email'] as String? ?? '',
            role: (user['isAdmin'] == true) ? 'admin' : 'user',
          );

      if (mounted) context.go(Routes.home);
    } catch (e) {
      setState(() {
        _errorMessage = _parseError(e);
      });
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showAboutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: RawbyPalette.darkSurface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.videocam_rounded, color: RawbyPalette.green500, size: 22),
            SizedBox(width: 10),
            Text(
              'What is RAWBY?',
              style: TextStyle(color: RawbyPalette.textDark, fontSize: 18, fontWeight: FontWeight.w700),
            ),
          ],
        ),
        content: const SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'RAWBY is a weekly filmmaking challenge app designed to help aspiring and experienced creators build a consistent creative habit. '
                'Instead of waiting for inspiration to strike, RAWBY gives you structure, accountability, and a community to grow with.',
                style: TextStyle(color: RawbyPalette.textDark, fontSize: 14, height: 1.5),
              ),
              SizedBox(height: 16),
              Text(
                'The Weekly Cycle',
                style: TextStyle(color: RawbyPalette.green500, fontSize: 13, fontWeight: FontWeight.w600),
              ),
              SizedBox(height: 6),
              Text(
                'Every week you receive a set of creative prompts — either generated locally, by AI, or written by you. '
                'Pick one, plan your shoot, film it, and submit before the deadline. After submission, your Instagram engagement '
                '(likes and views) is tracked for 7 days to calculate your final score.',
                style: TextStyle(color: RawbyPalette.textMutedDark, fontSize: 13, height: 1.6),
              ),
              SizedBox(height: 16),
              Text(
                'How Scoring Works',
                style: TextStyle(color: RawbyPalette.green500, fontSize: 13, fontWeight: FontWeight.w600),
              ),
              SizedBox(height: 6),
              Text(
                '\u2022 Each prompt has a difficulty level: Sequence, Short Story, or Narrative\n'
                '\u2022 Higher difficulty = more base points\n'
                '\u2022 Submitting on time earns a bonus; late submissions get a penalty multiplier\n'
                '\u2022 Instagram likes and views add engagement points\n'
                '\u2022 Your total score determines your rank on the leaderboard',
                style: TextStyle(color: RawbyPalette.textMutedDark, fontSize: 13, height: 1.6),
              ),
              SizedBox(height: 16),
              Text(
                'Features',
                style: TextStyle(color: RawbyPalette.green500, fontSize: 13, fontWeight: FontWeight.w600),
              ),
              SizedBox(height: 6),
              Text(
                '\u2022 Weekly prompts — AI-generated, local shuffle, or custom\n'
                '\u2022 Big Projects — long-form challenges spanning multiple weeks\n'
                '\u2022 Gear tracker — catalog your cameras, lenses, and subscriptions\n'
                '\u2022 Idea Bank — save prompts for later inspiration\n'
                '\u2022 Workflow planner — break your week into structured tasks\n'
                '\u2022 Leaderboard — compete with other creators\n'
                '\u2022 Rank progression — climb from Starter to Legend\n'
                '\u2022 Achievement system — unlock milestones as you grow',
                style: TextStyle(color: RawbyPalette.textMutedDark, fontSize: 13, height: 1.6),
              ),
              SizedBox(height: 16),
              Text(
                'Who Is It For?',
                style: TextStyle(color: RawbyPalette.green500, fontSize: 13, fontWeight: FontWeight.w600),
              ),
              SizedBox(height: 6),
              Text(
                'RAWBY is built for anyone who wants to make films regularly — whether you shoot on a phone or a cinema camera. '
                'If you have been struggling to finish projects, stay motivated, or just get started, this app gives you the nudge you need.',
                style: TextStyle(color: RawbyPalette.textMutedDark, fontSize: 13, height: 1.6),
              ),
              SizedBox(height: 16),
              Text(
                'Stop overthinking. Start creating. That is the RAWBY way.',
                style: TextStyle(color: RawbyPalette.textDark, fontSize: 13, fontStyle: FontStyle.italic),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Got it', style: TextStyle(color: RawbyPalette.green500)),
          ),
        ],
      ),
    );
  }

  void _showPrivacyDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: RawbyPalette.darkSurface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text(
          'Privacy Policy & Terms',
          style: TextStyle(color: RawbyPalette.textDark, fontSize: 18, fontWeight: FontWeight.w700),
        ),
        content: const SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Last updated: May 2026',
                style: TextStyle(color: RawbyPalette.textMutedDark, fontSize: 11),
              ),
              SizedBox(height: 12),
              Text(
                '1. Data We Collect',
                style: TextStyle(color: RawbyPalette.green500, fontSize: 13, fontWeight: FontWeight.w600),
              ),
              SizedBox(height: 6),
              Text(
                'When you create an account and use RAWBY, we collect the following information:',
                style: TextStyle(color: RawbyPalette.textMutedDark, fontSize: 13, height: 1.5),
              ),
              SizedBox(height: 4),
              Text(
                '\u2022 Account information: username, display name, and email address for authentication and identification\n'
                '\u2022 Project data: your prompt selections, submission timestamps, scores, and project history\n'
                '\u2022 Instagram URLs: only when you voluntarily provide them for engagement tracking\n'
                '\u2022 Engagement metrics: likes and views from your linked Instagram posts, fetched after submission\n'
                '\u2022 Device tokens: Firebase Cloud Messaging tokens used to deliver push notifications\n'
                '\u2022 Gear and subscription data: equipment and subscriptions you choose to track within the app\n'
                '\u2022 Preferences: your timezone, theme, AI generation settings, and notification preferences',
                style: TextStyle(color: RawbyPalette.textMutedDark, fontSize: 13, height: 1.6),
              ),
              SizedBox(height: 16),
              Text(
                '2. How We Use Your Data',
                style: TextStyle(color: RawbyPalette.green500, fontSize: 13, fontWeight: FontWeight.w600),
              ),
              SizedBox(height: 6),
              Text(
                '\u2022 To operate the weekly challenge cycle: prompt generation, submission tracking, and scoring\n'
                '\u2022 To display your profile, rank, and statistics on the leaderboard\n'
                '\u2022 To send opt-in push notifications for deadline reminders, stats readiness, and workflow tasks\n'
                '\u2022 To sync your local session data with the backend for backup and cross-device access\n'
                '\u2022 To generate AI-powered prompts through our backend service (Groq/OpenAI)\n'
                '\u2022 We do not sell, rent, or share your personal data with any third parties\n'
                '\u2022 We do not use your data for advertising or marketing purposes',
                style: TextStyle(color: RawbyPalette.textMutedDark, fontSize: 13, height: 1.6),
              ),
              SizedBox(height: 16),
              Text(
                '3. Data Storage & Security',
                style: TextStyle(color: RawbyPalette.green500, fontSize: 13, fontWeight: FontWeight.w600),
              ),
              SizedBox(height: 6),
              Text(
                '\u2022 Your session data is stored locally on your device using Hive encrypted storage\n'
                '\u2022 Backend data is stored securely on Render-hosted servers\n'
                '\u2022 API communication uses HTTPS encryption\n'
                '\u2022 Authentication tokens are stored locally and never exposed to other apps\n'
                '\u2022 You can delete your account and all associated data at any time by contacting the administrator',
                style: TextStyle(color: RawbyPalette.textMutedDark, fontSize: 13, height: 1.6),
              ),
              SizedBox(height: 16),
              Text(
                '4. Terms of Use',
                style: TextStyle(color: RawbyPalette.green500, fontSize: 13, fontWeight: FontWeight.w600),
              ),
              SizedBox(height: 6),
              Text(
                '\u2022 RAWBY is currently in active development and provided free of charge\n'
                '\u2022 All creative content you produce remains entirely yours — we claim no ownership\n'
                '\u2022 You agree not to abuse the platform, submit harmful content, or manipulate scoring\n'
                '\u2022 We reserve the right to suspend or remove accounts that violate community guidelines\n'
                '\u2022 The service is provided "as-is" without warranty of any kind, express or implied\n'
                '\u2022 We may update features, scoring rules, or these terms at any time with notice in the app',
                style: TextStyle(color: RawbyPalette.textMutedDark, fontSize: 13, height: 1.6),
              ),
              SizedBox(height: 16),
              Text(
                '5. Notifications',
                style: TextStyle(color: RawbyPalette.green500, fontSize: 13, fontWeight: FontWeight.w600),
              ),
              SizedBox(height: 6),
              Text(
                'RAWBY may send you push notifications for deadline reminders, stat availability, and workflow tasks. '
                'You can disable notifications at any time through your device settings. '
                'We will never send promotional or spam notifications.',
                style: TextStyle(color: RawbyPalette.textMutedDark, fontSize: 13, height: 1.6),
              ),
              SizedBox(height: 16),
              Text(
                '6. Contact',
                style: TextStyle(color: RawbyPalette.green500, fontSize: 13, fontWeight: FontWeight.w600),
              ),
              SizedBox(height: 6),
              Text(
                'If you have questions about your data, want to request deletion, or need support, '
                'reach out to the app administrator through the Feedback Wall in the admin panel or contact us directly.',
                style: TextStyle(color: RawbyPalette.textMutedDark, fontSize: 13, height: 1.6),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Close', style: TextStyle(color: RawbyPalette.green500)),
          ),
        ],
      ),
    );
  }

  String _parseError(Object e) {
    final msg = e.toString().toLowerCase();
    if (msg.contains('401') || msg.contains('invalid') || msg.contains('wrong')) {
      return 'Invalid username or password.';
    }
    if (msg.contains('network') || msg.contains('connection') || msg.contains('socket')) {
      return 'No connection. Check your internet.';
    }
    return 'Something went wrong. Please try again.';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: RawbyPalette.darkBg,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Container(
                padding: const EdgeInsets.all(32),
                decoration: BoxDecoration(
                  color: RawbyPalette.darkSurface,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: RawbyPalette.darkBorder,
                    width: 1,
                  ),
                ),
                child: Form(
                  key: _formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Logo placeholder
                      Container(
                        width: 56,
                        height: 56,
                        decoration: BoxDecoration(
                          color: RawbyPalette.green500.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: const Icon(
                          Icons.videocam_rounded,
                          color: RawbyPalette.green500,
                          size: 28,
                        ),
                      ),
                      const SizedBox(height: 20),

                      // Title
                      const Text(
                        'RAWBY',
                        style: TextStyle(
                          color: RawbyPalette.textDark,
                          fontSize: 28,
                          fontWeight: FontWeight.w700,
                          letterSpacing: -0.5,
                        ),
                      ),
                      const SizedBox(height: 6),
                      const Text(
                        'to boost your process',
                        style: TextStyle(
                          color: RawbyPalette.textMutedDark,
                          fontSize: 14,
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                      const SizedBox(height: 8),

                      // Free Demo badge
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          border: Border.all(
                            color: RawbyPalette.darkBorder,
                            width: 1,
                          ),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: const Text(
                          'Free Demo Version',
                          style: TextStyle(
                            color: RawbyPalette.textMutedDark,
                            fontSize: 12,
                          ),
                        ),
                      ),
                      const SizedBox(height: 28),

                      // Username field
                      TextFormField(
                        controller: _usernameController,
                        style: const TextStyle(
                          color: Color(0xFF2A2A1A),
                          fontSize: 15,
                        ),
                        decoration: InputDecoration(
                          hintText: 'Username',
                          filled: true,
                          fillColor: RawbyPalette.inputCream,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: BorderSide.none,
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: const BorderSide(
                              color: RawbyPalette.green500,
                              width: 2,
                            ),
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 14,
                          ),
                        ),
                        textInputAction: TextInputAction.next,
                        autocorrect: false,
                        validator: (v) =>
                            (v == null || v.trim().isEmpty) ? 'Enter your username' : null,
                      ),
                      const SizedBox(height: 12),

                      // Password field
                      TextFormField(
                        controller: _passwordController,
                        obscureText: _obscurePassword,
                        style: const TextStyle(
                          color: Color(0xFF2A2A1A),
                          fontSize: 15,
                        ),
                        decoration: InputDecoration(
                          hintText: 'Password',
                          filled: true,
                          fillColor: RawbyPalette.inputCream,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: BorderSide.none,
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: const BorderSide(
                              color: RawbyPalette.green500,
                              width: 2,
                            ),
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 14,
                          ),
                          suffixIcon: IconButton(
                            icon: Icon(
                              _obscurePassword
                                  ? Icons.visibility_off_outlined
                                  : Icons.visibility_outlined,
                              color: const Color(0xFF8A8A7A),
                              size: 18,
                            ),
                            onPressed: () => setState(
                                () => _obscurePassword = !_obscurePassword),
                          ),
                        ),
                        textInputAction: TextInputAction.done,
                        onFieldSubmitted: (_) => _login(),
                        validator: (v) =>
                            (v == null || v.isEmpty) ? 'Enter your password' : null,
                      ),
                      const SizedBox(height: 8),

                      // Error message
                      if (_errorMessage != null) ...[
                        const SizedBox(height: 4),
                        Text(
                          _errorMessage!,
                          style: const TextStyle(
                            color: RawbyPalette.danger,
                            fontSize: 13,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 4),
                      ],

                      const SizedBox(height: 16),

                      // Login button
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: _isLoading ? null : _login,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: RawbyPalette.green500,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 15),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                            elevation: 0,
                          ),
                          child: _isLoading
                              ? const SizedBox(
                                  height: 20,
                                  width: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                              : const Text(
                                  'Log in',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                        ),
                      ),
                      const SizedBox(height: 28),

                      // Footer links
                      TextButton(
                        onPressed: () => _showAboutDialog(context),
                        child: const Text(
                          'What is RAWBY?',
                          style: TextStyle(
                            color: RawbyPalette.textMutedDark,
                            fontSize: 13,
                            decoration: TextDecoration.underline,
                            decorationColor: RawbyPalette.textMutedDark,
                          ),
                        ),
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Text(
                            'No account? ',
                            style: TextStyle(
                              color: RawbyPalette.textMutedDark,
                              fontSize: 13,
                            ),
                          ),
                          TextButton(
                            onPressed: () => context.go(Routes.register),
                            style: TextButton.styleFrom(
                              padding: EdgeInsets.zero,
                              minimumSize: Size.zero,
                              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            ),
                            child: const Text(
                              'Create one',
                              style: TextStyle(
                                color: RawbyPalette.textMutedDark,
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                decoration: TextDecoration.underline,
                                decorationColor: RawbyPalette.textMutedDark,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      TextButton(
                        onPressed: () => _showPrivacyDialog(context),
                        child: const Text(
                          'Privacy Policy & Terms',
                          style: TextStyle(
                            color: RawbyPalette.textMutedDark,
                            fontSize: 12,
                            decoration: TextDecoration.underline,
                            decorationColor: RawbyPalette.textMutedDark,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
