import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:verasso/core/ui/glass_container.dart';
import 'package:verasso/core/ui/liquid_background.dart';
import 'package:verasso/features/auth/presentation/auth_controller.dart';

import '../../data/classroom_session_service.dart';

/// A screen for students to interact with a live classroom session, including polls and doubts.
class ClassroomStudentScreen extends ConsumerStatefulWidget {
  /// Creates a [ClassroomStudentScreen] instance.
  const ClassroomStudentScreen({super.key});

  @override
  ConsumerState<ClassroomStudentScreen> createState() =>
      _ClassroomStudentScreenState();
}

class _ClassroomStudentScreenState
    extends ConsumerState<ClassroomStudentScreen> {
  final _doubtController = TextEditingController();

  bool _joined = false;

  @override
  Widget build(BuildContext context) {
    final sessionStream =
        ref.watch(classroomSessionServiceProvider).sessionStream;

    return Scaffold(
      appBar: AppBar(title: const Text('Classroom')),
      body: LiquidBackground(
        child: StreamBuilder<ClassroomSession?>(
          stream: sessionStream,
          builder: (context, snapshot) {
            final session = snapshot.data;

            if (session == null) {
              return const Center(
                child: GlassContainer(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      CircularProgressIndicator(),
                      SizedBox(height: 16),
                      Text('Listening for Class Session...',
                          textAlign: TextAlign.center),
                      SizedBox(height: 8),
                      Text('Make sure you are near the teacher',
                          style:
                              TextStyle(fontSize: 12, color: Colors.white70)),
                    ],
                  ),
                ),
              );
            }

            if (!_joined) {
              return Center(
                child: GlassContainer(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(LucideIcons.school,
                          size: 48, color: Colors.white),
                      const SizedBox(height: 16),
                      Text('Join ${session.subject}?',
                          style: const TextStyle(
                              fontSize: 20, fontWeight: FontWeight.bold)),
                      Text(session.topic),
                      const SizedBox(height: 24),
                      ElevatedButton(
                        onPressed: _joinSession,
                        child: const Text('Join Class'),
                      )
                    ],
                  ),
                ),
              );
            }

            return SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  // Session Info
                  GlassContainer(
                    child: ListTile(
                      title: Text(session.subject,
                          style: const TextStyle(fontWeight: FontWeight.bold)),
                      subtitle: Text(session.topic),
                      trailing: const Chip(
                          label: Text('LIVE'),
                          backgroundColor: Colors.redAccent),
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Active Poll
                  StreamBuilder<SessionPoll?>(
                    stream:
                        ref.watch(classroomSessionServiceProvider).pollStream,
                    builder: (context, pollSnap) {
                      final poll = pollSnap.data;
                      if (poll == null) return const SizedBox.shrink();

                      return GlassContainer(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(poll.question,
                                style: const TextStyle(
                                    fontSize: 18, fontWeight: FontWeight.bold)),
                            const SizedBox(height: 16),
                            ...poll.options
                                .asMap()
                                .entries
                                .map((entry) => Padding(
                                      padding:
                                          const EdgeInsets.only(bottom: 8.0),
                                      child: SizedBox(
                                        width: double.infinity,
                                        child: OutlinedButton(
                                          onPressed: () =>
                                              _vote(poll.id, entry.key),
                                          child: Text(entry.value),
                                        ),
                                      ),
                                    ))
                          ],
                        ),
                      );
                    },
                  ),

                  const SizedBox(height: 24),

                  // Raise Hand Button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () => _showDoubtDialog(context),
                      icon: const Icon(LucideIcons.handMetal),
                      label: const Text('Raise Doubt'),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        backgroundColor: Colors.orange,
                      ),
                    ),
                  ),

                  const SizedBox(height: 24),
                  const Text('Doubt Feed',
                      style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  StreamBuilder<List<SessionDoubt>>(
                    // Reusing session doubt stream for local feedback
                    stream:
                        ref.watch(classroomSessionServiceProvider).doubtsStream,
                    initialData: const [],
                    builder: (ctx, snap) {
                      return Column(
                        children: snap.data!
                            .map((d) => Padding(
                                  padding: const EdgeInsets.only(bottom: 8),
                                  child:
                                      GlassContainer(child: Text(d.question)),
                                ))
                            .toList(),
                      );
                    },
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  void _joinSession() {
    final user = ref.read(currentUserProvider);
    final userName = user?.userMetadata['full_name'] ?? 'Student';

    ref.read(classroomSessionServiceProvider).joinSessionRequest(userName);
    setState(() => _joined = true);
  }

  void _raiseDoubt() {
    if (_doubtController.text.isEmpty) return;

    final user = ref.read(currentUserProvider);
    final userId = user?.id ?? 'anon';
    final userName = user?.userMetadata['full_name'] ?? 'Student';

    ref
        .read(classroomSessionServiceProvider)
        .raiseDoubt(userId, userName, _doubtController.text);
    _doubtController.clear();
    Navigator.pop(context);
  }

  void _showDoubtDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.black87,
        title:
            const Text('Ask Question', style: TextStyle(color: Colors.white)),
        content: TextField(
          controller: _doubtController,
          maxLines: 3,
          decoration: const InputDecoration(
              hintText: 'What is your doubt?',
              hintStyle: TextStyle(color: Colors.white54)),
          style: const TextStyle(color: Colors.white),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(onPressed: _raiseDoubt, child: const Text('Ask')),
        ],
      ),
    );
  }

  void _vote(String pollId, int index) {
    final userId = ref.read(currentUserProvider)?.id ?? 'anon';
    ref.read(classroomSessionServiceProvider).votePoll(pollId, index, userId);
    ScaffoldMessenger.of(context)
        .showSnackBar(const SnackBar(content: Text('Vote Cast!')));
  }
}
