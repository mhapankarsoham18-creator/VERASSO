import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/colors.dart';
import '../../../core/theme/neo_pixel_box.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';

class ProfileSetupScreen extends ConsumerStatefulWidget {
  const ProfileSetupScreen({super.key});

  @override
  ConsumerState<ProfileSetupScreen> createState() => _ProfileSetupScreenState();
}

class _ProfileSetupScreenState extends ConsumerState<ProfileSetupScreen> {
  final _nameCtrl = TextEditingController();
  final _institutionCtrl = TextEditingController();
  String _selectedRole = 'student';
  File? _avatarFile;
  bool _isLoading = false;

  Future<void> _pickAvatar() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery, imageQuality: 70);
    if (pickedFile != null) {
      setState(() {
        _avatarFile = File(pickedFile.path);
      });
    }
  }

  void _saveProfile() async {
    setState(() => _isLoading = true);
    
    // Determine the first badge to assign
    String firstBadge = '';
    if (_selectedRole == 'student') firstBadge = 'Novice Node';
    if (_selectedRole == 'mentor') firstBadge = 'Guiding Light';
    if (_selectedRole == 'explorer') firstBadge = 'Trailblazer';

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        String? avatarUrl;
        if (_avatarFile != null) {
          final ext = _avatarFile!.path.split('.').last;
          final fileName = '${user.uid}/avatar.$ext';
          await Supabase.instance.client.storage.from('avatars').upload(fileName, _avatarFile!, fileOptions: const FileOptions(upsert: true));
          avatarUrl = Supabase.instance.client.storage.from('avatars').getPublicUrl(fileName);
        }

        await Supabase.instance.client.from('profiles').update({
          'display_name': _nameCtrl.text,
          'institute': _institutionCtrl.text,
          'role': _selectedRole,
          'avatar_url': avatarUrl,
          'badges': [firstBadge], // Awards the first badge instantly
        }).eq('firebase_uid', user.uid);
      }
      if (mounted) context.go('/shell/feed');
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.neutralBg,
      appBar: AppBar(
        title: const Text('Setup Avatar'),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
               Text(
                'Complete your visual identity',
                style: Theme.of(context).textTheme.bodyLarge,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),

              Center(
                child: GestureDetector(
                  onTap: _pickAvatar,
                  child: NeoPixelBox(
                    isButton: true,
                    padding: 8,
                    child: Container(
                      width: 120,
                      height: 120,
                      decoration: const BoxDecoration(
                        color: AppColors.neutralBg,
                        shape: BoxShape.circle,
                      ),
                      clipBehavior: Clip.antiAlias,
                      child: _avatarFile != null 
                        ? Image.file(_avatarFile!, fit: BoxFit.cover)
                        : const Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.add_a_photo, size: 40, color: AppColors.primary),
                              SizedBox(height: 8),
                              Text('UPLOAD', style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
                            ],
                          ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 32),

              NeoPixelBox(
                padding: 8,
                child: TextField(
                  controller: _nameCtrl,
                  decoration: const InputDecoration(
                    hintText: 'Display Name',
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.symmetric(horizontal: 16),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              
              NeoPixelBox(
                padding: 8,
                child: TextField(
                  controller: _institutionCtrl,
                  decoration: const InputDecoration(
                    hintText: 'Institution / Organization',
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.symmetric(horizontal: 16),
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Role Selector
              Text('Select Protocol Role:', style: Theme.of(context).textTheme.bodyLarge),
              const SizedBox(height: 16),
              
              Row(
                children: [
                   _buildRoleCard('student', 'Student'),
                   const SizedBox(width: 12),
                   _buildRoleCard('mentor', 'Mentor'),
                   const SizedBox(width: 12),
                   _buildRoleCard('explorer', 'Explorer'),
                ],
              ),
              
              const SizedBox(height: 60),

              NeoPixelBox(
                isButton: true,
                onTap: _saveProfile,
                padding: 16,
                child: Center(
                  child: _isLoading 
                    ? const CircularProgressIndicator(color: AppColors.neutralBg)
                    : Text('FINALIZE', style: Theme.of(context).textTheme.displayMedium?.copyWith(
                        fontSize: 24, color: AppColors.primary,
                      )),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRoleCard(String  roleId, String title) {
    final isSelected = _selectedRole == roleId;
    return Expanded(
      child: NeoPixelBox(
        isButton: isSelected,
        onTap: () => setState(() => _selectedRole = roleId),
        padding: 8,
        child: Column(
          children: [
            // Pixel Art Placeholder Box
            Container(
              height: 60,
              width: double.infinity,
              decoration: BoxDecoration(
                color: AppColors.neutralBg.withAlpha(isSelected ? 0 : 150),
                border: Border.all(color: AppColors.blockEdge, width: 2),
              ),
              child: Image.asset(
                'assets/images/role_$roleId.gif',
                fit: BoxFit.contain,
                errorBuilder: (ctx, err, stack) {
                  return const Center(
                    child: Icon(Icons.broken_image, size: 24, color: AppColors.textSecondary),
                  );
                },
              ),
            ),
            const SizedBox(height: 8),
            Text(
              title,
              style: TextStyle(
                fontSize: 12,
                color: isSelected ? AppColors.primary : AppColors.textPrimary,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
              overflow: TextOverflow.ellipsis,
              maxLines: 1,
            ),
          ],
        ),
      ),
    );
  }
}
