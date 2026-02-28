import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';

/// Widget that displays or edits the portfolio section of a talent profile.
class TalentPortfolioList extends StatelessWidget {
  /// List of portfolio URLs.
  final List<String> portfolioUrls;

  /// Whether the list is in editing mode.
  final bool isEditing;

  /// Callback when an item is removed.
  final Function(int) onRemove;

  /// Creates a [TalentPortfolioList].
  const TalentPortfolioList({
    super.key,
    required this.portfolioUrls,
    required this.isEditing,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    if (portfolioUrls.isEmpty) {
      return const Text('No portfolio links listed.',
          style: TextStyle(color: Colors.white38));
    }
    return Column(
      children: portfolioUrls
          .asMap()
          .entries
          .map((entry) => _PortfolioItem(
                entry.value,
                entry.key,
                isEditing,
                onRemove,
              ))
          .toList(),
    );
  }
}

class _PortfolioItem extends StatelessWidget {
  final String url;
  final int index;
  final bool isEditing;
  final Function(int) onRemove;

  const _PortfolioItem(this.url, this.index, this.isEditing, this.onRemove);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          const Icon(LucideIcons.externalLink,
              size: 16, color: Colors.blueAccent),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              url,
              style: const TextStyle(
                  color: Colors.blue, decoration: TextDecoration.underline),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          if (isEditing)
            IconButton(
              icon: const Icon(LucideIcons.trash2,
                  size: 14, color: Colors.redAccent),
              onPressed: () => onRemove(index),
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
            ),
        ],
      ),
    );
  }
}
