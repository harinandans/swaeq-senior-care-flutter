import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../api/api_client.dart';
import '../auth/auth_state.dart';
import '../theme/app_theme.dart';
import '../widgets/common.dart';

/// WhatsApp-green accent for OTP CTA (visual only — still uses /auth/otp).
const _waGreen = Color(0xFF25D366);
const _waDark = Color(0xFF128C7E);

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _phone = TextEditingController();
  final _otpCtrls = List.generate(6, (_) => TextEditingController());
  final _otpFocus = List.generate(6, (_) => FocusNode());
  String? _otpToken;
  bool _otpStep = false;
  bool _loading = false;
  int _resendLeft = 0;

  @override
  void dispose() {
    _phone.dispose();
    for (final c in _otpCtrls) {
      c.dispose();
    }
    for (final f in _otpFocus) {
      f.dispose();
    }
    super.dispose();
  }

  Future<void> _sendOtp() async {
    final phone = _phone.text.trim();
    if (!RegExp(r'^\d{10}$').hasMatch(phone)) {
      showAppToast(context, 'Enter a 10-digit mobile number');
      return;
    }
    setState(() => _loading = true);
    try {
      final r = await context.read<AuthState>().api.sendOtp(phone);
      _otpToken = r['otpToken'] as String?;
      setState(() {
        _otpStep = true;
        _resendLeft = 45;
        for (final c in _otpCtrls) {
          c.clear();
        }
      });
      _otpFocus[0].requestFocus();
      _tickResend();
    } on ApiException catch (e) {
      showAppToast(context, e.message);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _tickResend() {
    Future.doWhile(() async {
      await Future<void>.delayed(const Duration(seconds: 1));
      if (!mounted || _resendLeft <= 0) return false;
      setState(() => _resendLeft--);
      return _resendLeft > 0;
    });
  }

  Future<void> _verify() async {
    final code = _otpCtrls.map((c) => c.text).join();
    if (!RegExp(r'^\d{6}$').hasMatch(code) || _otpToken == null) {
      showAppToast(context, 'Enter the 6-digit code');
      return;
    }
    setState(() => _loading = true);
    try {
      final auth = context.read<AuthState>();
      final r = await auth.api.verifyOtp(_otpToken!, code);
      await auth.afterLogin(r);
      if (!mounted) return;
      context.go('/today');
    } on ApiException catch (e) {
      showAppToast(context, e.message);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _otpStep ? _otpView() : _phoneView(),
    );
  }

  Widget _phoneView() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Expanded(
          child: LeafBackground(
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(24, 32, 24, 16),
                child: Column(
                  children: [
                    const BrandWordmark(size: 34),
                    const SizedBox(height: 10),
                    const Text(
                      'Senior Care',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                        color: AppColors.brand900,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Your gentle daily routine — yoga, walks,\nreminders & learning.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: AppColors.slate500, height: 1.35),
                    ),
                    const Spacer(),
                    Image.asset('assets/logo.png', height: 110),
                    const Spacer(),
                  ],
                ),
              ),
            ),
          ),
        ),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.fromLTRB(24, 28, 24, 32),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
            boxShadow: [
              BoxShadow(
                color: AppColors.brand500.withOpacity(0.12),
                blurRadius: 24,
                offset: const Offset(0, -4),
              ),
            ],
          ),
          child: Column(
            children: [
              Text(
                'Sign in with WhatsApp',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w800,
                      color: AppColors.brand900,
                    ),
              ),
              const SizedBox(height: 4),
              const Text(
                'We will send a one-time code on WhatsApp',
                style: TextStyle(color: AppColors.slate500),
              ),
              const SizedBox(height: 20),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    height: 56,
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: AppColors.slate50,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.slate200),
                    ),
                    child: const Text('🇮🇳 +91'),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextField(
                      controller: _phone,
                      keyboardType: TextInputType.phone,
                      maxLength: 10,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                      decoration: const InputDecoration(
                        hintText: 'WhatsApp mobile number',
                        counterText: '',
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              const Row(
                children: [
                  Icon(Icons.lock_outline, size: 14, color: AppColors.slate400),
                  SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      'Demo: any 10-digit number, then any 6-digit OTP.',
                      style: TextStyle(fontSize: 12, color: AppColors.slate500),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                height: 52,
                child: FilledButton.icon(
                  onPressed: _loading ? null : _sendOtp,
                  style: FilledButton.styleFrom(
                    backgroundColor: _waGreen,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(999),
                    ),
                  ),
                  icon: _loading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Icon(Icons.chat),
                  label: Text(
                    _loading ? 'Sending…' : 'Continue with WhatsApp',
                    style: const TextStyle(
                        fontWeight: FontWeight.w700, fontSize: 16),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _otpView() {
    return LeafBackground(
      child: SafeArea(
        child: Column(
          children: [
            Align(
              alignment: Alignment.centerLeft,
              child: IconButton(
                onPressed: () => setState(() => _otpStep = false),
                icon: const Icon(Icons.arrow_back, color: AppColors.brand700),
              ),
            ),
            Expanded(
              child: Container(
                width: double.infinity,
                margin: const EdgeInsets.only(top: 8),
                padding: const EdgeInsets.fromLTRB(24, 28, 24, 32),
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: _waGreen.withOpacity(0.15),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.chat, color: _waDark),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'WhatsApp OTP',
                            style: Theme.of(context)
                                .textTheme
                                .titleLarge
                                ?.copyWith(
                                  fontWeight: FontWeight.w800,
                                  color: AppColors.brand900,
                                ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Wrap(
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        Text(
                          'Enter the 6-digit code for +91 ${_phone.text}',
                          style: const TextStyle(color: AppColors.slate500),
                        ),
                        TextButton(
                          onPressed: () => setState(() => _otpStep = false),
                          style: TextButton.styleFrom(
                            padding: const EdgeInsets.symmetric(horizontal: 6),
                            minimumSize: Size.zero,
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          ),
                          child: const Text('Edit'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    Row(
                      children: List.generate(6, (i) {
                        return Expanded(
                          child: Padding(
                            padding: EdgeInsets.only(right: i < 5 ? 8 : 0),
                            child: TextField(
                              controller: _otpCtrls[i],
                              focusNode: _otpFocus[i],
                              textAlign: TextAlign.center,
                              keyboardType: TextInputType.number,
                              maxLength: 1,
                              style: const TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.w700,
                                color: AppColors.brand900,
                                height: 1.2,
                              ),
                              inputFormatters: [
                                FilteringTextInputFormatter.digitsOnly,
                              ],
                              decoration: const InputDecoration(
                                counterText: '',
                                isDense: true,
                                contentPadding: EdgeInsets.symmetric(
                                  vertical: 16,
                                  horizontal: 4,
                                ),
                              ),
                              onChanged: (v) {
                                if (v.isNotEmpty && i < 5) {
                                  _otpFocus[i + 1].requestFocus();
                                } else if (v.isEmpty && i > 0) {
                                  _otpFocus[i - 1].requestFocus();
                                }
                                if (_otpCtrls.every((c) => c.text.isNotEmpty)) {
                                  _verify();
                                }
                              },
                            ),
                          ),
                        );
                      }),
                    ),
                    const SizedBox(height: 12),
                    Text.rich(
                      TextSpan(
                        style: const TextStyle(
                          fontSize: 13,
                          color: AppColors.slate500,
                        ),
                        children: [
                          const TextSpan(text: "Didn't get the code? "),
                          WidgetSpan(
                            alignment: PlaceholderAlignment.middle,
                            child: TextButton(
                              onPressed:
                                  _resendLeft > 0 || _loading ? null : _sendOtp,
                              style: TextButton.styleFrom(
                                padding: EdgeInsets.zero,
                                minimumSize: Size.zero,
                                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                              ),
                              child: Text(
                                _resendLeft > 0
                                    ? 'Resend (00:${_resendLeft.toString().padLeft(2, '0')})'
                                    : 'Resend via WhatsApp',
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Demo: any 6-digit OTP works.',
                      style: TextStyle(fontSize: 12, color: AppColors.slate400),
                    ),
                    const Spacer(),
                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: FilledButton(
                        onPressed: _loading ? null : _verify,
                        style: FilledButton.styleFrom(
                          backgroundColor: _waGreen,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(999),
                          ),
                        ),
                        child: _loading
                            ? const SizedBox(
                                width: 22,
                                height: 22,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : const Text(
                                'Verify & Continue',
                                style: TextStyle(
                                  fontWeight: FontWeight.w700,
                                  fontSize: 16,
                                ),
                              ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
