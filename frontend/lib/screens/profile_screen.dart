import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:openmusic_frontend/services/auth_service.dart';
import 'package:openmusic_frontend/services/api_client.dart';
import 'package:openmusic_frontend/theme/app_theme.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _urlController = TextEditingController();

  @override
  void initState() {
    super.initState();
    final apiClient = Provider.of<ApiClient>(context, listen: false);
    _urlController.text = apiClient.baseUrl;
  }

  @override
  void dispose() {
    _urlController.dispose();
    super.dispose();
  }

  void _updateBaseUrl() {
    final apiClient = Provider.of<ApiClient>(context, listen: false);
    apiClient.setBaseUrl(_urlController.text.trim());
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Base URL berhasil diperbarui!'),
        backgroundColor: AppTheme.tealAccent,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthService>(context);
    final user = authService.currentUser;
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Profil & Pengaturan'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // User info card
            if (user != null) ...[
              Center(
                child: CircleAvatar(
                  radius: 50,
                  backgroundColor: AppTheme.primaryContainer,
                  child: Text(
                    user.username.substring(0, 1).toUpperCase(),
                    style: const TextStyle(fontSize: 40, color: Colors.white, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Center(
                child: Text(
                  user.username,
                  style: textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold),
                ),
              ),
              Center(
                child: Text(
                  user.email,
                  style: const TextStyle(color: AppTheme.mutedText),
                ),
              ),
              const SizedBox(height: 32),
            ],

            // Base URL Configuration
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Konfigurasi Backend API',
                      style: textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Ubah Base URL di bawah jika menggunakan emulator Android (10.0.2.2) atau device fisik (IP address lokal).',
                      style: TextStyle(color: AppTheme.mutedText, fontSize: 12),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: _urlController,
                      decoration: const InputDecoration(
                        labelText: 'API Base URL',
                        border: OutlineInputBorder(),
                        focusedBorder: OutlineInputBorder(
                          borderSide: BorderSide(color: AppTheme.tealAccent, width: 2),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: _updateBaseUrl,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.tealAccent,
                        foregroundColor: Colors.black,
                      ),
                      child: const Text('Simpan URL'),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 32),

            // Logout Button
            ElevatedButton.icon(
              onPressed: () async {
                await authService.logout();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.error,
                foregroundColor: Colors.black,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              icon: const Icon(Icons.logout),
              label: const Text(
                'Keluar Akun',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
