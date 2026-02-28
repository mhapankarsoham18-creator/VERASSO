import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:verasso/core/ui/glass_container.dart';

import '../../../data/classroom_session_service.dart';

/// A widget that displays a poll and allows users to cast their votes.
class PollVotingWidget extends StatefulWidget {
  /// The poll data to display.
  final SessionPoll poll;

  /// Callback triggered when an option at [optionIndex] is voted for.
  final Function(int optionIndex) onVote;

  /// Whether the current user is a teacher (allows viewing results without voting).
  final bool isTeacher;

  /// Creates a [PollVotingWidget] instance.
  const PollVotingWidget({
    super.key,
    required this.poll,
    required this.onVote,
    this.isTeacher = false,
  });

  @override
  State<PollVotingWidget> createState() => _PollVotingWidgetState();
}

class _PollVotingWidgetState extends State<PollVotingWidget> {
  int? _selectedOption;

  @override
  Widget build(BuildContext context) {
    // Calculate total votes
    int totalVotes =
        widget.poll.votes.values.fold(0, (sum, count) => sum + count);

    return GlassContainer(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                  child: Text(widget.poll.question,
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold))),
              if (widget.isTeacher)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                      color: Colors.blueAccent,
                      borderRadius: BorderRadius.circular(8)),
                  child: Text("Live: $totalVotes votes",
                      style:
                          const TextStyle(color: Colors.white, fontSize: 12)),
                )
            ],
          ),
          const SizedBox(height: 16),
          ...List.generate(widget.poll.options.length, (index) {
            final option = widget.poll.options[index];
            // Fix: Map key is String index
            final voteCount = widget.poll.votes[index.toString()] ?? 0;
            final percentage = totalVotes == 0 ? 0.0 : (voteCount / totalVotes);
            final isSelected = _selectedOption == index;

            return GestureDetector(
              onTap: widget.isTeacher || _selectedOption != null
                  ? null
                  : () {
                      setState(() => _selectedOption = index);
                      widget.onVote(index);
                    },
              child: Container(
                margin: const EdgeInsets.only(bottom: 8),
                height: 50,
                child: Stack(
                  children: [
                    // Background Bar (Results)
                    if (widget.isTeacher || _selectedOption != null)
                      FractionallySizedBox(
                        widthFactor: percentage,
                        child: Container(
                          decoration: BoxDecoration(
                            color: Colors.blueAccent.withValues(alpha: 0.3),
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ).animate().scaleX(
                          duration: 500.ms, alignment: Alignment.centerLeft),

                    // Button Frame
                    Container(
                      decoration: BoxDecoration(
                        border: Border.all(
                          color:
                              isSelected ? Colors.blueAccent : Colors.white24,
                          width: isSelected ? 2 : 1,
                        ),
                        borderRadius: BorderRadius.circular(12),
                        color: isSelected
                            ? Colors.blueAccent.withValues(alpha: 0.1)
                            : Colors.transparent,
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      alignment: Alignment.centerLeft,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(option,
                              style: const TextStyle(color: Colors.white)),
                          if (widget.isTeacher || _selectedOption != null)
                            Text("${(percentage * 100).toStringAsFixed(1)}%",
                                style: const TextStyle(color: Colors.white70)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            );
          }),
        ],
      ),
    );
  }
}
