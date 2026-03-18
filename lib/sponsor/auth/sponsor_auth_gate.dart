import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

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
  @override
  void initState() {
    super.initState();
    _checkAuth();
  }

  Future<void> _checkAuth() async {
    final session = Supabase.instance.client.auth.currentSession;

    if (session != null) {
      // ✅ Already logged in → continue immediately
      widget.onAuthenticated();
    } else {
      // ❌ Not logged in → send to website login
      await launchUrl(
        Uri.parse('https://www.thematesapp.com/login'),
        mode: LaunchMode.externalApplication,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    // 🔄 Simple loading state while checking auth
    return const Scaffold(
      backgroundColor: Color(0xFFF8FAFC),
      body: Center(
        child: CircularProgressIndicator(),
      ),
    );
  }
}