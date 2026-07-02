import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/theme/app_colors.dart';
import '../providers/auth_provider.dart';

// ── Onboarding design tokens ──────────────────────────────────────────────────
const _kBg       = Color(0xFF07111F);
const _kBgAlt    = Color(0xFF0B1730);
const _kSurface1 = Color(0xFF121826);
const _kSurface3 = Color(0xFF1E2A3E);
const _kPrimary  = Color(0xFF6C63FF);
const _kTxtPri   = Color(0xFFF8FAFC);
const _kTxtSec   = Color(0xFF94A3B8);
const _kTxtDis   = Color(0xFF64748B);
const _kBorder   = Color(0x1AFFFFFF);    // white 10 %
const _kSuccess  = Color(0xFF10B981);
const _kWarning  = Color(0xFFF59E0B);
const _kError    = Color(0xFFEF4444);

// ─────────────────────────────────────────────────────────────────────────────
// Password strength
// ─────────────────────────────────────────────────────────────────────────────

enum _Strength { empty, weak, fair, strong }

_Strength _evalStrength(String pw) {
  if (pw.isEmpty) return _Strength.empty;
  int s = 0;
  if (pw.length >= 8) s++;
  if (RegExp(r'[A-Z]').hasMatch(pw)) s++;
  if (RegExp(r'[0-9]').hasMatch(pw)) s++;
  if (RegExp(r'[!@#\$%^&*(),.?":{}|<>]').hasMatch(pw)) s++;
  if (s <= 1) return _Strength.weak;
  if (s == 2) return _Strength.fair;
  return _Strength.strong;
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
  final _nameFocus     = FocusNode();
  final _emailFocus    = FocusNode();
  final _passwordFocus = FocusNode();
  final _confirmFocus  = FocusNode();

  final _nameCtrl     = TextEditingController();
  final _emailCtrl    = TextEditingController();
  final _passwordCtrl = TextEditingController();
  final _confirmCtrl  = TextEditingController();

  bool _obscurePw      = true;
  bool _obscureConfirm = true;
  bool _isLoading      = false;
  _Strength _strength  = _Strength.empty;

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

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(children: [
          const Icon(Icons.error_outline_rounded, color: _kTxtPri, size: 17),
          const SizedBox(width: 10),
          Expanded(
            child: Text(msg,
                style: GoogleFonts.inter(color: _kTxtPri, fontSize: 13)),
          ),
        ]),
        backgroundColor: _kError,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  (Color, String) get _strengthMeta => switch (_strength) {
        _Strength.empty  => (Colors.transparent, ''),
        _Strength.weak   => (_kError,   'Weak'),
        _Strength.fair   => (_kWarning, 'Fair'),
        _Strength.strong => (_kSuccess, 'Strong'),
      };

  int get _strengthSteps => switch (_strength) {
        _Strength.empty  => 0,
        _Strength.weak   => 1,
        _Strength.fair   => 2,
        _Strength.strong => 3,
      };

  @override
  Widget build(BuildContext context) {
    ref.listen<AuthState>(authProvider, (prev, next) {
      final err = next.errorMessage;
      if (err != null && err != prev?.errorMessage) {
        _showError(err);
        ref.read(authProvider.notifier).clearError();
      }
    });

    final (strengthColor, strengthLabel) = _strengthMeta;

    return Scaffold(
      backgroundColor: _kBg,
      body: Container(
        // Subtle diagonal gradient background
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [_kBg, _kBgAlt],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // ── Top bar ──────────────────────────────────────────────
              _TopBar(),

              // ── Scrollable form card ──────────────────────────────────
              Expanded(
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
                  child: Container(
                    decoration: BoxDecoration(
                      color: _kSurface1,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: _kBorder),
                      boxShadow: const [
                        BoxShadow(
                          color: Color(0x26000000),
                          blurRadius: 20,
                          offset: Offset(0, 6),
                        ),
                      ],
                    ),
                    padding: const EdgeInsets.fromLTRB(24, 26, 24, 28),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          // Title
                          Text(
                            'Create Account',
                            style: GoogleFonts.outfit(
                              fontSize: 26,
                              fontWeight: FontWeight.w800,
                              color: _kTxtPri,
                              letterSpacing: -0.5,
                            ),
                          )
                              .animate()
                              .fadeIn(duration: 450.ms)
                              .slideY(begin: 0.25, end: 0, curve: Curves.easeOut),

                          const SizedBox(height: 6),

                          Text(
                            'Join DIU CGPA Tracker — your academic journey starts here.',
                            style: GoogleFonts.inter(
                              fontSize: 13,
                              color: _kTxtSec,
                              height: 1.5,
                            ),
                          ).animate(delay: 60.ms).fadeIn(duration: 400.ms),

                          const SizedBox(height: 24),

                          // Full Name
                          _DarkField(
                            controller: _nameCtrl,
                            focusNode: _nameFocus,
                            nextFocus: _emailFocus,
                            label: 'Full Name',
                            hint: 'e.g. Jahirun Hassan',
                            icon: Icons.person_outline_rounded,
                            textCapitalization: TextCapitalization.words,
                            validator: (v) => (v == null || v.trim().isEmpty)
                                ? 'Please enter your full name'
                                : null,
                          ).animate(delay: 100.ms).fadeIn(duration: 380.ms).slideY(begin: 0.12, end: 0),

                          const SizedBox(height: 14),

                          // Email
                          _DarkField(
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
                          ).animate(delay: 150.ms).fadeIn(duration: 380.ms).slideY(begin: 0.12, end: 0),

                          const SizedBox(height: 14),

                          // Password
                          _DarkField(
                            controller: _passwordCtrl,
                            focusNode: _passwordFocus,
                            nextFocus: _confirmFocus,
                            label: 'Password',
                            hint: 'Min. 8 characters',
                            icon: Icons.lock_outline_rounded,
                            obscureText: _obscurePw,
                            suffixIcon: _EyeToggle(
                              obscure: _obscurePw,
                              onTap: () => setState(() => _obscurePw = !_obscurePw),
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
                          ).animate(delay: 200.ms).fadeIn(duration: 380.ms).slideY(begin: 0.12, end: 0),

                          // Strength bar
                          if (_strength != _Strength.empty) ...[
                            const SizedBox(height: 10),
                            _StrengthBar(
                              steps: _strengthSteps,
                              color: strengthColor,
                              label: strengthLabel,
                            ).animate().fadeIn(duration: 250.ms),
                          ],

                          const SizedBox(height: 14),

                          // Confirm password
                          _DarkField(
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
                              onTap: () =>
                                  setState(() => _obscureConfirm = !_obscureConfirm),
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
                          ).animate(delay: 250.ms).fadeIn(duration: 380.ms).slideY(begin: 0.12, end: 0),

                          const SizedBox(height: 24),

                          // Submit
                          _PrimaryButton(
                            isLoading: _isLoading,
                            label: 'Create Account',
                            trailingIcon: Icons.arrow_forward_rounded,
                            onPressed: _isLoading ? null : _submit,
                          ).animate(delay: 300.ms).fadeIn(duration: 380.ms).slideY(begin: 0.15, end: 0),

                          const SizedBox(height: 18),

                          // Sign in link
                          Center(
                            child: GestureDetector(
                              onTap: () => context.go('/login'),
                              child: RichText(
                                text: TextSpan(
                                  style: GoogleFonts.inter(
                                    fontSize: 13,
                                    color: _kTxtSec,
                                  ),
                                  children: [
                                    const TextSpan(text: 'Already have an account?  '),
                                    TextSpan(
                                      text: 'Sign In',
                                      style: GoogleFonts.inter(
                                        fontSize: 13,
                                        color: _kPrimary,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ).animate(delay: 360.ms).fadeIn(duration: 380.ms),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
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
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.07),
                shape: BoxShape.circle,
                border: Border.all(color: _kBorder),
              ),
              child: const Icon(
                Icons.arrow_back_ios_new_rounded,
                size: 15,
                color: _kTxtSec,
              ),
            ),
          ),
          const SizedBox(width: 6),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'DIU CGPA Tracker',
                style: GoogleFonts.outfit(
                  fontSize: 11,
                  color: _kTxtDis,
                  letterSpacing: 0.4,
                ),
              ),
              Text(
                'New Account',
                style: GoogleFonts.outfit(
                  fontSize: 15,
                  color: _kTxtPri,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const Spacer(),
          // Step indicator
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 5),
            decoration: BoxDecoration(
              color: _kPrimary.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: _kPrimary.withValues(alpha: 0.30)),
            ),
            child: Text(
              'Step 1 of 2',
              style: GoogleFonts.inter(
                fontSize: 11,
                color: _kPrimary,
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
// Dark text field
// ─────────────────────────────────────────────────────────────────────────────

class _DarkField extends StatefulWidget {
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

  const _DarkField({
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
  State<_DarkField> createState() => _DarkFieldState();
}

class _DarkFieldState extends State<_DarkField> {
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
      duration: const Duration(milliseconds: 180),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: _focused
              ? _kPrimary.withValues(alpha: 0.80)
              : Colors.white.withValues(alpha: 0.10),
          width: _focused ? 1.5 : 1.0,
        ),
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
          color: _kTxtPri,
        ),
        decoration: InputDecoration(
          labelText: widget.label,
          labelStyle: GoogleFonts.inter(
            fontSize: 13,
            color: _focused ? _kPrimary : _kTxtSec,
            fontWeight: FontWeight.w500,
          ),
          hintText: widget.hint,
          hintStyle: GoogleFonts.inter(fontSize: 14, color: _kTxtDis),
          prefixIcon: Padding(
            padding: const EdgeInsets.only(left: 2),
            child: Icon(widget.icon,
                size: 19,
                color: _focused ? _kPrimary : _kTxtSec),
          ),
          suffixIcon: widget.suffixIcon,
          filled: true,
          fillColor: _kSurface3,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide.none,
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide.none,
          ),
          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide.none,
          ),
          focusedErrorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide.none,
          ),
          errorStyle: GoogleFonts.inter(
            fontSize: 11.5,
            color: _kError,
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
          obscure
              ? Icons.visibility_outlined
              : Icons.visibility_off_outlined,
          size: 19,
          color: _kTxtDis,
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Password strength bar
// ─────────────────────────────────────────────────────────────────────────────

class _StrengthBar extends StatelessWidget {
  final int steps;
  final Color color;
  final String label;
  const _StrengthBar(
      {required this.steps, required this.color, required this.label});

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
              height: 3,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(4),
                color: active ? color : Colors.white.withValues(alpha: 0.10),
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
              color: color),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Primary button
// ─────────────────────────────────────────────────────────────────────────────

class _PrimaryButton extends StatelessWidget {
  final bool isLoading;
  final String label;
  final IconData trailingIcon;
  final VoidCallback? onPressed;

  const _PrimaryButton({
    required this.isLoading,
    required this.label,
    required this.trailingIcon,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onPressed,
      child: Container(
        height: 52,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          color: onPressed != null ? _kPrimary : _kPrimary.withValues(alpha: 0.40),
          boxShadow: onPressed != null
              ? const [
                  BoxShadow(
                    color: Color(0x336C63FF),
                    blurRadius: 14,
                    offset: Offset(0, 4),
                  ),
                ]
              : null,
        ),
        child: Center(
          child: isLoading
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.5,
                    color: Colors.white,
                  ),
                )
              : Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      label,
                      style: GoogleFonts.outfit(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                        letterSpacing: 0.2,
                      ),
                    ),
                    const SizedBox(width: 7),
                    Icon(trailingIcon, color: Colors.white, size: 17),
                  ],
                ),
        ),
      ),
    );
  }
}