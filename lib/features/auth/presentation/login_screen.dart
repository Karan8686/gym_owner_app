import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/config/theme.dart';
import 'auth_controller.dart';

/// ──────────────────────────────────────────────
/// Login screen — matches the Stitch mockup:
///   FITTRACK heading + "Owner" subtitle
///   Card: USERNAME field + 4-digit PIN boxes + LOG IN button
///   "Forgot PIN?" link below
/// ──────────────────────────────────────────────
class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _emailController = TextEditingController();
  final _pinControllers = List.generate(4, (_) => TextEditingController());
  final _pinFocusNodes = List.generate(4, (_) => FocusNode());

  String? _error;
  bool _isLoading = false;

  @override
  void dispose() {
    _emailController.dispose();
    for (final c in _pinControllers) {
      c.dispose();
    }
    for (final f in _pinFocusNodes) {
      f.dispose();
    }
    super.dispose();
  }

  // ---- Helpers ------------------------------------------------------------

  String get _pin => _pinControllers.map((c) => c.text).join();

  bool get _canSubmit =>
      _emailController.text.trim().isNotEmpty && _pin.length == 4;

  Future<void> _submit() async {
    if (!_canSubmit || _isLoading) return;

    setState(() {
      _error = null;
      _isLoading = true;
    });

    final result = await ref.read(authControllerProvider.notifier).signIn(
          email: _emailController.text.trim(),
          pin: _pin,
        );

    if (!mounted) return;

    if (result != null) {
      // Error — show it inline.
      setState(() {
        _error = result;
        _isLoading = false;
      });
    } else {
      // Success — router redirect handles navigation.
      setState(() => _isLoading = false);
    }
  }

  // ---- Build --------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.containerPadding,
            ),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 400),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // ---- Header -----------------------------------------------
                  _buildHeader(),
                  const SizedBox(height: AppSpacing.stackLg),

                  // ---- Card -------------------------------------------------
                  _buildFormCard(),

                  // ---- Forgot PIN -------------------------------------------
                  const SizedBox(height: AppSpacing.stackLg),
                  _buildForgotPin(),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      children: [
        Text(
          'FITTRACK',
          style: Theme.of(context).textTheme.headlineLarge?.copyWith(
            fontWeight: FontWeight.w900,
            letterSpacing: 24 * 0.2, // 0.2 em wide tracking
          ),
        ),
        const SizedBox(height: AppSpacing.unit),
        Text(
          'Owner',
          style: Theme.of(context).textTheme.labelLarge?.copyWith(
            color: AppColors.inkSecondary,
          ),
        ),
      ],
    );
  }

  Widget _buildFormCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.containerPadding),
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: Border.all(color: AppColors.border),
        borderRadius: BorderRadius.circular(cornerRadius),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // ---- USERNAME field -----------------------------------------------
          _buildLabel('USERNAME'),
          const SizedBox(height: AppSpacing.unit),
          _buildEmailField(),

          const SizedBox(height: AppSpacing.stackMd),

          // ---- PIN field ----------------------------------------------------
          _buildLabel('PIN'),
          const SizedBox(height: AppSpacing.unit),
          _buildPinRow(),

          // ---- Error --------------------------------------------------------
          if (_error != null) ...[
            const SizedBox(height: AppSpacing.stackMd),
            Text(
              _error!,
              style: AppText.bodySm.copyWith(color: AppColors.inkSecondary),
              textAlign: TextAlign.center,
            ),
          ],

          const SizedBox(height: AppSpacing.stackMd),

          // ---- LOG IN button ------------------------------------------------
          _buildLoginButton(),
        ],
      ),
    );
  }

  Widget _buildLabel(String text) {
    return Text(
      text,
      style: Theme.of(context).textTheme.labelMedium?.copyWith(
        color: AppColors.inkSecondary,
      ),
    );
  }

  Widget _buildEmailField() {
    return SizedBox(
      height: 48,
      child: TextField(
        controller: _emailController,
        keyboardType: TextInputType.emailAddress,
        autocorrect: false,
        style: Theme.of(context).textTheme.titleMedium,
        decoration: InputDecoration(
          hintText: 'owner@gym.co',
          hintStyle: Theme.of(context).textTheme.titleMedium?.copyWith(
            color: AppColors.inkSecondary,
          ),
          filled: true,
          fillColor: AppColors.surface,
          contentPadding: const EdgeInsets.symmetric(horizontal: 12),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(0),
            borderSide: const BorderSide(color: AppColors.border),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(0),
            borderSide: const BorderSide(color: AppColors.border),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(0),
            borderSide: const BorderSide(
              color: AppColors.inkPrimary,
              width: 2,
            ),
          ),
        ),
        onSubmitted: (_) => _pinFocusNodes.first.requestFocus(),
      ),
    );
  }

  Widget _buildPinRow() {
    return Row(
      children: List.generate(4, (index) {
        return Expanded(
          child: Padding(
            padding: EdgeInsets.only(
              right: index < 3 ? AppSpacing.unit : 0,
              left: index > 0 ? AppSpacing.unit : 0,
            ),
            child: _buildPinBox(index),
          ),
        );
      }),
    );
  }

  Widget _buildPinBox(int index) {
    return SizedBox(
      height: 56,
      child: KeyboardListener(
        focusNode: FocusNode(), // outer listener node
        onKeyEvent: (event) {
          // Backspace on empty box → go back to previous box.
          if (event is KeyDownEvent &&
              event.logicalKey == LogicalKeyboardKey.backspace &&
              _pinControllers[index].text.isEmpty &&
              index > 0) {
            _pinControllers[index - 1].clear();
            _pinFocusNodes[index - 1].requestFocus();
            setState(() {});
          }
        },
        child: TextField(
          controller: _pinControllers[index],
          focusNode: _pinFocusNodes[index],
          keyboardType: TextInputType.number,
          textAlign: TextAlign.center,
          obscureText: true,
          style: Theme.of(context).textTheme.headlineSmall,
          maxLength: 1,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          decoration: InputDecoration(
            counterText: '', // hide the "0/1" counter
            filled: true,
            fillColor: AppColors.surface,
            contentPadding: EdgeInsets.zero,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(0),
              borderSide: const BorderSide(color: AppColors.border),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(0),
              borderSide: const BorderSide(color: AppColors.border),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(0),
              borderSide: const BorderSide(
                color: AppColors.inkPrimary,
                width: 2,
              ),
            ),
          ),
          onChanged: (value) {
            if (value.isNotEmpty && index < 3) {
              // Auto-advance to next PIN box.
              _pinFocusNodes[index + 1].requestFocus();
            }
            if (value.isNotEmpty && index == 3) {
              // Last digit entered — unfocus to dismiss keyboard.
              _pinFocusNodes[index].unfocus();
            }
            setState(() {}); // refresh _canSubmit
          },
        ),
      ),
    );
  }

  Widget _buildLoginButton() {
    return SizedBox(
      height: 48,
      child: ElevatedButton(
        onPressed: _canSubmit && !_isLoading ? _submit : null,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.inkPrimary,
          disabledBackgroundColor: AppColors.inkPrimary.withValues(alpha: 0.4),
          foregroundColor: AppColors.surface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(cornerRadius),
          ),
          elevation: 0,
        ),
        child: _isLoading
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: AppColors.surface,
                ),
              )
            : Text(
                'LOG IN',
                style: Theme.of(context).textTheme.labelLarge?.copyWith(
                  color: AppColors.surface,
                  letterSpacing: 12 * 0.15, // widest tracking for button
                ),
              ),
      ),
    );
  }

  Widget _buildForgotPin() {
    return GestureDetector(
      onTap: () {
        // TODO: trigger Supabase password reset email
      },
      child: Text(
        'Forgot PIN?',
        style: Theme.of(context).textTheme.labelLarge?.copyWith(
          color: AppColors.inkSecondary,
        ),
      ),
    );
  }
}
