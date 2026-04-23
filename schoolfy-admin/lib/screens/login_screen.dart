import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/auth_provider.dart';
import '../providers/locale_provider.dart';
import '../providers/theme_provider.dart';
import '../l10n/app_localizations.dart';
import '../theme/app_theme.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen>
    with TickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;
  bool _obscurePassword = true;
  String? _errorMessage;

  late AnimationController _fadeController;
  late AnimationController _glowController;
  late Animation<double> _fadeAnim;
  late Animation<double> _slideAnim;
  late Animation<double> _glowAnim;

  static const _bg = Color(0xFF080B14);
  static const _card = Color(0xFF0D1526);
  static const _fieldBg = Color(0xFF0A1628);
  static const _border = Color(0xFF1E3A5F);
  static const _accent = Color(0xFF3B82F6);
  static const _accentDim = Color(0xFF1D4ED8);
  static const _textPrimary = Colors.white;
  static const _textMuted = Color(0xFF8B9BB4);

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..forward();
    _glowController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat(reverse: true);

    _fadeAnim = CurvedAnimation(parent: _fadeController, curve: Curves.easeOut);
    _slideAnim = Tween<double>(begin: 24, end: 0).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeOutCubic),
    );
    _glowAnim = CurvedAnimation(parent: _glowController, curve: Curves.easeInOut);
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _fadeController.dispose();
    _glowController.dispose();
    super.dispose();
  }

  Future<void> _signIn() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    final error = await Provider.of<AuthProvider>(context, listen: false)
        .signInWithEmailPassword(
      _emailController.text.trim(),
      _passwordController.text,
    );
    setState(() {
      _isLoading = false;
      _errorMessage = error;
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final isArabic = Provider.of<LocaleProvider>(context).isArabic;

    return Directionality(
      textDirection: isArabic ? TextDirection.rtl : TextDirection.ltr,
      child: Scaffold(
        backgroundColor: _bg,
        body: Stack(
          children: [
            _buildGlowOrb(top: -120, left: -120, size: 480,
                color: _accent, opacity: 0.10, pulse: true),
            _buildGlowOrb(bottom: -160, right: -80, size: 420,
                color: _accentDim, opacity: 0.08, pulse: true, invert: true),

            Center(
              child: AnimatedBuilder(
                animation: _fadeController,
                builder: (_, child) => Opacity(
                  opacity: _fadeAnim.value,
                  child: Transform.translate(
                    offset: Offset(0, _slideAnim.value),
                    child: child,
                  ),
                ),
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(24),
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 420),
                    child: AnimatedBuilder(
                      animation: _glowAnim,
                      builder: (_, child) => Container(
                        padding: const EdgeInsets.all(36),
                        decoration: BoxDecoration(
                          color: _card,
                          borderRadius: BorderRadius.circular(24),
                          border: Border.all(color: _border),
                          boxShadow: [
                            BoxShadow(
                              color: _accent.withValues(alpha: 0.06 + _glowAnim.value * 0.04),
                              blurRadius: 50,
                              spreadRadius: -4,
                            ),
                            const BoxShadow(
                              color: Colors.black54,
                              blurRadius: 30,
                            ),
                          ],
                        ),
                        child: child,
                      ),
                      child: Form(
                        key: _formKey,
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildLogo(),
                            const SizedBox(height: 24),
                            const Center(
                              child: Text(
                                'Schoolfy Admin',
                                style: TextStyle(
                                  fontSize: 26,
                                  fontWeight: FontWeight.w700,
                                  color: _textPrimary,
                                  letterSpacing: 0.3,
                                ),
                              ),
                            ),
                            const SizedBox(height: 6),
                            Center(
                              child: Text(
                                l10n.dashboard,
                                style: const TextStyle(
                                    fontSize: 14, color: _textMuted),
                              ),
                            ),
                            const SizedBox(height: 32),

                            _buildLabel(l10n.email),
                            const SizedBox(height: 8),
                            _buildField(
                              controller: _emailController,
                              hint: 'admin@example.com',
                              icon: Icons.email_outlined,
                              keyboardType: TextInputType.emailAddress,
                              validator: (v) {
                                if (v?.isEmpty ?? true) return 'Enter your email';
                                if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$')
                                    .hasMatch(v!)) {
                                  return 'Enter a valid email';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 20),

                            _buildLabel(l10n.password),
                            const SizedBox(height: 8),
                            _buildField(
                              controller: _passwordController,
                              hint: '••••••••',
                              icon: Icons.lock_outlined,
                              obscure: _obscurePassword,
                              suffix: IconButton(
                                icon: Icon(
                                  _obscurePassword
                                      ? Icons.visibility_outlined
                                      : Icons.visibility_off_outlined,
                                  color: _textMuted,
                                  size: 20,
                                ),
                                onPressed: () => setState(
                                    () => _obscurePassword = !_obscurePassword),
                              ),
                              validator: (v) {
                                if (v?.isEmpty ?? true) return 'Enter your password';
                                if (v!.length < 6) return 'Min 6 characters';
                                return null;
                              },
                            ),
                            const SizedBox(height: 10),

                            Align(
                              alignment: isArabic
                                  ? Alignment.centerLeft
                                  : Alignment.centerRight,
                              child: TextButton(
                                onPressed:
                                    _isLoading ? null : _showForgotPasswordDialog,
                                style: TextButton.styleFrom(
                                  foregroundColor: _accent,
                                  padding: EdgeInsets.zero,
                                  minimumSize: Size.zero,
                                  tapTargetSize:
                                      MaterialTapTargetSize.shrinkWrap,
                                ),
                                child: Text(l10n.forgotPassword,
                                    style: const TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w500)),
                              ),
                            ),
                            const SizedBox(height: 24),

                            if (_errorMessage != null) ...[
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 14, vertical: 12),
                                decoration: BoxDecoration(
                                  color: AppTheme.errorColor.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(
                                      color: AppTheme.errorColor.withValues(alpha: 0.3)),
                                ),
                                child: Row(
                                  children: [
                                    const Icon(Icons.error_outline,
                                        color: AppTheme.errorColor, size: 18),
                                    const SizedBox(width: 10),
                                    Expanded(
                                      child: Text(
                                        _errorMessage!,
                                        style: const TextStyle(
                                            color: AppTheme.errorColor,
                                            fontSize: 13),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 20),
                            ],

                            _buildSignInButton(l10n),
                            const SizedBox(height: 24),

                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                TextButton.icon(
                                  onPressed: () =>
                                      Provider.of<LocaleProvider>(context,
                                              listen: false)
                                          .toggleLocale(),
                                  icon: const Icon(Icons.language,
                                      size: 15, color: _textMuted),
                                  label: Text(
                                    isArabic ? l10n.english : l10n.arabic,
                                    style: const TextStyle(
                                        color: _textMuted, fontSize: 13),
                                  ),
                                  style: TextButton.styleFrom(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 8)),
                                ),
                                Consumer<ThemeProvider>(
                                  builder: (_, tp, __) => IconButton(
                                    onPressed: tp.toggleTheme,
                                    icon: Icon(
                                      tp.isDarkMode
                                          ? Icons.light_mode_outlined
                                          : Icons.dark_mode_outlined,
                                      color: _textMuted,
                                      size: 18,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGlowOrb({
    double? top,
    double? bottom,
    double? left,
    double? right,
    required double size,
    required Color color,
    required double opacity,
    bool pulse = false,
    bool invert = false,
  }) {
    return AnimatedBuilder(
      animation: _glowAnim,
      builder: (_, __) {
        final t = invert ? (1 - _glowAnim.value) : _glowAnim.value;
        return Positioned(
          top: top,
          bottom: bottom,
          left: left,
          right: right,
          child: Container(
            width: size,
            height: size,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [
                  color.withValues(alpha: opacity + (pulse ? t * 0.05 : 0)),
                  Colors.transparent,
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildLogo() {
    return Center(
      child: AnimatedBuilder(
        animation: _glowAnim,
        builder: (_, __) => Container(
          width: 72,
          height: 72,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFF1D4ED8), Color(0xFF3B82F6)],
            ),
            boxShadow: [
              BoxShadow(
                color: _accent.withValues(alpha: 0.35 + _glowAnim.value * 0.2),
                blurRadius: 20 + _glowAnim.value * 12,
              ),
            ],
          ),
          child: const Icon(
            Icons.admin_panel_settings_rounded,
            color: Colors.white,
            size: 34,
          ),
        ),
      ),
    );
  }

  Widget _buildLabel(String text) => Text(
        text,
        style: const TextStyle(
            fontSize: 13, fontWeight: FontWeight.w500, color: _textMuted),
      );

  Widget _buildField({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    TextInputType? keyboardType,
    bool obscure = false,
    Widget? suffix,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      obscureText: obscure,
      keyboardType: keyboardType,
      style: const TextStyle(color: Colors.white, fontSize: 15),
      cursorColor: _accent,
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(color: Color(0xFF3D4F6A), fontSize: 14),
        prefixIcon: Icon(icon, color: const Color(0xFF3D5A80), size: 20),
        suffixIcon: suffix,
        filled: true,
        fillColor: _fieldBg,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: _border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: _border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: _accent, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: AppTheme.errorColor.withValues(alpha: 0.7)),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide:
              const BorderSide(color: AppTheme.errorColor, width: 1.5),
        ),
        errorStyle:
            const TextStyle(color: AppTheme.errorColor, fontSize: 12),
      ),
      validator: validator,
    );
  }

  Widget _buildSignInButton(AppLocalizations l10n) {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: _isLoading ? null : _signIn,
          borderRadius: BorderRadius.circular(12),
          child: AnimatedBuilder(
            animation: _glowAnim,
            builder: (_, child) => Ink(
              decoration: BoxDecoration(
                gradient: _isLoading
                    ? LinearGradient(
                        colors: [
                          Colors.grey.shade800,
                          Colors.grey.shade700
                        ],
                      )
                    : const LinearGradient(
                        colors: [Color(0xFF1D4ED8), Color(0xFF3B82F6)],
                      ),
                borderRadius: BorderRadius.circular(12),
                boxShadow: _isLoading
                    ? []
                    : [
                        BoxShadow(
                          color: _accent.withValues(alpha: 0.35 + _glowAnim.value * 0.15),
                          blurRadius: 18,
                          offset: const Offset(0, 4),
                        ),
                      ],
              ),
              child: child,
            ),
            child: Container(
              alignment: Alignment.center,
              child: _isLoading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor:
                            AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : Text(
                      l10n.signIn,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
            ),
          ),
        ),
      ),
    );
  }

  void _showForgotPasswordDialog() {
    final l10n = AppLocalizations.of(context)!;
    final emailController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: _card,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: _border),
        ),
        title: const Text('Reset Password',
            style: TextStyle(color: _textPrimary)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Enter your email to receive reset instructions.',
              style: TextStyle(color: _textMuted, fontSize: 14),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: emailController,
              keyboardType: TextInputType.emailAddress,
              style: const TextStyle(color: Colors.white),
              cursorColor: _accent,
              decoration: InputDecoration(
                labelText: l10n.email,
                labelStyle: const TextStyle(color: _textMuted),
                prefixIcon: const Icon(Icons.email_outlined,
                    color: Color(0xFF3D5A80), size: 20),
                filled: true,
                fillColor: _fieldBg,
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: _border)),
                enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: _border)),
                focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide:
                        const BorderSide(color: _accent, width: 1.5)),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(l10n.cancel,
                style: const TextStyle(color: _textMuted)),
          ),
          ElevatedButton(
            onPressed: () async {
              if (emailController.text.isNotEmpty) {
                try {
                  await Provider.of<AuthProvider>(context, listen: false)
                      .resetPassword(emailController.text);
                  if (mounted) {
                    Navigator.of(context).pop();
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Password reset email sent!'),
                        backgroundColor: AppTheme.successColor,
                      ),
                    );
                  }
                } catch (e) {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Error: $e'),
                        backgroundColor: AppTheme.errorColor,
                      ),
                    );
                  }
                }
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: _accent,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8)),
            ),
            child: Text(l10n.resetPassword),
          ),
        ],
      ),
    );
  }
}
