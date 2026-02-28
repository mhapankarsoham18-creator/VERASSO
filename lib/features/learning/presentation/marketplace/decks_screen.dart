import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:verasso/core/ui/glass_container.dart';
import 'package:verasso/core/ui/liquid_background.dart';

import '../../data/flashcard_model.dart';
import 'flashcard_controller.dart';

// --- Deck Detail / Study Screen ---
/// A screen that displays the details of a flashcard deck and allows users to study them.
class DeckDetailScreen extends ConsumerStatefulWidget {
  /// The deck to display.
  final Deck deck;

  /// Creates a [DeckDetailScreen] instance.
  const DeckDetailScreen({super.key, required this.deck});

  @override
  ConsumerState<DeckDetailScreen> createState() => _DeckDetailScreenState();
}

// --- Decks List Screen ---
/// A screen that displays a list of available flashcard decks.
class DecksScreen extends ConsumerWidget {
  /// Creates a [DecksScreen] instance.
  const DecksScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final decksAsync = ref.watch(decksProvider);

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(title: const Text('Flashcard Decks')),
      body: LiquidBackground(
        child: decksAsync.when(
          data: (decks) {
            if (decks.isEmpty) {
              return Center(
                  child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('No decks yet.'),
                  const SizedBox(height: 20),
                  ElevatedButton(
                      onPressed: () => _showCreateDeckDialog(context, ref),
                      child: const Text('Create Deck'))
                ],
              ));
            }
            return ListView.builder(
              padding: const EdgeInsets.only(top: 100, left: 16, right: 16),
              itemCount: decks.length,
              itemBuilder: (context, index) {
                final deck = decks[index];
                return GestureDetector(
                  onTap: () => Navigator.of(context).push(MaterialPageRoute(
                      builder: (_) => DeckDetailScreen(deck: deck))),
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 16),
                    child: GlassContainer(
                      padding: const EdgeInsets.all(20),
                      child: Row(
                        children: [
                          const Icon(LucideIcons.copy,
                              size: 30, color: Colors.blue),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(deck.title,
                                    style: const TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold)),
                                Text(
                                    '${deck.subject} • ${deck.description ?? ""}',
                                    style:
                                        const TextStyle(color: Colors.white70)),
                              ],
                            ),
                          ),
                          const Icon(LucideIcons.chevronRight,
                              color: Colors.white54)
                        ],
                      ),
                    ),
                  ),
                );
              },
            );
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, s) => Center(child: Text('Error: $e')),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        child: const Icon(LucideIcons.plus),
        onPressed: () => _showCreateDeckDialog(context, ref),
      ),
    );
  }

  void _showCreateDeckDialog(BuildContext context, WidgetRef ref) {
    final titleCtrl = TextEditingController();
    final subjectCtrl = TextEditingController();

    showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
              title: const Text('New Deck'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                      controller: titleCtrl,
                      decoration: const InputDecoration(labelText: 'Title')),
                  TextField(
                      controller: subjectCtrl,
                      decoration: const InputDecoration(labelText: 'Subject')),
                ],
              ),
              actions: [
                TextButton(
                    onPressed: () => Navigator.pop(ctx),
                    child: const Text('Cancel')),
                ElevatedButton(
                    onPressed: () {
                      if (titleCtrl.text.isNotEmpty) {
                        ref
                            .read(flashcardControllerProvider.notifier)
                            .createDeck(titleCtrl.text, subjectCtrl.text, '');
                        Navigator.pop(ctx);
                      }
                    },
                    child: const Text('Create'))
              ],
            ));
  }
}

class _DeckDetailScreenState extends ConsumerState<DeckDetailScreen> {
  bool _isFlipped = false;
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    final cardsAsync = ref.watch(deckCardsProvider(widget.deck.id));

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(title: Text(widget.deck.title)),
      body: LiquidBackground(
        child: cardsAsync.when(
          data: (cards) {
            if (cards.isEmpty) {
              return Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text('No cards in this deck.'),
                    const SizedBox(height: 10),
                    ElevatedButton(
                        onPressed: () => _showAddCardDialog(context, ref),
                        child: const Text('Add Card'))
                  ],
                ),
              );
            }

            final currentCard = cards[_currentIndex];

            return Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Flashcard Area
                GestureDetector(
                  onTap: () => setState(() => _isFlipped = !_isFlipped),
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 500),
                    transitionBuilder:
                        (Widget child, Animation<double> animation) {
                      final rotate =
                          Tween(begin: math.pi, end: 0.0).animate(animation);
                      return AnimatedBuilder(
                        animation: rotate,
                        child: child,
                        builder: (context, child) {
                          final isUnder = (ValueKey(_isFlipped) != child!.key);
                          var tilt =
                              ((animation.value - 0.5).abs() - 0.5) * 0.003;
                          tilt *= isUnder ? -1.0 : 1.0;
                          final value = isUnder
                              ? math.min(rotate.value, math.pi / 2)
                              : rotate.value;
                          return Transform(
                            transform: Matrix4.rotationY(value)
                              ..setEntry(3, 0, tilt),
                            alignment: Alignment.center,
                            child: child,
                          );
                        },
                      );
                    },
                    child: _isFlipped
                        ? _buildCardFace(currentCard.backText, true)
                        : _buildCardFace(currentCard.frontText, false),
                  ),
                ),

                const SizedBox(height: 30),

                // Controls
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    IconButton(
                      icon: const Icon(LucideIcons.chevronLeft,
                          color: Colors.white),
                      onPressed: _currentIndex > 0
                          ? () {
                              setState(() {
                                _currentIndex--;
                                _isFlipped = false;
                              });
                            }
                          : null,
                    ),
                    Text('${_currentIndex + 1} / ${cards.length}',
                        style: const TextStyle(fontSize: 18)),
                    IconButton(
                      icon: const Icon(LucideIcons.chevronRight,
                          color: Colors.white),
                      onPressed: _currentIndex < cards.length - 1
                          ? () {
                              setState(() {
                                _currentIndex++;
                                _isFlipped = false;
                              });
                            }
                          : null,
                    ),
                  ],
                ),

                const SizedBox(height: 20),
                TextButton.icon(
                    onPressed: () => _showAddCardDialog(context, ref),
                    icon: const Icon(LucideIcons.plus),
                    label: const Text('Add New Card'))
              ],
            );
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, s) => Center(child: Text('Error: $e')),
        ),
      ),
    );
  }

  Widget _buildCardFace(String text, bool isBack) {
    return Container(
      key: ValueKey(isBack),
      width: 300,
      height: 400,
      decoration: BoxDecoration(
        color: isBack
            ? Colors.blue.withValues(alpha: 0.8)
            : Colors.white.withValues(alpha: 0.9), // Visual distinction
        borderRadius: BorderRadius.circular(20),
        boxShadow: const [
          BoxShadow(color: Colors.black26, blurRadius: 10, offset: Offset(0, 4))
        ],
      ),
      alignment: Alignment.center,
      padding: const EdgeInsets.all(20),
      child: Text(text,
          textAlign: TextAlign.center,
          style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: isBack ? Colors.white : Colors.black87)),
    );
  }

  void _showAddCardDialog(BuildContext context, WidgetRef ref) {
    final frontCtrl = TextEditingController();
    final backCtrl = TextEditingController();

    showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
              title: const Text('Add Card'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                      controller: frontCtrl,
                      decoration:
                          const InputDecoration(labelText: 'Front (Question)')),
                  TextField(
                      controller: backCtrl,
                      decoration:
                          const InputDecoration(labelText: 'Back (Answer)')),
                ],
              ),
              actions: [
                TextButton(
                    onPressed: () => Navigator.pop(ctx),
                    child: const Text('Cancel')),
                ElevatedButton(
                    onPressed: () {
                      if (frontCtrl.text.isNotEmpty) {
                        ref.read(flashcardControllerProvider.notifier).addCard(
                            widget.deck.id, frontCtrl.text, backCtrl.text);
                        Navigator.pop(ctx);
                      }
                    },
                    child: const Text('Add'))
              ],
            ));
  }
}
