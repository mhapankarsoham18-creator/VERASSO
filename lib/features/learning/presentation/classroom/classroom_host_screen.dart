import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:verasso/core/ui/glass_container.dart';
import 'package:verasso/core/ui/liquid_background.dart';
import 'package:verasso/features/auth/presentation/auth_controller.dart';

import '../../data/classroom_session_service.dart';

/// A screen for teachers or hosts to manage a real-time mesh-based classroom session.
class ClassroomHostScreen extends ConsumerStatefulWidget {
  /// Creates a [ClassroomHostScreen] instance.
  const ClassroomHostScreen({super.key});

  @override
  ConsumerState<ClassroomHostScreen> createState() =>
      _ClassroomHostScreenState();
}

class _ClassroomHostScreenState extends ConsumerState<ClassroomHostScreen> {
  final _subjectController = TextEditingController();
  final _topicController = TextEditingController();
  final _pollController = TextEditingController();

  bool _isSessionStarted = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Host Classroom Session')),
      body: LiquidBackground(
        child:
            !_isSessionStarted ? _buildSetupView() : _buildActiveSessionView(),
      ),
    );
  }

  Widget _buildActiveSessionView() {
    final participantsStream =
        ref.watch(classroomSessionServiceProvider).participantsStream;
    final pollStream = ref.watch(classroomSessionServiceProvider).pollStream;
    final doubtsStream =
        ref.watch(classroomSessionServiceProvider).doubtsStream;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          GlassContainer(
            child: Row(
              children: [
                const Icon(LucideIcons.wifi, color: Colors.green),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(_subjectController.text,
                          style: const TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 18)),
                      Text(_topicController.text,
                          style: const TextStyle(color: Colors.white70)),
                    ],
                  ),
                ),
                Chip(
                  label: const Text('HOST'),
                  backgroundColor: Colors.orange.withValues(alpha: 0.8),
                )
              ],
            ),
          ),

          const SizedBox(height: 16),

          // Row: Participants & QR
          Row(
            children: [
              Expanded(
                child: StreamBuilder<List<String>>(
                  stream: participantsStream,
                  initialData: const [],
                  builder: (context, snapshot) {
                    final count = snapshot.data!.length;
                    return GlassContainer(
                      child: Column(
                        children: [
                          Text('$count',
                              style: const TextStyle(
                                  fontSize: 32, fontWeight: FontWeight.bold)),
                          const Text('Students Connected'),
                        ],
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(width: 16),
              // QR Code Placeholder (future feature: easy join)
              GlassContainer(
                child: QrImageView(
                  data: 'verasso_session_123', // Demo ID
                  version: QrVersions.auto,
                  size: 80,
                  eyeStyle: const QrEyeStyle(
                    eyeShape: QrEyeShape.square,
                    color: Colors.white,
                  ),
                  dataModuleStyle: const QrDataModuleStyle(
                    dataModuleShape: QrDataModuleShape.square,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 24),
          const Text('Live Activity',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),

          // Poll Section
          StreamBuilder<SessionPoll?>(
            stream: pollStream,
            builder: (context, snapshot) {
              final poll = snapshot.data;
              if (poll == null) {
                return GestureDetector(
                  onTap: () => _showPollDialog(context),
                  child: const GlassContainer(
                    child: Center(
                      child: Column(
                        children: [
                          Icon(LucideIcons.barChart2,
                              size: 32, color: Colors.white70),
                          SizedBox(height: 8),
                          Text('+ Launch Quick Poll'),
                        ],
                      ),
                    ),
                  ),
                );
              }

              return GlassContainer(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Poll: ${poll.question}',
                        style: const TextStyle(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 12),
                    ...poll.options.asMap().entries.map((entry) {
                      final opt = entry.value;
                      final idxStr = entry.key.toString();
                      final voteCount = poll.votes[idxStr] ?? 0;

                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        child: Row(
                          children: [
                            Expanded(child: Text(opt)),
                            Text('$voteCount votes',
                                style: const TextStyle(
                                    fontWeight: FontWeight.bold)),
                          ],
                        ),
                      );
                    }),
                  ],
                ),
              );
            },
          ),

          const SizedBox(height: 24),
          const Text('Doubts Feed',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),

          StreamBuilder<List<SessionDoubt>>(
            stream: doubtsStream,
            initialData: const [],
            builder: (context, snapshot) {
              final doubts = snapshot.data!;
              if (doubts.isEmpty) {
                return const Center(
                    child: Text('No doubts raised yet.',
                        style: TextStyle(color: Colors.white54)));
              }

              return Column(
                children: doubts
                    .map((doubt) => Padding(
                          padding: const EdgeInsets.only(bottom: 8.0),
                          child: GlassContainer(
                            child: ListTile(
                              leading: const CircleAvatar(
                                  child: Icon(LucideIcons.user)),
                              title: Text(doubt.question),
                              subtitle: Text('Asked by ${doubt.userName}'),
                              trailing:
                                  const Icon(LucideIcons.thumbsUp, size: 16),
                            ),
                          ),
                        ))
                    .toList(),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildSetupView() {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: GlassContainer(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(LucideIcons.presentation, size: 48, color: Colors.white),
            const SizedBox(height: 16),
            const Text(
              'Start a Mesh Session',
              style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.white),
            ),
            const SizedBox(height: 24),
            TextField(
              controller: _subjectController,
              decoration:
                  const InputDecoration(labelText: 'Subject (e.g. Physics)'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _topicController,
              decoration: const InputDecoration(
                  labelText: 'Topic (e.g. Thermodynamics)'),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _startSession,
                icon: const Icon(LucideIcons.radio),
                label: const Text('Broadcast Session'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _publishPoll() {
    if (_pollController.text.isEmpty) return;

    // Quick Poll format for MVP: Yes/No/Maybe
    // Or parsing custom options? Let's do defaults for speed.
    ref.read(classroomSessionServiceProvider).publishPoll(
      _pollController.text,
      ['Yes', 'No', 'Maybe'],
    );
    _pollController.clear();
    Navigator.pop(context); // Close dialog
  }

  void _showPollDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.black87,
        title: const Text('Create Poll', style: TextStyle(color: Colors.white)),
        content: TextField(
          controller: _pollController,
          decoration: const InputDecoration(
              hintText: 'Ask a question...',
              hintStyle: TextStyle(color: Colors.white54)),
          style: const TextStyle(color: Colors.white),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: _publishPoll,
            child: const Text('Publish'),
          )
        ],
      ),
    );
  }

  void _startSession() {
    if (_subjectController.text.isEmpty) return;

    final userId = ref.read(currentUserProvider)?.id;
    if (userId == null) return; // Should show error

    ref.read(classroomSessionServiceProvider).startSession(
          userId,
          _subjectController.text,
          _topicController.text,
        );

    setState(() => _isSessionStarted = true);
  }
}
