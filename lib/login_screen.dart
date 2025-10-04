import 'package:flutter/material.dart';
import 'auth_service.dart';
import 'local_storage.dart';
import 'chat_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _otpController = TextEditingController();
  final AuthService _authService = AuthService();
  bool _isLoading = false;
  bool _otpSent = false;
  String _userId = '';

  Future<void> _sendOTP() async {
    if (_emailController.text.isEmpty) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final response = await _authService.sendOTP(_emailController.text);
      setState(() {
        _otpSent = true;
        _userId = response['user_id'] ?? '';
      });


      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('OTP sent to your email')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _verifyOTP() async {
    if (_otpController.text.isEmpty) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final response = await _authService.verifyOTP(
        _userId,
        _otpController.text,
      );

      if (response['status'] == "success") {
        await LocalStorage.saveUserLogin(
          _userId,
          _emailController.text,
        );

        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const ChatScreen()),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Invalid OTP')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Login'),
        backgroundColor: Colors.green[600],
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (!_otpSent) ...[
              TextField(
                controller: _emailController,
                decoration: const InputDecoration(
                  labelText: 'Email',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.email),
                ),
                keyboardType: TextInputType.emailAddress,
              ),
              const SizedBox(height: 20),
              _isLoading
                  ? const CircularProgressIndicator()
                  : ElevatedButton(
                onPressed: _sendOTP,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green[600],
                  minimumSize: const Size(double.infinity, 50),
                ),
                child: const Text(
                  'Send OTP',
                  style: TextStyle(color: Colors.white),
                ),
              ),
            ] else ...[
              const Text(
                'Enter OTP sent to your email',
                style: TextStyle(fontSize: 16),
              ),
              const SizedBox(height: 20),
              TextField(
                controller: _otpController,
                decoration: const InputDecoration(
                  labelText: 'OTP',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.lock),
                ),
                keyboardType: TextInputType.number,
                maxLength: 6,
              ),
              const SizedBox(height: 20),
              _isLoading
                  ? const CircularProgressIndicator()
                  : ElevatedButton(
                onPressed: _verifyOTP,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green[600],
                  minimumSize: const Size(double.infinity, 50),
                ),
                child: const Text(
                  'Verify OTP',
                  style: TextStyle(color: Colors.white),
                ),
              ),
              const SizedBox(height: 10),
              TextButton(
                onPressed: () {
                  setState(() {
                    _otpSent = false;
                    _otpController.clear();
                  });
                },
                child: const Text('Change Email'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}