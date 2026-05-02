import 'package:flutter/material.dart';
import 'package:verasso/core/theme/verasso_loading.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/theme/colors.dart';
import '../../../core/theme/neo_pixel_box.dart';
import 'package:verasso/core/utils/logger.dart';

class CreateDoubtScreen extends StatefulWidget {
  const CreateDoubtScreen({super.key});

  @override
  State<CreateDoubtScreen> createState() => _CreateDoubtScreenState();
}

class _CreateDoubtScreenState extends State<CreateDoubtScreen> {
  final _titleController = TextEditingController();
  final _bodyController = TextEditingController();
  final _subjectController = TextEditingController();
  final _tagsController = TextEditingController();
  bool _isLoading = false;
  bool _isOfflineMeshEnabled = false;

  Future<void> _submit() async {
    if (_titleController.text.trim().isEmpty || _bodyController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Title and details are required!')));
      return;
    }

    setState(() => _isLoading = true);
    try {
      final fbUser = FirebaseAuth.instance.currentUser;
      if (fbUser == null) throw 'Not authenticated.';
      final profileResponse = await Supabase.instance.client.from('profiles').select('id').eq('firebase_uid', fbUser.uid).maybeSingle();
      if (profileResponse == null) throw 'Profile not found.';

      final tags = _tagsController.text.split(',').map((e) => e.trim()).where((e) => e.isNotEmpty).toList();
      await Supabase.instance.client.from('doubts').insert({
        'author_id': profileResponse['id'],
        'title': _titleController.text.trim(),
        'body': _bodyController.text.trim(),
        'subject': _subjectController.text.trim().isEmpty ? 'General' : _subjectController.text.trim(),
        'tags': tags,
      });

      if (mounted) {
        Navigator.pop(context, true);
      }
    } catch (e) {
      appLogger.d('Error creating doubt: $e');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.colors.neutralBg,
      appBar: AppBar(
        title: Text('ASK THE GRID', style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: 2, fontSize: 16)),
        leading: IconButton(icon: Icon(Icons.arrow_back, color: context.colors.textPrimary), onPressed: () => Navigator.pop(context)),
      ),
      body: _isLoading 
        ? Center(child: VerassoLoading())
        : SingleChildScrollView(
            padding: EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildField('SUBJECT', _subjectController, hint: 'e.g. Physics, Astrodynamics'),
                SizedBox(height: 24),
                _buildField('DOUBT TITLE', _titleController, hint: 'What is the exact question?'),
                SizedBox(height: 24),
                _buildField('DETAILS / CONTEXT', _bodyController, hint: 'Explain what you tried and where you are stuck...', maxLines: 5),
                SizedBox(height: 24),
                _buildField('TAGS (comma separated)', _tagsController, hint: 'e.g. mechanics, formula'),
                SizedBox(height: 24),
                
                // MESH BROADCAST OPTION
                NeoPixelBox(
                  padding: 12,
                  child: Row(
                    children: [
                      Icon(Icons.wifi_off_rounded, color: context.colors.primary, size: 28),
                      SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Offline Mesh Broadcast', style: TextStyle(fontWeight: FontWeight.w900, color: context.colors.textPrimary, fontSize: 14)),
                            Text('Relay this via nearby Bluetooth nodes', style: TextStyle(fontWeight: FontWeight.w600, color: context.colors.shadowDark, fontSize: 11)),
                          ],
                        ),
                      ),
                      Switch(
                        value: _isOfflineMeshEnabled,
                        onChanged: (val) => setState(() => _isOfflineMeshEnabled = val),
                        activeThumbColor: context.colors.primary,
                        activeTrackColor: context.colors.primary.withValues(alpha: 0.3),
                      ),
                    ],
                  ),
                ),
                
                SizedBox(height: 32),
                NeoPixelBox(
                  padding: 16,
                  isButton: true,
                  onTap: _submit,
                  child: Center(
                    child: Text(_isOfflineMeshEnabled ? 'INITIATE OFFLINE RELAY' : 'BROADCAST DOUBT', style: TextStyle(fontWeight: FontWeight.w900, color: context.colors.primary, letterSpacing: 2)),
                  ),
                ),
              ],
            ),
          ),
    );
  }

  Widget _buildField(String label, TextEditingController controller, {String? hint, int maxLines = 1}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: TextStyle(fontWeight: FontWeight.w900, fontSize: 12, color: context.colors.textSecondary, letterSpacing: 2)),
        SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: context.colors.shadowLight,
            border: Border.all(color: context.colors.blockEdge, width: 2),
            borderRadius: BorderRadius.circular(0), // strict sharp pixels here
          ),
          child: TextField(
            controller: controller,
            maxLines: maxLines,
            style: TextStyle(fontWeight: FontWeight.w600, color: context.colors.textPrimary, fontSize: 14),
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: TextStyle(color: context.colors.shadowDark, fontWeight: FontWeight.normal),
              border: InputBorder.none,
              contentPadding: EdgeInsets.all(12),
            ),
          ),
        ),
      ],
    );
  }
}

