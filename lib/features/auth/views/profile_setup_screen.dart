import 'package:flutter/material.dart';
import 'package:verasso/core/theme/verasso_loading.dart';
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
    
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        String? avatarUrl;
        if (_avatarFile != null) {
          final ext = _avatarFile!.path.split('.').last;
          final fileName = '${user.uid}/avatar.$ext';
          await Supabase.instance.client.storage.from('avatars').upload(fileName, _avatarFile!, fileOptions: FileOptions(upsert: true));
          avatarUrl = Supabase.instance.client.storage.from('avatars').getPublicUrl(fileName);
        }

        await Supabase.instance.client.from('profiles').upsert({
          'firebase_uid': user.uid,
          'display_name': _nameCtrl.text,
          'username': _nameCtrl.text,
          'institution': _institutionCtrl.text,
          'role': _selectedRole,
          'badges': ['VERASSO OS', _selectedRole.toUpperCase()],
          if (avatarUrl != null) 'avatar_url': avatarUrl,
        }, onConflict: 'firebase_uid');
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
      backgroundColor: context.colors.neutralBg,
      appBar: AppBar(
        title: Text('Setup Avatar'),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.all(32.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
               Text(
                'Complete your visual identity',
                style: Theme.of(context).textTheme.bodyLarge,
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 32),

              Center(
                child: GestureDetector(
                  onTap: _pickAvatar,
                  child: NeoPixelBox(
                    isButton: true,
                    padding: 8,
                    child: Container(
                      width: 120,
                      height: 120,
                      decoration: BoxDecoration(
                        color: context.colors.neutralBg,
                        shape: BoxShape.circle,
                      ),
                      clipBehavior: Clip.antiAlias,
                      child: _avatarFile != null 
                        ? Image.file(_avatarFile!, fit: BoxFit.cover)
                        : Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.add_a_photo, size: 40, color: context.colors.primary),
                              SizedBox(height: 8),
                              Text('UPLOAD', style: TextStyle(fontWeight: FontWeight.bold, color: context.colors.textPrimary)),
                            ],
                          ),
                    ),
                  ),
                ),
              ),
              SizedBox(height: 32),

              NeoPixelBox(
                padding: 8,
                child: TextField(
                  controller: _nameCtrl,
                  decoration: InputDecoration(
                    hintText: 'Display Name',
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.symmetric(horizontal: 16),
                  ),
                ),
              ),
              SizedBox(height: 24),
              
              NeoPixelBox(
                padding: 8,
                child: TextField(
                  controller: _institutionCtrl,
                  decoration: InputDecoration(
                    hintText: 'Institution / Organization',
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.symmetric(horizontal: 16),
                  ),
                ),
              ),
              SizedBox(height: 24),

              // Role Selector
              Text('Select Protocol Role:', style: Theme.of(context).textTheme.bodyLarge),
              SizedBox(height: 16),
              
              Row(
                children: [
                   _buildRoleCard('student', 'Student'),
                   SizedBox(width: 12),
                   _buildRoleCard('mentor', 'Mentor'),
                   SizedBox(width: 12),
                   _buildRoleCard('explorer', 'Explorer'),
                ],
              ),
              
              SizedBox(height: 60),

              NeoPixelBox(
                isButton: true,
                onTap: _saveProfile,
                padding: 16,
                child: Center(
                  child: _isLoading 
                    ? VerassoLoading()
                    : Text('FINALIZE', style: Theme.of(context).textTheme.displayMedium?.copyWith(
                        fontSize: 24, color: context.colors.primary,
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
                color: context.colors.neutralBg.withAlpha(isSelected ? 0 : 150),
                border: Border.all(color: context.colors.blockEdge, width: 2),
              ),
              child: Image.asset(
                'assets/images/role_$roleId.gif',
                fit: BoxFit.contain,
                errorBuilder: (ctx, err, stack) {
                  return Center(
                    child: Icon(Icons.broken_image, size: 24, color: context.colors.textSecondary),
                  );
                },
              ),
            ),
            SizedBox(height: 8),
            Text(
              title,
              style: TextStyle(
                fontSize: 12,
                color: isSelected ? context.colors.primary : context.colors.textPrimary,
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
