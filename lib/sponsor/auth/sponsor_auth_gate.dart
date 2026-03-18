import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class SponsorAuthGate extends StatefulWidget {
  final VoidCallback onAuthenticated;

  const SponsorAuthGate({
    super.key,
    required this.onAuthenticated,
  });

  @override
  State<SponsorAuthGate> createState() => _SponsorAuthGateState();
}

class _SponsorAuthGateState extends State<SponsorAuthGate> {
  final _emailController = TextEditingController();
  bool _loading = false;

  Future<void> _sendMagicLink() async {
    final email = _emailController.text.trim();

    if (email.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Enter your email")),
      );
      return;
    }

    setState(() => _loading = true);

    try {
      await Supabase.instance.client.auth.signInWithOtp(
        email: email,
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Check your email to continue")),
      );

    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error: $e")),
      );
    }

    setState(() => _loading = false);
  }

  @override
  void initState() {
    super.initState();

    Supabase.instance.client.auth.onAuthStateChange.listen((event) {
      if (event.session != null) {
        widget.onAuthenticated();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: Center(
        child: Container(
          padding: const EdgeInsets.all(28),
          width: 420,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: const Color(0xFFE2E8F0)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Continue to Secure Your Placement',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900),
              ),
              const SizedBox(height: 10),
              const Text(
                'Enter your email to continue. This saves your sponsorship setup and unlocks checkout.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Color(0xFF6B7280)),
              ),
              const SizedBox(height: 20),
              TextField(
                controller: _emailController,
                decoration: const InputDecoration(
                  hintText: 'Email address',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _loading ? null : _sendMagicLink,
                  child: _loading
                      ? const CircularProgressIndicator()
                      : const Text('Continue'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}