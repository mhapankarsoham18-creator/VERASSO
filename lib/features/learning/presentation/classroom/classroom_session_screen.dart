import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:verasso/core/ui/glass_container.dart';
import 'package:verasso/core/ui/liquid_background.dart';
import 'package:verasso/features/auth/presentation/auth_controller.dart';

import '../../data/classroom_session_service.dart';
import 'widgets/poll_voting_widget.dart';

/// A screen that displays the active classroom session for a student.
class ClassroomSessionScreen extends ConsumerStatefulWidget {
  /// Creates a [ClassroomSessionScreen] instance.
  const ClassroomSessionScreen({super.key});

  @override
  ConsumerState<ClassroomSessionScreen> createState() =>
      _ClassroomSessionScreenState();
}

class _ClassroomSessionScreenState
    extends ConsumerState<ClassroomSessionScreen> {
  final TextEditingController _doubtController = TextEditingController();
  final TextEditingController _nameController = TextEditingController();
  bool _isSearching = false;
  bool _joined = false;

  @override
  Widget build(BuildContext context) {
    final sessionService = ref.watch(classroomSessionServiceProvider);

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text("Student Session"),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: LiquidBackground(
        child: SafeArea(
          child: StreamBuilder<ClassroomSession?>(
            stream: sessionService.sessionStream,
            builder: (context, snapshot) {
              final session = snapshot.data;

              if (session == null) {
                return _buildLobby(sessionService);
              }

              if (!_joined) {
                return _buildJoinConfirm(session, sessionService);
              }

              return _buildActiveSession(session, sessionService);
            },
          ),
        ),
      ),
    );
  }

  Widget _buildActiveSession(
      ClassroomSession session, ClassroomSessionService service) {
    return Column(
      children: [
        // Header
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: GlassContainer(
            child: Row(
              children: [
                const Icon(LucideIcons.bookOpen, color: Colors.blueAccent),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(session.subject,
                        style: const TextStyle(fontWeight: FontWeight.bold)),
                    Text(session.topic,
                        style: const TextStyle(color: Colors.white70)),
                  ],
                ),
              ],
            ),
          ),
        ),

        const SizedBox(height: 10),

        // Polls Stream
        Expanded(
          child: StreamBuilder<SessionPoll?>(
            stream: service.pollStream,
            builder: (context, snapshot) {
              final poll = snapshot.data;
              if (poll == null) {
                return const Center(
                  child: Text("Waiting for activities...",
                      style: TextStyle(color: Colors.white54)),
                );
              }

              // Convert SessionPoll (Data) to Poll (Widget Model) mismatch?
              // The widget expects `Poll` class I defined locally before.
              // I should adapt the widget or use Poll data.
              // Let's adapt here inline or map it.
              // Actually `PollVotingWidget` expects `Poll` class.
              // `SessionPoll` in service has similar fields.

              return ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  PollVotingWidget(
                    poll: poll,
                    isTeacher: false, // This is student screen
                    onVote: (index) {
                      final userId =
                          ref.read(currentUserProvider)?.id ?? "GUEST";
                      service.votePoll(poll.id, index, userId);
                    },
                  ),
                ],
              );
            },
          ),
        ),

        // Doubt Input
        Container(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _doubtController,
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    hintText: "Ask a doubt...",
                    hintStyle: const TextStyle(color: Colors.white54),
                    filled: true,
                    fillColor: Colors.black54,
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(20),
                        borderSide: BorderSide.none),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              IconButton(
                style: IconButton.styleFrom(backgroundColor: Colors.blueAccent),
                icon: const Icon(LucideIcons.send, color: Colors.white),
                onPressed: () {
                  if (_doubtController.text.isNotEmpty) {
                    final userId = ref.read(currentUserProvider)?.id ?? "GUEST";
                    service.raiseDoubt(
                        userId, _nameController.text, _doubtController.text);
                    _doubtController.clear();
                    ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text("Doubt Sent")));
                  }
                },
              )
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildJoinConfirm(
      ClassroomSession session, ClassroomSessionService service) {
    return Center(
      child: GlassContainer(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(LucideIcons.wifi, size: 48, color: Colors.greenAccent),
            const SizedBox(height: 16),
            Text("Found Session: ${session.subject}",
                style: const TextStyle(
                    fontSize: 20,
                    color: Colors.white,
                    fontWeight: FontWeight.bold)),
            Text(session.topic, style: const TextStyle(color: Colors.white70)),
            const SizedBox(height: 24),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
              onPressed: () {
                service.joinSessionRequest(_nameController.text);
                setState(() => _joined = true);
              },
              child: const Text("Join Now"),
            )
          ],
        ),
      ),
    );
  }

  Widget _buildLobby(ClassroomSessionService service) {
    return Center(
      child: GlassContainer(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(LucideIcons.school, size: 64, color: Colors.white),
            const SizedBox(height: 20),
            const Text(
              "Join Classroom",
              style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.white),
            ),
            const SizedBox(height: 24),
            TextField(
              controller: _nameController,
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(
                labelText: "Your Name",
                prefixIcon: Icon(LucideIcons.user, color: Colors.white70),
              ),
            ),
            const SizedBox(height: 24),
            if (_isSearching)
              const Column(
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text("Searching for teacher...",
                      style: TextStyle(color: Colors.white70)),
                ],
              )
            else
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 50),
                  backgroundColor: Colors.blueAccent,
                ),
                icon: const Icon(LucideIcons.search),
                label: const Text("Find Session"),
                onPressed: () {
                  if (_nameController.text.isNotEmpty) {
                    setState(() => _isSearching = true);
                    service.startStudentDiscovery();
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text("Enter name first")));
                  }
                },
              ),
          ],
        ),
      ),
    );
  }
}
