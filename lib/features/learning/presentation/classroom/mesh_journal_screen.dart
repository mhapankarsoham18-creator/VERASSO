import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:verasso/core/ui/glass_container.dart';
import 'package:verasso/core/ui/liquid_background.dart';

import 'services/mesh_journal_service.dart';

/// A screen for collaborative note-taking over a mesh network.
class MeshJournalScreen extends ConsumerStatefulWidget {
  /// Creates a [MeshJournalScreen] instance.
  const MeshJournalScreen({super.key});

  @override
  ConsumerState<MeshJournalScreen> createState() => _MeshJournalScreenState();
}

class _MeshJournalScreenState extends ConsumerState<MeshJournalScreen> {
  late TextEditingController _controller;
  bool _isLocalUpdate = false;

  @override
  Widget build(BuildContext context) {
    final journalState = ref.watch(meshJournalServiceProvider);

    // Update controller text if it's a remote update and content changed
    if (!_isLocalUpdate && _controller.text != journalState.content) {
      _controller.text = journalState.content;
      // Maintain cursor position if possible or just reset
    }
    _isLocalUpdate = false;

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text("Mesh Journal"),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(LucideIcons.users),
            onPressed: () {},
          ),
        ],
      ),
      body: LiquidBackground(
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      "Last updated by: ${journalState.updatedBy}",
                      style:
                          const TextStyle(color: Colors.white54, fontSize: 12),
                    ),
                    const Icon(LucideIcons.wifi,
                        color: Colors.greenAccent, size: 14),
                  ],
                ),
                const SizedBox(height: 10),
                Expanded(
                  child: GlassContainer(
                    padding: const EdgeInsets.all(16),
                    child: TextField(
                      controller: _controller,
                      maxLines: null,
                      expands: true,
                      style: const TextStyle(
                          color: Colors.white, fontSize: 16, height: 1.5),
                      decoration: const InputDecoration(
                        border: InputBorder.none,
                        hintText: "Start taking collaborative notes...",
                        hintStyle: TextStyle(color: Colors.white24),
                      ),
                      onChanged: (val) {
                        _isLocalUpdate = true;
                        ref
                            .read(meshJournalServiceProvider.notifier)
                            .updateNote(val);
                      },
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                const Text(
                  "Changes sync instantly with nearby peers via Mesh network.",
                  style: TextStyle(color: Colors.white38, fontSize: 10),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController();
  }
}
