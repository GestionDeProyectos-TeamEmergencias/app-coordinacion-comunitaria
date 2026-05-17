import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/router.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../core/extensions/context_extensions.dart';
import '../../../../core/widgets/app_button.dart';
import '../providers/auth_provider.dart';
import '../widgets/auth_form_field.dart';

class RegisterPage extends ConsumerStatefulWidget {
  const RegisterPage({super.key});

  @override
  ConsumerState<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends ConsumerState<RegisterPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  bool _obscurePassword = true;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    await ref.read(authNotifierProvider.notifier).register(
          email: _emailCtrl.text.trim(),
          password: _passwordCtrl.text,
          displayName: _nameCtrl.text.trim(),
        );
    final error = ref.read(authNotifierProvider).error;
    if (error != null && mounted) {
      context.showSnackBar(error.toString(), isError: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isLoading = ref.watch(authNotifierProvider).isLoading;

    return Scaffold(
      appBar: AppBar(title: const Text(AppStrings.register)),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                AuthFormField(
                  controller: _nameCtrl,
                  label: AppStrings.displayName,
                  validator: (v) => (v == null || v.trim().isEmpty)
                      ? 'Ingresá tu nombre'
                      : null,
                ),
                const SizedBox(height: 16),
                AuthFormField(
                  controller: _emailCtrl,
                  label: AppStrings.email,
                  keyboardType: TextInputType.emailAddress,
                  validator: (v) =>
                      (v == null || !v.contains('@')) ? 'Email inválido' : null,
                ),
                const SizedBox(height: 16),
                AuthFormField(
                  controller: _passwordCtrl,
                  label: AppStrings.password,
                  obscureText: _obscurePassword,
                  validator: (v) => (v == null || v.length < 6)
                      ? 'Mínimo 6 caracteres'
                      : null,
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscurePassword
                          ? Icons.visibility
                          : Icons.visibility_off,
                    ),
                    onPressed: () =>
                        setState(() => _obscurePassword = !_obscurePassword),
                  ),
                ),
                const SizedBox(height: 24),
                AppButton(
                  label: AppStrings.register,
                  onPressed: _submit,
                  isLoading: isLoading,
                  icon: Icons.person_add,
                ),
                const SizedBox(height: 16),
                TextButton(
                  onPressed: () => context.go(AppRoutes.login),
                  child: const Text('¿Ya tenés cuenta? Iniciá sesión'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
