import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:verasso/core/ui/error_view.dart';
import 'package:verasso/core/ui/glass_container.dart';
import 'package:verasso/core/ui/liquid_background.dart';

import '../../auth/presentation/auth_controller.dart';
import '../data/mentor_model.dart';
import '../data/mentor_repository.dart';
import '../data/mentorship_models.dart';
import '../data/mentorship_repository.dart';
import '../data/talent_model.dart';

/// Provider that fetches talent packages offered by a specific mentor.
final mentorPackagesProvider =
    FutureProvider.family<List<TalentPost>, String>((ref, mentorId) {
  return ref.watch(mentorRepositoryProvider).getMentorPackages(mentorId);
});

/// Screen displaying detailed information about a mentor and their packages.
class MentorDetailScreen extends ConsumerWidget {
  /// The mentor profile to display.
  final MentorProfile mentor;

  /// Creates a [MentorDetailScreen].
  const MentorDetailScreen({super.key, required this.mentor});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final packagesAsync = ref.watch(mentorPackagesProvider(mentor.userId));

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(backgroundColor: Colors.transparent),
      body: LiquidBackground(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 100, 16, 40),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(),
              const SizedBox(height: 24),
              _buildBio(),
              const SizedBox(height: 32),
              const Text('Mentorship Packages',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              packagesAsync.when(
                data: (packages) {
                  if (packages.isEmpty) {
                    return const Text('No mentorship packages available yet.');
                  }
                  return Column(
                    children: packages
                        .map((pkg) => _buildPackageCard(context, ref, pkg))
                        .toList(),
                  );
                },
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (e, _) => AppErrorView(
                  message: e.toString(),
                  onRetry: () =>
                      ref.invalidate(mentorPackagesProvider(mentor.userId)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBio() {
    return GlassContainer(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('About Me',
              style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.white70)),
          const SizedBox(height: 8),
          Text(mentor.bio ?? 'No bio provided.',
              style: const TextStyle(color: Colors.white54, height: 1.5)),
          const SizedBox(height: 16),
          const Text('Specializations',
              style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Colors.white70)),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            children: mentor.specializations
                .map((s) => Chip(
                      label: Text(s, style: const TextStyle(fontSize: 10)),
                      backgroundColor: Colors.white10,
                      padding: EdgeInsets.zero,
                    ))
                .toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return GlassContainer(
      padding: const EdgeInsets.all(24),
      child: Row(
        children: [
          const CircleAvatar(
              radius: 40,
              backgroundImage: NetworkImage('https://i.pravatar.cc/150')),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(mentor.headline ?? 'Top Mentor',
                        style: const TextStyle(
                            fontSize: 22, fontWeight: FontWeight.bold)),
                    const SizedBox(width: 4),
                    const Icon(LucideIcons.badgeCheck,
                        color: Colors.blueAccent, size: 20),
                  ],
                ),
                Text('${mentor.experienceYears} Years of Experience',
                    style: const TextStyle(
                        color: Colors.blueAccent, fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Icon(LucideIcons.star, size: 14, color: Colors.amber),
                    const SizedBox(width: 4),
                    Text(mentor.averageRating.toStringAsFixed(1),
                        style: const TextStyle(fontWeight: FontWeight.bold)),
                    const SizedBox(width: 12),
                    const Icon(LucideIcons.users,
                        size: 14, color: Colors.white54),
                    const SizedBox(width: 4),
                    Text('${mentor.totalMentees} Mentees',
                        style: const TextStyle(
                            color: Colors.white54, fontSize: 13)),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPackageCard(
      BuildContext context, WidgetRef ref, TalentPost pkg) {
    return GlassContainer(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(pkg.title,
                  style: const TextStyle(
                      fontSize: 18, fontWeight: FontWeight.bold)),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                    color: Colors.blueAccent.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(20)),
                child: Text('\$${pkg.price}/${_periodLabel(pkg.billingPeriod)}',
                    style: const TextStyle(
                        color: Colors.blueAccent,
                        fontWeight: FontWeight.bold,
                        fontSize: 12)),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(pkg.description ?? '',
              style: const TextStyle(color: Colors.white54, fontSize: 13)),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () => _confirmBooking(context, ref, pkg),
              style:
                  ElevatedButton.styleFrom(backgroundColor: Colors.blueAccent),
              child: const Text('Book Mentorship'),
            ),
          ),
        ],
      ),
    );
  }

  void _confirmBooking(
      BuildContext context, WidgetRef ref, TalentPost pkg) async {
    final studentId = ref.read(currentUserProvider)?.id;
    if (studentId == null) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Please log in to book')));
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A1A),
        title: const Text('Confirm Booking'),
        content: Text(
            'Do you want to book "${pkg.title}" for \$${pkg.price}/${_periodLabel(pkg.billingPeriod)}?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel')),
          ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Confirm')),
        ],
      ),
    );

    if (confirmed == true) {
      final booking = MentorshipBooking(
        id: '',
        studentId: studentId,
        mentorId: mentor.userId,
        talentPostId: pkg.id,
        billingPeriod: pkg.billingPeriod,
        priceAtBooking: pkg.price,
        startDate: DateTime.now(),
        createdAt: DateTime.now(),
      );

      try {
        await ref.read(mentorshipRepositoryProvider).createBooking(booking);
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Booking Request Sent!')));
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context)
              .showSnackBar(SnackBar(content: Text('Error: $e')));
        }
      }
    }
  }

  String _periodLabel(String p) {
    switch (p) {
      case 'hourly':
        return 'hr';
      case 'monthly':
        return 'mo';
      case 'quarterly':
        return 'qtr';
      case 'yearly':
        return 'yr';
      default:
        return 'unit';
    }
  }
}
