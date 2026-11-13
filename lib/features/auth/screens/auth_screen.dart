import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../shared/services/auth_service.dart';

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key, this.onAuthenticated});

  final VoidCallback? onAuthenticated;

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  final _formKey = GlobalKey<FormState>();
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _confirm = TextEditingController();
  final _auth = AuthService();
  bool _register = false;
  bool _loading = false;
  String? _error;

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    _confirm.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate() || _loading) return;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      if (_register) {
        await _auth.register(_email.text, _password.text);
      } else {
        await _auth.signIn(_email.text, _password.text);
      }
      if (mounted) _finishAuthentication();
    } catch (error) {
      if (mounted) setState(() => _error = _auth.messageFor(error));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _google() async {
    if (_loading) return;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      await _auth.signInWithGoogle();
      if (mounted) _finishAuthentication();
    } catch (error) {
      if (mounted) setState(() => _error = _auth.messageFor(error));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _finishAuthentication() {
    if (widget.onAuthenticated != null) {
      widget.onAuthenticated!();
    } else {
      final router = GoRouter.maybeOf(context);
      if (router?.canPop() == true) router!.pop();
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: Text(_register ? 'Tạo tài khoản' : 'Đăng nhập')),
    body: SafeArea(
      child: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Icon(Icons.spa_outlined, size: 64),
                  const SizedBox(height: 16),
                  Text(
                    _register
                        ? 'Bắt đầu cùng Longeva'
                        : 'Chào mừng bạn trở lại',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  const SizedBox(height: 24),
                  TextFormField(
                    controller: _email,
                    keyboardType: TextInputType.emailAddress,
                    decoration: const InputDecoration(labelText: 'Email'),
                    validator: (value) =>
                        value == null ||
                            !RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$')
                                .hasMatch(value.trim())
                        ? 'Vui lòng nhập email hợp lệ.'
                        : null,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _password,
                    obscureText: true,
                    decoration: const InputDecoration(labelText: 'Mật khẩu'),
                    validator: (value) => value == null || value.length < 6
                        ? 'Mật khẩu cần ít nhất 6 ký tự.'
                        : null,
                  ),
                  if (_register) ...[
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _confirm,
                      obscureText: true,
                      decoration: const InputDecoration(
                        labelText: 'Xác nhận mật khẩu',
                      ),
                      validator: (value) => value != _password.text
                          ? 'Mật khẩu xác nhận chưa khớp.'
                          : null,
                    ),
                  ],
                  if (_error != null) ...[
                    const SizedBox(height: 16),
                    Text(
                      _error!,
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.error,
                      ),
                    ),
                  ],
                  const SizedBox(height: 20),
                  FilledButton(
                    onPressed: _loading ? null : _submit,
                    child: _loading
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : Text(_register ? 'Đăng ký' : 'Đăng nhập'),
                  ),
                  const SizedBox(height: 8),
                  OutlinedButton.icon(
                    onPressed: _loading ? null : _google,
                    icon: const Icon(Icons.login),
                    label: const Text('Tiếp tục với Google'),
                  ),
                  TextButton(
                    onPressed: _loading
                        ? null
                        : () => setState(() => _register = !_register),
                    child: Text(
                      _register
                          ? 'Đã có tài khoản? Đăng nhập'
                          : 'Chưa có tài khoản? Đăng ký',
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    ),
  );
}
