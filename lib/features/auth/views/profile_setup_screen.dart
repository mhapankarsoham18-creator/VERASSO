import 'package:flutter/material.dart';
import 'dart:async';
import 'package:verasso/core/theme/verasso_loading.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/colors.dart';
import '../../../core/theme/neo_pixel_box.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import '../../../core/utils/file_validator.dart';
import 'package:verasso/core/utils/logger.dart';

class ProfileSetupScreen extends ConsumerStatefulWidget {
  const ProfileSetupScreen({super.key});

  @override
  ConsumerState<ProfileSetupScreen> createState() => _ProfileSetupScreenState();
}

class _ProfileSetupScreenState extends ConsumerState<ProfileSetupScreen> {
  final _nameCtrl = TextEditingController();
  final _usernameCtrl = TextEditingController();
  final _institutionCtrl = TextEditingController();
  String _selectedRole = 'student';
  DateTime? _dateOfBirth;
  File? _avatarFile;
  bool _isLoading = false;
  bool? _isUsernameAvailable;
  Timer? _debounce;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _usernameCtrl.dispose();
    _institutionCtrl.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  void _checkUsername(String value) {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    if (value.trim().isEmpty) {
      setState(() => _isUsernameAvailable = null);
      return;
    }

    _debounce = Timer(const Duration(milliseconds: 500), () async {
      try {
        final bool available = await Supabase.instance.client
            .rpc('check_username_availability', params: {'target_username': value});
        if (mounted) {
          setState(() => _isUsernameAvailable = available);
        }
      } catch (e) {
        appLogger.d('Username check error: $e');
      }
    });
  }

  Future<void> _pickAvatar() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery, imageQuality: 70);
    if (pickedFile != null) {
      final error = await FileValidator.validateImage(pickedFile);
      if (error != null) {
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error)));
        return;
      }
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
          'username': _usernameCtrl.text.toLowerCase().trim(),
          'institution': _institutionCtrl.text,
          'role': _selectedRole,
          'date_of_birth': _dateOfBirth?.toIso8601String().split('T')[0],
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
                    hintText: 'Display Name (Public Name)',
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.symmetric(horizontal: 16),
                  ),
                ),
              ),
              SizedBox(height: 24),

              NeoPixelBox(
                padding: 8,
                child: TextField(
                  controller: _usernameCtrl,
                  onChanged: _checkUsername,
                  decoration: InputDecoration(
                    hintText: 'Unique Username',
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.symmetric(horizontal: 16),
                    suffixIcon: _isUsernameAvailable == null
                        ? null
                        : Icon(
                            _isUsernameAvailable! ? Icons.check_circle : Icons.cancel,
                            color: _isUsernameAvailable! ? Colors.green : Colors.red,
                          ),
                  ),
                ),
              ),
              if (_isUsernameAvailable == false)
                Padding(
                  padding: const EdgeInsets.only(top: 8.0, left: 8.0),
                  child: Text('This username is already taken.', style: TextStyle(color: Colors.red, fontSize: 12)),
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

              // Date of Birth (COPPA Compliance)
              GestureDetector(
                onTap: () async {
                  final picked = await showDatePicker(
                    context: context,
                    initialDate: DateTime.now().subtract(Duration(days: 365 * 13)), // Default to 13 years ago
                    firstDate: DateTime(1900),
                    lastDate: DateTime.now(),
                    builder: (context, child) {
                      return Theme(
                        data: Theme.of(context).copyWith(
                          colorScheme: ColorScheme.dark(
                            primary: context.colors.primary,
                            onPrimary: context.colors.neutralBg,
                            surface: context.colors.neutralBg,
                            onSurface: context.colors.textPrimary,
                          ),
                        ),
                        child: child!,
                      );
                    },
                  );
                  if (picked != null) {
                    setState(() {
                      _dateOfBirth = picked;
                    });
                  }
                },
                child: NeoPixelBox(
                  padding: 8,
                  child: Container(
                    padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          _dateOfBirth == null 
                              ? 'Date of Birth (Required)' 
                              : '${_dateOfBirth!.year}-${_dateOfBirth!.month.toString().padLeft(2, '0')}-${_dateOfBirth!.day.toString().padLeft(2, '0')}',
                          style: TextStyle(
                            color: _dateOfBirth == null ? context.colors.textSecondary : context.colors.textPrimary,
                            fontSize: 16,
                          ),
                        ),
                        Icon(Icons.calendar_today, color: context.colors.primary),
                      ],
                    ),
                  ),
                ),
              ),
              if (_dateOfBirth != null && DateTime.now().difference(_dateOfBirth!).inDays < 365 * 13)
                Padding(
                  padding: const EdgeInsets.only(top: 8.0, left: 8.0),
                  child: Text('You must be at least 13 years old to use Verasso.', style: TextStyle(color: Colors.red, fontSize: 12)),
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
                onTap: (_isLoading || 
                        _isUsernameAvailable != true || 
                        _dateOfBirth == null || 
                        DateTime.now().difference(_dateOfBirth!).inDays < 365 * 13) ? null : _saveProfile,
                padding: 16,
                child: Center(
                  child: _isLoading 
                    ? VerassoLoading()
                    : Text('FINALIZE', style: Theme.of(context).textTheme.displayMedium?.copyWith(
                        fontSize: 24, 
                        color: (_isUsernameAvailable == true) ? context.colors.primary : context.colors.textSecondary,
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

