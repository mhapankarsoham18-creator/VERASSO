import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';

/// A bottom sheet that allows teachers to create and broadcast a live poll.
class PollCreationSheet extends StatefulWidget {
  /// Callback triggered when a poll is created with a [question] and [options].
  final Function(String question, List<String> options) onCreate;

  /// Creates a [PollCreationSheet] instance.
  const PollCreationSheet({super.key, required this.onCreate});

  @override
  State<PollCreationSheet> createState() => _PollCreationSheetState();
}

class _PollCreationSheetState extends State<PollCreationSheet> {
  final TextEditingController _questionController = TextEditingController();
  final List<TextEditingController> _optionControllers = [
    TextEditingController(),
    TextEditingController(),
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: const BoxDecoration(
        color: Colors.black87, // Dark theme for Verasso
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            "Create Live Poll",
            style: TextStyle(
                color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 20),
          TextField(
            controller: _questionController,
            style: const TextStyle(color: Colors.white),
            decoration: InputDecoration(
              labelText: "Question",
              labelStyle: const TextStyle(color: Colors.white70),
              filled: true,
              fillColor: Colors.white.withValues(alpha: 0.1),
              border:
                  OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
          const SizedBox(height: 16),
          ...List.generate(_optionControllers.length, (index) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 8.0),
              child: TextField(
                controller: _optionControllers[index],
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  labelText: "Option ${index + 1}",
                  labelStyle: const TextStyle(color: Colors.white70),
                  filled: true,
                  fillColor: Colors.white.withValues(alpha: 0.1),
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12)),
                  suffixIcon: index > 1
                      ? IconButton(
                          icon: const Icon(LucideIcons.trash,
                              color: Colors.redAccent),
                          onPressed: () {
                            setState(() {
                              _optionControllers.removeAt(index);
                            });
                          },
                        )
                      : null,
                ),
              ),
            );
          }),
          TextButton.icon(
            onPressed: () {
              setState(() {
                _optionControllers.add(TextEditingController());
              });
            },
            icon: const Icon(LucideIcons.plus, color: Colors.blueAccent),
            label: const Text("Add Option",
                style: TextStyle(color: Colors.blueAccent)),
          ),
          const SizedBox(height: 20),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blueAccent,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: () {
              if (_questionController.text.isEmpty) return;
              final options = _optionControllers
                  .map((c) => c.text)
                  .where((t) => t.isNotEmpty)
                  .toList();
              if (options.length < 2) return; // Need at least 2 options

              widget.onCreate(_questionController.text, options);
              Navigator.pop(context);
            },
            child: const Text("Broadcast Poll",
                style: TextStyle(fontSize: 16, color: Colors.white)),
          ),
        ],
      ),
    );
  }
}
