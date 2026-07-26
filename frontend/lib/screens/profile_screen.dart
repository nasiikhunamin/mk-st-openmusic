import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:openmusic_frontend/services/auth_service.dart';
import 'package:openmusic_frontend/theme/app_theme.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthService>(context);
    final user = authService.currentUser;
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Profil Saya',
          style: textTheme.headlineMedium?.copyWith(
            fontWeight: FontWeight.bold,
            color: Colors.white,
            fontSize: 22,
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // User Header Profile Card
            if (user != null) ...[
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: AppTheme.surface,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.white.withOpacity(0.05)),
                ),
                child: Column(
                  children: [
                    // Profile Image with Glow
                    Container(
                      width: 96,
                      height: 96,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: AppTheme.primary.withOpacity(0.25),
                            blurRadius: 20,
                            spreadRadius: 2,
                          ),
                        ],
                      ),
                      child: CircleAvatar(
                        radius: 48,
                        backgroundColor: AppTheme.primaryContainer,
                        backgroundImage: const NetworkImage(
                          'https://lh3.googleusercontent.com/aida-public/AB6AXuCHVRZmtFnWgbZwRi_WxWflbvr6M_9ybtBaXjkBDElV-NpOMH9WFqnIOGoGTXQZ-3fUBYSNhXuNVuAlejDQo-sN4oB0coP2e3GageLuOWKZxGcD-moVSq4rFB7lnIoDxLelAqy73ehgy9S7KgHDEBnjIQTO0sl5II6GetFdwHsSdN7eWNydCSUJB-tkgTlbRyv3Oxk7Rkh4xvewL6fIAyoE9ayzeGujj7NL5QvRegeOVJ3stggRCzc4',
                        ),
                        child: null,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      user.username,
                      style: textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      user.email,
                      style: const TextStyle(
                        color: AppTheme.mutedText,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
            ],

            // Section Info Akun
            Text(
              'Informasi Akun',
              style: textTheme.labelLarge?.copyWith(
                color: AppTheme.primary,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.2,
              ),
            ),
            const SizedBox(height: 12),
            Container(
              decoration: BoxDecoration(
                color: AppTheme.surface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.white.withOpacity(0.05)),
              ),
              child: Column(
                children: [
                  ListTile(
                    leading: const Icon(Icons.person_outline, color: AppTheme.tealAccent),
                    title: const Text('Username', style: TextStyle(color: AppTheme.mutedText, fontSize: 12)),
                    subtitle: Text(
                      user?.username ?? '-',
                      style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                  ),
                  Divider(color: Colors.white.withOpacity(0.05), height: 1),
                  ListTile(
                    leading: const Icon(Icons.email_outlined, color: AppTheme.tealAccent),
                    title: const Text('Email', style: TextStyle(color: AppTheme.mutedText, fontSize: 12)),
                    subtitle: Text(
                      user?.email ?? '-',
                      style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Section Tentang
            Text(
              'Tentang',
              style: textTheme.labelLarge?.copyWith(
                color: AppTheme.primary,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.2,
              ),
            ),
            const SizedBox(height: 12),
            Container(
              decoration: BoxDecoration(
                color: AppTheme.surface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.white.withOpacity(0.05)),
              ),
              child: const Column(
                children: [
                  ListTile(
                    leading: Icon(Icons.info_outline, color: AppTheme.tealAccent),
                    title: Text('Versi Aplikasi', style: TextStyle(color: Colors.white, fontSize: 15)),
                    trailing: Text('v1.0.0', style: TextStyle(color: AppTheme.mutedText, fontSize: 14)),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),

            // Logout Button
            OutlinedButton.icon(
              onPressed: () async {
                await authService.logout();
              },
              style: OutlinedButton.styleFrom(
                foregroundColor: AppTheme.error,
                side: const BorderSide(color: AppTheme.error, width: 1.5),
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              icon: const Icon(Icons.logout),
              label: const Text(
                'Keluar Akun',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
            ),
            const SizedBox(height: 80), // extra padding for bottom navigation / player
          ],
        ),
      ),
    );
  }
}
