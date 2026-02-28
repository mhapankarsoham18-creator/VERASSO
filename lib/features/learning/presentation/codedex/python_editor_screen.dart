import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:verasso/core/ui/glass_container.dart';
import 'package:verasso/core/ui/liquid_background.dart';
import 'package:verasso/features/sandbox/python_sandbox.dart';

/// Interactive Python execution screen integrated with the [PythonSandbox].
class PythonEditorScreen extends StatefulWidget {
  /// The title of the current learning module.
  final String moduleTitle;

  /// The starter code pre-filled in the editor.
  final String initialCode;

  /// Creates a [PythonEditorScreen] instance.
  const PythonEditorScreen({
    super.key,
    required this.moduleTitle,
    required this.initialCode,
  });

  @override
  State<PythonEditorScreen> createState() => _PythonEditorScreenState();
}

class _PythonEditorScreenState extends State<PythonEditorScreen> {
  late TextEditingController _codeController;
  String _output = 'Output will appear here...';
  bool _isRunning = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: Text(widget.moduleTitle),
        backgroundColor: Colors.transparent,
      ),
      body: LiquidBackground(
        child: Column(
          children: [
            const SizedBox(height: 100),
            Expanded(
              flex: 2,
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(16),
                  border:
                      Border.all(color: Colors.white.withValues(alpha: 0.1)),
                ),
                child: TextField(
                  controller: _codeController,
                  maxLines: null,
                  expands: true,
                  style: const TextStyle(
                      fontFamily: 'monospace',
                      fontSize: 14,
                      color: Colors.greenAccent),
                  decoration: const InputDecoration(
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.all(16),
                    hintText: 'Enter Python code...',
                    hintStyle: TextStyle(color: Colors.white24),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton.icon(
                  onPressed: _isRunning ? null : _runCode,
                  icon: _isRunning
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: Colors.black))
                      : const Icon(LucideIcons.play),
                  label: const Text('RUN CODE',
                      style: TextStyle(fontWeight: FontWeight.bold)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.greenAccent,
                    foregroundColor: Colors.black,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16)),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Expanded(
              flex: 1,
              child: GlassContainer(
                margin: const EdgeInsets.only(left: 16, right: 16, bottom: 20),
                padding: const EdgeInsets.all(16),
                width: double.infinity,
                child: SingleChildScrollView(
                  child: Text(
                    _output,
                    style: TextStyle(
                      fontFamily: 'monospace',
                      color: _output.startsWith('Error')
                          ? Colors.redAccent
                          : Colors.white70,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _codeController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    _codeController = TextEditingController(text: widget.initialCode);
  }

  Future<void> _runCode() async {
    setState(() {
      _isRunning = true;
      _output = 'Executing...';
    });

    final code = _codeController.text;
    final result = await PythonSandbox.executeWithTests(code);

    if (!mounted) return;

    setState(() {
      _isRunning = false;
      if (result.isSuccessful) {
        _output = "Success!\n\n${result.output ?? ''}";
      } else {
        _output =
            "Error: [${result.status.name}]\n\n${result.error ?? 'Unknown error'}";
      }
    });

    if (result.isSuccessful) {
      // Optional: Hook up to gamification system here
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Execution Successful!'),
          backgroundColor: Colors.green));
    }
  }
}
