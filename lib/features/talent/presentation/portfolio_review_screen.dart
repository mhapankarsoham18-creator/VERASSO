import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:verasso/core/ui/glass_container.dart';
import 'package:verasso/core/ui/liquid_background.dart';

/// Screen for reviewing a specific portfolio item.
class PortfolioReviewScreen extends StatelessWidget {
  /// The unique identifier of the portfolio item to review.
  final String portfolioId;

  /// Creates a [PortfolioReviewScreen].
  const PortfolioReviewScreen({super.key, required this.portfolioId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text("Portfolio Review"),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: LiquidBackground(
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const GlassContainer(
                  child: ListTile(
                    leading: CircleAvatar(child: Icon(LucideIcons.user)),
                    title: Text("Talent Name",
                        style: TextStyle(color: Colors.white)),
                    subtitle: Text("UI/UX Designer • Level 4",
                        style: TextStyle(color: Colors.white70)),
                  ),
                ),
                const SizedBox(height: 20),
                const Text("Submission Content",
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold)),
                const SizedBox(height: 10),
                const GlassContainer(
                  height: 200,
                  child: Center(
                    child: Icon(LucideIcons.image,
                        size: 64, color: Colors.white24),
                  ),
                ),
                const SizedBox(height: 20),
                const Text("Review Comments",
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold)),
                const SizedBox(height: 10),
                TextField(
                  maxLines: 4,
                  decoration: InputDecoration(
                    hintText: "Enter your feedback...",
                    filled: true,
                    fillColor: Colors.white.withValues(alpha: 0.1),
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none),
                  ),
                ),
                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: () {},
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blueAccent,
                    minimumSize: const Size(double.infinity, 50),
                  ),
                  child: const Text("Submit Review"),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
