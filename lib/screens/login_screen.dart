import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../providers/auth_provider.dart';
import '../widgets/auth_shell.dart';
import '../widgets/common_widgets.dart';
import 'register_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen>
    with TickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _email = TextEditingController();
  final _password = TextEditingController();
  bool _obscure = true;
  bool _rememberMe = true;

  late final AnimationController _fadeCtrl;
  late final AnimationController _slideCtrl;
  late final Animation<double> _fadeAnim;
  late final Animation<Offset> _slideAnim;

  @override
  void initState() {
    super.initState();

    _fadeCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    _slideCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );
    _fadeAnim = CurvedAnimation(parent: _fadeCtrl, curve: Curves.easeInOut);
    _slideAnim = Tween<Offset>(
      begin: const Offset(0, 0.12),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _slideCtrl, curve: Curves.easeOut));

    _fadeCtrl.forward();
    _slideCtrl.forward();

    // Restore persisted session; root route reacts to AuthProvider state.
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await context.read<AuthProvider>().restoreSession();
    });
  }

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    _fadeCtrl.dispose();
    _slideCtrl.dispose();
    super.dispose();
  }

  // Navigation is handled by the root route watching AuthProvider.
  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    HapticFeedback.lightImpact();
    await context.read<AuthProvider>().login(_email.text, _password.text);
  }

  Future<void> _google() async {
    HapticFeedback.lightImpact();
    await context.read<AuthProvider>().loginWithGoogle();
  }

  Future<void> _gitHub() async {
    HapticFeedback.lightImpact();
    await context.read<AuthProvider>().loginWithGitHub();
  }

  Future<void> _guest() => context.read<AuthProvider>().loginAsGuest();

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final c = Theme.of(context).colorScheme;
    final t = Theme.of(context).textTheme;

    return AuthShell(
      title: 'Sign in',
      subtitle: 'Access your model registry.',
      // Glow blobs are painted behind the shell's content via its background
      // slot; if AuthShell doesn't expose one, wrap at Scaffold level instead.
      backgroundDecoration: const [
        _GlowBlob(color: Color(0x3C3D5AFE), size: 300, top: -80, left: -60),
        _GlowBlob(color: Color(0x327B1FA2), size: 260, bottom: -50, right: -70),
      ],
      children: [
        FadeTransition(
          opacity: _fadeAnim,
          child: SlideTransition(
            position: _slideAnim,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (auth.errorMessage != null) ...[
                  ErrorBanner(auth.errorMessage!),
                  const SizedBox(height: Space.lg),
                ],
                AutofillGroup(
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        TextFormField(
                          controller: _email,
                          keyboardType: TextInputType.emailAddress,
                          textInputAction: TextInputAction.next,
                          autofillHints: const [AutofillHints.email],
                          decoration: const InputDecoration(
                            labelText: 'Email',
                            prefixIcon: Icon(Icons.email_outlined, size: 20),
                          ),
                          validator: (v) {
                            if (v == null || v.trim().isEmpty) {
                              return 'Enter your email';
                            }
                            if (!auth.isEmailValid(v)) {
                              return 'Enter a valid email address';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: Space.lg),
                        TextFormField(
                          controller: _password,
                          obscureText: _obscure,
                          textInputAction: TextInputAction.done,
                          autofillHints: const [AutofillHints.password],
                          onFieldSubmitted: (_) => _submit(),
                          decoration: InputDecoration(
                            labelText: 'Password',
                            prefixIcon: const Icon(
                              Icons.lock_outline,
                              size: 20,
                            ),
                            suffixIcon: IconButton(
                              tooltip: _obscure
                                  ? 'Show password'
                                  : 'Hide password',
                              icon: Icon(
                                _obscure
                                    ? Icons.visibility_outlined
                                    : Icons.visibility_off_outlined,
                                size: 20,
                              ),
                              onPressed: () =>
                                  setState(() => _obscure = !_obscure),
                            ),
                          ),
                          validator: (v) {
                            if (v == null || v.isEmpty) {
                              return 'Enter your password';
                            }
                            if (!auth.isPasswordValid(v)) {
                              return 'At least 6 characters';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: Space.md),

                        // Remember me + Forgot password
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                SizedBox(
                                  height: 24,
                                  width: 24,
                                  child: Checkbox(
                                    value: _rememberMe,
                                    onChanged: (v) =>
                                        setState(() => _rememberMe = v ?? true),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  'Remember me',
                                  style: t.bodySmall?.copyWith(
                                    color: c.onSurfaceVariant,
                                  ),
                                ),
                              ],
                            ),
                            TextButton(
                              onPressed: () => _showForgotPassword(context),
                              child: const Text('Forgot password?'),
                            ),
                          ],
                        ),
                        const SizedBox(height: Space.xl),

                        FilledButton(
                          onPressed: auth.isLoading ? null : _submit,
                          child: auth.isLoading
                              ? const ButtonSpinner()
                              : const Text('Sign in'),
                        ),
                        const SizedBox(height: Space.sm),
                        OutlinedButton.icon(
                          onPressed: auth.isLoading ? null : _guest,
                          icon: const Icon(Icons.bolt_rounded, size: 18),
                          label: const Text('Quick demo (guest)'),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: Space.xl),

                Row(
                  children: [
                    const Expanded(child: Divider()),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: Space.md),
                      child: Text('or continue with', style: t.bodySmall),
                    ),
                    const Expanded(child: Divider()),
                  ],
                ),
                const SizedBox(height: Space.lg),

                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: auth.isLoading ? null : _google,
                        icon: const _GoogleIcon(),
                        label: const Text('Google'),
                      ),
                    ),
                    const SizedBox(width: Space.md),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: auth.isLoading ? null : _gitHub,
                        icon: const _GitHubIcon(),
                        label: const Text('GitHub'),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: Space.lg),

                Center(
                  child: Wrap(
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      Text(
                        'New to BroML?',
                        style: t.bodyMedium?.copyWith(
                          color: c.onSurfaceVariant,
                        ),
                      ),
                      TextButton(
                        onPressed: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const RegisterScreen(),
                          ),
                        ),
                        child: const Text('Create an account'),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  void _showForgotPassword(BuildContext context) {
    final ctrl = TextEditingController();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(
          left: 24,
          right: 24,
          top: 28,
          bottom: MediaQuery.of(ctx).viewInsets.bottom + 28,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Reset password',
              style: Theme.of(ctx).textTheme.titleMedium
                  ?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              'Enter your email to receive a reset link.',
              style: Theme.of(ctx).textTheme.bodySmall,
            ),
            const SizedBox(height: 18),
            TextFormField(
              controller: ctrl,
              keyboardType: TextInputType.emailAddress,
              textInputAction: TextInputAction.done,
              autofillHints: const [AutofillHints.email],
              decoration: const InputDecoration(labelText: 'Email'),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: () {
                  if (ctrl.text.trim().isEmpty) return;
                  Navigator.pop(ctx);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Reset link sent to ${ctrl.text.trim()}'),
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                },
                child: const Text('Send reset link'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Glow blob ─────────────────────────────────────────────────────────────────
// If AuthShell doesn't accept a backgroundDecoration parameter, position these
// in a Stack above your Scaffold's body instead.
class _GlowBlob extends StatelessWidget {
  final Color color;
  final double size;
  final double? top;
  final double? bottom;
  final double? left;
  final double? right;

  const _GlowBlob({
    required this.color,
    required this.size,
    this.top,
    this.bottom,
    this.left,
    this.right,
  });

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: top,
      bottom: bottom,
      left: left,
      right: right,
      child: IgnorePointer(
        child: Container(
          width: size,
          height: size,
          decoration: BoxDecoration(shape: BoxShape.circle, color: color),
        ),
      ),
    );
  }
}

// ── Google icon ───────────────────────────────────────────────────────────────
class _GoogleIcon extends StatelessWidget {
  const _GoogleIcon();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 18,
      height: 18,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(3),
      ),
      alignment: Alignment.center,
      child: const Text(
        'G',
        style: TextStyle(
          color: Color(0xFF4285F4),
          fontSize: 13,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}

// ── GitHub icon ───────────────────────────────────────────────────────────────
class _GitHubIcon extends StatelessWidget {
  const _GitHubIcon();

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      width: 18,
      height: 18,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: isDark ? Colors.white : Colors.black,
      ),
      alignment: Alignment.center,
      child: Icon(
        Icons.terminal_rounded,
        size: 12,
        color: isDark ? Colors.black : Colors.white,
      ),
    );
  }
}
