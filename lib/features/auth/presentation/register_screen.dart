import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/theme/app_colors.dart';
import '../providers/auth_provider.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Password strength helper
// ─────────────────────────────────────────────────────────────────────────────

enum _PasswordStrength { empty, weak, fair, strong }

_PasswordStrength _evalStrength(String pw) {
  if (pw.isEmpty) return _PasswordStrength.empty;
  int score = 0;
  if (pw.length >= 8) score++;
  if (RegExp(r'[A-Z]').hasMatch(pw)) score++;
  if (RegExp(r'[0-9]').hasMatch(pw)) score++;
  if (RegExp(r'[!@#\$%^&*(),.?":{}|<>]').hasMatch(pw)) score++;
  if (score <= 1) return _PasswordStrength.weak;
  if (score == 2) return _PasswordStrength.fair;
  return _PasswordStrength.strong;
}

// ─────────────────────────────────────────────────────────────────────────────
// Screen
// ─────────────────────────────────────────────────────────────────────────────

class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({super.key});

  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameFocus    = FocusNode();
  final _emailFocus   = FocusNode();
  final _passwordFocus = FocusNode();
  final _confirmFocus  = FocusNode();

  final _nameCtrl     = TextEditingController();
  final _emailCtrl    = TextEditingController();
  final _passwordCtrl = TextEditingController();
  final _confirmCtrl  = TextEditingController();

  bool _obscurePassword = true;
  bool _obscureConfirm  = true;
  bool _isLoading       = false;
  _PasswordStrength _strength = _PasswordStrength.empty;

  @override
  void initState() {
    super.initState();
    _passwordCtrl.addListener(() {
      final s = _evalStrength(_passwordCtrl.text);
      if (s != _strength) setState(() => _strength = s);
    });
  }

  @override
  void dispose() {
    _nameFocus.dispose();
    _emailFocus.dispose();
    _passwordFocus.dispose();
    _confirmFocus.dispose();
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    _confirmCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);
    await ref.read(authProvider.notifier).signUp(
          name: _nameCtrl.text,
          email: _emailCtrl.text,
          password: _passwordCtrl.text,
        );
    if (mounted) setState(() => _isLoading = false);
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.error_outline_rounded, color: Colors.white, size: 18),
            const SizedBox(width: 10),
            Expanded(child: Text(message, style: const TextStyle(color: Colors.white))),
          ],
        ),
        backgroundColor: AppColors.danger,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  // ── UI helpers ─────────────────────────────────────────────────────────────

  (Color, String) get _strengthMeta => switch (_strength) {
        _PasswordStrength.empty  => (Colors.transparent, ''),
        _PasswordStrength.weak   => (AppColors.danger,   'Weak'),
        _PasswordStrength.fair   => (AppColors.warning,  'Fair'),
        _PasswordStrength.strong => (AppColors.success,  'Strong'),
      };

  int get _strengthSteps => switch (_strength) {
        _PasswordStrength.empty  => 0,
        _PasswordStrength.weak   => 1,
        _PasswordStrength.fair   => 2,
        _PasswordStrength.strong => 3,
      };

  @override
  Widget build(BuildContext context) {
    ref.listen<AuthState>(authProvider, (previous, next) {
      final err = next.errorMessage;
      if (err != null && err != previous?.errorMessage) {
        _showError(err);
        ref.read(authProvider.notifier).clearError();
      }
    });

    final size = MediaQuery.sizeOf(context);
    final (strengthColor, strengthLabel) = _strengthMeta;

    return Scaffold(
      backgroundColor: const Color(0xFF0A0F1E),
      body: Stack(
        children: [
          // ── Decorative background blobs ─────────────────────────────────
          Positioned(
            top: -80,
            left: -60,
            child: _Blob(
              size: 280,
              color: AppColors.primary.withValues(alpha: 0.35),
            ),
          ),
          Positioned(
            top: 40,
            right: -40,
            child: _Blob(
              size: 200,
              color: AppColors.secondary.withValues(alpha: 0.25),
            ),
          ),
          Positioned(
            top: 160,
            left: size.width * 0.3,
            child: _Blob(
              size: 150,
              color: const Color(0xFF8B5CF6).withValues(alpha: 0.2),
            ),
          ),

          // ── Main content ────────────────────────────────────────────────
          SafeArea(
            child: Column(
              children: [
                // Back button + branding
                _TopBar(),

                // Scrollable card
                Expanded(
                  child: SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(28),
                        child: BackdropFilter(
                          filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
                          child: Container(
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.06),
                              borderRadius: BorderRadius.circular(28),
                              border: Border.all(
                                color: Colors.white.withValues(alpha: 0.12),
                              ),
                            ),
                            padding: const EdgeInsets.fromLTRB(24, 28, 24, 32),
                            child: Form(
                              key: _formKey,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  // Title
                                  Text(
                                    'Create Account',
                                    style: GoogleFonts.outfit(
                                      fontSize: 30,
                                      fontWeight: FontWeight.w800,
                                      color: Colors.white,
                                      letterSpacing: -0.5,
                                    ),
                                  )
                                      .animate()
                                      .fadeIn(duration: 500.ms)
                                      .slideY(begin: 0.3, end: 0, curve: Curves.easeOut),

                                  const SizedBox(height: 6),

                                  Text(
                                    'Join DIU CGPA Tracker — your academic journey starts here.',
                                    style: GoogleFonts.inter(
                                      fontSize: 13,
                                      color: Colors.white60,
                                      fontWeight: FontWeight.w400,
                                      height: 1.5,
                                    ),
                                  )
                                      .animate(delay: 80.ms)
                                      .fadeIn(duration: 400.ms),

                                  const SizedBox(height: 28),

                                  // ── Full Name ─────────────────────────
                                  _GlassField(
                                    controller: _nameCtrl,
                                    focusNode: _nameFocus,
                                    nextFocus: _emailFocus,
                                    label: 'Full Name',
                                    hint: 'e.g. Jahirun Hassan',
                                    icon: Icons.person_outline_rounded,
                                    textCapitalization: TextCapitalization.words,
                                    validator: (v) {
                                      if (v == null || v.trim().isEmpty) {
                                        return 'Please enter your full name';
                                      }
                                      return null;
                                    },
                                  )
                                      .animate(delay: 140.ms)
                                      .fadeIn(duration: 400.ms)
                                      .slideY(begin: 0.15, end: 0),

                                  const SizedBox(height: 16),

                                  // ── Email ────────────────────────────
                                  _GlassField(
                                    controller: _emailCtrl,
                                    focusNode: _emailFocus,
                                    nextFocus: _passwordFocus,
                                    label: 'Email Address',
                                    hint: 'you@diu.edu.bd',
                                    icon: Icons.alternate_email_rounded,
                                    keyboardType: TextInputType.emailAddress,
                                    validator: (v) {
                                      if (v == null || v.trim().isEmpty) {
                                        return 'Please enter your email';
                                      }
                                      if (!RegExp(r'^[\w\.\+\-]+@[\w\-]+\.[a-z]{2,}$')
                                          .hasMatch(v.trim())) {
                                        return 'Enter a valid email address';
                                      }
                                      return null;
                                    },
                                  )
                                      .animate(delay: 200.ms)
                                      .fadeIn(duration: 400.ms)
                                      .slideY(begin: 0.15, end: 0),

                                  const SizedBox(height: 16),

                                  // ── Password ─────────────────────────
                                  _GlassField(
                                    controller: _passwordCtrl,
                                    focusNode: _passwordFocus,
                                    nextFocus: _confirmFocus,
                                    label: 'Password',
                                    hint: 'Min. 8 characters',
                                    icon: Icons.lock_outline_rounded,
                                    obscureText: _obscurePassword,
                                    suffixIcon: _EyeToggle(
                                      obscure: _obscurePassword,
                                      onTap: () => setState(
                                          () => _obscurePassword = !_obscurePassword),
                                    ),
                                    validator: (v) {
                                      if (v == null || v.isEmpty) {
                                        return 'Please enter a password';
                                      }
                                      if (v.length < 8) {
                                        return 'Password must be at least 8 characters';
                                      }
                                      return null;
                                    },
                                  )
                                      .animate(delay: 260.ms)
                                      .fadeIn(duration: 400.ms)
                                      .slideY(begin: 0.15, end: 0),

                                  // Strength bar
                                  if (_strength != _PasswordStrength.empty) ...[
                                    const SizedBox(height: 10),
                                    _StrengthBar(
                                      steps: _strengthSteps,
                                      color: strengthColor,
                                      label: strengthLabel,
                                    ).animate().fadeIn(duration: 250.ms),
                                  ],

                                  const SizedBox(height: 16),

                                  // ── Confirm Password ──────────────────
                                  _GlassField(
                                    controller: _confirmCtrl,
                                    focusNode: _confirmFocus,
                                    label: 'Confirm Password',
                                    hint: 'Re-enter your password',
                                    icon: Icons.lock_outline_rounded,
                                    obscureText: _obscureConfirm,
                                    textInputAction: TextInputAction.done,
                                    onFieldSubmitted: (_) => _submit(),
                                    suffixIcon: _EyeToggle(
                                      obscure: _obscureConfirm,
                                      onTap: () => setState(
                                          () => _obscureConfirm = !_obscureConfirm),
                                    ),
                                    validator: (v) {
                                      if (v == null || v.isEmpty) {
                                        return 'Please confirm your password';
                                      }
                                      if (v != _passwordCtrl.text) {
                                        return 'Passwords do not match';
                                      }
                                      return null;
                                    },
                                  )
                                      .animate(delay: 320.ms)
                                      .fadeIn(duration: 400.ms)
                                      .slideY(begin: 0.15, end: 0),

                                  const SizedBox(height: 28),

                                  // ── Submit button ─────────────────────
                                  _SubmitButton(
                                    isLoading: _isLoading,
                                    onPressed: _isLoading ? null : _submit,
                                  )
                                      .animate(delay: 380.ms)
                                      .fadeIn(duration: 400.ms)
                                      .slideY(begin: 0.2, end: 0),

                                  const SizedBox(height: 20),

                                  // ── Sign in link ──────────────────────
                                  Center(
                                    child: GestureDetector(
                                      onTap: () => context.go('/login'),
                                      child: RichText(
                                        text: TextSpan(
                                          style: GoogleFonts.inter(
                                            fontSize: 13.5,
                                            color: Colors.white54,
                                          ),
                                          children: [
                                            const TextSpan(
                                                text: 'Already have an account?  '),
                                            TextSpan(
                                              text: 'Sign In',
                                              style: GoogleFonts.inter(
                                                fontSize: 13.5,
                                                color: AppColors.secondary,
                                                fontWeight: FontWeight.w700,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ).animate(delay: 440.ms).fadeIn(duration: 400.ms),
                                ],
                              ),
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
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Top bar
// ─────────────────────────────────────────────────────────────────────────────

class _TopBar extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 8, 16, 0),
      child: Row(
        children: [
          IconButton(
            onPressed: () => context.go('/auth'),
            icon: Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.08),
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
              ),
              child: const Icon(
                Icons.arrow_back_ios_new_rounded,
                size: 16,
                color: Colors.white,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'DIU CGPA Tracker',
                style: GoogleFonts.outfit(
                  fontSize: 13,
                  color: Colors.white38,
                  fontWeight: FontWeight.w500,
                  letterSpacing: 0.5,
                ),
              ),
              Text(
                'New Account',
                style: GoogleFonts.outfit(
                  fontSize: 16,
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const Spacer(),
          // Step indicator pill
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppColors.primary.withValues(alpha: 0.4)),
            ),
            child: Text(
              'Step 1 of 2',
              style: GoogleFonts.inter(
                fontSize: 11,
                color: AppColors.primary.withValues(alpha: 0.9),
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    ).animate().fadeIn(duration: 400.ms);
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Glassmorphism text field
// ─────────────────────────────────────────────────────────────────────────────

class _GlassField extends StatefulWidget {
  final TextEditingController controller;
  final FocusNode focusNode;
  final FocusNode? nextFocus;
  final String label;
  final String hint;
  final IconData icon;
  final TextInputType keyboardType;
  final TextCapitalization textCapitalization;
  final bool obscureText;
  final Widget? suffixIcon;
  final TextInputAction textInputAction;
  final ValueChanged<String>? onFieldSubmitted;
  final FormFieldValidator<String>? validator;

  const _GlassField({
    required this.controller,
    required this.focusNode,
    this.nextFocus,
    required this.label,
    required this.hint,
    required this.icon,
    this.keyboardType = TextInputType.text,
    this.textCapitalization = TextCapitalization.none,
    this.obscureText = false,
    this.suffixIcon,
    this.textInputAction = TextInputAction.next,
    this.onFieldSubmitted,
    this.validator,
  });

  @override
  State<_GlassField> createState() => _GlassFieldState();
}

class _GlassFieldState extends State<_GlassField> {
  bool _focused = false;

  @override
  void initState() {
    super.initState();
    widget.focusNode.addListener(() {
      if (mounted) setState(() => _focused = widget.focusNode.hasFocus);
    });
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: _focused
              ? AppColors.primary.withValues(alpha: 0.7)
              : Colors.white.withValues(alpha: 0.10),
          width: _focused ? 1.5 : 1.0,
        ),
        color: _focused
            ? Colors.white.withValues(alpha: 0.09)
            : Colors.white.withValues(alpha: 0.05),
        boxShadow: _focused
            ? [
                BoxShadow(
                  color: AppColors.primary.withValues(alpha: 0.15),
                  blurRadius: 16,
                  offset: const Offset(0, 4),
                )
              ]
            : [],
      ),
      child: TextFormField(
        controller: widget.controller,
        focusNode: widget.focusNode,
        keyboardType: widget.keyboardType,
        textCapitalization: widget.textCapitalization,
        obscureText: widget.obscureText,
        textInputAction: widget.textInputAction,
        onFieldSubmitted: widget.onFieldSubmitted ??
            (_) {
              if (widget.nextFocus != null) {
                FocusScope.of(context).requestFocus(widget.nextFocus);
              }
            },
        validator: widget.validator,
        style: GoogleFonts.inter(
          fontSize: 15,
          fontWeight: FontWeight.w500,
          color: Colors.white,
        ),
        decoration: InputDecoration(
          labelText: widget.label,
          labelStyle: GoogleFonts.inter(
            fontSize: 13,
            color: _focused ? AppColors.primary.withValues(alpha: 0.9) : Colors.white38,
            fontWeight: FontWeight.w500,
          ),
          hintText: widget.hint,
          hintStyle: GoogleFonts.inter(
            fontSize: 14,
            color: Colors.white24,
          ),
          prefixIcon: Padding(
            padding: const EdgeInsets.only(left: 4),
            child: Icon(
              widget.icon,
              size: 20,
              color: _focused ? AppColors.primary.withValues(alpha: 0.8) : Colors.white30,
            ),
          ),
          suffixIcon: widget.suffixIcon,
          filled: false,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
          border: InputBorder.none,
          enabledBorder: InputBorder.none,
          focusedBorder: InputBorder.none,
          errorBorder: InputBorder.none,
          focusedErrorBorder: InputBorder.none,
          errorStyle: GoogleFonts.inter(
            fontSize: 11.5,
            color: AppColors.danger,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Eye toggle
// ─────────────────────────────────────────────────────────────────────────────

class _EyeToggle extends StatelessWidget {
  final bool obscure;
  final VoidCallback onTap;
  const _EyeToggle({required this.obscure, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Icon(
          obscure ? Icons.visibility_outlined : Icons.visibility_off_outlined,
          size: 20,
          color: Colors.white38,
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Password strength bar
// ─────────────────────────────────────────────────────────────────────────────

class _StrengthBar extends StatelessWidget {
  final int steps;     // 1, 2, or 3
  final Color color;
  final String label;
  const _StrengthBar({required this.steps, required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        ...List.generate(3, (i) {
          final active = i < steps;
          return Expanded(
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              margin: EdgeInsets.only(right: i < 2 ? 4 : 0),
              height: 4,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(4),
                color: active ? color : Colors.white12,
              ),
            ),
          );
        }),
        const SizedBox(width: 10),
        Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 11.5,
            fontWeight: FontWeight.w600,
            color: color,
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Submit button
// ─────────────────────────────────────────────────────────────────────────────

class _SubmitButton extends StatelessWidget {
  final bool isLoading;
  final VoidCallback? onPressed;
  const _SubmitButton({required this.isLoading, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onPressed,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        height: 56,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: onPressed != null
              ? const LinearGradient(
                  colors: [Color(0xFF6366F1), Color(0xFF4F46E5), Color(0xFF4338CA)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                )
              : null,
          color: onPressed == null ? Colors.white12 : null,
          boxShadow: onPressed != null
              ? [
                  BoxShadow(
                    color: AppColors.primary.withValues(alpha: 0.45),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  )
                ]
              : [],
        ),
        child: Center(
          child: isLoading
              ? const SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.5,
                    color: Colors.white,
                  ),
                )
              : Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Create Account',
                      style: GoogleFonts.outfit(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                        letterSpacing: 0.3,
                      ),
                    ),
                    const SizedBox(width: 8),
                    const Icon(
                      Icons.arrow_forward_rounded,
                      color: Colors.white,
                      size: 18,
                    ),
                  ],
                ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Decorative blob
// ─────────────────────────────────────────────────────────────────────────────

class _Blob extends StatelessWidget {
  final double size;
  final Color color;
  const _Blob({required this.size, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: color,
      ),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 60, sigmaY: 60),
        child: const SizedBox.expand(),
      ),
    );
  }
}