import 'package:flutter/material.dart';
import 'auth_storage.dart';
import 'profile_storage.dart';

class AuthScreen extends StatefulWidget {
  final VoidCallback onAuthSuccess;

  const AuthScreen({
    super.key,
    required this.onAuthSuccess,
  });

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  bool isLogin = true;

  final _loginEmailController = TextEditingController();
  final _loginPasswordController = TextEditingController();

  final _nameController = TextEditingController();
  final _signupEmailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _signupPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  @override
  void dispose() {
    _loginEmailController.dispose();
    _loginPasswordController.dispose();
    _nameController.dispose();
    _signupEmailController.dispose();
    _phoneController.dispose();
    _signupPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    final email = _loginEmailController.text.trim();
    final password = _loginPasswordController.text;

    if (email.isEmpty) {
      _showError('Please enter your email.');
      return;
    }

    if (!email.contains('@')) {
      _showError('Please enter a valid email.');
      return;
    }

    if (password.isEmpty) {
      _showError('Please enter your password.');
      return;
    }

    final success = await AuthStorage.login(
      email: email,
      password: password,
    );

    if (!mounted) {
      return;
    }

    if (success) {
      widget.onAuthSuccess();
    } else {
      _showError('Incorrect email or password.');
    }
  }

  Future<void> _signup() async {
    final name = _nameController.text.trim();
    final email = _signupEmailController.text.trim();
    final phone = _phoneController.text.trim();
    final password = _signupPasswordController.text;
    final confirmPassword = _confirmPasswordController.text;

    if (name.isEmpty) {
      _showError('Please enter your name.');
      return;
    }

    if (email.isEmpty || !email.contains('@')) {
      _showError('Please enter a valid email.');
      return;
    }

    if (phone.isEmpty || phone.length < 10) {
      _showError('Please enter a valid phone number.');
      return;
    }

    if (password.length < 6) {
      _showError('Password must be at least 6 characters.');
      return;
    }

    if (password != confirmPassword) {
      _showError('Passwords do not match.');
      return;
    }

    final accountExists = await AuthStorage.hasAccount();

    if (!mounted) {
      return;
    }

    if (accountExists) {
      _showError('An account already exists. Please login.');
      return;
    }

    await AuthStorage.signup(
      email: email,
      password: password,
    );

    await ProfileStorage.saveProfile(
      name: name,
      email: email,
      phone: phone,
    );

    if (!mounted) {
      return;
    }

    widget.onAuthSuccess();
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F8FA),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              const SizedBox(height: 40),
              Container(
                width: 82,
                height: 82,
                decoration: const BoxDecoration(
                  color: Colors.black,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.drive_eta_outlined,
                  size: 44,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                'Driver On Demand',
                style: TextStyle(
                  fontSize: 27,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                isLogin
                    ? 'Login to continue'
                    : 'Create your account',
                style: const TextStyle(
                  fontSize: 15,
                  color: Colors.grey,
                ),
              ),
              const SizedBox(height: 32),
              Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: _TabButton(
                        title: 'LOGIN',
                        selected: isLogin,
                        onTap: () {
                          setState(() {
                            isLogin = true;
                          });
                        },
                      ),
                    ),
                    Expanded(
                      child: _TabButton(
                        title: 'SIGN UP',
                        selected: !isLogin,
                        onTap: () {
                          setState(() {
                            isLogin = false;
                          });
                        },
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              if (isLogin) _buildLoginForm() else _buildSignupForm(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLoginForm() {
    return Column(
      children: [
        _InputField(
          controller: _loginEmailController,
          label: 'Email',
          hint: 'Enter your email',
          icon: Icons.email_outlined,
          keyboardType: TextInputType.emailAddress,
        ),
        const SizedBox(height: 16),
        _InputField(
          controller: _loginPasswordController,
          label: 'Password',
          hint: 'Enter your password',
          icon: Icons.lock_outline,
          obscureText: true,
        ),
        const SizedBox(height: 28),
        _PrimaryButton(
          title: 'LOGIN',
          onPressed: _login,
        ),
      ],
    );
  }

  Widget _buildSignupForm() {
    return Column(
      children: [
        _InputField(
          controller: _nameController,
          label: 'Name',
          hint: 'Enter your name',
          icon: Icons.person_outline,
        ),
        const SizedBox(height: 16),
        _InputField(
          controller: _signupEmailController,
          label: 'Email',
          hint: 'Enter your email',
          icon: Icons.email_outlined,
          keyboardType: TextInputType.emailAddress,
        ),
        const SizedBox(height: 16),
        _InputField(
          controller: _phoneController,
          label: 'Phone',
          hint: 'Enter your phone number',
          icon: Icons.phone_outlined,
          keyboardType: TextInputType.phone,
        ),
        const SizedBox(height: 16),
        _InputField(
          controller: _signupPasswordController,
          label: 'Password',
          hint: 'Minimum 6 characters',
          icon: Icons.lock_outline,
          obscureText: true,
        ),
        const SizedBox(height: 16),
        _InputField(
          controller: _confirmPasswordController,
          label: 'Confirm Password',
          hint: 'Re-enter your password',
          icon: Icons.lock_outline,
          obscureText: true,
        ),
        const SizedBox(height: 28),
        _PrimaryButton(
          title: 'CREATE ACCOUNT',
          onPressed: _signup,
        ),
      ],
    );
  }
}

class _TabButton extends StatelessWidget {
  final String title;
  final bool selected;
  final VoidCallback onTap;

  const _TabButton({
    required this.title,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 13),
        decoration: BoxDecoration(
          color: selected ? Colors.black : Colors.transparent,
          borderRadius: BorderRadius.circular(11),
        ),
        child: Text(
          title,
          textAlign: TextAlign.center,
          style: TextStyle(
            color: selected ? Colors.white : Colors.black,
            fontWeight: FontWeight.bold,
            fontSize: 13,
          ),
        ),
      ),
    );
  }
}

class _PrimaryButton extends StatelessWidget {
  final String title;
  final VoidCallback onPressed;

  const _PrimaryButton({
    required this.title,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.black,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
        child: Text(
          title,
          style: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}

class _InputField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final String hint;
  final IconData icon;
  final TextInputType keyboardType;
  final bool obscureText;

  const _InputField({
    required this.controller,
    required this.label,
    required this.hint,
    required this.icon,
    this.keyboardType = TextInputType.text,
    this.obscureText = false,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      obscureText: obscureText,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: Icon(icon),
        filled: true,
        fillColor: Colors.white,
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
          borderSide: const BorderSide(
            color: Colors.black,
          ),
        ),
      ),
    );
  }
}