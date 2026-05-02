import 'dart:io';
import 'package:flutter/material.dart';
import 'package:sentry_flutter/sentry_flutter.dart';
import 'package:verasso/core/theme/verasso_loading.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:image_picker/image_picker.dart';
import '../../../core/theme/colors.dart';
import '../../../core/theme/neo_pixel_box.dart';
import '../../../core/validators/input_validator.dart';
import '../../../core/utils/file_validator.dart';
import 'package:verasso/core/utils/logger.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _displayNameController = TextEditingController();
  final _usernameController = TextEditingController();
  final _institutionController = TextEditingController();
  final _bioController = TextEditingController();

  bool _isLoading = true;
  bool _isSaving = false;
  String? _avatarUrl;
  File? _newAvatar;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) throw 'Not logged in';

      final profile = await Supabase.instance.client
          .from('profiles')
          .select()
          .eq('firebase_uid', user.uid)
          .maybeSingle();

      if (profile != null) {
        _displayNameController.text = profile['display_name'] ?? '';
        _usernameController.text = profile['username'] ?? '';
        _institutionController.text = profile['institution'] ?? '';
        _bioController.text = profile['bio'] ?? '';
        _avatarUrl = profile['avatar_url'];
      }
    } catch (e, stackTrace) {
      Sentry.captureException(e, stackTrace: stackTrace);
      appLogger.d('Error loading profile: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
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
      setState(() => _newAvatar = File(pickedFile.path));
    }
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSaving = true);

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) throw 'User not authenticated';

      String? uploadedUrl = _avatarUrl;
      
      if (_newAvatar != null) {
        final ext = _newAvatar!.path.split('.').last;
        final filename = '${user.uid}_${DateTime.now().millisecondsSinceEpoch}.$ext';
        // Note: Assumes 'avatars' bucket exists and is public
        await Supabase.instance.client.storage.from('avatars').upload(filename, _newAvatar!);
        uploadedUrl = Supabase.instance.client.storage.from('avatars').getPublicUrl(filename);
      }

      await Supabase.instance.client.from('profiles').update({
        'display_name': InputValidator.sanitize(_displayNameController.text),
        'username': InputValidator.sanitize(_usernameController.text).toLowerCase(),
        'institution': InputValidator.sanitize(_institutionController.text),
        'bio': InputValidator.sanitize(_bioController.text),
        if (uploadedUrl != null) 'avatar_url': uploadedUrl,
      }).eq('firebase_uid', user.uid);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Profile updated successfully.')));
        Navigator.pop(context, true); // Pop and optionally tell parent to refresh
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to update profile: $e')));
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        backgroundColor: context.colors.neutralBg,
        body: Center(child: VerassoLoading()),
      );
    }

    return Scaffold(
      backgroundColor: context.colors.neutralBg,
      appBar: AppBar(
        title: Text('EDIT PROFILE', style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: 2)),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: EdgeInsets.all(24.0),
          children: [
            Center(
              child: GestureDetector(
                onTap: _pickAvatar,
                child: Container(
                  width: 120, height: 120,
                  decoration: BoxDecoration(
                    color: context.colors.blockEdge,
                    shape: BoxShape.circle,
                    border: Border.all(color: context.colors.primary, width: 4),
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: Stack(
                    children: [
                      if (_newAvatar != null)
                        Image.file(_newAvatar!, fit: BoxFit.cover, width: double.infinity, height: double.infinity)
                      else if (_avatarUrl != null)
                        CachedNetworkImage(imageUrl: _avatarUrl!, fit: BoxFit.cover, width: double.infinity, height: double.infinity)
                      else
                        Center(child: Icon(Icons.person, size: 64, color: context.colors.neutralBg)),
                      
                      Align(
                        alignment: Alignment.bottomCenter,
                        child: Container(
                          width: double.infinity,
                          color: context.colors.neutralBg,
                          padding: EdgeInsets.symmetric(vertical: 4),
                          child: Icon(Icons.camera_alt, color: context.colors.textPrimary, size: 20),
                        ),
                      )
                    ],
                  ),
                ),
              ),
            ),
            SizedBox(height: 32),
            NeoPixelBox(
              padding: 16,
              enableTilt: false,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _buildLabel('DISPLAY NAME'),
                  _buildTextField(_displayNameController, 'Enter Display Name', validator: (val) {
                    return InputValidator.validateDisplayName(val ?? '');
                  }),
                  Divider(color: context.colors.blockEdge, height: 32, thickness: 2),
                  
                  _buildLabel('USERNAME'),
                  _buildTextField(_usernameController, 'Enter Username', validator: (val) {
                    return InputValidator.validateUsername(val ?? '');
                  }),
                  Divider(color: context.colors.blockEdge, height: 32, thickness: 2),

                  _buildLabel('INSTITUTION / NODE'),
                  _buildTextField(_institutionController, 'Enter Institution Name'),
                  Divider(color: context.colors.blockEdge, height: 32, thickness: 2),

                  _buildLabel('BIO'),
                  _buildTextField(_bioController, 'Write a short bio...', maxLines: 3),
                ],
              ),
            ),
            SizedBox(height: 32),
            NeoPixelBox(
              padding: 16,
              isButton: true,
              onTap: _isSaving ? null : _saveProfile,
              child: Center(
                child: _isSaving 
                    ? SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: context.colors.primary, strokeWidth: 3))
                    : Text('SAVE IDENTITY', style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 2, color: context.colors.primary, fontSize: 16)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLabel(String text) {
    return Padding(
      padding: EdgeInsets.only(bottom: 8),
      child: Text(text, style: TextStyle(fontWeight: FontWeight.w900, color: context.colors.textSecondary, fontSize: 12)),
    );
  }

  Widget _buildTextField(TextEditingController controller, String hint, {int maxLines = 1, String? Function(String?)? validator}) {
    return TextFormField(
      controller: controller,
      maxLines: maxLines,
      validator: validator,
      style: TextStyle(fontWeight: FontWeight.bold, color: context.colors.textPrimary),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(color: context.colors.textSecondary, fontWeight: FontWeight.normal),
        border: InputBorder.none,
        isDense: true,
      ),
    );
  }
}

