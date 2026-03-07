import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../features/lesson/data/codedex_service.dart';
import '../../features/lesson/domain/codedex_model.dart';
import '../engine/combat/combat_actions.dart';

/// A premium, glassmorphic overlay to view unlocked coding knowledge.
class CodedexOverlay extends ConsumerStatefulWidget {
  final VoidCallback onClose;

  const CodedexOverlay({super.key, required this.onClose});

  @override
  ConsumerState<CodedexOverlay> createState() => _CodedexOverlayState();
}

class _CodedexOverlayState extends ConsumerState<CodedexOverlay> {
  LanguageArc selectedArc = LanguageArc.python;

  @override
  Widget build(BuildContext context) {
    final codedex = ref.watch(codedexServiceProvider).currentCodedex;
    final entries = codedex.entries[selectedArc] ?? [];

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Stack(
        children: [
          // Blur Background
          GestureDetector(
            onTap: widget.onClose,
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
              child: Container(color: Colors.black.withValues(alpha: 0.7)),
            ),
          ),

          // Content Container
          Center(
            child: Container(
              width: MediaQuery.of(context).size.width * 0.85,
              height: MediaQuery.of(context).size.height * 0.8,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.2),
                  width: 1.5,
                ),
              ),
              child: Column(
                children: [
                  // Header
                  _buildHeader(),

                  // Arc Tabs
                  _buildArcTabs(),

                  // Lesson List
                  Expanded(child: _buildLessonList(entries)),
                ],
              ),
            ),
          ),

          // Close Button
          Positioned(
            top: 40,
            right: 40,
            child: IconButton(
              icon: const Icon(Icons.close, color: Colors.white, size: 32),
              onPressed: widget.onClose,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildArcTabs() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: LanguageArc.values.map((arc) {
          final isSelected = selectedArc == arc;
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: ChoiceChip(
              label: Text(
                arc.name.toUpperCase(),
                style: GoogleFonts.inter(
                  color: isSelected ? Colors.black : Colors.white70,
                  fontWeight: FontWeight.bold,
                ),
              ),
              selected: isSelected,
              onSelected: (selected) {
                if (selected) {
                  setState(() => selectedArc = arc);
                }
              },
              selectedColor: Colors.cyanAccent,
              backgroundColor: Colors.white.withValues(alpha: 0.05),
              showCheckmark: false,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Row(
        children: [
          const Icon(Icons.menu_book, color: Colors.cyanAccent, size: 32),
          const SizedBox(width: 16),
          Text(
            'CODEDEX',
            style: GoogleFonts.orbitron(
              color: Colors.white,
              fontSize: 28,
              fontWeight: FontWeight.bold,
              letterSpacing: 2,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLessonCard(CodedexEntry entry) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: entry.isUnlocked
              ? Colors.cyanAccent.withValues(alpha: 0.3)
              : Colors.white.withValues(alpha: 0.1),
        ),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        leading: Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: entry.isUnlocked
                ? Colors.cyanAccent.withValues(alpha: 0.2)
                : Colors.white.withValues(alpha: 0.05),
            shape: BoxShape.circle,
          ),
          child: Icon(
            entry.isUnlocked ? Icons.lock_open : Icons.lock,
            color: entry.isUnlocked ? Colors.cyanAccent : Colors.white24,
            size: 20,
          ),
        ),
        title: Text(
          entry.lesson.title,
          style: GoogleFonts.inter(
            color: entry.isUnlocked ? Colors.white : Colors.white38,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 8),
          child: Text(
            entry.isUnlocked
                ? entry.lesson.description
                : 'Complete challenges in this region to unlock.',
            style: GoogleFonts.inter(
              color: entry.isUnlocked ? Colors.white70 : Colors.white24,
              fontSize: 14,
            ),
          ),
        ),
        trailing: entry.isUnlocked
            ? const Icon(Icons.chevron_right, color: Colors.cyanAccent)
            : null,
        onTap: entry.isUnlocked
            ? () {
                // Show lesson detail or replay
              }
            : null,
      ),
    );
  }

  Widget _buildLessonList(List<CodedexEntry> entries) {
    if (entries.isEmpty) {
      return Center(
        child: Text(
          'No data found in this sector.',
          style: GoogleFonts.inter(color: Colors.white38),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: entries.length,
      itemBuilder: (context, index) {
        final entry = entries[index];
        return _buildLessonCard(entry);
      },
    );
  }
}
