import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:verasso/core/ui/glass_container.dart';
import 'package:verasso/core/ui/liquid_background.dart';

import '../../../../core/services/bluetooth_mesh_service.dart';
import 'services/doubt_swarm_service.dart';

/// A screen that facilitates peer-to-peer help through a "swarm" of student experts.
class DoubtSwarmScreen extends ConsumerStatefulWidget {
  /// Creates a [DoubtSwarmScreen] instance.
  const DoubtSwarmScreen({super.key});

  @override
  ConsumerState<DoubtSwarmScreen> createState() => _DoubtSwarmScreenState();
}

class _DoubtSwarmScreenState extends ConsumerState<DoubtSwarmScreen> {
  final TextEditingController _questionController = TextEditingController();
  String _selectedSubject = "Physics";
  final List<String> _subjects = [
    "Physics",
    "Chemistry",
    "Biology",
    "Mathematics",
    "Computer Science"
  ];

  @override
  Widget build(BuildContext context) {
    final swarmDoubts = ref.watch(doubtSwarmServiceProvider);
    final swarmService = ref.read(doubtSwarmServiceProvider.notifier);
    final meshService = ref.watch(bluetoothMeshServiceProvider);

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text("Doubt Swarm"),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: LiquidBackground(
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 1. My Expertise Config
                GlassContainer(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text("My Expertise",
                          style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold)),
                      const SizedBox(height: 10),
                      Wrap(
                        spacing: 8,
                        children: _subjects.map((sub) {
                          final isExpert = meshService.expertise.contains(sub);
                          return FilterChip(
                            label: Text(sub),
                            selected: isExpert,
                            onSelected: (val) {
                              final current =
                                  List<String>.from(meshService.expertise);
                              if (val) {
                                current.add(sub);
                              } else {
                                current.remove(sub);
                              }
                              meshService.setExpertise(current);
                              setState(() {});
                            },
                            selectedColor:
                                Colors.blueAccent.withValues(alpha: 0.5),
                            labelStyle: TextStyle(
                                color:
                                    isExpert ? Colors.white : Colors.white70),
                          );
                        }).toList(),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 20),

                // 2. Ask a Doubt
                GlassContainer(
                  child: Column(
                    children: [
                      Row(
                        children: [
                          const Icon(LucideIcons.helpCircle,
                              color: Colors.orangeAccent),
                          const SizedBox(width: 10),
                          Expanded(
                            child: DropdownButton<String>(
                              value: _selectedSubject,
                              dropdownColor: Colors.black87,
                              isExpanded: true,
                              underline: Container(),
                              items: _subjects
                                  .map((s) => DropdownMenuItem(
                                      value: s,
                                      child: Text(s,
                                          style: const TextStyle(
                                              color: Colors.white))))
                                  .toList(),
                              onChanged: (val) =>
                                  setState(() => _selectedSubject = val!),
                            ),
                          ),
                        ],
                      ),
                      TextField(
                        controller: _questionController,
                        style: const TextStyle(color: Colors.white),
                        decoration: const InputDecoration(
                          hintText: "What's your tough doubt?",
                          hintStyle: TextStyle(color: Colors.white54),
                        ),
                      ),
                      const SizedBox(height: 10),
                      ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.orangeAccent),
                        icon: const Icon(LucideIcons.send),
                        label: const Text("Swarm Help!"),
                        onPressed: () {
                          if (_questionController.text.isNotEmpty) {
                            swarmService.requestHelp(
                                _questionController.text, _selectedSubject);
                            _questionController.clear();
                            ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                    content: Text("Swarm Request Sent!")));
                          }
                        },
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 20),

                // 3. Incoming Requests (For Me as Expert)
                const Text("Requests for You (Expert)",
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold)),
                const SizedBox(height: 10),
                Expanded(
                  child: swarmDoubts.isEmpty
                      ? const Center(
                          child: Text(
                              "Waiting for doubts in your expertise area...",
                              style: TextStyle(color: Colors.white54)))
                      : ListView.builder(
                          itemCount: swarmDoubts.length,
                          itemBuilder: (context, index) {
                            final request = swarmDoubts[index];
                            return GlassContainer(
                              margin: const EdgeInsets.only(bottom: 12),
                              child: ListTile(
                                leading: CircleAvatar(
                                  backgroundColor: Colors.blueAccent,
                                  child: Text(request.senderName[0]),
                                ),
                                title: Text(request.question,
                                    style: const TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold)),
                                subtitle: Text(
                                    "From: ${request.senderName} • ${request.subject}",
                                    style:
                                        const TextStyle(color: Colors.white70)),
                                trailing: IconButton(
                                  icon: const Icon(LucideIcons.messageSquare,
                                      color: Colors.greenAccent),
                                  onPressed: () {
                                    // Future: Deep link to chat or quick reply
                                  },
                                ),
                              ),
                            )
                                .animate()
                                .slideX(begin: 1, end: 0, duration: 300.ms);
                          },
                        ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
